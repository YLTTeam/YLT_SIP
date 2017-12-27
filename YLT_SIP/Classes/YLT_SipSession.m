//
//  YLT_SipSession.m
//  SecretVoice
//
//  Created by YLT_Alex on 2017/10/26.
//  Copyright © 2017年 QTEC. All rights reserved.
//

#import "YLT_SipSession.h"

@implementation YLT_SipSession

- (void)saveCallback:(void(^)(BOOL success, id response))callback {
    [[YLT_DBHelper shareInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        BOOL result = NO;
        @try {
            [db open];
            [db executeUpdate:@"CREATE TABLE IF NOT EXISTS DB_YLT_SipSession(dbid INTEGER PRIMARY KEY AUTOINCREMENT, callId INTEGER, phone TEXT, sessionType INTEGER, answer TINYINT, state INTEGER, unRead INTEGER, startTime INTEGER, endTime INTEGER, extra TEXT)"];
            result = [db executeUpdate:@"INSERT INTO DB_YLT_SipSession(callId,phone,sessionType,answer,state,unRead,startTime,endTime,extra) VALUES (?,?,?,?,?,?,?,?,?)", [NSNumber numberWithInteger:self.callId], self.phone, [NSNumber numberWithInteger:self.sessionType], [NSNumber numberWithBool:self.answer], [NSNumber numberWithInteger:self.state], [NSNumber numberWithInteger:self.unRead], [NSNumber numberWithInteger:self.startTime], [NSNumber numberWithInteger:self.endTime], self.extra];
            self.dbid = [db lastInsertRowId];
            [db close];
        } @catch (NSException *exception) {
            YLT_LogError(@"数据库异常");
            [db rollback];
        } @finally {
            [db commit];
            if (callback) {
                callback(result, self);
            }
        }
    }];
}

- (void)delCallback:(void(^)(BOOL success, id response))callback {
    [[YLT_DBHelper shareInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        BOOL result = NO;
        @try {
            [db open];
            result = [db executeUpdate:@"DELETE FROM DB_YLT_SipSession WHERE dbid = ?", [NSNumber numberWithInteger:self.dbid]];
            [db close];
        } @catch (NSException *exception) {
            YLT_LogError(@"数据库异常");
            [db rollback];
        } @finally {
            [db commit];
            if (callback) {
                callback(result, self);
            }
        }
    }];
}

+ (void)delByConditions:(NSString *)sender callback:(void(^)(BOOL success, id response))callback {
    [[YLT_DBHelper shareInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        BOOL result = NO;
        @try {
            [db open];
            result = [db executeUpdate:[NSString stringWithFormat:@"DELETE FROM DB_YLT_SipSession WHERE %@", sender]];
            [db close];
        } @catch (NSException *exception) {
            YLT_LogError(@"数据库异常");
            [db rollback];
        } @finally {
            [db commit];
            if (callback) {
                callback(result, self);
            }
        }
    }];
}

- (void)updateCallback:(void(^)(BOOL success, id response))callback {
    [[YLT_DBHelper shareInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        BOOL result = NO;
        @try {
            [db open];
            result = [db executeUpdate:@"UPDATE DB_YLT_SipSession SET  callId = ?, phone = ?, sessionType = ?, answer = ?, state = ?, unRead = ?, startTime = ?, endTime = ?, extra = ? WHERE dbid = ?", [NSNumber numberWithInteger:self.callId], self.phone, [NSNumber numberWithInteger:self.sessionType], [NSNumber numberWithBool:self.answer], [NSNumber numberWithInteger:self.state], [NSNumber numberWithInteger:self.unRead], [NSNumber numberWithInteger:self.startTime], [NSNumber numberWithInteger:self.endTime], self.extra, [NSNumber numberWithInteger:self.dbid]];
            [db close];
        } @catch (NSException *exception) {
            YLT_LogError(@"数据库异常");
            [db rollback];
        } @finally {
            [db commit];
            if (callback) {
                callback(result, self);
            }
        }
    }];
}

+ (void)updateByConditions:(NSString *)sender callback:(void(^)(BOOL success, id response))callback {
    [[YLT_DBHelper shareInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        BOOL result = NO;
        @try {
            [db open];
            result = [db executeUpdate:[NSString stringWithFormat:@"UPDATE DB_YLT_SipSession SET %@", sender]];
            [db close];
        } @catch (NSException *exception) {
            YLT_LogError(@"数据库异常");
            [db rollback];
        } @finally {
            [db commit];
            if (callback) {
                callback(result, self);
            }
        }
    }];
}

+ (void)findByConditions:(NSString *)sender callback:(void(^)(BOOL success, id response))callback {
    [[YLT_DBHelper shareInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        NSMutableArray *result = [[NSMutableArray alloc] init];
        @try {
            [db open];
            FMResultSet* set;
            if (sender.length == 0) {
                set = [db executeQuery:@"SELECT * FROM DB_YLT_SipSession"];
            }
            else {
                set = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM DB_YLT_SipSession WHERE %@", sender]];
            }
            while ([set next]) {
                YLT_SipSession *item = [[YLT_SipSession alloc] init];
                item.dbid = [set intForColumn:@"dbid"];
                item.callId = [set intForColumn:@"callId"];
                item.phone = [set stringForColumn:@"phone"];
                item.sessionType = [set intForColumn:@"sessionType"];
                item.answer = [set boolForColumn:@"answer"];
                item.state = [set intForColumn:@"state"];
                item.unRead = [set intForColumn:@"unRead"];
                item.startTime = [set intForColumn:@"startTime"];
                item.endTime = [set intForColumn:@"endTime"];
                item.extra = [set stringForColumn:@"extra"];
                [result addObject:item];
            }
            [db close];
        } @catch (NSException *exception) {
            YLT_LogError(@"数据库异常");
            [db rollback];
        } @finally {
            [db commit];
            if (callback) {
                callback((result.count != 0), result);
            }
        }
    }];
}

+ (void)maxKeyValueCallback:(void(^)(BOOL success, id response))callback {
    [[YLT_DBHelper shareInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        NSInteger result = 0;
        @try {
            [db open];
            FMResultSet* set = [db executeQuery:@"SELECT MAX(CAST(dbid as INT)) FROM DB_YLT_SipSession"];
            if ([set next]) {
                result = [set intForColumnIndex:0];
            }
            [db close];
        } @catch (NSException *exception) {
            YLT_LogError(@"数据库异常");
            [db rollback];
        } @finally {
            [db commit];
            if (callback) {
                callback((result != 0), @(result));
            }
        }
    }];
}

+ (NSInteger)unreadCount {
    FMDatabase *db = [FMDatabase databaseWithPath:[YLT_DBHelper shareInstance].dbPath];
    if (![db open]) {
        YLT_LogWarn(@"数据库打开失败");
        return 0;
    }
    FMResultSet* set = [db executeQuery:[NSString stringWithFormat:@"SELECT sum(unRead) as unreadTotalCount FROM DB_YLT_SipSession"]];
    while ([set next]) {
        return [set intForColumn:@"unreadTotalCount"];
    }
    return 0;
}

+ (void)clearUnreadCount {
    [[YLT_DBHelper shareInstance].databaseQueue inDatabase:^(FMDatabase *db) {
        BOOL result = NO;
        @try {
            [db open];
            result = [db executeUpdate:@"UPDATE DB_YLT_SipSession SET unRead = 0"];
            [db close];
        } @catch (NSException *exception) {
            YLT_LogError(@"数据库异常");
            [db rollback];
        } @finally {
            [db commit];
        }
    }];
}

/**
 清除数据
 */
- (void)clear {
    self.answer = NO;
    self.sessionType = 0;
    self.callId = PJSUA_INVALID_ID;
    self.phone = @"";
    self.sessionType = 0;
    self.extra = @"";
    self.startTime = 0;
    self.endTime = 0;
    self.state = 0;
    self.unRead = 0;
}

@end

