// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatBaseViewController.h"
#import "BotSubSessionListViewModel.h"
#import <NEBaseUIKitOC/SearchTextField.h>
#import <NEBaseUIKitOC/NEAdaptiveBottomSheetController.h>

NS_ASSUME_NONNULL_BEGIN

@class NEBaseUserSettingViewController;

@interface BotSubSessionListCell : UITableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(nullable NSString *)reuseIdentifier NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (void)setupUI;
- (void)applyStyleWithBackgroundColor:(UIColor *)backgroundColor
                         showsDivider:(BOOL)showsDivider
                          dividerColor:(UIColor *)dividerColor;
- (void)configureWithItem:(BotSubSessionItem *)item
              sessionName:(NSString *)sessionName
                  keyword:(NSString *)keyword
           highlightColor:(UIColor *)highlightColor;
@end

/// Bot 子会话的「重命名 / 删除」底部弹窗。
@interface BotSubSessionActionSheetController : NEAdaptiveBottomSheetController <UIGestureRecognizerDelegate>
@property(nonatomic, copy, readonly) NSString *topicTitle;
@property(nonatomic, copy, nullable) void (^onRename)(void);
@property(nonatomic, copy, nullable) void (^onDelete)(void);
- (instancetype)initWithTitle:(NSString *)title NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                          bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (void)setupUI;
@end

@interface BotSubSessionRenameDialogController : UIViewController <UITextFieldDelegate>
@property(nonatomic, copy, readonly) NSString *initialName;
@property(nonatomic, strong, readonly) UIColor *saveButtonBackgroundColor;
@property(nonatomic, copy, nullable) void (^onSave)(NSString *name);
- (instancetype)initWithName:(NSString *)name
   saveButtonBackgroundColor:(UIColor *)saveButtonBackgroundColor NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                          bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (void)setupUI;
- (void)showToast:(NSString *)message;
@end

@interface BotSubSessionDeleteDialogController : UIViewController
@property(nonatomic, copy, nullable) void (^onDelete)(void);
@property(nonatomic, copy, readonly) NSString *dialogTitle;
@property(nonatomic, copy, readonly) NSString *dialogMessage;
@property(nonatomic, strong, readonly) UIColor *confirmButtonBackgroundColor;
- (instancetype)initWithTitle:(NSString *)title
                       message:(NSString *)message
  confirmButtonBackgroundColor:(UIColor *)confirmButtonBackgroundColor NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                          bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (void)setupUI;
@end

@interface NEBaseBotSubSessionListViewController : NEChatBaseViewController
  <BotSubSessionListViewModelDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property(nonatomic, strong, readonly) BotSubSessionListViewModel *viewModel;
@property(nonatomic, copy, readonly) NSString *conversationId;
@property(nonatomic, copy, readonly) NSString *sessionId;
@property(nonatomic, copy, readonly) NSString *sessionName;
@property(nonatomic, assign, readonly) CGFloat listTopSpacing;
@property(nonatomic, strong, nullable) NSLayoutConstraint *tableViewTopAnchor;
@property(nonatomic, strong) UIColor *deleteButtonBackgroundColor;
@property(nonatomic, strong) UIColor *renameButtonBackgroundColor;
@property(nonatomic, strong, readonly) UIColor *pageBackgroundColor;
@property(nonatomic, strong, readonly) UIColor *listItemBackgroundColor;
@property(nonatomic, assign, readonly) BOOL showsListItemDivider;
@property(nonatomic, strong, readonly) UIColor *listItemDividerColor;
@property(nonatomic, copy, readonly) NSString *defaultEmptyImageName;
@property(nonatomic, copy, readonly) NSString *searchEmptyImageName;
@property(nonatomic, strong, readonly) UIColor *emptyActionTitleColor;
@property(nonatomic, strong, readonly) UIColor *emptyActionBackgroundColor;
@property(nonatomic, strong, readonly) UIColor *searchHighlightColor;
@property(nonatomic, strong) UIButton *emptyActionButton;
@property(nonatomic, strong) UIButton *createTopicButton;
@property(nonatomic, strong) SearchTextField *searchTextField;
@property(nonatomic, strong) UITableView *tableView;

- (instancetype)initWithConversationId:(NSString *)conversationId
                              sessionId:(NSString *)sessionId
                            sessionName:(NSString *)sessionName NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                          bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (void)setupUI;
- (void)refreshData;
- (void)showDeleteAlertWithTopic:(V2NIMTopic *)topic;
- (void)showRenameAlertWithTopic:(V2NIMTopic *)topic;
- (void)showCreateAlert;
- (void)searchTextChanged;
- (void)enterTopic:(nullable V2NIMTopic *)topic;
- (void)openSettingPage;
- (nullable NEBaseUserSettingViewController *)getUserSettingViewController;

@end

NS_ASSUME_NONNULL_END
