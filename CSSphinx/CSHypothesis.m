//
//  CSHypothesis.m
//  CSSphinx
//
//  Created by hcs on 2020/11/12.
//

#import "CSHypothesis.h"

@implementation CSHypothesis

- (instancetype)initWithText:(NSString *)text score:(NSInteger)score
{
    self = [super init];
    if (self) {
        _text = text;
        _score = score;
    }
    return self;
}
@end
