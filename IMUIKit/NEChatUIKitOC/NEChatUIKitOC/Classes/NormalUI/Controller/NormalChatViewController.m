// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NormalChatViewController.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "ChatInpuView.h"
#import "ForwardAlertViewController.h"
#import "NormalMultiForwardViewController.h"
#import "SelectUserViewController.h"
#import "SelectLanguageViewController.h"
#import "NormalChatUIColor.h"
#import "ChatMessageHelper.h"
#import <NEChatKit/ChatRepo.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import "ChatNavigationView.h"
#import "ChatRecordView.h"
#import "NEChatMoreActionView.h"
#import "ChatCellConstantValue.h"

@implementation NormalChatViewController

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.cellRegisterDic = [ChatMessageHelper getChatCellRegisterDic:NO];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([ChatUIConfig shared].messageProperties.chatViewBackgroundSolid &&
        [ChatUIConfig shared].messageProperties.chatTableViewBackgroundColor) {
        UIColor *color = [ChatUIConfig shared].messageProperties.chatTableViewBackgroundColor;
        self.navigationController.navigationBar.backgroundColor = color;
        [self.navigationView setNavigationBackgroundColor:color];
        self.chatInputView.recordView.backgroundColor = color;
        self.chatInputView.chatAddMoreView.backgroundColor = color;
    } else {
        self.navigationController.navigationBar.backgroundColor = UIColor.normalChatNavigationBg;
        self.navigationView.backgroundColor = UIColor.normalChatNavigationBg;
        self.navigationView.titleBarBottomLine.backgroundColor = UIColor.normalChatNavigationDivideBg;
        self.bodyTopView.backgroundColor = UIColor.normalChatBodyTopViewBg;
        self.brokenNetworkView.backgroundColor = UIColor.normalChatNetworkBrokenViewBg;
        self.brokenNetworkView.contentLabel.textColor = UIColor.normalChatNetworkBrokenTitleColor;
        self.bodyView.backgroundColor = UIColor.normalChatBodyViewBg;
        self.tableView.backgroundColor = UIColor.normalChatTableViewBg;
        self.bodyBottomView.backgroundColor = UIColor.normalChatBodyBottomViewBg;
        self.chatInputView.backgroundColor = UIColor.normalChatInputViewBg;
    }

    self.topMessageView.topImageView.image = [UIImage ne_imageNamed:@"top_message_image"];
    self.topMessageView.layer.borderColor = [UIColor ne_colorWithHexString:@"#E8EAED"].CGColor;
    self.topMessageView.layer.borderWidth = 1;
}

- (NEBaseChatInputView *)getMenuView:(V2NIMConversationType)conversationType {
    ChatInputView *chat = [[ChatInputView alloc] initWithConversationType:conversationType];
    chat.multipleLineDelegate = self;
    return chat;
}

- (NEBaseForwardAlertViewController *)getForwardAlertController {
    return [[ForwardAlertViewController alloc] init];
}

- (MultiForwardViewController *)getMultiForwardViewController:(NSString *)messageAttachmentUrl
                                                     filePath:(NSString *)messageAttachmentFilePath
                                                          md5:(NSString *)messageAttachmentMD5 {
    return [[NormalMultiForwardViewController alloc] initWithAttachmentUrl:messageAttachmentUrl
                                                     attachmentFilePath:messageAttachmentFilePath
                                                          attachmentMD5:messageAttachmentMD5];
}

- (NEBaseSelectUserViewController *)getUserSelectVC:(BOOL)showTeamMembers {
    return [[SelectUserViewController alloc] initWithConversationId:ChatRepo.conversationId showSelf:NO showTeamMembers:showTeamMembers];
}

- (void)getMessageModel:(id<MessageModel>)model {
    MessageContentModel *contentModel = [model isKindOfClass:[MessageContentModel class]] ? (MessageContentModel *)model : nil;
    if (contentModel.isReply) {
        CGFloat normalMoreHeight = chat_reply_height + chat_content_margin;
        contentModel.contentSize = CGSizeMake(contentModel.contentSize.width, contentModel.contentSize.height + normalMoreHeight);
        contentModel.height += normalMoreHeight;
    }
}

- (NSArray<NEMoreItemModel *> *)expandMoreAction {
    NSMutableArray<NEMoreItemModel *> *items = [[super expandMoreAction] mutableCopy];
    [items filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NEMoreItemModel *item, NSDictionary *bindings) {
        return item.type != NEMoreActionTypePhoto && item.type != NEMoreActionTypeAiChat;
    }]];
    [self.chatInputView.chatAddMoreView configData:items];
    return items;
}

- (void)expandButtonDidClick {
    NSLog(@"expandButtonDidClick");
    [super expandButtonDidClick];
    [(ChatInputView *)self.chatInputView changeToMultipleLineStyle];
    self.normalInputHeight = 296;
    self.bottomViewTopAnchor.constant = -self.normalInputHeight;
    [self.chatInputView.textView resignFirstResponder];
    [self.chatInputView.titleField resignFirstResponder];
    [self checkAndRemoveReplyView];
}

- (void)didHideMultipleButtonClick {
    [super didHideMultipleButtonClick];
    if (self.chatInputView.chatInpuMode == ChatInputModeNormal) {
        self.normalInputHeight = 100;
    } else {
        self.normalInputHeight = 150;
    }
    [self layoutInputViewWithAnimation:0 animation:0 scrollToBottom:NO];
    [self checkAndRestoreReplyView];
}

- (void)checkAndRemoveReplyView {
    if (self.chatInputView.chatInpuMode == ChatInputModeMultipleReturn) {
        if (self.replyView.superview != nil) {
            [self.replyView removeFromSuperview];
        }
    }
}

- (void)checkAndRestoreReplyView {
    if (self.viewModel.isReplying && self.replyView.superview == nil) {
        [self.view addSubview:self.replyView];
        if ([IMKitConfigCenter shared].enableAIUser) {
            [NSLayoutConstraint activateConstraints:@[
                [self.replyView.leadingAnchor constraintEqualToAnchor:self.translateLanguageView.leadingAnchor],
                [self.replyView.trailingAnchor constraintEqualToAnchor:self.translateLanguageView.trailingAnchor],
                [self.replyView.bottomAnchor constraintEqualToAnchor:self.translateLanguageView.topAnchor],
                [self.replyView.heightAnchor constraintEqualToConstant:36],
            ]];
        } else {
            [NSLayoutConstraint activateConstraints:@[
                [self.replyView.leadingAnchor constraintEqualToAnchor:self.chatInputView.leadingAnchor],
                [self.replyView.trailingAnchor constraintEqualToAnchor:self.chatInputView.trailingAnchor],
                [self.replyView.bottomAnchor constraintEqualToAnchor:self.chatInputView.topAnchor],
                [self.replyView.heightAnchor constraintEqualToConstant:36],
            ]];
        }
    }
}

- (void)titleTextDidClearEmpty {
    if (self.chatInputView.chatInpuMode == ChatInputModeMultipleSend) {
        self.chatInputView.chatInpuMode = ChatInputModeNormal;
        if (self.chatInputView.chatInpuMode == ChatInputModeNormal) {
            self.normalInputHeight = 100;
        } else {
            self.normalInputHeight = 150;
        }
        [self.chatInputView restoreNormalInputStyle];
        [self layoutInputViewWithAnimation:self.currentKeyboardHeight animation:0 scrollToBottom:NO];
        [self.chatInputView.textView becomeFirstResponder];
    }
}

- (void)keyBoardWillShow:(NSNotification *)notification {
    NSValue *keyboardRectValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [keyboardRectValue CGRectValue];
    self.currentKeyboardHeight = keyboardRect.size.height;
    [super keyBoardWillShow:notification];
}

- (void)keyBoardWillHide:(NSNotification *)notification {
    self.currentKeyboardHeight = 0;
    [super keyBoardWillHide:notification];
}

- (void)didHideMultiple {
    if (self.chatInputView.chatInpuMode == ChatInputModeNormal) {
        self.normalInputHeight = 100;
    } else {
        self.normalInputHeight = 150;
    }
    self.bottomViewTopAnchor.constant = -(self.normalInputHeight + self.currentKeyboardHeight);
}

- (void)didSwitchLanguageClick:(NSString *)currentLanguage {
    SelectLanguageViewController *languageSelectController = [[SelectLanguageViewController alloc] init];
    if (currentLanguage) {
        languageSelectController.currentContent = currentLanguage;
    }
    [self showLanguageContentController:languageSelectController];
}

@end
