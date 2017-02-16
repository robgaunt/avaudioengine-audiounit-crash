//
//  ViewController.m
//  AVAudioEngine_AVCaptureSession_Crash
//
//  Created by Rob Gaunt on 2/15/17.
//  Copyright © 2017 Rob Gaunt. All rights reserved.
//

#import "ViewController.h"
#import <mach/mach_time.h>

@import AVFoundation;

static const UInt32 kChannelBits = 16;
static const UInt32 kChannelCount = 2;
static const UInt32 kFrameCount = 1;
static const Float64 kSampleRate = 44100.0;

@interface ViewController ()
@end

@implementation ViewController {
  AVAudioEngine *_audioEngine;
  AVAudioMixerNode *_mainMixerNode;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self createAudioEngine];

  AudioComponentInstance instances[10];
  for (int i = 0; i < 10; i++) {
    NSLog(@"Setting up instance: %d", i);

    // If this call is moved outside of the loop, it won't crash.
    [self setupAudioSession];

    [self setupAudioComponent:instances[i]];
  }
}


- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (void)createAudioEngine {
  _audioEngine = [[AVAudioEngine alloc] init];
  // If you don't access _audioEngine.mainMixerNode, it won't crash.
  _mainMixerNode = _audioEngine.mainMixerNode;
}

- (void)setupAudioSession {
  AVAudioSession *session = [AVAudioSession sharedInstance];
  AVAudioSessionCategoryOptions options = (AVAudioSessionCategoryOptionDefaultToSpeaker |
                                           AVAudioSessionCategoryOptionMixWithOthers);
  NSError *error;
  [session setCategory:AVAudioSessionCategoryPlayAndRecord
           withOptions:options
                 error:&error];
  assert(error == nil);
}

- (void)setupAudioComponent:(AudioComponentInstance)audioComponent {
  // Find an audio component on the device & set it up for input.
  AudioComponentDescription acd;
  acd.componentType = kAudioUnitType_Output;
  acd.componentSubType = kAudioUnitSubType_RemoteIO;
  acd.componentManufacturer = kAudioUnitManufacturer_Apple;
  acd.componentFlags = 0;
  acd.componentFlagsMask = 0;
  AudioComponent ac = AudioComponentFindNext(NULL, &acd);
  AudioComponentInstanceNew(ac, &audioComponent);
  UInt32 inDataFlag = 1;
  AudioUnitSetProperty(audioComponent, kAudioOutputUnitProperty_EnableIO,
                       kAudioUnitScope_Input, 1, &inDataFlag, sizeof(inDataFlag));

  // Configure the audio stream format.
  AudioStreamBasicDescription asbd;
  asbd.mSampleRate = kSampleRate;
  asbd.mFormatID = kAudioFormatLinearPCM;
  asbd.mFormatFlags = (kAudioFormatFlagIsSignedInteger |
                       kAudioFormatFlagsNativeEndian |
                       kAudioFormatFlagIsPacked);
  asbd.mChannelsPerFrame = kChannelCount;
  asbd.mFramesPerPacket = kFrameCount;
  asbd.mBitsPerChannel = kChannelBits;
  asbd.mBytesPerFrame = kChannelBits / 8 * kChannelCount;
  asbd.mBytesPerPacket = asbd.mBytesPerFrame * kFrameCount;
  AudioUnitSetProperty(audioComponent, kAudioUnitProperty_StreamFormat,
                       kAudioUnitScope_Output, 1, &asbd, sizeof(asbd));

  AudioUnitInitialize(audioComponent);
}

@end
