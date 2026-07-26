// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKitOC.h>
#import <NIMSDK/NIMSDK.h>
#import "NEChatBaseViewController.h"
#import "TeamHistoryMessageViewModel.h"
#import "NEHistorySearchFileCell.h"
#import "NEBaseForwardAlertViewController.h"

NS_ASSUME_NONNULL_BEGIN

#ifndef NEHistorySearchTypeVideo
#define NEHistorySearchTypeVideo MessageTypeVideo
#endif

#ifndef NEHistorySearchTypeFile
#define NEHistorySearchTypeFile MessageTypeFile
#endif

@interface NEBaseHistoryMediaResultController : NEChatBaseViewController <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIDocumentInteractionControllerDelegate, NEHistorySearchFileCellDelegate, ChatViewModelDelegate>

@property(nonatomic, strong) UICollectionView *collectionView;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, assign) CGFloat rowItemCount;
@property(nonatomic, strong) TeamHistoryMessageViewModel *viewModel;
@property(nonatomic, assign) MessageType searchType;
@property(nonatomic, assign) BOOL isLoadingMore;

- (void)setupUI;
- (void)setupTableView;
- (void)setupCollectionView;
- (void)loadData:(BOOL)firstLoad;
- (void)refreshData;
- (void)loadMoreData;
- (void)scrollToLastItem:(BOOL)animated;
- (void)addTableViewFootter;
- (void)addTableViewFooter;
- (void)removeTableViewBottomLoadMore;
- (void)removeCollectionBottomLoadMore;
- (void)forwardMessage:(V2NIMMessage *)message;
- (void)addForwardAlertControllerWithItems:(NSArray *)items type:(NSString *)type sureBlock:(nullable void (^)(NSString * _Nullable comment))sureBlock;
- (NEBaseForwardAlertViewController *)getForwardAlertController;
- (void)toCollectMessage:(MessageContentModel *)model;
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture;
- (void)showAction:(V2NIMMessage *)message;
- (void)routerToMessage:(nullable V2NIMMessage *)message;
- (void)didTapFileMessage:(MessageImageModel *)model indexPath:(NSIndexPath *)indexPath;
- (void)openFilePreviewWithFilePath:(NSString *)filePath fileName:(NSString *)fileName;
- (void)didTapImageMessage:(MessageImageModel *)model indexPath:(NSIndexPath *)indexPath;
- (void)didTapVideoMessage:(MessageImageModel *)model indexPath:(NSIndexPath *)indexPath;
- (void)downloadFile:(MessageImageModel *)model url:(nullable NSString *)url path:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
