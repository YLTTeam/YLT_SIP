//
//  YTL_Sip.h
//  SecretVoice
//
//  Created by YLT_Alex on 2017/10/25.
//  Copyright © 2017年 QTEC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YLT_SipUser.h"
#import "YLT_SipSession.h"

typedef NS_ENUM(NSUInteger, SipStatus) {
    SIP_STATUS_NORMAL = 1,//无任何状态
    SIP_STATUS_CALLING = 2,//拨打中
    SIP_STATUS_INCOMING = 3,//来电中
    SIP_STATUS_EARLY = 4,//响应了
    SIP_STATUS_CONNECTING = 5,//连接中
    SIP_STATUS_CONFIRMED = 6,//确认了
    SIP_STATUS_DISCONNECTED = 7,//断开了连接
    
    SIP_STATUS_CALL_FAILED = 8,//呼叫失败
    SIP_STATUS_ANSWER_FAILED = 9,//应答失败
    
    SIP_STATUS_BUSYING = 10,//忙线中
    
    SIP_STATUS_UNSAFE = 11,//非安全通话
    SIP_STATUS_SAFE = 12,//安全通话
};



@interface YLT_SipServer : NSObject
/**
 当前用户
 */
@property (nonatomic, strong) YLT_SipUser *currentUser;

/**
 当前会话
 */
@property (nonatomic, strong) YLT_SipSession *currentSession;

/**
 回调
 */
@property (nonatomic, copy) void(^callback)(SipStatus status, NSDictionary *info);
/**
 接收到key id 以后 回调拿到KEY
 */
@property (nonatomic, copy) NSString *(^receiveCall)(NSString *keyId);

/**
 是否静音
 */
@property (nonatomic, assign) BOOL mute;

+ (YLT_SipServer *)sharedInstance;

/**
 注册Sip服务
 
 @param server 服务器域名
 @param port 服务器端口号
 @param username 用户名
 @param password 密码
 @param callback 回调
 @return 是否登录成功
 */
- (BOOL)registerServiceOnServer:(NSString *)server port:(NSInteger)port username:(NSString *)username password:(NSString *)password callback:(void(^)(BOOL success))callback;

/**
 自动登录
 */
- (void)autoLoginCallback:(void(^)(BOOL success))callback;

/**
 退出登录
 
 @return 是否退出成功
 */
- (BOOL)logout;

/**
 拨打电话
 
 @param destPhone 目标电话
 @param keys 密钥 安全通话必须 @"key":@"value" key为密钥的传输KEY，value即为密钥
 */
- (void)makeCallTo:(NSString *)destPhone keys:(NSDictionary *)keys;


/**
 应答
 */
- (void)answerCall;

/**
 挂断
 */
- (void)hangUp;

/**
 保持活跃
 */
- (void)keepAlive;

@end

