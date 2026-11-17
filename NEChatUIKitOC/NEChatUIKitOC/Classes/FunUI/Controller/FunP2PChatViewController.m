// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunP2PChatViewController.h"
#import "UIImage+Chat.h"
#import "P2PChatViewModel.h"
#import <NEChatKit/ContactRepo.h>
#import "NEP2PChatUserCache.h"
#import <NEChatKit/ChatRepo.h>
#import "FunChatUIColor.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import "NEChatUIConstant.h"
#import <NEBaseUIKitOC/NELottieAnimationView.h>
#import "AIChatViewController.h"
#import "UITextView+NEPlaceholder.h"

@implementation FunP2PChatViewController

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.viewModel = [[P2PChatViewModel alloc] initWithConversationId:conversationId anchor:nil];
    }
    return self;
}

- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(nullable V2NIMMessage *)anchor {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.viewModel = [[P2PChatViewModel alloc] initWithConversationId:conversationId anchor:anchor];
    }
    return self;
}

- (void)addListener {
    [super addListener];
    [[ContactRepo shared] addContactListener:self];
    [[NEP2PChatUserCache shared] addListener:self];
}

- (void)removeListener {
    [super removeListener];
    [[ContactRepo shared] removeContactListener:self];
    [[NEP2PChatUserCache shared] removeListener:self];
}

- (void)setTitleContent:(NSString *)titleContent {
    [super setTitleContent:titleContent];
    NSString *text = chatLocalizable(@"chat_input_placeholder_prompt");
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    style.alignment = NSTextAlignmentLeft;
    NSRange range = NSMakeRange(0, text.length);
    [attribute addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:range];
    [attribute addAttribute:NSForegroundColorAttributeName value:[UIColor funChatInputViewPlaceholderTextColor] range:range];
    [attribute addAttribute:NSParagraphStyleAttributeName value:style range:range];
    self.chatInputView.textView.attributedPlaceholder = attribute;
    [self.chatInputView setUnMuteInputStyle];
    [self.chatInputView.textView setNeedsLayout];
}

- (void)getSessionInfo:(NSString *)sessionId completion:(void (^)(void))completion {
    __weak typeof(self) weakSelf = self;
    [super getSessionInfo:sessionId completion:^{
        [weakSelf.viewModel loadShowName:@[sessionId] teamId:nil completion:^{
            NSString *name = [weakSelf.viewModel getShowName:sessionId showAlias:YES] ?: sessionId;
            weakSelf.titleContent = name;
        }];
        if (completion) completion();
    }];
}

- (void)commonUI {
    [super commonUI];
    if ([IMKitConfigCenter shared].enableAIChatHelper) {
        NELottieAnimationView *loadingView = [[NELottieAnimationView alloc] initWithName:@"fun_ai_chat_loading" bundle:chatBundle()];
        loadingView.translatesAutoresizingMaskIntoConstraints = NO;
        loadingView.loopMode = LottieLoopModeLoop;
        loadingView.contentMode = UIViewContentModeCenter;
        self.chatInputView.aiChatViewController.loadDataView = loadingView;
        self.chatInputView.aiChatViewController.titleIcon.image = [UIImage ne_imageNamed:@"fun_ai_icon_highlight"];
    }
}

- (void)checkAndSendTypingState:(BOOL)endEdit {
    if (![self.viewModel isKindOfClass:[P2PChatViewModel class]]) return;
    P2PChatViewModel *vm = (P2PChatViewModel *)self.viewModel;
    if (endEdit) {
        [vm sendInputTypingEndState];
        return;
    }
    if (self.chatInputView.chatInpuMode == ChatInputModeNormal) {
        if (self.chatInputView.textView.text.length > 0) {
            [vm sendInputTypingState];
        } else {
            [vm sendInputTypingEndState];
        }
    } else {
        NSString *title = self.chatInputView.titleField.text ?: @"";
        NSString *content = self.chatInputView.textView.text ?: @"";
        if (title.length == 0 && content.length == 0) {
            [vm sendInputTypingEndState];
        } else {
            [vm sendInputTypingState];
        }
    }
}

#pragma mark - NEContactListener

- (void)onContactChange:(NEContactChangeType)changeType contacts:(NSArray<NEUserWithFriend *> *)contacts {
    for (NEUserWithFriend *contact in contacts) {
        NSString *accid = contact.user.accountId;
        if ([accid isEqualToString:ChatRepo.sessionId]) {
            if (changeType == NEContactChangeTypeAddFriend) {
                [[NEP2PChatUserCache shared] removeUserInfo:ChatRepo.sessionId];
            }
            if (changeType == NEContactChangeTypeDeleteFriend) {
                contact.friend = nil;
                [[NEP2PChatUserCache shared] updateUserInfoWithFriend:contact];
            }
            [self onUserOrFriendInfoChanged:accid];
        }
    }
}

#pragma mark - NEP2PChatUserCacheListener

- (void)onUserInfoUpdate:(NSString *)accountId {
    [self onUserOrFriendInfoChanged:accountId];
}

@end
