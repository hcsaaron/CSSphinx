//
//  CSSphinxDecoder.m
//  CSSphinx
//
//  Created by hcs on 2020/11/12.
//

#import "CSSphinxDecoder.h"
#import "CSHypothesis.h"

#include "pocketsphinx.h"

NSErrorDomain const CSSphinxDecodeErrorDomain = @"CSSphinxDecodeErrorDomain";

typedef enum : NSUInteger {
    CSSphinxDecodeErrorCantOpenAudioFiled,    // 无法打开文件
    CSSphinxDecodeErrorDecodeAudioFailed,     // 音频解码失败
} CSSphinxDecodeErrorCode;

@implementation CSSphinxDecoder
{
    ps_decoder_t *_decoder;
}

- (void)dealloc {
    NSLog(@"CSSphinxDecoder dealloc");
    ps_free(_decoder);
}

- (instancetype)initWithHmm:(NSString *)hmm lm:(NSString *)lm dict:(NSString *)dict
{
    self = [super init];
    if (self) {
        
        _state = CSSpeechStateSilence;
        
//        char *argv[] = {"-hmm", hmm.UTF8String, "-lm", lm.UTF8String, "-dict", dict.UTF8String};
//        cmd_ln_t *config = cmd_ln_parse_r(NULL, ps_args(), 6, argv, TRUE);
        
        cmd_ln_t *config = cmd_ln_init(NULL, ps_args(), TRUE, "-hmm", hmm.UTF8String, "-lm", lm.UTF8String, "-dict", dict.UTF8String, NULL);
        
        _decoder = ps_init(config);
        
        cmd_ln_free_r(config);
    }
    return self;
}

#pragma mark - public
/// 开始发声处理
/// 在将任何话语数据传递到解码器之前，应先调用此函数。 它标志着新话语的开始，并重新初始化了内部数据结构。
/// @return YES：解码器启动成功，NO：发生错误
- (BOOL)startUtteranceProcessing {
    int result = ps_start_utt(_decoder);
    return result == 0;
}

/// 结束发声处理
- (BOOL)endUtteranceProcessing {
    int result = ps_end_utt(_decoder);
    return result == 0;
}

/// 语音文件识别
/// @param filePath 文件路径
/// @param error 如果成功，返回nil
- (nullable CSHypothesis *)decodeAudioFile:(NSString *)filePath error:(NSError **)error {
    
    // fopen函数：打开文件（r：只读）
    FILE *file = fopen(filePath.UTF8String, "r");
    if (file == NULL) {
        *error = [NSError errorWithDomain:CSSphinxDecodeErrorDomain code:CSSphinxDecodeErrorCantOpenAudioFiled userInfo:@{@"message": @"无法打开文件"}];
        return nil;
    }
    
    // 开始声音处理（在将任何话语数据传递到解码器之前，应先调用此函数。 它标志着新话语的开始，并重新初始化了内部数据结构。）
    int result = ps_start_utt(_decoder);
    
    size_t count = 512;
    int16_t buffer[count];
    
    // feof函数：其功能是检测流上的文件结束符，如果文件结束，则返回非0值，否则返回0
    // return：返回成功读取的对象个数，若出现错误或到达文件末尾，则可能小于count。
    while (!feof(file)) {
        // fread函数：从给定输入流stream读取最多count个对象到数组buffer中（相当于以对每个对象调用size次fgetc），把buffer当作unsigned char数组并顺序保存结果。流的文件位置指示器前进读取的字节数。
        size_t samples = fread(buffer, 2, count, file);
        // @param noSearch 如果非0，则执行特征提取，但尚未进行任何识别。 如果您的处理器无法实时识别，则可能有必要。
        // @param fullUtterance 如果非0，则此数据块是完整语音数据，这可以使识别器产生更准确的结果。
        result = ps_process_raw(_decoder, buffer, samples, FALSE, FALSE);
    }
    
    // 结束声音处理
    result |= ps_end_utt(_decoder);
    
    // fclose函数：关闭文件
    fclose(file);
    
    if (result != 0) {
        *error = [NSError errorWithDomain:CSSphinxDecodeErrorDomain code:CSSphinxDecodeErrorDecodeAudioFailed userInfo:@{@"message": @"音频解码失败"}];
        return nil;
    }
    
    CSHypothesis *hypothesis = [self getHypothesis];
    
    return hypothesis;
}

- (BOOL)processRaw:(NSData *)data {
    
    int result = ps_process_raw(_decoder, data.bytes, data.length/2, FALSE, FALSE);
    
    BOOL isInSpeech = [self inSpeech];
    
    if (self.state == CSSpeechStateSilence && isInSpeech) {
        self.state = CSSpeechStateSpeech;
    } else if (self.state == CSSpeechStateSpeech && !isInSpeech) {
        self.state = CSSpeechStateUtterance;
    } else if (self.state == CSSpeechStateUtterance && !isInSpeech) {
        self.state = CSSpeechStateSilence;
    }
    
    return result == 0;
}

- (BOOL)inSpeech {
    return ps_get_in_speech(_decoder) == 1;
}

/// 获取假设字符串和分数
- (nullable CSHypothesis *)getHypothesis {
    
    if (!_decoder) {
        return nil;
    }
    
    int32_t out_best_score;
    char const *str = ps_get_hyp(_decoder, &out_best_score);
    
    if (str == NULL) {
        return nil;
    }
    
    NSString *text = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
    
    CSHypothesis *hypothesis = [[CSHypothesis alloc] initWithText:text score:(NSInteger)out_best_score];
    
    return hypothesis;
}

@end
