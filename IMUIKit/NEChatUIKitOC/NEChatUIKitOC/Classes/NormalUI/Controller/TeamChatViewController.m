// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamChatViewController.h"
#import <NEChatKitOC/ChatRepo.h>
#import "NETeamUserManager.h"
#import <NEChatKitOC/ChatConstant.h>
#import <NEChatKitOC/IMKitClient.h>
#import <NEChatKitOC/IMKitConfigCenter.h>
#import "NormalChatUIColor.h"
#import "NEChatUIConstant.h"
#import "UITextView+NEPlaceholder.h"

@interface TeamChatViewController ()
@property (nonatomic, assign) BOOL isLeaveTeamByOther;
@property (nonatomic, assign) BOOL isLeaveTeamBySelf;
@property (nonatomic, assign) BOOL isdismissTeam;
@property (nonatomic, assign) BOOL isdismissDiscuss;
@property (nonatomic, assign) BOOL onCurrentPage;
@end

@implementation TeamChatViewController

- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(V2NIMMessage *)anchor {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.viewModel = [[TeamChatViewModel alloc] initWithConversationId:conversationId anchor:anchor];
        self.viewModel.delegate = self;
    }
    return self;
}

- (instancetype)initWithSessionId:(NSString *)sessionId {
    NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:sessionId] ?: @"";
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.viewModel = [[TeamChatViewModel alloc] initWithConversationId:conversationId anchor:nil];
        self.viewModel.delegate = self;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.onCurrentPage = YES;
    if (self.isdismissDiscuss || self.isLeaveTeamBySelf) {
        [self popGroupChatVC];
    }
    if (self.isLeaveTeamByOther) {
        [self showLeaveTeamAlert];
    }
    if (self.isdismissTeam) {
        [self showDismissTeamAlert];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.onCurrentPage = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popGroupChatVC) name:NENotificationPopGroupChatVC object:nil];
}

- (void)getSessionInfo:(NSString *)sessionId completion:(void (^)(void))completion {
    self.chatInputView.textView.attributedPlaceholder = [self getPlaceHolder:chatLocalizable(@"send_to")];
    __weak typeof(self) weakSelf = self;
    [super getSessionInfo:sessionId completion:^{
        if ([weakSelf.viewModel isKindOfClass:[TeamChatViewModel class]]) {
            TeamChatViewModel *vm = (TeamChatViewModel *)weakSelf.viewModel;
            [vm getTeamInfoWithTeamId:sessionId completion:^(NSError *error, V2NIMTeam *team) {
                if (team) {
                    if ([IMKitConfigCenter shared].enableDismissTeamDeleteConversation && !team.isValidTeam) {
                        [weakSelf showSingleAlert:nil message:commonLocalizable(@"team_not_exist") handler:^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:NENotificationDeleteConversation object:[V2NIMConversationIdUtil teamConversationId:team.teamId]];
                            [weakSelf popGroupChatVC];
                        }];
                    }
                    [weakSelf updateTeamInfo:team];
                }
            }];
        }
        completion();
    }];
}

- (void)popGroupChatVC {
    UIViewController *beforeChat = nil;
    NSInteger loopCount = 0;
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:[ChatViewController class]]) {
            if (loopCount <= 1) {
                [self.navigationController popToRootViewControllerAnimated:YES];
                return;
            }
            [self.navigationController popToViewController:beforeChat animated:YES];
            return;
        } else {
            beforeChat = vc;
            loopCount++;
        }
    }
}

- (NSMutableAttributedString *)getPlaceHolder:(NSString *)text {
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc] initWithString:text];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = NSLineBreakByTruncatingTail;
    style.alignment = NSTextAlignmentLeft;
    NSRange range = NSMakeRange(0, text.length);
    [attribute addAttribute:NSParagraphStyleAttributeName value:style range:range];
    [attribute addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:range];
    [attribute addAttribute:NSForegroundColorAttributeName value:UIColor.normalChatInputViewPlaceholderTextColor range:range];
    return attribute;
}

- (void)updateTeamInfo:(V2NIMTeam *)team {
    self.titleContent = team.name;
    [self setMuteWithTeam:team];
}

- (void)setMuteWithTeam:(V2NIMTeam *)team {
    if (![self.viewModel isKindOfClass:[TeamChatViewModel class]]) return;
    TeamChatViewModel *vm = (TeamChatViewModel *)self.viewModel;

    BOOL isMuted = (team.chatBannedMode == V2NIM_TEAM_CHAT_BANNED_MODE_BANNED_ALL) ||
                   (team.chatBannedMode == V2NIM_TEAM_CHAT_BANNED_MODE_BANNED_NORMAL &&
                    vm.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_NORMAL);

    if (isMuted) {
        self.isMute = YES;
        self.chatInputView.textView.editable = NO;
        self.chatInputView.textView.attributedPlaceholder = [self getPlaceHolder:chatLocalizable(@"team_mute")];
        [self layoutInputViewWithAnimation:0 animation:0 scrollToBottom:NO];
        self.chatInputView.stackView.userInteractionEnabled = NO;
        [self.chatInputView setMuteInputStyle];
        if (self.chatInputView.chatInpuMode != ChatInputModeNormal) {
            self.chatInputView.titleField.text = nil;
            [self didHideMultipleButtonClick];
        }
        [self closeReply:nil];
    } else {
        self.isMute = NO;
        self.chatInputView.textView.editable = YES;
        self.chatInputView.textView.attributedPlaceholder = [self getPlaceHolder:[NSString stringWithFormat:@"%@%@", chatLocalizable(@"send_to"), self.titleContent]];
        self.chatInputView.stackView.userInteractionEnabled = YES;
        [self.chatInputView setUnMuteInputStyle];
    }
}

- (void)onRecvMessages:(NSArray<V2NIMMessage *> *)messages indexs:(NSArray<NSIndexPath *> *)indexs {
    [super onRecvMessages:messages indexs:indexs];
    for (V2NIMMessage *message in messages) {
        if ([message.attachment isKindOfClass:[V2NIMMessageNotificationAttachment class]]) {
            V2NIMMessageNotificationAttachment *content = (V2NIMMessageNotificationAttachment *)message.attachment;
            if (content.type == V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_UPDATE_TINFO) {
                if (content.updatedTeamInfo.name) {
                    self.titleContent = content.updatedTeamInfo.name;
                    [self onTeamMemberUpdate:@[]];
                }
            } else if (content.type == V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_INVITE) {
                if ([content.targetIds containsObject:[[IMKitClient instance] account]]) {
                    self.isLeaveTeamByOther = NO;
                    if (self.onCurrentPage) {
                        [self dismissAlert];
                    }
                }
            } else if (content.type == V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_LEAVE &&
                       [message.senderId isEqualToString:[[IMKitClient instance] account]]) {
                self.isLeaveTeamBySelf = YES;
                if (self.onCurrentPage) {
                    [self popGroupChatVC];
                }
            } else if (content.type == V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_KICK &&
                       [content.targetIds containsObject:[[IMKitClient instance] account]]) {
                self.isLeaveTeamByOther = YES;
                if (self.onCurrentPage) {
                    [self showLeaveTeamAlert];
                }
            } else if (content.type == V2NIM_MESSAGE_NOTIFICATION_TYPE_TEAM_DISMISS) {
                if (self.isdismissDiscuss) return;
                self.isdismissTeam = YES;
                if (self.onCurrentPage) {
                    [self showDismissTeamAlert];
                }
            }
        }
    }
}

#pragma mark - TeamChatViewModelDelegate

- (void)onTeamUpdate:(V2NIMTeam *)team {
    [self updateTeamInfo:team];
}

- (void)onTeamMemberUpdate:(NSArray<V2NIMTeamMember *> *)teamMembers {
    V2NIMTeam *team = [[NETeamUserManager shared] getTeamInfo];
    if (team) {
        [self setMuteWithTeam:team];
    }
}

- (void)updateTeamTitle:(NSNotification *)noti {
    NSString *tid = noti.userInfo[@"teamId"];
    if (tid && [tid isEqualToString:[ChatRepo sessionId]]) {
        V2NIMTeam *team = [[NETeamUserManager shared] getTeamInfo];
        if (team) {
            [self updateTeamInfo:team];
        }
    }
}

@end
