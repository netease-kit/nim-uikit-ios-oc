// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatViewController.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import "ChatCellConstantValue.h"
#import "ChatUIConfig.h"
#import "ChatMessageHelper.h"
#import "FunChatUIColor.h"
#import "FunChatInputView.h"
#import "FunRecordAudioView.h"
#import "FunChatNewMessageView.h"
#import "FunForwardAlertViewController.h"
#import "FunMultiForwardViewController.h"
#import "FunSelectUserViewController.h"
#import "FunSelectLanguageViewController.h"
#import "FunTextViewController.h"
#import "FunReadViewController.h"
#import "FunUserSettingViewController.h"
#import "NEEmotionTool.h"
#import "NETeamUserManager.h"
#import "NEChatMoreActionView.h"

@implementation FunChatViewController

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.normalInputHeight = 90;
        self.brokenNetworkViewHeight = 48;
        self.cellRegisterDic = [ChatMessageHelper getChatCellRegisterDicWithIsFun:YES];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([ChatUIConfig shared].messageProperties.chatViewBackgroundSolid &&
        [ChatUIConfig shared].messageProperties.chatTableViewBackgroundColor) {
        UIColor *color = [ChatUIConfig shared].messageProperties.chatTableViewBackgroundColor;
        self.navigationController.navigationBar.backgroundColor = color;
        [self.navigationView setNavigationBackgroundColor:color];
        self.chatInputView.chatAddMoreView.backgroundColor = color;
    } else {
        self.navigationController.navigationBar.backgroundColor = [UIColor funChatNavigationBg];
        self.navigationView.backgroundColor = [UIColor funChatNavigationBg];
        self.navigationView.titleBarBottomLine.backgroundColor = [UIColor funChatNavigationDivideBg];
        self.view.backgroundColor = [UIColor funChatBackgroundColor];
        self.bodyTopView.backgroundColor = [UIColor funChatBodyTopViewBg];
        self.brokenNetworkView.backgroundColor = [UIColor funChatNetworkBrokenViewBg];
        self.bodyView.backgroundColor = [UIColor funChatBodyViewBg];
        self.tableView.backgroundColor = [UIColor funChatTableViewBg];
        self.bodyBottomView.backgroundColor = [UIColor funChatBodyBottomViewBg];
        self.chatInputView.backgroundColor = [UIColor funChatInputViewBg];
    }

    self.topMessageView.topImageView.image = [UIImage ne_imageNamed:@"top_message_image"];
    self.brokenNetworkView.errorIconView.hidden = NO;
    self.brokenNetworkView.contentLabel.textColor = [UIColor funChatNetworkBrokenTitleColor];

    [self.view bringSubviewToFront:self.chatInputView];
    [self getFunInputView].funDelegate = self;
}

- (NEBaseChatInputView *)getMenuView:(V2NIMConversationType)conversationType {
    FunChatInputView *input = [[FunChatInputView alloc] initWithConversationType:conversationType];
    input.multipleLineDelegate = self;
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(holdToSpeak:)];
    [input.holdToSpeakView addGestureRecognizer:gesture];
    return input;
}

- (NEBaseChatNewMessageView *)getJumpDownView {
    return [[FunChatNewMessageView alloc] init];
}

- (NEBaseForwardAlertViewController *)getForwardAlertController {
    return [[FunForwardAlertViewController alloc] init];
}

- (MultiForwardViewController *)getMultiForwardViewController:(NSString *)messageAttachmentUrl
                                                     filePath:(NSString *)messageAttachmentFilePath
                                                          md5:(nullable NSString *)messageAttachmentMD5 {
    return [[FunMultiForwardViewController alloc] initWithAttachmentUrl:messageAttachmentUrl
                                                   attachmentFilePath:messageAttachmentFilePath
                                                      attachmentMD5:messageAttachmentMD5];
}

- (NEBaseSelectUserViewController *)getUserSelectVC:(BOOL)showTeamMembers {
    return [[FunSelectUserViewController alloc] initWithConversationId:[ChatRepo conversationId]
                                                              showSelf:NO
                                                       showTeamMembers:showTeamMembers];
}

- (TextViewController *)getTextViewController:(nullable NSString *)title body:(nullable NSAttributedString *)body {
    FunTextViewController *vc = [[FunTextViewController alloc] initWithTitle:title body:body];
    [vc updateLinkDetection];
    return vc;
}

- (void)recordModeChangeDidClick {
    [self.translateLanguageView changeToIdleState:YES];
    self.translateLanguageViewHeightAnchor.constant = 0;
    self.normalOffset = 0;
    if (self.chatInputView.chatInpuMode == ChatInputModeMultipleSend) {
        self.normalInputHeight = 90;
        FunChatInputView *inputView = [self getFunInputView];
        [inputView setRecordNormalStyle];
    }
    [self layoutInputViewWithAnimation:0 animation:0.1 scrollToBottom:NO];
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

- (void)didHideRecordMode {
    if (self.chatInputView.chatInpuMode == ChatInputModeMultipleSend) {
        self.normalInputHeight = 130;
        FunChatInputView *inputView = [self getFunInputView];
        [inputView resotreMutipleModeFromRecordMode];
        [self layoutInputViewWithAnimation:0 animation:0 scrollToBottom:NO];
    }
}

- (void)didHideReplyMode {
    self.viewModel.isReplying = NO;
    if (self.currentKeyboardHeight > 0) {
        self.normalOffset = 30;
    } else {
        self.normalOffset = 0;
    }
    [self layoutInputViewWithAnimation:self.currentKeyboardHeight animation:0 scrollToBottom:NO];
}

- (void)didShowReplyMode {
    self.viewModel.isReplying = YES;
    [self.chatInputView.textView becomeFirstResponder];
}

- (NSArray<NEMoreItemModel *> *)expandMoreAction {
    NSArray *items = [super expandMoreAction];
    [self.chatInputView.chatAddMoreView configData:items];
    return items;
}

- (void)openPhoto {
    [NEALog infoLog:NSStringFromClass([self class]) desc:@"open photo"];
    [self willSelectItem:self.chatInputView.currentButton index:showPhotoTag];
}

- (void)showRtcCallAction {
    __weak typeof(self) weakSelf = self;
    NECustomAlertAction *videoCallAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"video_call") handler:^{
        [weakSelf useToCallViewRouter:2];
    }];
    NECustomAlertAction *audioCallAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"audio_call") handler:^{
        [weakSelf useToCallViewRouter:1];
    }];
    [self showCustomActionSheet:@[videoCallAction, audioCallAction]];
}

- (NEBaseUserSettingViewController *)getUserSettingViewController {
    return [[FunUserSettingViewController alloc] initWithUserId:[ChatRepo sessionId]];
}

- (void)keyBoardWillShow:(NSNotification *)notification {
    if (self.chatInputView.chatInpuMode == ChatInputModeNormal ||
        self.chatInputView.chatInpuMode == ChatInputModeMultipleSend) {
        if (self.viewModel.isReplying) {
            self.normalOffset = -10;
        } else {
            self.normalOffset = 30;
        }
    }
    NSValue *keyboardRectValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [keyboardRectValue CGRectValue];
    self.currentKeyboardHeight = keyboardRect.size.height;
    [super keyBoardWillShow:notification];
}

- (void)keyBoardWillHide:(NSNotification *)notification {
    if (self.chatInputView.chatInpuMode == ChatInputModeNormal ||
        self.chatInputView.chatInpuMode == ChatInputModeMultipleSend) {
        if (self.viewModel.isReplying) {
            self.normalOffset = -30;
        } else {
            self.normalOffset = 0;
        }
    }
    self.currentKeyboardHeight = 0;
    [super keyBoardWillHide:notification];
}

- (void)holdToSpeak:(UILongPressGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            if ([NEAuthManager hasAudioAuthorization]) {
                [self showRecordView];
            } else {
                __weak typeof(self) weakSelf = self;
                [NEAuthManager requestAudioAuthorization:^(BOOL granted) {
                    if (!granted) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf showSingleAlert:commonLocalizable(@"jump_microphone_setting") completion:^{}];
                        });
                    }
                }];
            }
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint location = [gesture locationInView:self.view];
            if (location.y < [UIScreen mainScreen].bounds.size.height - [FunRecordAudioView getGestureHeight]) {
                [self.recordView changeToCancelStyle];
            } else {
                [self.recordView changeToNormalStyle];
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self removeRecordView];
            break;
        default:
            break;
    }
}

- (void)showTakePicture {
    [self showCustomBottomVideoAction:self isVideo:NO];
}

- (void)showFileAction {
    [self stopPlay];
    [self showCustomBottomFileAction:self];
}

- (void)didTapTel:(NSURL *)url {
    [self showCustomBottomTelAction:url];
}

- (void)didTapMailto:(NSURL *)url {
    [self showCustomBottomMailAction:url];
}

- (void)showRecordView {
    if (!self.recordView) {
        FunRecordAudioView *recordAudio = [[FunRecordAudioView alloc] init];
        recordAudio.delegate = self;
        recordAudio.frame = [UIScreen mainScreen].bounds;
        self.recordView = recordAudio;
        [[UIApplication sharedApplication].keyWindow addSubview:recordAudio];
    }
    [self startRecord];
}

- (void)removeRecordView {
    if (self.recordView) {
        if ([self.recordView isRecordNormalStyle]) {
            [self endRecord:YES];
        } else {
            [self endRecord:NO];
        }
    }
    [self.recordView removeFromSuperview];
    self.recordView = nil;
}

- (void)didEndRecord:(FunRecordAudioView *)view {
    [self endRecord:YES];
    [view removeFromSuperview];
    [[self getFunInputView].holdToSpeakView resignFirstResponder];
}

- (nullable FunChatInputView *)getFunInputView {
    if ([self.chatInputView isKindOfClass:[FunChatInputView class]]) {
        return (FunChatInputView *)self.chatInputView;
    }
    return nil;
}

- (void)setMutilSelectBottomView {
    self.mutilSelectBottomView.backgroundColor = [UIColor whiteColor];
    self.mutilSelectBottomView.buttonTopAnchor.constant = 6;
    [self.mutilSelectBottomView.multiForwardButton setImage:[UIImage ne_imageNamed:@"fun_select_multiForward"] forState:UIControlStateNormal];
    [self.mutilSelectBottomView.multiForwardButton setImage:[UIImage ne_imageNamed:@"fun_unselect_multiForward"] forState:UIControlStateDisabled];
    [self.mutilSelectBottomView.singleForwardButton setImage:[UIImage ne_imageNamed:@"fun_select_singleForward"] forState:UIControlStateNormal];
    [self.mutilSelectBottomView.singleForwardButton setImage:[UIImage ne_imageNamed:@"fun_unselect_singleForward"] forState:UIControlStateDisabled];
    [self.mutilSelectBottomView.deleteButton setImage:[UIImage ne_imageNamed:@"fun_select_delete"] forState:UIControlStateNormal];
    [self.mutilSelectBottomView.deleteButton setImage:[UIImage ne_imageNamed:@"fun_unselect_delete"] forState:UIControlStateDisabled];
    [self.mutilSelectBottomView setLabelColor:[UIColor funChatInputHoldspeakTextColor]];
}

- (void)closeReply:(UIButton *)button {
    self.viewModel.isReplying = NO;
    [[self getFunInputView] hideReplyMode];
    [self getFunInputView].replyLabel.attributedText = nil;
}

- (void)showReplyMessageView:(BOOL)isReEdit {
    self.viewModel.isReplying = YES;
    FunChatInputView *replyView = [self getFunInputView];
    if (!replyView) return;
    [replyView showReplyMode];
    if (self.viewModel.operationModel.message) {
        if (isReEdit) {
            replyView.replyLabel.attributedText = [NEEmotionTool getAttWithStr:self.viewModel.operationModel.replyText ?: @""
                                                                          font:[UIFont systemFontOfSize:13]
                                                                         color:[UIColor ne_greyText]
                                                                        offset:CGPointMake(0, -4)];
            __weak typeof(self) weakSelf = self;
            [self.viewModel getReplyMessage:self.viewModel.operationModel.message completion:^(id<MessageModel> model) {
                if ([model isKindOfClass:[MessageContentModel class]]) {
                    weakSelf.viewModel.operationModel = (MessageContentModel *)model;
                }
            }];
        } else {
            NSString *text = chatLocalizable(@"operation_replay");
            NSString *uid = [ChatMessageHelper getSenderId:self.viewModel.operationModel.message];
            if (uid) {
                NSString *showName = [NETeamUserManager.shared getShowName:uid showAlias:NO];
                if ([V2NIMConversationIdUtil conversationType:[ChatRepo conversationId]] != V2NIM_CONVERSATION_TYPE_P2P &&
                    ![[IMKitClient instance] isMe:uid]) {
                    [self addToAtUsers:[NSString stringWithFormat:@"@%@ ", showName] isReply:YES accid:uid isLongPress:NO];
                }
                showName = [NETeamUserManager.shared getShowName:uid showAlias:YES];
                text = [NSString stringWithFormat:@"%@ %@: %@", text, showName, [ChatMessageHelper contentOfMessage:self.viewModel.operationModel.message]];
                replyView.replyLabel.attributedText = [NEEmotionTool getAttWithStr:text
                                                                              font:[UIFont systemFontOfSize:13]
                                                                             color:[UIColor ne_greyText]
                                                                            offset:CGPointMake(0, -4)];
            }
        }
        if (self.chatInputView.textView.isFirstResponder) {
            self.normalOffset = -10;
            [self layoutInputViewWithAnimation:self.currentKeyboardHeight animation:0 scrollToBottom:NO];
        } else {
            [self.chatInputView.textView becomeFirstResponder];
        }
    }
}

- (NEBaseReadViewController *)getReadView:(V2NIMMessage *)message teamId:(NSString *)teamId {
    return [[FunReadViewController alloc] initWithMessage:message teamId:teamId];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.messages.count) return 0;

    id model = self.viewModel.messages[indexPath.row];
    if ([model isKindOfClass:[MessageContentModel class]]) {
        MessageContentModel *contentModel = (MessageContentModel *)model;
        if (contentModel.type == MessageTypeRevoke) {
            if (contentModel.timeContent.length > 0) {
                return chat_min_h + chat_timeCellH;
            }
            return chat_min_h;
        }
    }

    return [(id<MessageModel> )model cellHeight];
}

- (void)addToAtUsers:(NSString *)addText isReply:(BOOL)isReply accid:(NSString *)accid isLongPress:(BOOL)isLongPress {
    FunChatInputView *inputView = [self getFunInputView];
    if ([inputView isRecordMode]) {
        [inputView hideRecordMode];
    }
    [super addToAtUsers:addText isReply:isReply accid:accid isLongPress:isLongPress];
}

#pragma mark - Multiple Line

- (void)expandButtonDidClick {
    [super expandButtonDidClick];
    NSLog(@"expandButtonDidClick");
    [self.chatInputView changeToMultipleLineStyle];
    self.normalInputHeight = 295;
    self.bottomViewTopAnchor.constant = -self.normalInputHeight;
}

- (void)didHideMultipleButtonClick {
    [super didHideMultipleButtonClick];
    [self setInputValue];
    [self layoutInputViewWithAnimation:0 animation:0.1 scrollToBottom:NO];
}

- (void)titleTextDidClearEmpty {
    if (self.chatInputView.chatInpuMode == ChatInputModeMultipleSend) {
        self.chatInputView.chatInpuMode = ChatInputModeNormal;
        [self setInputValue];
        [self.chatInputView restoreNormalInputStyle];
        [self.chatInputView.textView becomeFirstResponder];
        [self layoutInputViewWithAnimation:self.currentKeyboardHeight animation:0.1 scrollToBottom:NO];
    }
}

- (void)setInputValue {
    if (self.chatInputView.chatInpuMode == ChatInputModeNormal) {
        self.normalInputHeight = 90;
    } else if (self.chatInputView.chatInpuMode == ChatInputModeMultipleSend) {
        self.normalInputHeight = 130;
    }

    if (self.viewModel.isReplying) {
        self.normalOffset = -30;
    } else {
        self.normalOffset = 0;
    }
}

/// 不隐藏键盘
- (void)didHideMultiple {
    self.normalInputHeight = 90;
    if (self.currentKeyboardHeight > 0) {
        self.normalOffset = 30;
    }
    [self layoutInputViewWithAnimation:self.currentKeyboardHeight animation:0.1 scrollToBottom:NO];
}

- (void)didSwitchLanguageClick:(NSString *)currentLanguage {
    FunSelectLanguageViewController *funLanguageSelectController = [[FunSelectLanguageViewController alloc] init];
    if (currentLanguage) {
        funLanguageSelectController.currentContent = currentLanguage;
    }
    [self showLanguageContentController:funLanguageSelectController];
}

- (void)getMessageModel:(id<MessageModel> )model {
    if (model.type == MessageTypeTip || model.type == MessageTypeNotification) {
        return;
    }

    CGFloat contentWidth = model.contentSize.width;
    CGFloat contentHeight = model.contentSize.height;
    CGFloat subHeight = 0;
    if (contentHeight < fun_chat_min_h) {
        subHeight = fun_chat_min_h - contentHeight;
        model.contentSize = CGSizeMake(contentWidth, fun_chat_min_h);
        model.offset = subHeight;
    }

    if (model.isReply) {
        model.offset = subHeight + fun_chat_reply_height + chat_content_margin;
    }

    if (model.type == MessageTypeRtcCallRecord) {
        model.contentSize = CGSizeMake(contentWidth, contentHeight - 2);
        model.offset = -2;
    }
}

@end
