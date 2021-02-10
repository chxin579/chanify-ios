//
//  CHMessagesDataSource.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHMessagesDataSource.h"
#import "CHMessagesHeaderView.h"
#import "CHUnknownMsgCellConfiguration.h"
#import "CHDateCellConfiguration.h"
#import "CHUserDataSource.h"
#import "CHLogic.h"

#define kCHMessageListPageSize  16
#define kCHMessageListDateDiff  300

@interface CHMessagesDataSource ()

@property (nonatomic, readonly, strong) NSString *cid;
@property (nonatomic, readonly, strong) NSDictionary<NSString *, UICollectionViewCellRegistration *> *cellRegistrations;
@property (nonatomic, readonly, strong) UICollectionViewCellRegistration *unknownCellRegistration;
@property (nonatomic, nullable, strong) CHMessagesHeaderView *headerView;
@property (nonatomic, readonly, weak) UICollectionView *collectionView;

@end

@implementation CHMessagesDataSource

typedef NSDiffableDataSourceSnapshot<NSString *, CHCellConfiguration *> CHConversationDiffableSnapshot;

+ (instancetype)dataSourceWithCollectionView:(UICollectionView *)collectionView channelID:(NSString *)cid {
    return [[self.class alloc] initWithCollectionView:collectionView channelID:cid];
}

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView channelID:(NSString *)cid {
    _cid = cid;
    _cellRegistrations = CHCellConfiguration.cellRegistrations;
    _unknownCellRegistration = [self.cellRegistrations objectForKey:NSStringFromClass(CHUnknownMsgCellConfiguration.class)];
    UICollectionViewDiffableDataSourceCellProvider cellProvider = ^UICollectionViewCell *(UICollectionView *collectionView, NSIndexPath *indexPath, CHCellConfiguration *item) {
        UICollectionViewCellRegistration *cellRegistration = [self.cellRegistrations objectForKey:NSStringFromClass(item.class)];
        if (cellRegistration != nil) {
            return [collectionView dequeueConfiguredReusableCellWithRegistration:cellRegistration forIndexPath:indexPath item:item];
        }
        return [collectionView dequeueConfiguredReusableCellWithRegistration:self.unknownCellRegistration forIndexPath:indexPath item:item];
    };
    if (self = [super initWithCollectionView:collectionView cellProvider:cellProvider]) {
        _collectionView = collectionView;
        UICollectionViewSupplementaryRegistration *supplementaryRegistration = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:CHMessagesHeaderView.class elementKind:UICollectionElementKindSectionHeader configurationHandler:^(CHMessagesHeaderView *supplementaryView, NSString *elementKind, NSIndexPath *indexPath) {
        }];
        @weakify(self);
        self.supplementaryViewProvider = ^UICollectionReusableView *(UICollectionView *collectionView, NSString *elementKind, NSIndexPath *indexPath) {
            @strongify(self);
            if (self.headerView == nil) {
                self.headerView = [collectionView dequeueConfiguredReusableSupplementaryViewWithRegistration:supplementaryRegistration forIndexPath:indexPath];
                [self updateHeaderView];
            }
            return self.headerView;
        };

        CHConversationDiffableSnapshot *snapshot = [CHConversationDiffableSnapshot new];
        [snapshot appendSectionsWithIdentifiers:@[@"main"]];
        [self applySnapshot:snapshot animatingDifferences:NO];
        
        [self loadLatestMessage:NO];
    }
    return self;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeMake(self.collectionView.bounds.size.width, 30);
    CHCellConfiguration *item = [self itemIdentifierForIndexPath:indexPath];
    if (item != nil) {
        size.height = [item calcHeight:size];
    }
    return size;
}

- (CGSize)sizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(self.collectionView.bounds.size.width, 30);
}

- (void)scrollViewDidScroll {
    if (self.headerView != nil && self.headerView.status == CHMessagesHeaderStatusNormal) {
        self.headerView.status = CHMessagesHeaderStatusLoading;
        @weakify(self);
        dispatch_main_after(1, ^{
            @strongify(self);
            [self loadEarlistMessage];
        });
    }
}

- (void)loadEarlistMessage {
    if ([self.collectionView numberOfItemsInSection:0] <= 0) {
        [self loadLatestMessage:YES];
    } else {
        CHCellConfiguration *item = [self itemIdentifierForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        NSArray<CHMessageModel *> *items = [CHLogic.shared.userDataSource messageWithCID:self.cid from:item.mid to:0 count:kCHMessageListPageSize];
        self.headerView.status = (items.count < kCHMessageListPageSize ? CHMessagesHeaderStatusFinish : CHMessagesHeaderStatusNormal);
        if (items.count > 0) {
            [self performAndKeepOffset:^{
                NSArray<CHCellConfiguration *> *cells = [self calcItems:items last:nil];
                CHConversationDiffableSnapshot *snapshot = self.snapshot;
                [snapshot insertItemsWithIdentifiers:cells beforeItemWithIdentifier:item];
                [self applySnapshot:snapshot animatingDifferences:NO];
            }];
        }
    }
}

- (void)loadLatestMessage:(BOOL)animated {
    NSDate *last = nil;
    uint64_t to = 0;
    uint64_t from = (~to) >> 1;
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    if (count > 0) {
        CHCellConfiguration *item = [self itemIdentifierForIndexPath:[NSIndexPath indexPathForRow:count - 1 inSection:0]];
        to = item.mid;
        last = item.date;
    }
    NSArray<CHMessageModel *> *items = [CHLogic.shared.userDataSource messageWithCID:self.cid from:from to:to count:kCHMessageListPageSize];
    if (items.count > 0) {
        CHConversationDiffableSnapshot *snapshot = self.snapshot;
        [snapshot appendItemsWithIdentifiers:[self calcItems:items last:last]];
        [self applySnapshot:snapshot animatingDifferences:animated];
        @weakify(self);
        dispatch_main_async(^{
            @strongify(self);
            [self scrollToBottom:animated];
            [self updateHeaderView];
        });
    }
}

#pragma mark - Private Methods
- (void)updateHeaderView {
    if (self.headerView != nil && self.headerView.status != CHMessagesHeaderStatusLoading) {
        self.headerView.status = ([self.collectionView numberOfItemsInSection:0] < kCHMessageListPageSize ? CHMessagesHeaderStatusFinish : CHMessagesHeaderStatusNormal);
    }
}

- (void)scrollToBottom:(BOOL)animated {
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    if (count > 0) {
        [self.collectionView layoutIfNeeded];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:count-1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:animated];
    }
}

- (void)performAndKeepOffset:(void (NS_NOESCAPE ^)(void))actions {
    CGPoint offset = self.collectionView.contentOffset;
    [self.collectionView setContentOffset:offset animated:NO];
    CGFloat height = self.collectionView.contentSize.height;
    if (actions != NULL) {
        [UIView performWithoutAnimation:actions];
    }
    [self.collectionView layoutIfNeeded];
    offset.y += self.collectionView.contentSize.height - height;
    [self.collectionView setContentOffset:offset animated:NO];
}

- (NSArray<CHCellConfiguration *> *)calcItems:(NSArray<CHMessageModel *> *)items last:(NSDate *)last {
    NSInteger count = items.count;
    NSMutableArray<CHCellConfiguration *> *cells = [NSMutableArray arrayWithCapacity:items.count];
    for (NSInteger index = count - 1; index >= 0; index--) {
        CHCellConfiguration *item = [CHCellConfiguration cellConfiguration:[items objectAtIndex:index]];
        if (last == nil || [item.date timeIntervalSinceDate:last] > kCHMessageListDateDiff) {
            CHCellConfiguration *itm = [CHDateCellConfiguration cellConfiguration:item.mid];
            last = itm.date;
            [cells addObject:itm];
        }
        [cells addObject:item];
    }
    return cells;
}


@end