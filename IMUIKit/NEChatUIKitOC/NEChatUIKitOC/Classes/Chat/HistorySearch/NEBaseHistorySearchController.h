// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/NERouterUrl.h>
#import <NIMSDK/NIMSDK.h>
#import "TeamHistoryMessageViewModel.h"
#import "NEChatBaseViewController.h"
#import "NEHistoryDatePickerViewController.h"
#import "NEBaseChatMessageCell.h"

NS_ASSUME_NONNULL_BEGIN

/// 自定义 View：重写 hitTest，在触摸分发最早阶段就收起键盘
@interface NEHistorySearchContainerView : UIView
@property(nonatomic, weak, nullable) UITextField *searchTextField;
@end

@class FunSearchView;

@interface NEBaseHistorySearchController : NEChatBaseViewController <UITextFieldDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource, NEHistoryDatePickerViewControllerDelegate, UIGestureRecognizerDelegate, ChatBaseCellDelegate, ChatViewModelDelegate>

@property(nonatomic, copy) NSString *tag;
@property(nonatomic, strong) TeamHistoryMessageViewModel *viewModel;
@property(nonatomic, strong) V2NIMMessageSearchExParams *messageSearchExParams;
@property(nonatomic, copy, nullable) NSString *conversationId;
@property(nonatomic, copy) NSString *searchStr;
@property(nonatomic, assign) BOOL isSearching;

@property(nonatomic, strong) UICollectionViewFlowLayout *layout;
@property(nonatomic, strong) NSMutableDictionary<NSString *, Class> *cellRegisterDic;
@property(nonatomic, strong) UIColor *themeColor;
@property(nonatomic, strong) UICollectionView *collectionView;

@property(nonatomic, strong) UILabel *tipLable;
@property(nonatomic, strong) SearchTextField *searchTextField;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong, nullable) NSLayoutConstraint *tableViewTopAnchor;

- (instancetype)initWithConversationId:(NSString *)conversationId;

- (void)setupSubviews;
- (void)initialConfig;
- (void)refreshData;
- (void)loadMoreData;
- (void)loadData:(nullable V2NIMMessageSearchExParams *)params firstLoad:(BOOL)firstLoad;
- (void)loadData:(nullable V2NIMMessageSearchExParams *)params autoSearch:(BOOL)autoSearch;
- (void)addBottomLoadMore;
- (void)removeBottomLoadMore;
- (void)searchTeamMemberAction;
- (void)searchImageAction;
- (void)searchVideoAction;
- (void)searchDateAction;
- (void)searchFileAction;
- (void)routerToMessage:(nullable V2NIMMessage *)message;
- (void)searchTextChanged;

@end

NS_ASSUME_NONNULL_END
