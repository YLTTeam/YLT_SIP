//
//  YLT_CallManager.h
//  Pods
//
//  Created by YLT_Alex on 2017/12/16.
//

#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>
#import <YLT_BaseLib/YLT_BaseLib.h>
#import "YLT_SipUser.h"

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, YLT_CallActionType) {
    YLT_CallActionTypeStart,
    YLT_CallActionTypeEnd,
    YLT_CallActionTypeAnswer,
    YLT_CallActionTypeMute,
    YLT_CallActionTypeHold
};

typedef NS_ENUM(NSInteger, YLT_CallState) {
    YLT_CallStatePending,
    YLT_CallStateConnecting,
    YLT_CallStateConnected,
    YLT_CallStateEnded,
    YLT_CallStateEndedWithFailure,
    YLT_CallStateEndedUnanswered
};

@interface YLT_CallManager : NSObject

@property (nonatomic, strong) dispatch_queue_t completionQueue;

/**
 通过mobile获取用户名
 */
@property (nonatomic, copy) NSString *(^displayNameCallback)(NSString *mobile);

YLT_ShareInstanceHeader(YLT_CallManager);

- (void)setupWithAppName:(NSString *)appName
           supportsVideo:(BOOL)supportsVideo
 actionNotificationBlock:(void(^)(CXCallAction *action, YLT_CallActionType actionType))actionNotificationBlock;


- (NSUUID *)reportIncomingCallWithContact:(YLT_SipUser *)contact completion:(void(^)(NSError * error))completion;
- (NSUUID *)reportOutgoingCallWithContact:(YLT_SipUser *)contact completion:(void(^)(NSError * error))completion;
- (void)updateCall:(NSUUID *)callUUID state:(YLT_CallState)state;

- (void)mute:(BOOL)mute callUUID:(NSUUID *)callUUID completion:(void(^)(NSError * error))completion;
- (void)hold:(BOOL)hold callUUID:(NSUUID *)callUUID completion:(void(^)(NSError * error))completion;
- (void)endCall:(NSUUID *)callUUID completion:(void(^)(NSError * error))completion;

@end
NS_ASSUME_NONNULL_END
