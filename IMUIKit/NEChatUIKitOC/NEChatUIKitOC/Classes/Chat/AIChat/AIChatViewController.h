// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NECommonUIKitOC/NELottieAnimationView.h>
#import "AIChatTableViewCell.h"
#import "AIChatViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AIChatViewDelegate <NSObject>
- (void)didClickMessageItem:(NSString *)text;
- (void)didClickEditButton:(nullable NSString *)text;
@end

/// AI助聊视图控制器
@interface AIChatViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, AIChatTableViewCellDelegate>

@property (nonatomic, weak, nullable) id<AIChatViewDelegate> delegate;
@property (nonatomic, strong, readonly) AIChatViewModel *viewModel;
@property (nonatomic, strong, nullable) NSArray<V2NIMMessage *> *lastMessages;

@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UIImageView *titleIcon;
@property (nonatomic, strong) ExpandButton *reloadButton;
@property (nonatomic, strong) NELottieAnimationView *loadDataView;
@property (nonatomic, strong) UIView *loadDataFailedView;
@property (nonatomic, strong) UITableView *tableView;

- (void)commonUI;
- (void)showLoadingView;
- (void)showFaildeView;
- (void)showTableView;
- (void)loadData:(nullable NSArray<V2NIMMessage *> *)messages;
- (void)loadMoreData:(nullable NSArray<V2NIMMessage *> *)messages;
- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
