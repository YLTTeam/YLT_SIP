//
//  YLT_AudioManager.h
//  Pods
//
//  Created by YLT_Alex on 2017/12/20.
//

#import <Foundation/Foundation.h>
#import <YLT_BaseLib/YLT_BaseLib.h>

@interface YLT_AudioManager : NSObject

YLT_ShareInstanceHeader(YLT_AudioManager);
/**
 音频会话开启

 @return 结果
 */
- (BOOL)configureAudioSessionStart;

/**
 音频会话关闭

 @return 结果
 */
- (BOOL)configureAudioSessionEnd;

@end
