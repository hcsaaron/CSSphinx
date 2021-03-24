//
//  CSLanguageModel.m
//  CSSphinx
//
//  Created by hcs on 2020/11/16.
//

#import "CSLanguageModel.h"

@interface CSLanguageModel ()

@end

@implementation CSLanguageModel

- (instancetype)initWithHmmPath:(NSString *)hmmPath lmPath:(NSString *)lmPath dictPath:(NSString *)dictPath
{
    self = [super init];
    if (self) {
        _hmmPath = hmmPath;
        _lmPath = lmPath;
        _dictPath = dictPath;
    }
    return self;
}

@end
