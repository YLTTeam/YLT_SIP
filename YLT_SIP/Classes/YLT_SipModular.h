//
//  YLT_SipModular.h
//  SecretVoice
//
//  Created by YLT_Alex on 2017/10/26.
//  Copyright © 2017年 QTEC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <YLT_BaseLib/YLT_BaseLib.h>

#define YLT_SIPBundle [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"YLT_Faceboard" withExtension:@"bundle"]]
#define YLT_SIPImage(name) [UIImage imageNamed:name inBundle:YLT_FaceboardBundle compatibleWithTraitCollection:nil]


@interface YLT_SipModular : YLT_BaseModular

YLT_ShareInstanceHeader(YLT_SipModular);
/**
 提示音
 */
@property (nonatomic, strong) NSString *soundName;

/**
 获取token的回调
 */
@property (nonatomic, copy) void(^tokenCallback)(NSString *token);

/**
 提示内容的回调
 */
@property (nonatomic, copy) NSString *(^tipCallback)(NSDictionary *payload);

/**
 通过userId获取用户名
 */
@property (nonatomic, copy) NSDictionary *(^displayNameCallback)(NSInteger userId);

@end
