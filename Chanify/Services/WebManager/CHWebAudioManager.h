//
//  CHWebAudioManager.h
//  iOS
//
//  Created by WizJin on 2021/5/28.
//

#import "CHWebCacheManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CHWebAudioItem <NSObject>

- (void)webAudioUpdated:(nullable NSURL *)item fileURL:(nullable NSString *)fileURL;
- (void)webAudioProgress:(double)progress fileURL:(nullable NSString *)fileURL;

@end

@interface CHWebAudioManager : CHWebCacheManager

+ (instancetype)webAudioManagerWithURL:(NSURL *)fileBaseDir;
- (void)close;
- (void)loadAudioURL:(nullable NSString *)fileURL toItem:(id<CHWebAudioItem>)item expectedSize:(uint64_t)expectedSize;
- (void)resetFileURLFailed:(nullable NSString *)fileURL;
- (void)removeWithURLs:(NSArray<NSURL *> *)urls;
- (NSDictionary *)infoWithURL:(NSURL *)url;


@end

NS_ASSUME_NONNULL_END
