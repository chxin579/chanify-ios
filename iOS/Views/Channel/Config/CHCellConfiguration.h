//
//  CHCellConfiguration.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <UIKit/UIKit.h>
#import "CHMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CHMessagesDataSource;

@interface CHCellConfiguration : NSObject<UIContentConfiguration>

@property (nonatomic, readonly, strong) NSString *mid;

+ (instancetype)cellConfiguration:(CHMessageModel *)model;
+ (NSDictionary<NSString *, UICollectionViewCellRegistration *> *)cellRegistrations;
- (instancetype)initWithMID:(NSString *)mid;
- (nullable NSString *)mediaThumbnailURL;
- (NSDate *)date;
- (void)setNeedRecalcLayout;
- (CGSize)calcSize:(CGSize)size;


@end

NS_ASSUME_NONNULL_END