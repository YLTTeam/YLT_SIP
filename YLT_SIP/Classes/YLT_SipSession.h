//
//  YLT_SipSession.h
//  SecretVoice
//
//  Created by YLT_Alex on 2017/10/26.
//  Copyright © 2017年 QTEC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pjsua.h>
#import <YLT_BaseLib/YLT_BaseLib.h>

/**
 当前会话对象
 */
@interface YLT_SipSession : YLT_BaseModel

/**
 数据库ID
 */
@property (readwrite, nonatomic, assign) NSInteger dbid;
/**
 通话ID
 */
@property (readwrite, nonatomic, assign) pjsua_call_id callId;
/**
 手机号码 电话号码作为用户的唯一标识符 URI
 */
@property (readwrite, nonatomic, strong) NSString * phone;
/**
 1:呼出  0:呼入
 */
@property (readwrite, nonatomic, assign) NSInteger sessionType;
/**
 是否接听
 */
@property (readwrite, nonatomic, assign) BOOL answer;
/**
 通话状态
 */
@property (readwrite, nonatomic, assign) NSInteger state;
/**
 用来统计未接来电未读的数量
 */
@property (readwrite, nonatomic, assign) NSInteger unRead;//是否看过 0:看过 1:未看
/**
 开始时间
 */
@property (readwrite, nonatomic, assign) NSInteger startTime;
/**
 结束时间
 */
@property (readwrite, nonatomic, assign) NSInteger endTime;
/**
 扩展字符串，如有需要  可以考虑将其他内容转化为json字符串存储
 */
@property (readwrite, nonatomic, strong) NSString * extra;

/**
 清除数据
 */
- (void)clear;

- (void)saveCallback:(void(^)(BOOL success, id response))callback;
- (void)delCallback:(void(^)(BOOL success, id response))callback;
+ (void)delByConditions:(NSString *)sender callback:(void(^)(BOOL success, id response))callback;
- (void)updateCallback:(void(^)(BOOL success, id response))callback;
+ (void)updateByConditions:(NSString *)sender callback:(void(^)(BOOL success, id response))callback;
+ (void)findByConditions:(NSString *)sender callback:(void(^)(BOOL success, id response))callback;
+ (void)maxKeyValueCallback:(void(^)(BOOL success, id response))callback;
+ (NSInteger)unreadCount;
+ (void)clearUnreadCount;

@end

