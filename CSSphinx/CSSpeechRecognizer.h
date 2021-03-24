//
//  CSSpeechRecognizer.h
//  CSSphinx
//
//  Created by hcs on 2020/11/12.
//

#import <Foundation/Foundation.h>
#import <CSSphinx/CSSphinxDecoder.h>

NS_ASSUME_NONNULL_BEGIN

@class CSLanguageModel;
@class CSHypothesis;
@interface CSSpeechRecognizer : NSObject

@property (nonatomic, assign, getter=isRecording) BOOL recording; // 是否录音中

@property (nonatomic, assign, getter=isDecoding) BOOL decoding; // 是否识别中（文件识别）

@property (nonatomic, strong) CSLanguageModel *languageModel;


- (instancetype)initWithLanguageModel:(CSLanguageModel *)languageModel;

/// 识别语音文件
/// @param filePath 文件路径
/// @param completion 回调
- (void)decodeAudioFile:(NSString *)filePath completion:(void (^)(CSHypothesis * _Nullable hypothesis, NSError * _Nullable error))completion;

/// 实时识别
/// @param error 错误
/// @param receive 回调
/// @param stateChanged 状态改变
- (void)startRecordAndReturnError:(NSError **)error receive:(void(^ __nullable)(CSHypothesis * _Nullable hypothesis, BOOL isLast))receive stateChanged:(void(^ __nullable)(CSSpeechState state))stateChanged;

/// 停止录音
- (void)stopRecord;

/// 开始等待唤醒
/// @param keyword 唤醒关键词
/// @param error 错误
/// @param completion 唤醒回调
- (void)wakeupForKeyword:(NSString *)keyword error:(NSError *__autoreleasing  _Nullable *)error completion:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END
