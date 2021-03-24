//
//  CSSpeechViewController.m
//  CSSphinxExample
//
//  Created by hcs on 2020/11/16.
//

#define kWakeupSwitchIsOn @"kWakeupSwitchIsOn"

#import "CSSpeechViewController.h"
#import <CSSphinx/CSSphinx.h>

@interface CSSpeechViewController ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stopButtonItem;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segment;
@property (weak, nonatomic) IBOutlet UIButton *recognizitionButton;
@property (weak, nonatomic) IBOutlet UILabel *wakeupLabel;
@property (weak, nonatomic) IBOutlet UISwitch *wakeupSwitch;
@property (nonatomic, strong) CSSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) CSLanguageModel *englishModel;
@property (nonatomic, strong) CSLanguageModel *chineseModel;
@end

@implementation CSSpeechViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    BOOL isOn = [[NSUserDefaults standardUserDefaults] boolForKey:kWakeupSwitchIsOn];
    
    self.wakeupSwitch.on = isOn;
    
    [self refreshControlState];
    
    if (self.wakeupSwitch.isOn) {
        [self startWakeup];
    }
}

#pragma mark - private methods
- (void)refreshControlState {
    
    if (self.wakeupSwitch.isOn) {
        
        self.startButtonItem.enabled = NO;
        self.stopButtonItem.enabled = NO;
        self.recognizitionButton.enabled = NO;
        self.segment.enabled = NO;

    } else {
        
        self.startButtonItem.enabled = YES;
        self.stopButtonItem.enabled = YES;
        self.recognizitionButton.enabled = YES;
        self.segment.enabled = YES;
    }
}

- (void)startWakeup {
    
    if (self.speechRecognizer.isRecording || self.speechRecognizer.isDecoding) {
        [self outputText:@"上一个识别未结束"];
        return;
    }
    
    NSString *keyword = self.segment.selectedSegmentIndex == 0 ? @"小安小安": @"hello";
    NSString *message = self.segment.selectedSegmentIndex == 0 ? @"你已唤醒小安": [NSString stringWithFormat:@"Has been awakened with \"%@\"", keyword];
    
    NSError *error = nil;
    __weak typeof(self) weakSelf = self;
    [self.speechRecognizer wakeupForKeyword:keyword error:&error completion:^{
        [weakSelf stopWakeup];
        [weakSelf alertMessage:message completion:^{
            [weakSelf startWakeup];
        }];
    }];
    
    if (error) {
        self.wakeupSwitch.on = NO;
    }
}

- (void)stopWakeup {
    
    if (!self.speechRecognizer) {
        return;
    }
    
    if (!self.speechRecognizer.isRecording) {
        return;
    }
    
    [self.speechRecognizer stopRecord];
}

- (void)outputText:(NSString *)text {
    NSMutableString *str = [NSMutableString stringWithString:self.textView.text ?: @""];
    
    if (str.length > 0 && ![str hasSuffix:@"\n"]) {
        [str appendString:@"\n"];
    }
    
    [str appendString:text?:@""];
    [str appendString:@"\n"];
    self.textView.text = str;
    [self scrollToBottom];
}

- (void)changeTextForLastLine:(NSString *)text final:(BOOL)final {
    
    NSMutableString *str = [NSMutableString stringWithString:self.textView.text ?: @""];
    
    // 如果不是\n结尾，则删掉最后一个\n后面的所有字符
    if (str.length > 0 && ![str hasSuffix:@"\n"]) {
        
        NSRange range = [str rangeOfString:@"\n" options:NSBackwardsSearch];
        
        if (range.location != NSNotFound) {
            range.location += 1;
            range.length = str.length - range.location;
            [str replaceCharactersInRange:range withString:@""];
        }
    }
    
    [str appendString:text?:@""];
    if (final) {
        [str appendString:@"\n"];
    }
    self.textView.text = str;
    [self scrollToBottom];
}

- (void)scrollToBottom {
    if (self.textView.text.length > 0) {
        [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length - 1, 1)];
    }
}

- (void)alertMessage:(NSString *)message completion:(void (^ __nullable)(void))completion {
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (completion) {
            completion();
        }
    }];
    
    [alertC addAction:action];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (NSString *)getAudioFilePath {
    
    NSString *audioPath = [[NSBundle mainBundle] pathForResource:@"Audio" ofType:nil];
    
    NSString *fileName = self.segment.selectedSegmentIndex == 0 ? @"xiaoan.wav" : @"en_goforward.raw";
    
    return [audioPath stringByAppendingPathComponent:fileName];
}

- (CSSpeechRecognizer *)speechRecognizer {
    if (!_speechRecognizer) {
        CSLanguageModel *model = self.segment.selectedSegmentIndex == 0 ? self.chineseModel : self.englishModel;
        _speechRecognizer = [[CSSpeechRecognizer alloc] initWithLanguageModel:model];
    }
    return _speechRecognizer;
}

- (CSLanguageModel *)englishModel {
    if (!_englishModel) {
        
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"model" ofType:nil];
        NSString *modelPath = [path stringByAppendingPathComponent:@"en-us"];
        
        NSString *hmmPath = [modelPath stringByAppendingPathComponent:@"en-us"];
        NSString *lmPath = [modelPath stringByAppendingPathComponent:@"en-us.lm.bin"];
        NSString *dictPath = [modelPath stringByAppendingPathComponent:@"en-us.dict"];

        _englishModel = [[CSLanguageModel alloc] initWithHmmPath:hmmPath lmPath:lmPath dictPath:dictPath];
    }
    return _englishModel;
}

- (CSLanguageModel *)chineseModel {
    if (!_chineseModel) {
        
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"model" ofType:nil];
        NSString *modelPath = [path stringByAppendingPathComponent:@"xiaoan"];
        
        NSString *hmmPath = [modelPath stringByAppendingPathComponent:@"xiaoan"];
        NSString *lmPath = [modelPath stringByAppendingPathComponent:@"xiaoan.lm.bin"];
        NSString *dictPath = [modelPath stringByAppendingPathComponent:@"xiaoan.dict"];

        _chineseModel = [[CSLanguageModel alloc] initWithHmmPath:hmmPath lmPath:lmPath dictPath:dictPath];
    }
    return _chineseModel;
}

- (IBAction)startButtonClicked:(id)sender {
    
    if (self.speechRecognizer.isRecording || self.speechRecognizer.isDecoding) {
        [self outputText:@"上一个识别未结束"];
        return;
    }
    
    NSError *error = nil;
    __weak typeof(self) weakSelf = self;
    [self.speechRecognizer startRecordAndReturnError:&error receive:^(CSHypothesis * _Nullable hypothesis, BOOL isLast) {
        
        [weakSelf changeTextForLastLine:hypothesis.text final:isLast];

        if (isLast) {
            [weakSelf outputText:[NSString stringWithFormat:@"text: %@, score: %ld", hypothesis.text, hypothesis.score]];
        }
        
    } stateChanged:^(CSSpeechState state) {
        
        if (state == CSSpeechStateSpeech) {
            self.title = @"正在说话...";
        } else {
            self.title = @"录音中...";
        }
    }];
    
    if (error) {
        
        [self outputText:[NSString stringWithFormat:@"录音失败：%@", error.localizedDescription]];

    } else {
        
        self.title = @"开始录音...";
        
        [self outputText:[NSString stringWithFormat:@"开始录音-识别%@", self.segment.selectedSegmentIndex == 0 ? @"普通话" : @"英语"]];
        
        self.segment.enabled = NO;
        self.recognizitionButton.enabled = NO;
        self.wakeupSwitch.enabled = NO;
    }
}

- (IBAction)stopButtonClicked:(id)sender {
    
    self.title = @"本地语音识别";
    
    if (!self.speechRecognizer) {
        return;
    }
    
    if (!self.speechRecognizer.isRecording) {
        return;
    }
    
    [self.speechRecognizer stopRecord];
    
    [self outputText:@"停止录音"];
    
    self.segment.enabled = YES;
    self.recognizitionButton.enabled = YES;
    self.wakeupSwitch.enabled = YES;
}

- (IBAction)segmentChanged:(id)sender {
    if (_speechRecognizer) {
        self.speechRecognizer = nil;
    }
    
    if (self.segment.selectedSegmentIndex == 0) {
        self.wakeupLabel.text = @"使用“小安小安”唤醒";
    } else {
        self.wakeupLabel.text = @"Wake up with \"hello\"";
    }
}

- (IBAction)recognitionButtonClicked:(id)sender {
    
    if (self.speechRecognizer.isRecording || self.speechRecognizer.isDecoding) {
        [self outputText:@"上一个识别未结束"];
        return;
    }
    
    NSString *filePath = [self getAudioFilePath];
    
    if (!filePath) {
        [self outputText:@"文件不存在"];
        return;
    }
    
    NSError *error = nil;
    __weak typeof(self) weakSelf = self;
    [self.speechRecognizer decodeAudioFile:filePath completion:^(CSHypothesis * _Nullable hypothesis, NSError * _Nullable error) {
        if (error) {
            [weakSelf outputText:[NSString stringWithFormat:@"识别文件错: %@", error]];
            return;
        }
        [weakSelf outputText:hypothesis ? [NSString stringWithFormat:@"text: %@, score: %ld", hypothesis.text, hypothesis.score] : @"无识别结果"];
    }];
    
    if (error) {
        
        [self outputText:[NSString stringWithFormat:@"识别语音文件失败 error: %@", error.localizedDescription]];
        
    } else {
        
        [self outputText:@"开始识别语音文件"];
    }
}

- (IBAction)wakeupSwitchChanged:(id)sender {
    
    [[NSUserDefaults standardUserDefaults] setBool:self.wakeupSwitch.isOn forKey:kWakeupSwitchIsOn];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self refreshControlState];
    
    if (self.wakeupSwitch.isOn) {
        
        [self startWakeup];
        
    } else {
        
        [self stopWakeup];
    }
}

@end
