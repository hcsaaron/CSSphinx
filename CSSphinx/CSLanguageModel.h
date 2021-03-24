//
//  CSLanguageModel.h
//  CSSphinx
//
//  Created by hcs on 2020/11/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSLanguageModel : NSObject

@property (nonatomic, copy) NSString *hmmPath;
@property (nonatomic, copy) NSString *lmPath;
@property (nonatomic, copy) NSString *dictPath;

- (instancetype)initWithHmmPath:(NSString *)hmmPath lmPath:(NSString *)lmPath dictPath:(NSString *)dictPath;

@end

NS_ASSUME_NONNULL_END
