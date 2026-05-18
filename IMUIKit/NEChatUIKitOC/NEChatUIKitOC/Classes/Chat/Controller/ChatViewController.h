// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>
#import <CoreLocation/CoreLocation.h>
#import "NEChatBaseViewController.h"
#import "ChatInputViewDelegate.h"
#import "ChatViewModel.h"
#import "NEBaseChatInputView.h"
#import "NEBaseChatNewMessageView.h"
#import "ChatBrokenNetworkView.h"
#import "NEMutilSelectBottomView.h"
#import "TopMessageView.h"
#import "ReplyView.h"
#import "NEAITranslateView.h"
#import "MessageOperationView.h"
#import "MessageContentModel.h"
#import "MessageAudioModel.h"
#import "MessageVideoModel.h"
#import <NEChatKitOC/OperationItem.h>
#import "NEBaseSelectLanguageViewController.h"

@class ForwardItem;
@class NEBaseUserSettingViewController;
@class NEBaseForwardAlertViewController;
@class NEBaseReadViewController;
@class TextViewController;
@class MultiForwardViewController;
@class NEBaseSelectUserViewController;
@class MessageSendParams;
@class NEInputMoreCell;
@class NEMoreItemModel;

@protocol ChatAudioCellProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface ChatViewController : NEChatBaseViewController
    <UINavigationControllerDelegate,
     UITableViewDataSource,
     UITableViewDelegate,
     UIDocumentPickerDelegate,
     UIDocumentInteractionControllerDelegate,
     NIMMediaManagerDelegate,
     CLLocationManagerDelegate,
     UIImagePickerControllerDelegate,
     ChatInputViewDelegate,
     ChatInputMultilineDelegate,
     ChatViewModelDelegate,
     MessageOperationViewDelegate,
     NETranslateViewDelegate,
     SelectLanguageDelegate>

@property (nonatomic, copy) NSString *titleContent;
@property (nonatomic, strong, nullable) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) ChatViewModel *viewModel;
@property (nonatomic, strong) UIDocumentInteractionController *interactionController;
@property (nonatomic, assign) BOOL isCurrentPage;
@property (nonatomic, assign) BOOL isMute;
@property (nonatomic, strong, nullable) NSArray<NSNumber *> *operationCellFilter;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *cellRegisterDic;
@property (nonatomic, strong) NSMutableArray<V2NIMMessage *> *onReceiveNewMsgs;
@property (nonatomic, strong) NSMutableArray<V2NIMMessage *> *pendingNewMessages;
@property (nonatomic, assign) CGFloat normalOffset;
@property (nonatomic, assign) CGFloat bottomExanpndHeight;
@property (nonatomic, assign) CGFloat normalInputHeight;
@property (nonatomic, assign) CGFloat brokenNetworkViewHeight;
@property (nonatomic, assign) CGFloat currentKeyboardHeight;
@property (nonatomic, assign) CGFloat bodyTopViewTopConstant;
@property (nonatomic, assign) CGFloat bodyTopViewHeight;
@property (nonatomic, assign) CGFloat bodyBottomViewHeight;
@property (nonatomic, assign) CGFloat bottomViewHeight;

@property (nonatomic, strong, nullable) NSLayoutConstraint *bodyTopViewTopAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bodyTopViewHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bodyBottomViewHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentViewTopAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bottomViewTopAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bottomViewHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *translateLanguageViewHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *jumpDownViewRightAncher;

@property (nonatomic, strong) UIView *bodyTopView;
@property (nonatomic, strong) UIView *bodyView;
@property (nonatomic, strong) NEBrokenNetworkView *brokenNetworkView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *bodyBottomView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) NEBaseChatInputView *chatInputView;
@property (nonatomic, strong) NEBaseChatNewMessageView *jumpDownView;
@property (nonatomic, strong) ReplyView *replyView;
@property (nonatomic, strong) NEMutilSelectBottomView *mutilSelectBottomView;
@property (nonatomic, strong) TopMessageView *topMessageView;
@property (nonatomic, strong) NEAITranslateView *translateLanguageView;
@property (nonatomic, strong) MessageOperationView *operationView;

- (instancetype)initWithConversationId:(NSString *)conversationId;

- (void)addListener;
- (void)removeListener;
- (void)loadData;
- (void)loadMoreData;
- (void)loadFartherToNowData;
- (void)loadCloserToNowData;
- (void)mergePendingNewMessages:(nullable NSArray<V2NIMMessage *> *)messages;
- (void)addObseve;
- (void)commonUI;
- (void)addBottomLoadMore;
- (void)removeBottomLoadMore;
- (void)markNeedReadMsg:(NSArray<V2NIMMessage *> *)messages;
- (void)appEnterBackground;
- (void)appEnterForegournd;
- (void)onMarkdownImageDidLoad:(NSNotification *)notification;
- (void)onTeamMemberChange:(V2NIMTeam *)team;
- (void)getSessionInfo:(NSString *)sessionId completion:(void (^)(void))completion;
- (void)didTapHeadPortrait:(nullable MessageContentModel *)model;
- (void)setOperationItems:(NSMutableArray<OperationItem *> *)items model:(nullable MessageContentModel *)model;
- (void)removeOperationView:(BOOL)cellEndEditing;
- (void)onUserOrFriendInfoChanged:(NSString *)accountId;
- (void)didLongTouchMessageView:(UITableViewCell *)cell model:(nullable MessageContentModel *)model;
- (void)remoteUserEditing;
- (void)remoteUserEndEditing;
- (void)timeoutEndEditing;
- (void)trigerEndTimer;
- (void)remoteUserOnlineChanged;
- (NEBaseUserSettingViewController *)getUserSettingViewController;
- (void)toSetting;
- (void)jumpDownMessage;
- (void)showJumpDownMessage:(NSInteger)messageCount;
- (void)keyBoardWillShow:(NSNotification *)notification;
- (void)keyBoardWillHide:(NSNotification *)notification;
- (void)scrollTableViewToBottom;
- (void)layoutInputView:(CGFloat)offset scrollToBottom:(BOOL)scrollToBottom;
- (void)layoutInputViewWithAnimation:(CGFloat)offset animation:(CGFloat)animation scrollToBottom:(BOOL)scrollToBottom;
- (void)didTranslateResult:(NSString *)content;
- (void)sendText:(nullable NSString *)text attribute:(nullable NSAttributedString *)attribute;
- (void)sendContentText:(nullable NSString *)text attribute:(nullable NSAttributedString *)attribute;
- (void)didSelectMoreCell:(NEInputMoreCell *)cell;
- (void)openPhoto;
- (void)showTakePicture;
- (void)showFileAction;
- (void)showRtcCallAction;
- (void)showTranslateView;
- (void)useToCallViewRouter:(NSInteger)type;
- (void)didToSearchLocationView;
- (void)willSelectItem:(nullable UIButton *)button index:(NSInteger)index;
- (void)setHandsetMode:(OperationItem *)item;
- (void)copyMessage;
- (void)deleteMessage;
- (void)showReplyMessageView:(BOOL)isReEdit;
- (void)closeReply:(nullable UIButton *)button;
- (void)recallMessage;
- (NEBaseForwardAlertViewController *)getForwardAlertController;
- (void)addForwardAlertController:(NSArray<ForwardItem *> *)items type:(NSString *)type sureBlock:(nullable void (^)(NSString *_Nullable comment))sureBlock;
- (void)forwardMessage;
- (void)pinMessage;
- (void)removePinMessage;
- (void)topMessage;
- (void)toCollectMessage;
- (void)voiceToText;
- (void)untopMessage;
- (void)selectMessage;
- (void)cancelMutilSelect;
- (void)setInputView:(BOOL)edit;
- (void)startPlay:(nullable id<ChatAudioCellProtocol>)cell model:(nullable MessageAudioModel *)model;
- (void)stopPlay;
- (void)startRecord;
- (void)endRecord:(BOOL)insideView;
- (void)startPlaying:(nullable V2NIMMessage *)audioMessage isSend:(BOOL)isSend;
- (void)didTapMessage:(nullable UITableViewCell *)cell model:(nullable MessageContentModel *)model replyIndex:(NSInteger)replyIndex;
- (void)didTapAudioMessage:(nullable UITableViewCell *)cell model:(nullable MessageContentModel *)model;
- (void)didTapImageMessage:(nullable MessageContentModel *)model replyIndex:(NSInteger)replyIndex;
- (void)didTapVideoMessage:(nullable UITableViewCell *)cell model:(nullable MessageContentModel *)model replyIndex:(NSInteger)replyIndex;
- (void)didTapFileMessage:(nullable UITableViewCell *)cell model:(nullable MessageContentModel *)model replyIndex:(NSInteger)replyIndex;
- (void)didTapCallMessage:(nullable MessageContentModel *)model;
- (void)didTapLocationMessage:(nullable MessageContentModel *)model;
- (void)didTapCustomMessage:(nullable MessageContentModel *)model replyIndex:(NSInteger)replyIndex;
- (void)downloadFile:(nullable UITableViewCell *)cell model:(nullable MessageContentModel *)model url:(nullable NSString *)url path:(NSString *)path;
- (void)setModelProgress:(nullable V2NIMMessage *)message progress:(NSUInteger)progress;
- (void)showTextViewController:(nullable MessageContentModel *)model;
- (TextViewController *)getTextViewController:(nullable NSString *)title body:(nullable NSAttributedString *)body;
- (MultiForwardViewController *)getMultiForwardViewController:(nullable NSString *)messageAttachmentUrl filePath:(NSString *)messageAttachmentFilePath md5:(nullable NSString *)messageAttachmentMD5;
- (NSArray<NEMoreItemModel *> *)expandMoreAction;
- (NEBaseChatInputView *)getMenuView:(V2NIMConversationType)conversationType;
- (NEBaseChatNewMessageView *)getJumpDownView;
- (void)setMutilSelectBottomView;
- (NEBaseSelectUserViewController *)getUserSelectVC:(BOOL)showTeamMembers;
- (void)showUserSelectVC:(BOOL)showTeamMembers;
- (void)showErrorToast:(nullable NSError *)error defaultToast:(nullable NSString *)defaultToast;
- (void)tableViewDeleteIndexs:(NSArray<NSIndexPath *> *)indexs;
- (void)tableViewReloadIndexs:(NSArray<NSIndexPath *> *)indexs completion:(nullable void (^)(void))completion;
- (void)tableViewReload;
- (void)dataReload;
- (void)insertRows:(NSArray<NSIndexPath *> *)indexs scrollToBottom:(BOOL)scrollToBottom;
- (void)addToAtUsers:(NSString *)addText isReply:(BOOL)isReply accid:(NSString *)accid isLongPress:(BOOL)isLongPress;
- (void)setMoreButton;
- (void)showJumpDownView;
- (BOOL)isCloseToBottom;
- (void)loadDataFinish;
- (void)showLeaveTeamAlert;
- (void)showDismissTeamAlert;
- (void)dismissAlert;
- (void)didClickMultiForwardButton;
- (void)didClickSingleForwardButton;
- (void)filterSelectedMessage:(NSArray<V2NIMMessage *> *)invalidMessages;
- (void)forwardMessages:(BOOL)isMultiForward depth:(NSInteger)depth;
- (void)customOperation;
- (void)cancelMutilSelectAction;
- (void)selectedMessagesChanged:(NSInteger)count;
- (void)expandButtonDidClick;
- (void)showAIChatView;
- (void)closeAIChatView;
- (void)didHideMultiple;
- (void)didSendFinishAndCheckoutInput;
- (void)didHideMultipleButtonClick;
- (void)titleTextDidClearEmpty;
- (void)checkAndSendTypingState:(BOOL)endEdit;
- (void)showLanguageContentController:(NEBaseSelectLanguageViewController *)controller;
- (NEBaseReadViewController *)getReadView:(V2NIMMessage *)message teamId:(NSString *)teamId;
- (MessageSendParams *_Nullable)beforeSend:(MessageSendParams *)param;
- (void)beforeSend:(MessageSendParams *)param completion:(void (^)(MessageSendParams *_Nullable))completion;
- (void)sendMessageCallback:(nullable V2NIMSendMessageResult *)result error:(nullable V2NIMError *)error progress:(NSUInteger)progress;

@end

NS_ASSUME_NONNULL_END
