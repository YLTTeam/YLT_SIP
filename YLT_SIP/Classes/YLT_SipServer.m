//
//  YTL_Sip.m
//  SecretVoice
//
//  Created by YLT_Alex on 2017/10/25.
//  Copyright © 2017年 QTEC. All rights reserved.
//

#import "YLT_SipServer.h"
#import <YLT_BaseLib/YLT_BaseMacro.h>
#import <pjsua.h>
#import <openssl/evp.h>
#import "sip_types.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import "YLT_CallAudio.h"
#import "YLT_CallManager.h"

#define THIS_FILE "YLT_SipServer.m"

#define NEED_ENCODER YES

const size_t MAX_SIP_ID_LENGTH = 50;
const size_t MAX_SIP_REG_URI_LENGTH = 50;

static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_call_media_state(pjsua_call_id call_id);
static void on_reg_state2(pjsua_acc_id acc_id, pjsua_reg_info *info);
static void error_exit(const char *title, pj_status_t status);
static void on_call_sdp_created(pjsua_call_id call_id,
                                pjmedia_sdp_session *sdp,
                                pj_pool_t *pool,
                                const pjmedia_sdp_session *rem_sdp);

@interface YLT_SipServer () {
}

/**
 注册的回调
 */
@property (nonatomic, copy) void(^registerCallback)(BOOL success);
/**
 密钥 安全密钥必须
 */
@property (nonatomic, strong) NSString *keys;
/**
 key id 用来获取加密密钥的key
 */
@property (nonatomic, strong) NSString *keyId;
/**
 通过KEY ID 获取Key 非安全通话 不比理会
 */
@property (nonatomic, copy) NSString *(^keysBlock)(NSString *keyId);

@end

@implementation YLT_SipServer

static YLT_SipServer *sipShareData = nil;
+ (YLT_SipServer *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sipShareData = [[self alloc] init];
    });
    return sipShareData;
}

/**
 注册Sip服务
 
 @param server 服务器域名
 @param port 服务器端口号
 @param username 用户名
 @param password 密码
 @param callback 回调
 @return 是否登录成功
 */
- (BOOL)registerServiceOnServer:(NSString *)server
                           port:(NSInteger)port
                       username:(NSString *)username
                       password:(NSString *)password
                       callback:(void(^)(BOOL success))callback {
    self.registerCallback = callback;
    //    username = @"1001";
    //    password = @"123456";
    port = (port==0)?5060:port;
    pj_status_t status;
    //注册线程
    if (!pj_thread_is_registered()) {
        pj_thread_desc desc;
        pj_thread_t *thread;
        status = pj_thread_register(NULL, desc, &thread);
        if (status != PJ_SUCCESS) {
            YLT_LogError(@"线程注册失败");
        }
    }
    if (self.currentUser.loginState) {
        [self logout];
    }
    status = pjsua_destroy();
    if (status != PJ_SUCCESS) {
        YLT_LogError(@"信息清除失败");
    }
    status = pjsua_create();
    if (status != PJ_SUCCESS) {
        error_exit("pjsua 创建失败", status);
    }
    //初始化 pjsua
    pjsua_config cfg;
    pjsua_config_default(&cfg);
    cfg.cb.on_incoming_call = &on_incoming_call;//电话进来的回调
    cfg.cb.on_call_media_state = &on_call_media_state;//
    cfg.cb.on_call_state = &on_call_state;
    cfg.cb.on_reg_state2 = &on_reg_state2;
    cfg.cb.on_call_sdp_created = &on_call_sdp_created;
    
    pjsua_logging_config log_cfg;
    pjsua_logging_config_default(&log_cfg);
    log_cfg.console_level = 4;
    
    pjsua_media_config media_cfg;
    pjsua_media_config_default(&media_cfg);
    
    status = pjsua_init(&cfg, &log_cfg, &media_cfg);
    if (status != PJ_SUCCESS) {
        YLT_LogError(@"初始化失败");
        return NO;
    }
    
    //添加 UDP 协议支持
    pjsua_transport_config udp_cfg;
    pjsua_transport_config_default(&udp_cfg);
    udp_cfg.port = (unsigned int)port;
    status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &udp_cfg, NULL);
    if (status != PJ_SUCCESS) {
        YLT_LogError(@"UDP创建失败");
        return NO;
    }
    
    //    pjsua_transport_config tcp_cfg;
    //    pjsua_transport_config_default(&tcp_cfg);
    //    tcp_cfg.port = (unsigned int)port;
    //    status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &tcp_cfg, NULL);
    //    if (status != PJ_SUCCESS) {
    //        YLT_LogError(@"创建TCP传输失败");
    //        return NO;
    //    }
    
    //启动 pjsua
    // 启动pjsua
    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        YLT_LogError(@"启动组件失败");
        return NO;
    }
    //配置账号
    pjsua_acc_config acc_cfg;
    pjsua_acc_config_default(&acc_cfg);
    
    acc_cfg.id = pj_str((char *)[NSString stringWithFormat:@"sip:%@@%@", username, server].UTF8String);
    acc_cfg.reg_uri = pj_str((char *)[NSString stringWithFormat:@"sip:%@", server].UTF8String);
    // Account cred info
    acc_cfg.cred_count = 1;
    acc_cfg.cred_info[0].scheme = pj_str("digest");
    acc_cfg.cred_info[0].realm = pj_str("*");
    acc_cfg.cred_info[0].username = pj_str((char *)[username UTF8String]);
    acc_cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    acc_cfg.cred_info[0].data = pj_str((char *)[password UTF8String]);
    acc_cfg.media_stun_use = PJSUA_STUN_USE_DISABLED;
    acc_cfg.sip_stun_use = PJSUA_STUN_USE_DISABLED;
    
    pjsua_acc_id _acc_id;
    status = pjsua_acc_add(&acc_cfg, PJ_TRUE, &_acc_id);
    if (status != PJ_SUCCESS) {
        YLT_LogError(@"添加创建账户失败");
        return NO;
    }
    self.currentUser.accId = _acc_id;
    self.currentUser.username = username;
    self.currentUser.password = password;
    self.currentUser.domain = server;
    self.currentUser.port = port;
    [self.currentUser save];
    return YES;
}

/**
 自动登录
 */
- (void)autoLogin {
    [self.currentSession clear];
    self.currentUser.loginState = NO;
    if ([self.currentUser read] && self.currentUser.check) {//读取上次登录的用户数据
        self.currentUser.loginState = NO;
        @weakify(self);
        [self registerServiceOnServer:self.currentUser.domain port:self.currentUser.port username:self.currentUser.username password:self.currentUser.password callback:^(BOOL success) {
            @strongify(self);
        }];
    }
}

/**
 退出登录
 */
- (BOOL)logout {
    if (pjsua_acc_is_valid(self.currentUser.accId)) {
        pj_status_t status = pjsua_acc_del(self.currentUser.accId);
        if (status != PJ_SUCCESS) {
            error_exit("退出失败", status);
            return NO;
        }
        self.callback = NULL;
        return YES;
    }
    return YES;
}

/**
 拨打电话
 
 @param destPhone 目标电话
 @param keys 密钥 安全通话必须
 */
- (void)makeCallTo:(NSString *)destPhone keys:(NSDictionary *)keys {
    if ([keys isKindOfClass:[NSDictionary class]] && keys.allKeys.count > 0) {
        self.keyId = [keys.allKeys firstObject];
        self.keys = [keys objectForKey:self.keyId];
        self.callback(SIP_STATUS_SAFE, nil);
    } else {
        self.keys = nil;
        self.keyId = @"";
        self.callback(SIP_STATUS_UNSAFE, nil);
    }
    NSString *destURI = [NSString stringWithFormat:@"sip:%@@%@", destPhone, self.currentUser.domain];
    pj_str_t uri = pj_str((char *)[destURI UTF8String]);
    pjsua_call_id callId = 0;
    pj_status_t status = pjsua_call_make_call(self.currentUser.accId, &uri, 0, NULL, NULL, &callId);
    self.currentSession.phone = destURI;
    self.currentSession.sessionType = 1;
    self.currentSession.startTime = [[NSDate date] timeIntervalSince1970];
    self.currentSession.callId = callId;
    if (status != PJ_SUCCESS) {
        YLT_LogError(@"呼叫失败  %zd", status);
        [[YLT_CallAudio shareInstance] stopAudio];
        self.callback(SIP_STATUS_CALL_FAILED, nil);
        [self save];
    }
}

/**
 应答
 */
- (void)answerCall {
    if (self.currentSession.callId == PJSUA_INVALID_ID) {
        return;
    }
    BOOL res = [self.keys YLT_CheckString] && [self.keyId YLT_CheckString];
    if (res) {
        pjsua_call_set_user_data(self.currentSession.callId, (void *)self.keyId.UTF8String);
    }
    self.currentSession.unRead = 0;
    pj_status_t status = pjsua_call_answer(self.currentSession.callId, 200, NULL, NULL);
    self.currentSession.sessionType = 0;
    self.currentSession.startTime = [[NSDate date] timeIntervalSince1970];
    if (status != PJ_SUCCESS) {
        YLT_LogError(@"应答失败");
        [[YLT_CallAudio shareInstance] stopAudio];
        [[YLT_CallManager shareInstance] updateCallState:YLT_CallStateEnded];
        [self save];
        self.callback(SIP_STATUS_ANSWER_FAILED, nil);
    }
}

/**
 挂断
 */
- (void)hangUp {
    self.currentSession.unRead = 0;
    pjsua_call_hangup_all();
}

/**
 保持活跃
 */
- (void)keepAlive {
    if (!pj_thread_is_registered()) {
        static pj_thread_desc desc;
        static pj_thread_t *thread;
        pj_thread_register("PJ_MAIN_THREAD", desc, &thread);
    }
    pj_thread_sleep(5000);
}

#pragma mark - lazy
- (YLT_SipUser *)currentUser {
    if (!_currentUser) {
        _currentUser = [[YLT_SipUser alloc] init];
    }
    return _currentUser;
}

- (YLT_SipSession *)currentSession {
    if (!_currentSession) {
        _currentSession = [[YLT_SipSession alloc] init];
    }
    return _currentSession;
}

- (void)setMute:(BOOL)mute {
    if (mute) {//设置静音
        _mute = ((pjsua_conf_adjust_rx_level(0, 1) == PJ_SUCCESS) && (pjsua_conf_adjust_tx_level(0, 0) == PJ_SUCCESS));
    } else {
        _mute = !((pjsua_conf_adjust_rx_level(0, 1) == PJ_SUCCESS) && (pjsua_conf_adjust_tx_level(0, 1) == PJ_SUCCESS));
    }
}

- (void(^)(SipStatus status, NSDictionary *info))callback {
    if (!_callback) {
        _callback = ^(SipStatus status, NSDictionary *info) {
            NSLog(@"%@", info);
        };
    }
    return _callback;
}

- (void)save {
    if (self.currentSession.startTime == 0) {
        self.currentSession.startTime = [[NSDate date] timeIntervalSince1970];
    }
    self.currentSession.endTime = [[NSDate date] timeIntervalSince1970];
    [self.currentSession saveCallback:^(BOOL success, id response) {
    }];
}

@end




#pragma mark - c method



/* 注册状态改变的回调 */
static void on_reg_state2(pjsua_acc_id acc_id, pjsua_reg_info *info) {
    switch (info->cbparam->code) {
        case 200://注册成功
            [YLT_SipServer sharedInstance].currentUser.loginState = YES;
            [YLT_SipServer sharedInstance].registerCallback(YES);
            break;
        case 401://注册失败
            [YLT_SipServer sharedInstance].currentUser.loginState = NO;
            [YLT_SipServer sharedInstance].registerCallback(NO);
            break;
        default:
            [YLT_SipServer sharedInstance].currentUser.loginState = NO;
            [YLT_SipServer sharedInstance].registerCallback(NO);
            break;
    }
}

static void call_status_change(pjsua_call_info ci) {
    switch (ci.state) {
        case PJSIP_INV_STATE_INCOMING: {
            [YLT_SipServer sharedInstance].currentSession.sessionType = 0;
            [YLT_SipServer sharedInstance].currentSession.startTime = [[NSDate date] timeIntervalSince1970];
            [YLT_SipServer sharedInstance].callback(SIP_STATUS_INCOMING, @{@"name":[NSString stringWithUTF8String:ci.remote_info.ptr]});
        }
            break;
        case PJSIP_INV_STATE_NULL:{
            [YLT_SipServer sharedInstance].callback(SIP_STATUS_NORMAL, nil);
        }
            break;
        case PJSIP_INV_STATE_CONFIRMED: {
            [YLT_SipServer sharedInstance].currentSession.answer = YES;
            [YLT_SipServer sharedInstance].currentSession.startTime = [[NSDate date] timeIntervalSince1970];//接听了就更新一下起始时间
            [YLT_SipServer sharedInstance].callback(SIP_STATUS_CONFIRMED, @{@"name":[NSString stringWithUTF8String:ci.remote_info.ptr]});
        }
            break;
        case PJSIP_INV_STATE_CALLING: {
            [YLT_SipServer sharedInstance].currentSession.sessionType = 1;
            [YLT_SipServer sharedInstance].currentSession.startTime = [[NSDate date] timeIntervalSince1970];
            [YLT_SipServer sharedInstance].callback(SIP_STATUS_CALLING, @{@"name":[NSString stringWithUTF8String:ci.remote_info.ptr]});
        }
            break;
        case PJSIP_INV_STATE_EARLY: {
            [YLT_SipServer sharedInstance].callback(SIP_STATUS_EARLY, nil);
        }
            break;
        case PJSIP_INV_STATE_CONNECTING: {
            [YLT_SipServer sharedInstance].callback(SIP_STATUS_CONNECTING, nil);
        }
            break;
        case PJSIP_INV_STATE_DISCONNECTED: {
            if ([YLT_SipServer sharedInstance].currentSession.state == PJSIP_INV_STATE_CALLING) {
                printf("呼叫失败！");
                [YLT_SipServer sharedInstance].callback(SIP_STATUS_CALL_FAILED, nil);
            } else {
                [YLT_SipServer sharedInstance].callback(SIP_STATUS_DISCONNECTED, nil);
            }
            //保存通话记录并重制最新通话记录的数据
            if ([YLT_SipServer sharedInstance].currentSession.state != PJSIP_INV_STATE_DISCONNECTED) {
            }
            [[YLT_CallManager shareInstance] updateCallState:YLT_CallStateEnded];
            [[YLT_SipServer sharedInstance] save];
        }
            break;
    }
    
    if (ci.state == PJSIP_INV_STATE_CONNECTING) {
        pjmedia_key_clear();
    } else if (ci.state == PJSIP_INV_STATE_CONFIRMED) {
        if (ci.remote_key.ptr && [[YLT_SipServer sharedInstance].keyId isEqualToString:[NSString stringWithUTF8String:ci.remote_key.ptr]] && [YLT_SipServer sharedInstance].keyId.YLT_CheckString && [YLT_SipServer sharedInstance].keys.YLT_CheckString) {
            pjmedia_set_key((unsigned char *)[YLT_SipServer sharedInstance].keys.UTF8String, (unsigned int)[YLT_SipServer sharedInstance].keys.length);
            [YLT_SipServer sharedInstance].keyId = @"";
            [YLT_SipServer sharedInstance].keys = @"";
            [YLT_SipServer sharedInstance].callback(SIP_STATUS_SAFE, nil);
        } else {
            [YLT_SipServer sharedInstance].keyId = @"";
            [YLT_SipServer sharedInstance].keys = @"";
            [YLT_SipServer sharedInstance].callback(SIP_STATUS_UNSAFE, nil);
        }
    }
    
    [YLT_SipServer sharedInstance].currentSession.state = ci.state;
}

/* 收到呼入电话的回调 */
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata) {
    [[YLT_SipServer sharedInstance].currentSession clear];
    pjsua_call_info ci;
    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);
    pjsua_call_get_info(call_id, &ci);
    PJ_LOG(3,(THIS_FILE, "Incoming call from %.*s!!",
              (int)ci.remote_info.slen,
              ci.remote_info.ptr));
    [YLT_SipServer sharedInstance].currentSession.phone = [NSString stringWithUTF8String:ci.remote_info.ptr];
    [YLT_SipServer sharedInstance].currentSession.unRead = 1;//未读
    if ([YLT_SipServer sharedInstance].currentSession.callId == PJSUA_INVALID_ID) {
        [YLT_SipServer sharedInstance].currentSession.callId = call_id;
        
    } else {//当前通话处理占线状态
        [YLT_SipServer sharedInstance].callback(SIP_STATUS_BUSYING, nil);
        [[YLT_SipServer sharedInstance] save];
        return;
    }
    [YLT_SipServer sharedInstance].callback(SIP_STATUS_INCOMING, @{@"name":[NSString stringWithUTF8String:ci.remote_info.ptr]});
}

/* 呼出状态改变的回调 */
static void on_call_state(pjsua_call_id call_id, pjsip_event *e) {
    pjsua_call_info ci;
    PJ_UNUSED_ARG(e);
    pjsua_call_get_info(call_id, &ci);
    call_status_change(ci);
}

/* 会话时media状态改变的回调 */
static void on_call_media_state(pjsua_call_id call_id) {
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
        printf("会话成功，创建语音设备连接");
    }
}

/* 输出错误信息 */
static void error_exit(const char *title, pj_status_t status) {
    pjsua_perror(THIS_FILE, title, status);
    pjsua_destroy();
    exit(1);
}

/* SDP包创建时候的回调 */
static void on_call_sdp_created(pjsua_call_id call_id,
                                pjmedia_sdp_session *sdp,
                                pj_pool_t *pool,
                                const pjmedia_sdp_session *rem_sdp) {
    
    /**
     * 远程里面有数据      说明是接收方     接收方解密
     * 远程里面没有数据    说明是发送方     发送方加密数据
     **/
    if (rem_sdp) {//接收方  下面接收加密密钥索引
        pjmedia_sdp_attr *key = NULL;
        for (int i = 0; i < rem_sdp->media_count; i++) {
            pjmedia_sdp_media *media = *(rem_sdp->media+i);
            pj_str_t k = {"k", 1};
            key = pjmedia_sdp_attr_find(media->attr_count, media->attr, &k, NULL);
            if (key) {
                break;
            }
        }
        if (key) {
            [YLT_SipServer sharedInstance].keyId = [[NSString alloc] initWithCString:key->value.ptr encoding:NSUTF8StringEncoding];
            if (NEED_ENCODER && [[YLT_SipServer sharedInstance].keyId YLT_CheckString] && [YLT_SipServer sharedInstance].receiveCall) {
                [YLT_SipServer sharedInstance].keys = [YLT_SipServer sharedInstance].receiveCall([YLT_SipServer sharedInstance].keyId);
                [YLT_SipServer sharedInstance].callback(SIP_STATUS_SAFE, nil);
            } else {
                [YLT_SipServer sharedInstance].callback(SIP_STATUS_UNSAFE, nil);
            }
        } else {
            [YLT_SipServer sharedInstance].callback(SIP_STATUS_UNSAFE, nil);
        }
    } else {//发送方  下面传输加密密钥索引
        //获取到需要使用的加密密钥的索引  然后放到 0807060504030201 字段部分 进行传输
        if ([[YLT_SipServer sharedInstance].keyId YLT_CheckString]) {
            for (int i = 0; i < sdp->media_count; i++) {
                pjmedia_sdp_media *media = *(sdp->media+i);
                if (![[YLT_SipServer sharedInstance].keyId YLT_CheckString]) {
                    [YLT_SipServer sharedInstance].keyId = @"";
                }
                char *keyID = (char *)[YLT_SipServer sharedInstance].keyId.UTF8String;
                pj_str_t value = {keyID, [YLT_SipServer sharedInstance].keyId.length};//索引值
                pjmedia_sdp_attr* key = pjmedia_sdp_attr_create(pool, "k", &value);
                pjmedia_sdp_media_add_attr(media, key);
            }
            [YLT_SipServer sharedInstance].callback(SIP_STATUS_SAFE, nil);
        } else {
            [YLT_SipServer sharedInstance].callback(SIP_STATUS_UNSAFE, nil);
        }
    }
}



