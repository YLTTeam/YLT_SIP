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
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif

@interface YLT_SipModular()<PKPushRegistryDelegate> {
    
}

@property (nonatomic, strong) UILocalNotification *callNotification;
@property (nonatomic, strong) UNNotificationRequest *request;//ios 10

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
    BOOL isCalling = false;
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
        NSString *tips = @"邀请您进行加密通话...";
        if ([YLT_SipModular shareInstance].tipCallback) {
            tips = [YLT_SipModular shareInstance].tipCallback(payload.dictionaryPayload);
        }
        //本地通知，实现响铃效果
        if (@available(iOS 10.0, *)) {
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
            content.body = [NSString localizedUserNotificationStringForKey:tips arguments:nil];;
            UNNotificationSound *customSound = [UNNotificationSound soundNamed:[[YLT_SipModular shareInstance].soundName YLT_CheckString]?[YLT_SipModular shareInstance].soundName:@"YLT_SIP/voip_call.caf"];
            content.sound = customSound;
            UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger
                                                          triggerWithTimeInterval:1 repeats:NO];
            [YLT_SipModular shareInstance].request = [UNNotificationRequest requestWithIdentifier:@"Voip_Push" content:content trigger:trigger];
            [center addNotificationRequest:[YLT_SipModular shareInstance].request withCompletionHandler:^(NSError *error) {
            }];
        } else {
            [YLT_SipModular shareInstance].callNotification = [[UILocalNotification alloc] init];
            [YLT_SipModular shareInstance].callNotification.alertBody = tips;
            
            [YLT_SipModular shareInstance].callNotification.soundName = [[YLT_SipModular shareInstance].soundName YLT_CheckString]?[YLT_SipModular shareInstance].soundName:@"YLT_SIP/voip_call.caf";
            [[UIApplication sharedApplication] presentLocalNotificationNow:[YLT_SipModular shareInstance].callNotification];
        }
    }
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

#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
@end
