//
//  EZAudioFloatConverter.m
//  EZAudioPlayFileExample
//
//  Created by Syed Haris Ali on 2/14/15.
//  Copyright (c) 2015 Syed Haris Ali. All rights reserved.
//

#import "EZAudioFloatConverter.h"

#import "EZAudio.h"

static UInt32 EZAudioFloatConverterDefaultOutputBufferSize = 32 * 128;

typedef struct
{
    AudioConverterRef converterRef;
    AudioBufferList *floatAudioBufferList;
    AudioStreamBasicDescription inputFormat;
    AudioStreamBasicDescription outputFormat;
    AudioStreamPacketDescription *packetDescriptions;
    UInt32 packetsPerBuffer;
} EZAudioFloatConverterInfo;

OSStatus EZAudioFloatConverterCallback(AudioConverterRef            inAudioConverter,
                                       UInt32                       *ioNumberDataPackets,
                                       AudioBufferList              *ioData,
                                       AudioStreamPacketDescription **outDataPacketDescription,
                                       void                         *inUserData)
{
    AudioBufferList *sourceBuffer = (AudioBufferList *)inUserData;
    memcpy(ioData,
           sourceBuffer,
           sizeof(AudioBufferList) + (sourceBuffer->mNumberBuffers-1)*sizeof(AudioBuffer));
    return noErr;
}

@interface EZAudioFloatConverter ()
@property (nonatomic, assign) EZAudioFloatConverterInfo info;
@end

@implementation EZAudioFloatConverter

//------------------------------------------------------------------------------
#pragma mark - Class Methods
//------------------------------------------------------------------------------

+ (instancetype)converterWithInputFormat:(AudioStreamBasicDescription)inputFormat
{
    return [[self alloc] initWithInputFormat:inputFormat];
}

//------------------------------------------------------------------------------
#pragma mark - Dealloc
//------------------------------------------------------------------------------

- (void)dealloc
{
    free(self.info.packetDescriptions);
    [EZAudio freeBufferList:self.info.floatAudioBufferList];
}

//------------------------------------------------------------------------------
#pragma mark - Initialization
//------------------------------------------------------------------------------

- (instancetype)initWithInputFormat:(AudioStreamBasicDescription)inputFormat
{
    self = [super init];
    if (self)
    {
        EZAudioFloatConverterInfo info;
        memset(&info, 0, sizeof(info));
        info.inputFormat = inputFormat;
        info.outputFormat = [EZAudio floatFormatWithNumberOfChannels:inputFormat.mChannelsPerFrame
                                                          sampleRate:inputFormat.mSampleRate];
        
        // get max packets per buffer so you can allocate a proper AudioBufferList
        UInt32 packetsPerBuffer = 0;
        UInt32 outputBufferSize = EZAudioFloatConverterDefaultOutputBufferSize;
        UInt32 sizePerPacket = info.inputFormat.mBytesPerPacket;
        BOOL isVBR = sizePerPacket == 0;
        
        // VBR
        if (isVBR)
        {
            // determine the max output buffer size
            UInt32 maxOutputPacketSize;
            UInt32 propSize = sizeof(maxOutputPacketSize);
            [EZAudio checkResult:AudioConverterGetProperty(info.converterRef,
                                                           kAudioConverterPropertyMaximumOutputPacketSize,
                                                           &propSize,
                                                           &maxOutputPacketSize)
                       operation:"Failed to get max packet size in converter"];
            
            // set the output buffer size to at least the max output size
            if (maxOutputPacketSize > outputBufferSize)
            {
                outputBufferSize = maxOutputPacketSize;
            }
            packetsPerBuffer = outputBufferSize / maxOutputPacketSize;
            
            // allocate memory for the packet descriptions
            info.packetDescriptions = (AudioStreamPacketDescription *)malloc(sizeof(AudioStreamPacketDescription) * packetsPerBuffer);
        }
        else
        {
            packetsPerBuffer = outputBufferSize / sizePerPacket;
        }
        info.packetsPerBuffer = packetsPerBuffer;
        
        // allocate the AudioBufferList to hold the float values
        BOOL isInterleaved = [EZAudio isInterleaved:info.outputFormat];
        info.floatAudioBufferList = [EZAudio audioBufferListWithNumberOfFrames:packetsPerBuffer
                                                              numberOfChannels:info.outputFormat.mChannelsPerFrame
                                                                   interleaved:isInterleaved];

        self.info = info;
        [self setup];
    }
    return self;
}

//------------------------------------------------------------------------------
#pragma mark - Setup
//------------------------------------------------------------------------------

- (void)setup
{
    // create a new instance of the audio converter
    [EZAudio checkResult:AudioConverterNew(&_info.inputFormat,
                                           &_info.outputFormat,
                                           &_info.converterRef)
               operation:"Failed to create new audio converter"];
}

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

- (void)convertDataFromAudioBufferList:(AudioBufferList *)audioBufferList
                    withNumberOfFrames:(UInt32)frames
                        toFloatBuffers:(float **)buffers
{
    EZAudioFloatConverterInfo info = self.info;
    if (frames == 0)
    {
        
    }
    else
    {
        [EZAudio checkResult:AudioConverterFillComplexBuffer(info.converterRef,
                                                             EZAudioFloatConverterCallback,
                                                             audioBufferList,
                                                             &frames,
                                                             info.floatAudioBufferList,
                                                             info.packetDescriptions)
                   operation:"Failed to fill complex buffer in float converter"];
        
        for (int i = 0; i < info.floatAudioBufferList->mNumberBuffers; i++)
        {
            memcpy(buffers[i],
                   info.floatAudioBufferList->mBuffers[i].mData,
                   info.floatAudioBufferList->mBuffers[i].mDataByteSize);
        }
    }
}

//------------------------------------------------------------------------------

@end
