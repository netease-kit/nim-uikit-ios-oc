// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "P2PChatViewController.h"
#import <NEChatKitOC/ContactRepo.h>
#import "NEP2PChatUserCache.h"
#import <NEChatKitOC/ChatRepo.h>
#import "NormalChatUIColor.h"
#import "UITextView+NEPlaceholder.h"

@implementation P2PChatViewController

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.viewModel = [[P2PChatViewModel alloc] initWithConversationId:conversationId anchor:nil];
    }
    return self;
}

- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(V2NIMMessage *)anchor {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.viewModel = [[P2PChatViewModel alloc] initWithConversationId:conversationId anchor:anchor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
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
    NSString *text = [NSString stringWithFormat:@"%@%@", chatLocalizable(@"send_to"), titleContent];
    NSMutableAttributedString *attribute = [self getPlaceHolder:text];
    self.chatInputView.textView.attributedPlaceholder = attribute;
    [self.chatInputView setUnMuteInputStyle];
    [self.chatInputView.textView setNeedsLayout];
}

- (NSMutableAttributedString *)getPlaceHolder:(NSString *)text {
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    style.alignment = NSTextAlignmentLeft;
    NSRange range = NSMakeRange(0, text.length);
    [attribute addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:range];
    [attribute addAttribute:NSForegroundColorAttributeName value:UIColor.normalChatInputViewPlaceholderTextColor range:range];
    [attribute addAttribute:NSParagraphStyleAttributeName value:style range:range];
    return attribute;
}

- (void)getSessionInfo:(NSString *)sessionId completion:(void (^)(void))completion {
    self.chatInputView.textView.attributedPlaceholder = [self getPlaceHolder:chatLocalizable(@"send_to")];
    __weak typeof(self) weakSelf = self;
    [super getSessionInfo:sessionId completion:^{
        [weakSelf.viewModel loadShowName:@[sessionId] teamId:nil completion:^{
            NSString *name = [weakSelf.viewModel getShowName:sessionId showAlias:YES] ?: sessionId;
            weakSelf.titleContent = name;
        }];
        completion();
    }];
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
