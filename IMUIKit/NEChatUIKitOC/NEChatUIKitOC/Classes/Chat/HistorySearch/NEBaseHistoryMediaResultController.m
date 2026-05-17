// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseHistoryMediaResultController.h"
#import <MJRefresh/MJRefresh.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NEChatKitOC/NECoreIM2Constant.h>
#import <NEChatKitOC/NEALog.h>
#import <NEChatKitOC/Router.h>
#import <NEChatKitOC/NERouterUrl.h>
#import <NIMSDK/NIMSDK.h>
#import <SDWebImage/SDWebImage.h>
#import "NEChatUIConstant.h"
#import "TeamHistoryMessageViewModel.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "NEHistorySearchFileCell.h"
#import "NEHistorySearchImageCell.h"
#import "NEHistorySearchMediaCollectionSectionHeader.h"
#import "NEHistorySearchMediaTableSectionHeader.h"
#import "NEHistorySearchVideoCell.h"
#import "NERefreshHasNoMoreView.h"
#import "ChatNavigationView.h"
#import "ChatMessageHelper.h"
#import <NECommonUIKitOC/PhotoBrowserController.h>
#import <NECommonUIKitOC/VideoPlayerViewController.h>
#import "NEAudioSessionManager.h"
#import "ChatViewController.h"
#import "MessageVideoModel.h"
#import "MessageFileModel.h"
#import "MessageImageModel.h"
#import "MediaSectionModel.h"

@implementation NEBaseHistoryMediaResultController

- (instancetype)init {
    self = [super init];
    if (self) {
        _rowItemCount = 4;
        _viewModel = [[TeamHistoryMessageViewModel alloc] init];
        _searchType = MessageTypeImage;
        _isLoadingMore = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewModel.delegate = self;
    [self setupUI];
    [self loadData:YES];
}

- (void)setupUI {
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationView.moreButton.hidden = YES;

    switch (self.searchType) {
        case MessageTypeImage:
            self.title = commonLocalizable(@"images");
            self.emptyView.message = chatLocalizable(@"no_search_result_image");
            [self setupCollectionView];
            break;
        case MessageTypeVideo:
            self.title = commonLocalizable(@"videos");
            self.emptyView.message = chatLocalizable(@"no_search_result_video");
            [self setupCollectionView];
            break;
        default:
            self.title = chatLocalizable(@"chat_file");
            self.emptyView.message = chatLocalizable(@"no_search_result_file");
            [self setupTableView];
            break;
    }

    [self.view addSubview:self.emptyView];
    self.emptyView.backgroundColor = UIColor.whiteColor;
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.emptyView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.emptyView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.emptyView.topAnchor constraintEqualToAnchor:self.navigationView.bottomAnchor],
    ]];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.whiteColor;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshData)];
    header.automaticallyChangeAlpha = YES;
    self.tableView.mj_header = header;

    [self.tableView registerClass:[NEHistorySearchFileCell class] forCellReuseIdentifier:NSStringFromClass([NEHistorySearchFileCell class])];
    [self.tableView registerClass:[NEHistorySearchMediaTableSectionHeader class] forHeaderFooterViewReuseIdentifier:NSStringFromClass([NEHistorySearchMediaTableSectionHeader class])];

    [self.view addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.navigationView.bottomAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)addTableViewFootter {
    [self addTableViewFooter];
}

- (void)addTableViewFooter {
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    footer.triggerAutomaticallyRefreshPercent = -20;
    self.tableView.mj_footer = footer;
}

- (void)removeTableViewBottomLoadMore {
    [self.tableView.mj_footer endRefreshingWithNoMoreData];
    self.tableView.mj_footer = nil;

    if (self.viewModel.mediaMessageModels.count > 0) {
        NERefreshHasNoMoreView *view = [[NERefreshHasNoMoreView alloc] initWithFrame:CGRectMake(0, 0, (NSInteger)CGRectGetWidth(self.tableView.bounds), 20)];
        self.tableView.tableFooterView = view;
    }
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsZero;
    layout.minimumInteritemSpacing = 2;
    layout.minimumLineSpacing = 2;

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        self.collectionView.backgroundColor = UIColor.systemBackgroundColor;
    } else {
        self.collectionView.backgroundColor = UIColor.whiteColor;
    }
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;

    MJRefreshNormalHeader *mjHeader = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    [mjHeader setTitle:chatLocalizable(@"search_load_more_messages") forState:MJRefreshStateIdle];
    [mjHeader setTitle:chatLocalizable(@"search_load_immediately_upon_release") forState:MJRefreshStatePulling];
    [mjHeader setTitle:chatLocalizable(@"search_loading_more_messages") forState:MJRefreshStateRefreshing];
    mjHeader.lastUpdatedTimeLabel.hidden = YES;
    mjHeader.ignoredScrollViewContentInsetTop = 0;
    mjHeader.automaticallyChangeAlpha = YES;
    self.collectionView.mj_header = mjHeader;

    [self.collectionView registerClass:[NEHistorySearchMediaCollectionSectionHeader class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:NSStringFromClass([NEHistorySearchMediaCollectionSectionHeader class])];

    switch (self.searchType) {
        case MessageTypeImage:
            [self.collectionView registerClass:[NEHistorySearchImageCell class] forCellWithReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)self.searchType]];
            break;
        case MessageTypeVideo:
            [self.collectionView registerClass:[NEHistorySearchVideoCell class] forCellWithReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)self.searchType]];
            break;
        default:
            [self.collectionView registerClass:[NEHistorySearchImageCell class] forCellWithReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)self.searchType]];
            [self.collectionView registerClass:[NEHistorySearchVideoCell class] forCellWithReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)self.searchType]];
            break;
    }

    [self.view addSubview:self.collectionView];
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.navigationView.bottomAnchor],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)removeCollectionBottomLoadMore {
    [self.collectionView.mj_header endRefreshing];
    self.collectionView.mj_header = nil;

    if (self.viewModel.mediaMessageModels.count > 0) {
        NERefreshHasNoMoreView *headerView = [[NERefreshHasNoMoreView alloc] initWithFrame:CGRectMake(0, -20, (NSInteger)CGRectGetWidth(self.collectionView.bounds), 20)];
        [self.collectionView addSubview:headerView];
        self.collectionView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    }
}

- (void)loadData:(BOOL)firstLoad {
    if (self.isLoadingMore) return;
    self.isLoadingMore = YES;

    NSInteger lastSection = (NSInteger)self.viewModel.mediaMessageModels.count - 1;
    NSInteger lastItem = 0;
    if (lastSection >= 0) {
        lastItem = (NSInteger)self.viewModel.mediaMessageModels[0].messageModels.count - 1;
    }

    MessageType searchType = self.searchType;
    __weak typeof(self) weakSelf = self;
    [self.viewModel searchHistryMediaMessages:firstLoad searchType:searchType completion:^(NSError * _Nullable error, NSInteger messageCount, BOOL hasMore) {
        weakSelf.isLoadingMore = NO;
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf.tableView.mj_footer endRefreshing];
        [weakSelf.collectionView.mj_header endRefreshing];

        if (error) {
            NSError *err = error;
            if (err.code == protocolSendFailed) {
                [weakSelf showToast:commonLocalizable(@"network_error")];
            } else {
                [weakSelf showToast:err.localizedDescription];
                [NEALog errorLog:[ModuleName stringByAppendingString:NSStringFromClass([NEBaseHistoryMediaResultController class])] desc:[NSString stringWithFormat:@"%s failed, error: %@", __FUNCTION__, err.localizedDescription]];
            }
            return;
        }

        if (searchType == MessageTypeFile) {
            if (!hasMore) {
                [weakSelf removeTableViewBottomLoadMore];
            } else {
                [weakSelf addTableViewFooter];
            }
            [weakSelf.tableView reloadData];
        } else {
            if (!hasMore) {
                [weakSelf removeCollectionBottomLoadMore];
            }
            [weakSelf.collectionView reloadData];
        }

        weakSelf.emptyView.hidden = weakSelf.viewModel.mediaMessageModels.count > 0;

        if (searchType != MessageTypeFile && weakSelf.viewModel.mediaMessageModels.count > 0) {
            if (firstLoad) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf scrollToLastItem:NO];
                });
            } else {
                NSInteger sectionCount = (NSInteger)weakSelf.viewModel.mediaMessageModels.count - 1;
                NSInteger targetSection = sectionCount - lastSection;
                if (targetSection >= 0 && targetSection < (NSInteger)weakSelf.viewModel.mediaMessageModels.count) {
                    NSInteger itemIdx = (NSInteger)weakSelf.viewModel.mediaMessageModels[targetSection].messageModels.count - 1 - lastItem;
                    if (itemIdx >= 0 && itemIdx < (NSInteger)[weakSelf.collectionView numberOfItemsInSection:targetSection]) {
                        [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:itemIdx inSection:targetSection]
                                                         atScrollPosition:UICollectionViewScrollPositionBottom
                                                                 animated:NO];
                    }
                }
            }
        }
    }];
}

- (void)refreshData {
    [self loadData:YES];
}

- (void)loadMoreData {
    [self loadData:NO];
}

- (void)scrollToLastItem:(BOOL)animated {
    if (self.viewModel.mediaMessageModels.count == 0) return;

    NSInteger lastSection = (NSInteger)self.viewModel.mediaMessageModels.count - 1;
    NSInteger lastItem = (NSInteger)self.viewModel.mediaMessageModels[lastSection].messageModels.count - 1;
    if (lastItem < 0) return;

    if (self.searchType == MessageTypeFile) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastItem inSection:lastSection];
        if ([self.tableView numberOfSections] > lastSection &&
            [self.tableView numberOfRowsInSection:lastSection] > lastItem) {
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
        }
    } else {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:lastItem inSection:lastSection];
        if (self.collectionView.numberOfSections > lastSection &&
            [self.collectionView numberOfItemsInSection:lastSection] > lastItem) {
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:animated];
        }
    }
}

- (void)forwardMessage:(V2NIMMessage *)message {
    __weak typeof(self) weakSelf = self;
    [Router.shared register:ForwardMultiSelectedRouter closure:^(NSDictionary * _Nullable param) {
        NSMutableArray *items = [NSMutableArray array];
        NSArray *conversations = param[@"conversations"];
        if ([conversations isKindOfClass:[NSArray class]]) {
            NSMutableArray *conversationIds = [NSMutableArray array];
            for (NSDictionary *conversation in conversations) {
                NSString *conversationId = conversation[@"conversationId"];
                if (conversationId) {
                    [conversationIds addObject:conversationId];
                    ForwardItem *item = [[ForwardItem alloc] init];
                    item.conversationId = conversationId;
                    item.name = conversation[@"name"];
                    item.avatar = conversation[@"avatar"];
                    [items addObject:item];
                }
            }

            NSString *type = chatLocalizable(@"operation_forward");
            [weakSelf addForwardAlertControllerWithItems:items type:type sureBlock:^(NSString * _Nullable comment) {
                if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
                    [weakSelf showToast:commonLocalizable(@"network_error")];
                    return;
                }
                [weakSelf.viewModel forwardMessage:@[message] conversationIds:conversationIds comment:comment completion:^(NSError * _Nullable error) {
                    // 转发失败不展示错误信息
                }];
            }];
        }
    }];

    [Router.shared use:ForwardMultiSelectRouter parameters:@{@"nav": self.navigationController ?: [NSNull null], @"selctorMode": @(0)} closure:nil];
}

- (void)addForwardAlertControllerWithItems:(NSArray *)items type:(NSString *)type sureBlock:(void (^)(NSString * _Nullable))sureBlock {
    NEBaseForwardAlertViewController *forwardAlert = [self getForwardAlertController];
    [forwardAlert setItems:items];
    forwardAlert.forwardType = type;
    forwardAlert.sureBlock = sureBlock;

    NSString *content = [ChatMessageHelper getSessionName:ChatRepo.conversationId showAlias:YES];
    forwardAlert.sessionName = content;

    [self addChildViewController:forwardAlert];
    [self.view addSubview:forwardAlert.view];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIApplication.sharedApplication.keyWindow endEditing:YES];
    });
}

- (NEBaseForwardAlertViewController *)getForwardAlertController {
    return [[NEBaseForwardAlertViewController alloc] init];
}

- (void)toCollectMessage:(MessageContentModel *)model {
    if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
        [self showToast:commonLocalizable(@"network_error")];
        return;
    }

    NSString *titleContent = [ChatMessageHelper getSessionName:ChatRepo.conversationId showAlias:YES];
    __weak typeof(self) weakSelf = self;
    [self.viewModel collectMessage:model conversationName:titleContent completion:^(NSError * _Nullable error) {
        if (error) {
            if (error.code == collectionLimitCode) {
                [weakSelf showToast:chatLocalizable(@"collection_limit")];
            } else {
                [weakSelf showToast:commonLocalizable(@"failed_operation")];
            }
        } else {
            [weakSelf showToast:chatLocalizable(@"collection_success")];
        }
    }];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.viewModel.mediaMessageModels.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section >= (NSInteger)self.viewModel.mediaMessageModels.count) return 0;
    return (NSInteger)self.viewModel.mediaMessageModels[section].messageModels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NEHistorySearchFileCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NEHistorySearchFileCell class]) forIndexPath:indexPath];

    if (indexPath.section >= (NSInteger)self.viewModel.mediaMessageModels.count ||
        indexPath.row >= (NSInteger)self.viewModel.mediaMessageModels[indexPath.section].messageModels.count) {
        return cell;
    }

    id model = self.viewModel.mediaMessageModels[indexPath.section].messageModels[indexPath.row];
    if ([model isKindOfClass:[MessageFileModel class]]) {
        [cell configureWithModel:(MessageFileModel *)model];
        cell.delegate = self;
    }
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section >= (NSInteger)self.viewModel.mediaMessageModels.count) return nil;

    NEHistorySearchMediaTableSectionHeader *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([NEHistorySearchMediaTableSectionHeader class])];
    [header configureWithTitle:self.viewModel.mediaMessageModels[section].time];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 124;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section >= (NSInteger)self.viewModel.mediaMessageModels.count ||
        indexPath.row >= (NSInteger)self.viewModel.mediaMessageModels[indexPath.section].messageModels.count) return;
    id model = self.viewModel.mediaMessageModels[indexPath.section].messageModels[indexPath.row];
    if (![model isKindOfClass:[MessageFileModel class]]) return;
    [self didTapFileMessage:model indexPath:indexPath];
}

- (void)didTapFileMessage:(MessageImageModel *)model indexPath:(NSIndexPath *)indexPath {
    if (!model.message) return;
    if (![model.message.attachment isKindOfClass:[V2NIMMessageFileAttachment class]]) return;
    V2NIMMessageFileAttachment *attachment = (V2NIMMessageFileAttachment *)model.message.attachment;
    if (!attachment) return;

    NSString *path = attachment.path ?: [ChatMessageHelper createFilePath:model.message];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [self openFilePreviewWithFilePath:path fileName:attachment.name];
    } else {
        if ([self.tableView cellForRowAtIndexPath:indexPath] != nil) {
            [self downloadFile:model url:attachment.url path:path];
        }
    }
}

- (void)openFilePreviewWithFilePath:(NSString *)filePath fileName:(NSString *)fileName {
    NSURL *url = [NSURL fileURLWithPath:filePath];
    UIDocumentInteractionController *documentController = [UIDocumentInteractionController interactionControllerWithURL:url];
    documentController.name = fileName;
    documentController.delegate = self;
    if (![documentController presentPreviewAnimated:YES]) {
        [documentController presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
    }
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return (NSInteger)self.viewModel.mediaMessageModels.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (section >= (NSInteger)self.viewModel.mediaMessageModels.count) return 0;
    return (NSInteger)self.viewModel.mediaMessageModels[section].messageModels.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseId = [NSString stringWithFormat:@"%ld", (long)self.searchType];
    NEHistorySearchImageCell *cell = (NEHistorySearchImageCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseId forIndexPath:indexPath];

    if (indexPath.section >= (NSInteger)self.viewModel.mediaMessageModels.count ||
        indexPath.row >= (NSInteger)self.viewModel.mediaMessageModels[indexPath.section].messageModels.count) {
        return cell;
    }

    id model = self.viewModel.mediaMessageModels[indexPath.section].messageModels[indexPath.item];
    [cell configureWithModel:model];

    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [cell addGestureRecognizer:longPressGesture];

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        NEHistorySearchMediaCollectionSectionHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([NEHistorySearchMediaCollectionSectionHeader class]) forIndexPath:indexPath];
        if (indexPath.section < (NSInteger)self.viewModel.mediaMessageModels.count) {
            [header configureWithTitle:self.viewModel.mediaMessageModels[indexPath.section].time];
        }
        return header;
    }
    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([NEHistorySearchMediaCollectionSectionHeader class]) forIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section >= (NSInteger)self.viewModel.mediaMessageModels.count ||
        indexPath.item >= (NSInteger)self.viewModel.mediaMessageModels[indexPath.section].messageModels.count) return;
    id model = self.viewModel.mediaMessageModels[indexPath.section].messageModels[indexPath.item];

    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if (!cell) return;

    [UIView animateWithDuration:0.1 animations:^{
        cell.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            cell.transform = CGAffineTransformIdentity;
        }];
    }];

    switch (self.searchType) {
        case MessageTypeImage:
            [self didTapImageMessage:model indexPath:indexPath];
            break;
        case MessageTypeVideo:
            [self didTapVideoMessage:model indexPath:indexPath];
            break;
        default:
            break;
    }
}

- (void)didTapImageMessage:(MessageImageModel *)model indexPath:(NSIndexPath *)indexPath {
    if (!model.message) return;
    if (![model.message.attachment isKindOfClass:[V2NIMMessageImageAttachment class]]) return;
    V2NIMMessageImageAttachment *attachment = (V2NIMMessageImageAttachment *)model.message.attachment;
    if (!attachment || !attachment.url) return;

    NSMutableArray<NSString *> *showImages = [NSMutableArray array];
    NSInteger currentNumber = 0;
    for (NSUInteger sectionIdx = 0; sectionIdx < self.viewModel.mediaMessageModels.count; sectionIdx++) {
        if ((NSInteger)sectionIdx == indexPath.section) {
            currentNumber += indexPath.item;
        } else if ((NSInteger)sectionIdx < indexPath.section) {
            currentNumber += (NSInteger)self.viewModel.mediaMessageModels[sectionIdx].messageModels.count;
        }
        NSInteger unusedIndex = 0;
        NSArray *sectionImages = [ChatMessageHelper getUrls:nil messages:self.viewModel.mediaMessageModels[sectionIdx].messageModels currentIndex:&unusedIndex];
        if ([sectionImages isKindOfClass:[NSArray class]]) {
            [showImages addObjectsFromArray:sectionImages];
        }
    }

    PhotoBrowserController *showController = [[PhotoBrowserController alloc] initWithUrls:showImages url:attachment.url currentIndex:currentNumber];
    showController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:showController animated:NO completion:nil];
}

- (void)didTapVideoMessage:(MessageImageModel *)model indexPath:(NSIndexPath *)indexPath {
    if (!model.message) return;
    if (![model.message.attachment isKindOfClass:[V2NIMMessageVideoAttachment class]]) return;
    V2NIMMessageVideoAttachment *videoAttachment = (V2NIMMessageVideoAttachment *)model.message.attachment;
    if (!videoAttachment) return;

    NSString *path = videoAttachment.path ?: [ChatMessageHelper createFilePath:model.message];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [NEAudioSessionManager.shared switchToSpeaker];
        [NEAudioSessionManager.shared stopProximityMonitoring];

        NSURL *url = [NSURL fileURLWithPath:path];
        VideoPlayerViewController *videoPlayer = [[VideoPlayerViewController alloc] init];
        videoPlayer.modalPresentationStyle = UIModalPresentationOverFullScreen;
        videoPlayer.videoUrl = url;
        videoPlayer.totalTime = (NSInteger)videoAttachment.duration;
        [self presentViewController:videoPlayer animated:YES completion:nil];
    } else {
        [self downloadFile:model url:videoAttachment.url path:path];
    }
}

- (void)downloadFile:(MessageImageModel *)model url:(nullable NSString *)url path:(NSString *)path {
    if (!url || ![model isKindOfClass:[MessageVideoModel class]]) {
        [NEALog infoLog:[[ModuleName stringByAppendingString:@" "] stringByAppendingString:NSStringFromClass([self class])] desc:[NSString stringWithFormat:@"%s MessageFileModel not exit", __FUNCTION__]];
        return;
    }

    MessageVideoModel *fileModel = (MessageVideoModel *)model;
    if (fileModel.state == DownloadStateDownalod) {
        [NEALog infoLog:[[ModuleName stringByAppendingString:@" "] stringByAppendingString:NSStringFromClass([self class])] desc:[NSString stringWithFormat:@"%s downLoad state, click ingore", __FUNCTION__]];
        return;
    }

    [self.viewModel downLoad:url filePath:path progress:^(NSUInteger progress) {
        [NEALog infoLog:[[ModuleName stringByAppendingString:@" "] stringByAppendingString:NSStringFromClass([self class])] desc:[NSString stringWithFormat:@"%s downLoad file progress: %lu", __FUNCTION__, (unsigned long)progress]];
        fileModel.state = DownloadStateDownalod;
        fileModel.progress = progress;
        [fileModel setModelProgress:progress];
    } completion:^(NSString * _Nullable localPath, NSError * _Nullable error) {
        if (localPath) {
            fileModel.state = DownloadStateSuccess;
        }
    }];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;

    CGPoint point = [gesture locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    if (!indexPath) return;
    if (indexPath.section >= (NSInteger)self.viewModel.mediaMessageModels.count ||
        indexPath.item >= (NSInteger)self.viewModel.mediaMessageModels[indexPath.section].messageModels.count) return;

    id model = self.viewModel.mediaMessageModels[indexPath.section].messageModels[indexPath.item];
    if ([model respondsToSelector:@selector(message)]) {
        V2NIMMessage *message = [(MessageImageModel *)model message];
        if (message) {
            [self showAction:message];
        }
    }
}

- (void)showAction:(V2NIMMessage *)message {}

- (void)routerToMessage:(nullable V2NIMMessage *)message {
    NSString *conversationId = message.conversationId ?: ChatRepo.conversationId;
    V2NIMConversationType conversationType = [V2NIMConversationIdUtil conversationType:conversationId];

    NSMutableArray *newMsgs = [NSMutableArray array];
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:[ChatViewController class]]) {
            ChatViewController *chatVC = (ChatViewController *)vc;
            newMsgs = [chatVC.onReceiveNewMsgs mutableCopy];
            break;
        }
    }

    if (conversationType == V2NIM_CONVERSATION_TYPE_P2P) {
        [Router.shared use:PushP2pChatVCRouter parameters:@{
            @"nav": self.navigationController ?: [NSNull null],
            @"conversationId": conversationId ?: [NSNull null],
            @"anchor": message ?: [NSNull null],
            @"onReceiveNewMsgs": newMsgs,
            @"animated": @NO,
        } closure:nil];
        for (UIViewController *vc in self.navigationController.viewControllers) {
            if ([vc isKindOfClass:[ChatViewController class]]) {
                [[(ChatViewController *)vc onReceiveNewMsgs] removeAllObjects];
                break;
            }
        }
    } else if (conversationType == V2NIM_CONVERSATION_TYPE_TEAM) {
        [Router.shared use:PushTeamChatVCRouter parameters:@{
            @"nav": self.navigationController ?: [NSNull null],
            @"conversationId": conversationId ?: [NSNull null],
            @"anchor": message ?: [NSNull null],
            @"onReceiveNewMsgs": newMsgs,
            @"animated": @NO,
        } closure:nil];
        for (UIViewController *vc in self.navigationController.viewControllers) {
            if ([vc isKindOfClass:[ChatViewController class]]) {
                [[(ChatViewController *)vc onReceiveNewMsgs] removeAllObjects];
                break;
            }
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat padding = 2.0 * (self.rowItemCount - 1);
    CGFloat availableWidth = CGRectGetWidth(collectionView.frame) - padding;
    CGFloat itemWidth = availableWidth / self.rowItemCount;
    return CGSizeMake(itemWidth, itemWidth);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(CGRectGetWidth(collectionView.frame), 40);
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self;
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - NEHistorySearchFileCellDelegate

- (void)didClickMoreAction:(NEHistorySearchFileCell *)cell model:(nullable MessageFileModel *)model {}

- (void)reloadSearchResults {
    BOOL isEmpty = self.viewModel.mediaMessageModels.count == 0;
    self.emptyView.hidden = !isEmpty;
    self.tableView.hidden = isEmpty && self.searchType == MessageTypeFile;
    self.collectionView.hidden = isEmpty && self.searchType != MessageTypeFile;

    if (self.searchType == MessageTypeFile) {
        [self.tableView reloadData];
    } else {
        [self.collectionView reloadData];
    }
}

- (void)reloadSearchResultsAfterMessageRemoved {
    [self reloadSearchResults];
}

#pragma mark - ChatBaseCellDelegate

- (void)didTapAvatarView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didLongPressAvatar:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapMessageView:(UITableViewCell *)cell model:(MessageContentModel *)model replyModel:(id)replyModel {}
- (void)didLongPressMessageView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapResendView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapReeditButton:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapReadView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapSelectButton:(UITableViewCell *)cell model:(MessageContentModel *)model {}

#pragma mark - ChatViewModelDelegate

- (void)sending:(V2NIMMessage *)message index:(NSIndexPath *)index {}
- (void)sendSuccess:(V2NIMMessage *)message index:(NSIndexPath *)index {}
- (void)onResendSuccess:(NSIndexPath *)fromIndex toIndexPath:(NSIndexPath *)toIndexPath {}
- (void)onRecvMessages:(NSArray<V2NIMMessage *> *)messages indexs:(NSArray<NSIndexPath *> *)indexs {}
- (void)onLoadMoreWithMessage:(NSArray<NSIndexPath *> *)indexs {}
- (void)onModefiedMessage:(NSIndexPath *)index {}
- (void)onDeleteMessage:(NSArray<V2NIMMessage *> *)messages deleteIndexs:(NSArray<NSIndexPath *> *)deleteIndexs reloadIndex:(NSArray<NSIndexPath *> *)reloadIndex {}

- (void)onRevokeMessage:(V2NIMMessage *)message atIndexs:(NSArray<NSIndexPath *> *)atIndexs {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadSearchResultsAfterMessageRemoved];
    });
}

- (void)onMessageStatusChange:(V2NIMMessage *)message atIndexs:(NSArray<NSIndexPath *> *)atIndexs {}
- (void)remoteUserEditing {}
- (void)remoteUserEndEditing {}
- (void)remoteUserOnlineChanged {}
- (void)tableViewReload {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadSearchResults];
    });
}
- (void)setTopValueWithName:(NSString *)name content:(NSString *)content url:(NSString *)url isVideo:(BOOL)isVideo hideClose:(BOOL)hideClose {}
- (void)updateTopName:(NSString *)name {}

@end
