//
//  YLT_SipModular.m
//  SecretVoice
//
//  Created by YLT_Alex on 2017/10/26.
//  Copyright © 2017年 QTEC. All rights reserved.
//

#import "YLT_SipModular.h"
#import "YLT_SipServer.h"
#import <PushKit/PushKit.h>
#import "YLT_CallManager.h"
#import <MJExtension/MJExtension.h>
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

@interface PushMessage : YLT_BaseModel {
}
/**
 
 */
@property (readwrite, nonatomic, assign) NSInteger fromUser;
/**
 
 */
@property (readwrite, nonatomic, assign) NSInteger toUser;

@property (readwrite, nonatomic, strong) NSString *fromUsername;

@property (readwrite, nonatomic, strong) NSString *fromMobilephone;
/**
 
 */
@property (readwrite, nonatomic, strong) NSString * timestamp;
/**
 
 */
@property (readwrite, nonatomic, strong) NSString * cmd;

@end

@implementation PushMessage

- (id)init {
    self = [super init];
    if (self) {
        self.fromUser = 0;
        self.toUser = 0;
        self.timestamp = @"";
        self.cmd = @"";
    }
    return self;
}

+ (NSDictionary *)YLT_KeyMapper {
    return @{
             };
}
+ (NSDictionary *)YLT_ClassInArray {
    return @{
             };
}
@end

@interface YLT_SipModular()<PKPushRegistryDelegate> {
}

@property (nonatomic, assign) UIBackgroundTaskIdentifier taskIdentifier;
@property (nonatomic, strong) UILocalNotification *callNotification;
@property (nonatomic, strong) UNNotificationRequest *request;//ios 10
@property (nonatomic, strong) PushMessage *push;

@end

@implementation YLT_SipModular

YLT_ShareInstance(YLT_SipModular);

- (void)YLT_init {
    
}

NS_ASSUME_NONNULL_BEGIN
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"

+ (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //    [[YLT_SipServer sharedInstance] autoLogin];
    PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushRegistry.delegate = [YLT_SipModular shareInstance];
    pushRegistry.desiredPushTypes = [NSSet setWithObjects:PKPushTypeVoIP, nil];
    
    
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError *error) {
            if (!error) {
                YLT_Log(@"request authorization succeeded!");
            }
        }];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            YLT_Log(@"%@",settings);
        }];
    } else {
        // Fallback on earlier versions
    }
    return YES;
}

#pragma mark + PKPushRegistryDelegate

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    if([credentials.token length] == 0) {
        return;
    }
    //应用启动获取token，并上传服务器
    NSString *token = [[[[credentials.token description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
                        stringByReplacingOccurrencesOfString:@">" withString:@""]
                       stringByReplacingOccurrencesOfString:@" " withString:@""];
    //token上传服务器
    if ([YLT_SipModular shareInstance].tokenCallback) {
        [YLT_SipModular shareInstance].tokenCallback(token);
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    BOOL isCalling = true;
    switch ([UIApplication sharedApplication].applicationState) {
        case UIApplicationStateActive: {
            isCalling = false;
        }
            break;
        case UIApplicationStateInactive: {
            isCalling = false;
        }
            break;
        case UIApplicationStateBackground: {
            isCalling = true;
        }
            break;
        default:
            isCalling = true;
            break;
    }
    
    if (isCalling){
        YLT_WEAKSELF
        NSString *tips = @"邀请您进行加密通话...";
        if ([YLT_SipModular shareInstance].tipCallback) {
            tips = [YLT_SipModular shareInstance].tipCallback(payload.dictionaryPayload);
        }
        if (self.push != nil) {
            YLT_LogError(@"上一通电话未结束");
            return;
        }
        [YLT_CallManager shareInstance].currentUUID = nil;
        if (payload.dictionaryPayload && [payload.dictionaryPayload.allKeys containsObject:@"aps"]) {
            NSDictionary *aps = [payload.dictionaryPayload objectForKey:@"aps"];
            if ([aps.allKeys containsObject:@"alert"] && [[aps objectForKey:@"alert"] YLT_CheckString]) {
                NSMutableString *res = [[NSMutableString alloc] initWithString:[aps objectForKey:@"alert"]];
                [res stringByReplacingOccurrencesOfString:@"\\" withString:@""];
                NSDictionary *alert = [NSJSONSerialization JSONObjectWithData:[res dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
                if (alert) {
                    weakSelf.push = [PushMessage mj_objectWithKeyValues:alert];
                }
            }
        }
        if (weakSelf.push == nil) {
            return;
        }
        NSDictionary *userInfo = self.displayNameCallback(weakSelf.push.fromUser);
        weakSelf.push.fromUsername = userInfo[@"username"];
        weakSelf.push.fromMobilephone = userInfo[@"mobilephone"];
        //本地通知，实现响铃效果
        if (@available(iOS 10.0, *)) {
            if ([weakSelf.push.cmd isEqualToString:@"call"]) {
                NSTimeInterval cur_stamp = [[NSDate date] timeIntervalSince1970];
                unsigned int time_delta = fabs(weakSelf.push.timestamp.doubleValue-cur_stamp);
                //                if (weakSelf.push.timestamp.doubleValue >= cur_stamp || time_delta > 45) {
                //                    [self sendNotificationTitle:@"未接来电" tip:weakSelf.push.fromUsername];
                //                    return;
                //                }
                
                if (![YLT_SipServer sharedInstance].currentUser.loginState) {
                    [[YLT_SipServer sharedInstance] autoLoginCallback:^(BOOL success) {
                    }];
                } else {
                }
            }
        } else {
            [YLT_SipModular shareInstance].callNotification = [[UILocalNotification alloc] init];
            [YLT_SipModular shareInstance].callNotification.alertBody = tips;
            
            [YLT_SipModular shareInstance].callNotification.soundName = [[YLT_SipModular shareInstance].soundName YLT_CheckString]?[YLT_SipModular shareInstance].soundName:@"YLT_SIP/voip_call.caf";
            [[UIApplication sharedApplication] presentLocalNotificationNow:[YLT_SipModular shareInstance].callNotification];
        }
    }
}

- (void)awakeCall {
    self.taskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    [[YLT_CallManager shareInstance] reportIncomingCallWithContact:@{@"mobilephone":self.push.fromMobilephone, @"username":self.push.fromUsername} completion:^(NSError * _Nonnull error) {
    }];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), queue, ^{
        [[UIApplication sharedApplication] endBackgroundTask:self.taskIdentifier];
    });
    self.push = nil;
}

/**
 接收电话
 */
- (void)accept:(NSString *)mobilephone {
    pj_str_t to;
    to = pj_str([NSString stringWithFormat:@"sip:%@@%@", mobilephone, [YLT_SipServer sharedInstance].currentUser.domain].UTF8String);
    pj_str_t text;
    text = pj_str([NSString stringWithFormat:@"%@woshixiangpuhua", [YLT_SipServer sharedInstance].currentUser.username].UTF8String);
    //    pjsua_im_send(<#pjsua_acc_id acc_id#>, <#const pj_str_t *to#>, <#const pj_str_t *mime_type#>, <#const pj_str_t *content#>, <#const pjsua_msg_data *msg_data#>, <#void *user_data#>)
    pj_status_t status = pjsua_im_send([YLT_SipServer sharedInstance].currentUser.accId, &to, NULL, &text, NULL, NULL);
    if (status != PJ_SUCCESS) {
        YLT_LogError(@"error %zd", status);
    }
}

- (void)sendNotificationTitle:(NSString *)title tip:(NSString *)tip {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = [title YLT_CheckString]?title:YLT_AppName;
    content.body = [NSString localizedUserNotificationStringForKey:tip arguments:nil];;
    UNNotificationSound *customSound = [UNNotificationSound soundNamed:[[YLT_SipModular shareInstance].soundName YLT_CheckString]?[YLT_SipModular shareInstance].soundName:@"YLT_SIP/voip_call.caf"];
    content.sound = customSound;
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger
                                                  triggerWithTimeInterval:1 repeats:NO];
    [YLT_SipModular shareInstance].request = [UNNotificationRequest requestWithIdentifier:@"Voip_Push" content:content trigger:trigger];
    [center addNotificationRequest:[YLT_SipModular shareInstance].request withCompletionHandler:^(NSError *error) {
    }];
    
}

- (void)onCancelRing {
    //取消通知栏
    NSMutableArray *arraylist = [[NSMutableArray alloc] init];
    [arraylist addObject:@"Voip_Push"];
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:arraylist];
    } else {
        [[UIApplication sharedApplication] cancelLocalNotification:[YLT_SipModular shareInstance].callNotification];
    }
}

- (NSDictionary *(^)(NSInteger userId))displayNameCallback {
    if (!_displayNameCallback) {
        _displayNameCallback = ^(NSInteger userId) {
            return @{@"mobilephone":@(userId), @"username":@"陌生号码"};
        };
    }
    return _displayNameCallback;
}

#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
@end


