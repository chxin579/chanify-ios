//
//  CHNSDataSource.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@class FMDatabase;

@protocol CHKeyStorage <NSObject>
- (nullable NSData *)keyForUID:(nullable NSString *)uid;
@end

@protocol CHBlockedStorage <NSObject>
- (BOOL)checkBlockedTokenWithKey:(nullable NSString *)key uid:(nullable NSString *)uid;
@end

@interface CHNSDataSource : NSObject<CHKeyStorage, CHBlockedStorage>

+ (instancetype)dataSourceWithURL:(NSURL *)url;
- (void)close;
- (void)flush;
- (nullable NSData *)keyForUID:(nullable NSString *)uid;
- (void)updateKey:(nullable NSData *)key uid:(nullable NSString *)uid;
- (NSUInteger)badgeForUID:(nullable NSString *)uid;
- (NSUInteger)nextBadgeForUID:(nullable NSString *)uid;
- (void)updateBadge:(NSUInteger)badge uid:(nullable NSString *)uid;
- (nullable CHMessageModel *)pushMessage:(NSData *)data mid:(NSString *)mid uid:(NSString *)uid flags:(CHMessageProcessFlags * _Nullable)flags;
- (void)enumerateMessagesWithUID:(nullable NSString *)uid block:(void (NS_NOESCAPE ^)(FMDatabase *db, NSString *mid, NSData *data))block;
- (void)removeMessages:(NSArray<NSString *> *)mids uid:(nullable NSString *)uid;
- (BOOL)upsertBlockedToken:(nullable NSString *)token uid:(nullable NSString *)uid;
- (BOOL)removeBlockedTokens:(NSArray<NSString *> *)tokens uid:(nullable NSString *)uid;
- (NSArray<NSString *> *)blockedTokensWithUID:(nullable NSString *)uid;


@end

@interface CHTempNSDatasource : NSObject<CHKeyStorage, CHBlockedStorage>
+ (instancetype)datasourceFromDB:(FMDatabase *)db;
@end


NS_ASSUME_NONNULL_END
