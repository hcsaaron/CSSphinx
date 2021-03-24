//
//  CSHypothesis.h
//  CSSphinx
//
//  Created by hcs on 2020/11/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSHypothesis : NSObject
@property (nonatomic, copy) NSString *text;
@property (nonatomic, assign) NSInteger score;

- (instancetype)initWithText:(NSString *)text score:(NSInteger)score;
@end

NS_ASSUME_NONNULL_END
