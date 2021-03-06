//
//  EZAudioFloatData.m
//  EZAudioPlayFileExample
//
//  Created by Syed Haris Ali on 2/14/15.
//  Copyright (c) 2015 Syed Haris Ali. All rights reserved.
//

#import "EZAudioFloatData.h"

#import "EZAudio.h"

//------------------------------------------------------------------------------
#pragma mark - EZAudioFloatData
//------------------------------------------------------------------------------

@interface EZAudioFloatData ()
@property (nonatomic, assign, readwrite) int    numberOfChannels;
@property (nonatomic, assign, readwrite) float  **buffers;
@property (nonatomic, assign, readwrite) UInt32 bufferSize;
@end

//------------------------------------------------------------------------------

@implementation EZAudioFloatData

//------------------------------------------------------------------------------

- (void)dealloc
{
    [EZAudio freeFloatBuffers:self.buffers
             numberOfChannels:self.numberOfChannels];
}

//------------------------------------------------------------------------------

+ (instancetype)dataWithNumberOfChannels:(int)numberOfChannels
                                 buffers:(float **)buffers
                              bufferSize:(UInt32)bufferSize
{
    id waveformData = [[self alloc] init];
    
    size_t size = sizeof(float) * bufferSize;
    float **buffersCopy = [EZAudio floatBuffersWithNumberOfFrames:bufferSize
                                                 numberOfChannels:numberOfChannels];
    for (int i = 0; i < numberOfChannels; i++)
    {
        memcpy(buffersCopy[i], buffers[i], size);
    }
    
    ((EZAudioFloatData *)waveformData).buffers = buffersCopy;
    ((EZAudioFloatData *)waveformData).bufferSize = bufferSize;
    ((EZAudioFloatData *)waveformData).numberOfChannels = numberOfChannels;
    
    return waveformData;
}

//------------------------------------------------------------------------------

- (float *)bufferForChannel:(int)channel
{
    float *buffer = NULL;
    if (channel < self.numberOfChannels)
    {
        buffer = self.buffers[channel];
    }
    return buffer;
}

//------------------------------------------------------------------------------

@end