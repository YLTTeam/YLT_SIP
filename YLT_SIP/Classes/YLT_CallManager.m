//
//  YLT_CallManager.m
//  Pods
//
//  Created by YLT_Alex on 2017/12/16.
//

#import "YLT_CallManager.h"

NS_ASSUME_NONNULL_BEGIN
@implementation CXTransaction (ADPrivateAdditions)

+ (CXTransaction *)transactionWithActions:(NSArray <CXAction *> *)actions {
    CXTransaction *transcation = [[CXTransaction alloc] init];
    for (CXAction *action in actions) {
        [transcation addAction:action];
    }
    return transcation;
}

@end

@interface YLT_CallManager()<CXProviderDelegate> {
}

@property (nonatomic, strong) CXProvider *provider;
@property (nonatomic, strong) CXCallController *callController;
@property (nonatomic, copy) void(^actionNotificationBlock)(CXCallAction *action, YLT_CallActionType actionType);

@end

@implementation YLT_CallManager

static const NSInteger YLT_DefaultMaximumCallsPerCallGroup = 1;
static const NSInteger YLT_DefaultMaximumCallGroups = 1;

YLT_ShareInstance(YLT_CallManager);

- (void)setupWithAppName:(NSString *)appName supportsVideo:(BOOL)supportsVideo actionNotificationBlock:(void(^)(CXCallAction *action, YLT_CallActionType actionType))actionNotificationBlock {
    CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:appName];
    configuration.maximumCallGroups = YLT_DefaultMaximumCallGroups;
    configuration.maximumCallsPerCallGroup = YLT_DefaultMaximumCallsPerCallGroup;
    configuration.supportedHandleTypes = [NSSet setWithObject:@(CXHandleTypePhoneNumber)];
    configuration.supportsVideo = supportsVideo;
    
    self.provider = [[CXProvider alloc] initWithConfiguration:configuration];
    [self.provider setDelegate:self queue:self.completionQueue ? self.completionQueue : dispatch_get_main_queue()];
    
    self.callController = [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
    self.actionNotificationBlock = actionNotificationBlock;
}

- (void)setCompletionQueue:(dispatch_queue_t)completionQueue {
    _completionQueue = completionQueue;
    if (self.provider) {
        [self.provider setDelegate:self queue:_completionQueue];
    }
}

- (NSUUID *)reportIncomingCallWithContact:(YLT_SipUser *)contact completion:(void(^)(NSError *_Nullable error))completion {
    NSUUID *callUUID = [NSUUID UUID];
    
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:contact.username];
    callUpdate.remoteHandle = handle;
    callUpdate.localizedCallerName = self.displayNameCallback(contact.username);
    [self.provider reportNewIncomingCallWithUUID:callUUID update:callUpdate completion:completion];
    return callUUID;
}

- (NSUUID *)reportOutgoingCallWithContact:(YLT_SipUser *)contact completion:(void(^)(NSError *_Nullable error))completion {
    NSUUID *callUUID = [NSUUID UUID];
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:contact.username];
    
    CXStartCallAction *action = [[CXStartCallAction alloc] initWithCallUUID:callUUID handle:handle];
    action.contactIdentifier = [callUUID UUIDString];
    
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
    return callUUID;
}

- (void)updateCall:(NSUUID *)callUUID state:(YLT_CallState)state {
    if (callUUID) {
        switch (state) {
            case YLT_CallStateConnecting:
                [self.provider reportOutgoingCallWithUUID:callUUID startedConnectingAtDate:nil];
                break;
            case YLT_CallStateConnected:
                [self.provider reportOutgoingCallWithUUID:callUUID connectedAtDate:nil];
                break;
            case YLT_CallStateEnded:
                [self.provider reportCallWithUUID:callUUID endedAtDate:nil reason:CXCallEndedReasonRemoteEnded];
                break;
            case YLT_CallStateEndedWithFailure:
                [self.provider reportCallWithUUID:callUUID endedAtDate:nil reason:CXCallEndedReasonFailed];
                break;
            case YLT_CallStateEndedUnanswered:
                [self.provider reportCallWithUUID:callUUID endedAtDate:nil reason:CXCallEndedReasonUnanswered];
                break;
            default:
                break;
        }
    }
}

- (void)mute:(BOOL)mute callUUID:(NSUUID *)callUUID completion:(void(^)(NSError *_Nullable error))completion {
    CXSetMutedCallAction *action = [[CXSetMutedCallAction alloc] initWithCallUUID:callUUID muted:mute];
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
}

- (void)hold:(BOOL)hold callUUID:(NSUUID *)callUUID completion:(void(^)(NSError *_Nullable error))completion {
    CXSetHeldCallAction *action = [[CXSetHeldCallAction alloc] initWithCallUUID:callUUID onHold:hold];
    [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
}

- (void)endCall:(NSUUID *)callUUID completion:(void(^)(NSError *_Nullable error))completion {
    if (callUUID) {
        CXEndCallAction *action = [[CXEndCallAction alloc] initWithCallUUID:callUUID];
        [self.callController requestTransaction:[CXTransaction transactionWithActions:@[action]] completion:completion];
    }
}

#pragma mark - CXProviderDelegate
- (void)provider:(CXProvider *)provider performAnswerCallAction:(nonnull CXAnswerCallAction *)action {
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, YLT_CallActionTypeAnswer);
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(nonnull CXEndCallAction *)action {
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, YLT_CallActionTypeEnd);
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performStartCallAction:(nonnull CXStartCallAction *)action {
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, YLT_CallActionTypeStart);
    }
    if (action.handle.value) {
        [action fulfill];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(nonnull CXSetMutedCallAction *)action {
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, YLT_CallActionTypeMute);
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(nonnull CXSetHeldCallAction *)action {
    if (self.actionNotificationBlock) {
        self.actionNotificationBlock(action, YLT_CallActionTypeHold);
    }
    [action fulfill];
}

- (void)providerDidReset:(CXProvider *)provider {
    
}

- (NSString *(^)(NSString *mobile))displayNameCallback {
    if (!_displayNameCallback) {
        _displayNameCallback = ^(NSString *mobile) {
            return @"陌生号码";
        };
    }
    return _displayNameCallback;
}
@end
NS_ASSUME_NONNULL_END
