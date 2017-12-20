//
//  YLT_AudioManager.m
//  Pods
//
//  Created by YLT_Alex on 2017/12/20.
//

#import "YLT_AudioManager.h"

@implementation YLT_AudioManager

YLT_ShareInstance(YLT_AudioManager);

- (void)YLT_init {
    
}

/**
 音频会话开启
 
 @return 结果
 */
- (BOOL)configureAudioSessionStart {
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    
    // we are going to play and record so we pick that category
    NSError *error = nil;
    [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        YLT_LogWarn(@"%s --- failed to set audio session category:%@", __FUNCTION__, error.localizedDescription);
        return NO;
    }
    // set the mode to voice chat
    [sessionInstance setMode:AVAudioSessionModeVoiceChat error:&error];
    if (error) {
        YLT_LogWarn(@"%s --- failed to set audio mode with error :%@", __FUNCTION__, error.localizedDescription);
        return NO;
    }
    //* set the buffer duration to 5 ms
    NSTimeInterval bufferDuration = .005;
    [sessionInstance setPreferredIOBufferDuration:bufferDuration error:&error];
    if (error) {
        YLT_LogWarn(@"%s --- failed to active audio buffer with error:%@", __FUNCTION__, error.localizedDescription);
        return NO;
    }
    // set the session's sample rate
    [sessionInstance setPreferredSampleRate:44100 error:&error];
    if (error) {
        YLT_LogWarn(@"%s --- failed to active audio sampleRate with error:%@", __FUNCTION__, error.localizedDescription);
        return NO;
    }
    //*/
    [sessionInstance setActive:true error:&error];
    if (error) {
        YLT_LogWarn(@"%s --- failed to active audio active with error:%@", __FUNCTION__, error.localizedDescription);
        return NO;
    }
    // add interruption handler
    [[NSNotificationCenter defaultCenter] addObserver:[YLT_AudioManager shareInstance]
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:sessionInstance];
    // if media services are reset, we need to rebuild our audio chain
    [[NSNotificationCenter defaultCenter]    addObserver:[YLT_AudioManager shareInstance]
                                                selector:@selector(handleMediaServerReset:)
                                                    name:AVAudioSessionMediaServicesWereResetNotification
                                                  object:sessionInstance];
    return YES;
}

/**
 音频会话关闭
 
 @return 结果
 */
- (BOOL)configureAudioSessionEnd {
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    
    // we are going to play and record so we pick that category
    NSError *error = nil;
    [sessionInstance setCategory:AVAudioSessionCategoryAmbient error:&error];
    
    // set the mode to voice chat
    [sessionInstance setMode:AVAudioSessionModeDefault error:&error];
    if (error) {
        YLT_LogWarn(@"%s --- failed to close audio active with error:%@", __FUNCTION__, error.localizedDescription);
        return NO;
    }
    return YES;
}

- (void)handleInterruption:(NSNotification *)notification {
    @try {
        UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
        YLT_LogWarn(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
        
        if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
        }else if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
            // make sure to activate the session
            NSError *error = nil;
            [[AVAudioSession sharedInstance] setActive:YES error:&error];
            if (nil != error) NSLog(@"AVAudioSession set active failed with error: %@", error);
        }
    } @catch (NSException *exception) {
        //char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", exception.name.UTF8String, exception.reason.UTF8String);
    } @finally {
    }
}

- (void)handleMediaServerReset:(NSNotification *)notification {
    YLT_LogWarn(@"Media server has reset");
}


@end
