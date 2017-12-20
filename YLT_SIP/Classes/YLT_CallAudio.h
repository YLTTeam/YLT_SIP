//
//  YLT_CallAudio.h
//  Pods
//
//  Created by YLT_Alex on 2017/12/20.
//

#import <Foundation/Foundation.h>
#import <YLT_BaseLib/YLT_BaseLib.h>
//#import "AudioController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface YLT_CallAudio : NSObject

YLT_ShareInstanceHeader(YLT_CallAudio);

/**
 音频会话开启

 @return 结果
 */
- (BOOL)configureAudio;

- (void)startAudio;

- (void)stopAudio;

@end
