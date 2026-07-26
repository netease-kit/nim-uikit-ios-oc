// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamIntroduceViewController.h"
#import "TeamConstant.h"
#import "TeamIntroduceViewModel.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/NECoreIM2Constant.h>

@interface NEBaseTeamIntroduceViewController ()
@property (nonatomic, assign, readwrite) NSInteger textLimit;
@property (nonatomic, strong, readwrite) UIView *backView;
@property (nonatomic, strong, readwrite) TeamIntroduceViewModel *viewModel;
@property (nonatomic, strong, readwrite) UITextView *textView;
@property (nonatomic, strong, readwrite) UIButton *clearButton;
@property (nonatomic, strong, readwrite) UILabel *countLabel;
@end

@implementation NEBaseTeamIntroduceViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _textLimit = 100;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  __weak typeof(self) weakSelf = self;
  [self.viewModel getCurrentUserTeamMember:self.team.teamId completion:^(NSError * _Nullable error) {
    if (error) {
      [weakSelf.view ne_makeToast:NETeamUIKitErrorToast(error)];
    }
    [weakSelf setupUI];
  }];
}

- (void)setupUI {
  [self.navigationView setMoreButtonTitle:NETeamUIKitLocalizable(@"save")];
  [self.navigationView addMoreButtonTarget:self selector:@selector(saveIntr)];
  if ([self.team.serverExtension containsString:discussTeamKey]) {
    self.title = NETeamUIKitLocalizable(@"discuss_introduce");
  } else {
    self.title = NETeamUIKitLocalizable(@"team_intr");
  }

  self.backView.backgroundColor = UIColor.whiteColor;
  self.backView.translatesAutoresizingMaskIntoConstraints = NO;
  self.backView.clipsToBounds = NO;

  [self.view addSubview:self.backView];
  [self.backView addSubview:self.textView];
  [self.backView addSubview:self.clearButton];
  [self.backView addSubview:self.countLabel];

  [NSLayoutConstraint activateConstraints:@[
    [self.countLabel.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-16.0],
    [self.countLabel.bottomAnchor constraintEqualToAnchor:self.backView.bottomAnchor constant:-8.0],
  ]];

  [self figureTextCount:self.team.intro ?: @""];

  if (![self getPermission]) {
    self.textView.editable = NO;
    self.rightNavButton.hidden = YES;
    self.navigationView.moreButton.hidden = YES;
  }
}

- (BOOL)getPermission {
  if ([IMKitClient.instance isMe:self.team.ownerAccountId]) {
    return YES;
  }
  if (self.team.updateInfoMode == V2NIM_TEAM_UPDATE_INFO_MODE_ALL) {
    return YES;
  }
  if (self.viewModel.currentTeamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
    return YES;
  }
  return NO;
}

- (void)saveIntr {
  [self.textView resignFirstResponder];
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  NSString *teamId = self.team.teamId ?: @"";
  if (teamId.length == 0) {
    return;
  }

  NSString *text = self.textView.text ?: @"";
  [self.view makeToastActivity:NEToastPositionCenter];

  __weak typeof(self) weakSelf = self;
  [self.viewModel updateTeamIntroduce:teamId introduce:text completion:^(NSError * _Nullable error) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [[self class] className]]
               desc:[NSString stringWithFormat:@"CALLBACK updateTeamIntroduce %@", error.localizedDescription ?: @"no error"]];
    [weakSelf.view ne_hideToastActivity];
    if (error) {
      if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else if (error.code == noPermissionOperationCode) {
        [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      } else {
        [weakSelf showToast:commonLocalizable(@"failed_operation")];
      }
    } else {
      [weakSelf.navigationController popViewControllerAnimated:YES];
    }
  }];
}

- (void)figureTextCount:(NSString *)text {
  self.textView.text = text;
  self.countLabel.text = [NSString stringWithFormat:@"%lu/%ld", (unsigned long)text.length, (long)self.textLimit];
  self.clearButton.hidden = ![self getPermission] || text.length <= 0;
}

- (void)clearText {
  [self figureTextCount:@""];
}

- (void)textViewDidChange:(UITextView *)textView {
  if (textView.markedTextRange) {
    return;
  }
  [self figureTextCount:textView.text ?: @""];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  if (text.length > 0) {
    NSString *finalStr = [textView.text ?: @"" stringByReplacingCharactersInRange:range withString:text];
    if (finalStr.length > self.textLimit) {
      return NO;
    }
  }
  return YES;
}

- (TeamIntroduceViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[TeamIntroduceViewModel alloc] init];
  }
  return _viewModel;
}

- (UIView *)backView {
  if (!_backView) {
    _backView = [[UIView alloc] init];
  }
  return _backView;
}

- (UITextView *)textView {
  if (!_textView) {
    _textView = [[UITextView alloc] init];
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    _textView.textColor = [NEConstant hexRGB:0x333333];
    _textView.font = [NEConstant defaultTextFont:14.0];
    _textView.delegate = self;
    _textView.textContainerInset = UIEdgeInsetsZero;
    _textView.layoutManager.allowsNonContiguousLayout = NO;
    _textView.accessibilityIdentifier = @"id.introduce";
  }
  return _textView;
}

- (UIButton *)clearButton {
  if (!_clearButton) {
    _clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_clearButton setImage:[NETeamUIKitLoader() loadImage:@"clear_btn"] forState:UIControlStateNormal];
    [_clearButton addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
    _clearButton.accessibilityIdentifier = @"id.clear";
  }
  return _clearButton;
}

- (UILabel *)countLabel {
  if (!_countLabel) {
    _countLabel = [[UILabel alloc] init];
    _countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _countLabel.textColor = UIColor.ne_emptyTitleColor;
    _countLabel.font = [NEConstant defaultTextFont:12.0];
    _countLabel.accessibilityIdentifier = @"id.flag";
  }
  return _countLabel;
}

@end
