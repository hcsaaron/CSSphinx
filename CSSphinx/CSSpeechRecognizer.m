//
//  CSSpeechRecognizer.m
//  CSSphinx
//
//  Created by hcs on 2020/11/12.
//

#import "CSSpeechRecognizer.h"
#import <AVFoundation/AVFoundation.h>
#import "CSHypothesis.h"
#import "CSLanguageModel.h"

NSErrorDomain const CSSpeechRecognizeErrorDomain = @"CSSpeechRecognizeErrorDomain";

typedef enum : NSUInteger {
    CSSpeechRecognizeErrorSetAudioSessionFailed,        // AudioSession设置失败
    CSSpeechRecognizeErrorStartRecordFailed,            // 开始录音失败
    CSSpeechRecognizeErrorStartAudioEngineFailed,       // 启动AudioEngine失败
    CSSpeechRecognizeErrorRecognizeAudioFileFailed,     // 识别音频文件失败
} CSSpeechRecognizeError;

#pragma mark - AVAudioPCMBuffer Category
@interface AVAudioPCMBuffer (Addition)

- (NSData *)toData;

@end

@implementation AVAudioPCMBuffer (Addition)

- (NSData *)toData {
    
    NSInteger length = self.frameCapacity * self.format.streamDescription->mBytesPerFrame;
    
    return [NSData dataWithBytes:self.int16ChannelData[0] length:length];
}

@end

#pragma mark - CSSpeechRecognizer
@interface CSSpeechRecognizer ()
@property (nonatomic, strong) AVAudioEngine *audioAngine;
@property (nonatomic, strong) CSSphinxDecoder *decoder;
@end

@implementation CSSpeechRecognizer
{
    double _sampleRate; // 采样率
    float _ioBufferDuration;   // 采样间隔
    int _bit;   // 位宽
}


- (instancetype)initWithLanguageModel:(CSLanguageModel *)languageModel
{
    self = [super init];
    if (self) {
        
        _sampleRate = 48000;
        _ioBufferDuration = 0.005;
        _bit = 16;
        
        self.languageModel = languageModel;
    }
    return self;
}

#pragma mark - public
- (void)wakeupForKeyword:(NSString *)keyword error:(NSError *__autoreleasing  _Nullable *)error completion:(void(^)(void))completion {
    
    [self startRecordAndReturnError:error receive:^(CSHypothesis * _Nullable hypothesis, BOOL isLast) {
        
        if ([hypothesis.text isEqualToString:keyword] && completion) {
            completion();
        }
        
    } stateChanged:nil];
}

- (void)startRecordAndReturnError:(NSError *__autoreleasing  _Nullable *)error receive:(void (^)(CSHypothesis * _Nullable, BOOL))receive stateChanged:(void (^)(CSSpeechState))stateChanged {
    
    NSLog(@"startRecord");
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setPreferredSampleRate:_sampleRate error:error];
    if (*error) {
        return;
    }
    
    [audioSession setPreferredIOBufferDuration:_ioBufferDuration error:error];
    if (*error) {
        return;
    }
    
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:error];
    if (*error) {
        return;
    }
    
    __weak AVAudioInputNode *inputNode = self.audioAngine.inputNode;
    AVAudioFormat *inputFormat = [inputNode inputFormatForBus:0];
    NSMutableDictionary *settings = [inputFormat.settings mutableCopy];
    settings[AVLinearPCMBitDepthKey] = @(_bit);
    settings[AVSampleRateKey] = @(_sampleRate);
    settings[AVLinearPCMIsFloatKey] = 0;
    
    // 录音信息
    AVAudioFormat *fromFormat = [[AVAudioFormat alloc] initWithSettings:settings];
    // 重采样信息
    AVAudioFormat *toFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16 sampleRate:16000 channels:1 interleaved:NO];
    
    AVAudioConverter *audioConverter = [[AVAudioConverter alloc] initFromFormat:fromFormat toFormat:toFormat];
    if (!audioConverter) {
        *error = [NSError errorWithDomain:CSSpeechRecognizeErrorDomain code:CSSpeechRecognizeErrorStartRecordFailed userInfo:@{@"message": @"开始录音失败"}];
        return;
    }
    
    AVAudioFrameCount bufferSize = (AVAudioFrameCount)(0.1 * _sampleRate);
    
    [inputNode removeTapOnBus:0];
    
    __block CSSpeechState state = CSSpeechStateUnknow;
    
    [inputNode installTapOnBus:0 bufferSize:bufferSize format:fromFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        
        AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:toFormat frameCapacity:(AVAudioFrameCount)1600];
        
        if (!pcmBuffer) {
            return;
        }
        
        NSError *error = nil;
        [audioConverter convertToBuffer:pcmBuffer error:&error withInputFromBlock:^AVAudioBuffer * _Nullable(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus * _Nonnull outStatus) {
            *outStatus = AVAudioConverterInputStatus_HaveData;
            return buffer;
        }];
        
        NSData *audioData = [pcmBuffer toData];
        
        [self.decoder processRaw:audioData];
        
        if (self.decoder.state != state) {
            state = self.decoder.state;
            if (stateChanged) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    stateChanged(state);
                });
            }
        }
        
        if (self.decoder.state == CSSpeechStateUtterance) {
            
            [self.decoder endUtteranceProcessing];
            
            CSHypothesis *hypothesis = [self.decoder getHypothesis];
            if (hypothesis && receive) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"实时识别返回：%@, 识别score：%ld", hypothesis.text, hypothesis.score);
                    receive(hypothesis, YES);
                });
            }
            
            [self.decoder startUtteranceProcessing];
            
        } else if (self.decoder.state == CSSpeechStateSpeech) {
            
            CSHypothesis *hypothesis = [self.decoder getHypothesis];
            if (hypothesis && receive) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"实时识别返回：%@, 识别score：%ld", hypothesis.text, hypothesis.score);
                    receive(hypothesis, NO);
                });
            }
        }
    }];
    
    [self.decoder startUtteranceProcessing];
    
    [self.audioAngine prepare];
    
    [self.audioAngine startAndReturnError:error];
    
    if (*error) {
        [self.decoder endUtteranceProcessing];
        return;
    }
    
    self.recording = YES;
}

- (void)stopRecord {
    
    [self.audioAngine stop];
    [self.audioAngine.inputNode removeTapOnBus:0];
    
    [self.decoder endUtteranceProcessing];
    
    self.recording = NO;
}

- (void)decodeAudioFile:(NSString *)filePath completion:(void (^)(CSHypothesis * _Nullable hypothesis, NSError * _Nullable error))completion  {
    
    dispatch_queue_t queue = dispatch_queue_create("com.hcsaaron.decode", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        
        NSError *error = nil;
        CSHypothesis *hypothesis = [self.decoder decodeAudioFile:filePath error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(hypothesis, error);
        });
    });
}

- (void)setLanguageModel:(CSLanguageModel *)languageModel {
    if (languageModel != _languageModel) {
        _languageModel = languageModel;
        
        self.decoder = [[CSSphinxDecoder alloc] initWithHmm:self.languageModel.hmmPath lm:self.languageModel.lmPath dict:self.languageModel.dictPath];
    }
}

#pragma mark - getter
- (AVAudioEngine *)audioAngine {
    if (!_audioAngine) {
        _audioAngine = [[AVAudioEngine alloc] init];
    }
    return _audioAngine;
}

- (BOOL)isDecoding {
    if (!self.decoder) {
        return NO;
    }
    return self.decoder.isDecoding;
}
@end
