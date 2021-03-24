//
//  CSDecoder.h
//  CSSphinx
//
//  Created by hcs on 2020/11/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CSSpeechState) {
    CSSpeechStateUnknow,    // 未知
    CSSpeechStateSilence,   // 静音
    CSSpeechStateSpeech,    // 说话
    CSSpeechStateUtterance, // 说完一句话（说话过程中停顿）
};

@class CSHypothesis;
@interface CSSphinxDecoder : NSObject

@property (nonatomic, assign) CSSpeechState state;

@property (nonatomic, assign, getter=isDecoding) BOOL decoding;

- (instancetype)initWithHmm:(NSString *)hmm lm:(NSString *)lm dict:(NSString *)dict;

/// 语音文件识别
/// @param filePath 文件路径
/// @param error 如果成功，返回nil
- (nullable CSHypothesis *)decodeAudioFile:(NSString *)filePath error:(NSError **)error;

/// 开始发声处理
/// 在将任何话语数据传递到解码器之前，应先调用此函数。 它标志着新话语的开始，并重新初始化了内部数据结构。
/// @return YES：解码器启动成功，NO：发生错误
- (BOOL)startUtteranceProcessing;

/// 结束发声处理
- (BOOL)endUtteranceProcessing;

/// 解码原始音频数据
/// @param data 音频数据
- (BOOL)processRaw:(NSData *)data;

/// 获取假设字符串和分数
- (nullable CSHypothesis *)getHypothesis;
@end

NS_ASSUME_NONNULL_END
