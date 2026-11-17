// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamNameViewController.h"
#import "TeamConstant.h"
#import "TeamNameViewModel.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/UIView+YXToast.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/TeamRepo.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>

@interface NEBaseTeamNameViewController ()
@property (nonatomic, strong, readwrite) UIView *backView;
@property (nonatomic, strong, readwrite) TeamNameViewModel *viewModel;
@end

@implementation NEBaseTeamNameViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _type = ChangeTypeTeamName;
    _repo = [TeamRepo shared];
    _textLimit = 30;
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
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf configData];
    });
  }];
  [self setupUI];
}

- (void)setupUI {
  [self.navigationView setMoreButtonTitle:NETeamUIKitLocalizable(@"save")];
  [self.navigationView addMoreButtonTarget:self selector:@selector(saveName)];

  [self.view addSubview:self.backView];
  [self.backView addSubview:self.textInputView];
  [self.backView addSubview:self.clearButton];
  [self.backView addSubview:self.countLabel];

  self.backView.backgroundColor = UIColor.whiteColor;
  self.backView.clipsToBounds = YES;
  self.backView.translatesAutoresizingMaskIntoConstraints = NO;

  [NSLayoutConstraint activateConstraints:@[
    [self.countLabel.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-16.0],
    [self.countLabel.bottomAnchor constraintEqualToAnchor:self.backView.bottomAnchor constant:-8.0],
  ]];
}

- (void)configData {
  NSString *name = @"";
  if (self.type == ChangeTypeTeamName) {
    name = self.team.name ?: @"";
    if (![self getEditablePermission]) {
      self.rightNavButton.hidden = YES;
      self.navigationView.moreButton.hidden = YES;
      self.textInputView.editable = NO;
    }
  } else if (self.type == ChangeTypeNickName) {
    self.title = NETeamUIKitLocalizable(@"team_nick");
    name = self.teamMember.teamNick ?: @"";
  }
  [self figureTextCount:name];

  if (name.length <= 0 && self.type != ChangeTypeNickName) {
    [self disableSubmit];
  }
}

- (BOOL)getEditablePermission {
  if (self.type == ChangeTypeNickName) {
    return YES;
  }
  if (self.team.updateInfoMode == V2NIM_TEAM_UPDATE_INFO_MODE_ALL) {
    return YES;
  }
  if ([IMKitClient.instance isMe:self.team.ownerAccountId]) {
    return YES;
  }
  if (self.viewModel.currentTeamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
    return YES;
  }
  return NO;
}

- (void)disableSubmit {
  UIColor *disableColor = [NEConstant hexRGBAlpha:0x337EFF alpha:0.5];
  [self.rightNavButton setTitleColor:disableColor forState:UIControlStateNormal];
  self.rightNavButton.enabled = NO;
  [self.navigationView.moreButton setTitleColor:disableColor forState:UIControlStateNormal];
  self.navigationView.moreButton.enabled = NO;
}

- (void)enableSubmit {
  UIColor *enableColor = [NEConstant hexRGB:0x337EFF];
  [self.rightNavButton setTitleColor:enableColor forState:UIControlStateNormal];
  self.rightNavButton.enabled = YES;
  [self.navigationView.moreButton setTitleColor:enableColor forState:UIControlStateNormal];
  self.navigationView.moreButton.enabled = YES;
}

- (void)saveName {
  NSString *teamId = self.team.teamId ?: @"";
  if (teamId.length == 0) {
    [self showToast:commonLocalizable(@"failed_operation")];
    return;
  }

  if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  NSString *text = self.textInputView.text ?: @"";
  if ([text rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet].location != NSNotFound) {
    [self showToast:commonLocalizable(@"failed_operation")];
    return;
  }
  if (text.length > 0) {
    NSString *trimText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (trimText.length == 0) {
      [self.view ne_makeToast:NETeamUIKitLocalizable(@"space_not_support") duration:2 position:NEToastPositionCenter];
      [self figureTextCount:trimText];
      return;
    }
  }

  [self.textInputView resignFirstResponder];
  __weak typeof(self) weakSelf = self;

  if (self.type == ChangeTypeTeamName) {
    NSString *name = self.textInputView.text ?: @"";
    [self.view makeToastActivity:NEToastPositionCenter];
    [self.repo updateTeamName:teamId teamType:V2NIM_TEAM_TYPE_NORMAL name:name completion:^(NSError * _Nullable error) {
      [weakSelf.view ne_hideToastActivity];
      if (error) {
        [weakSelf showToast:NETeamUIKitErrorToast(error)];
      } else {
        [weakSelf.navigationController popViewControllerAnimated:YES];
      }
    }];
  } else if (self.type == ChangeTypeNickName) {
    NSString *uid = self.teamMember.accountId ?: @"";
    NSString *name = self.textInputView.text ?: @"";
    [self.view makeToastActivity:NEToastPositionCenter];
    [self.repo updateMemberNick:teamId teamType:V2NIM_TEAM_TYPE_NORMAL accId:uid nickName:name completion:^(NSError * _Nullable error) {
      [weakSelf.view ne_hideToastActivity];
      if (error) {
        [weakSelf showToast:NETeamUIKitErrorToast(error)];
      } else {
        [weakSelf.navigationController popViewControllerAnimated:YES];
      }
    }];
  }
}

- (void)clearText {
  [self figureTextCount:@""];
}

- (void)figureTextCount:(NSString *)text {
  self.textInputView.text = text;
  self.countLabel.text = [NSString stringWithFormat:@"%lu/%ld", (unsigned long)text.length, (long)self.textLimit];
  self.clearButton.hidden = ![self getEditablePermission] || text.length <= 0;
  if (self.type == ChangeTypeNickName) {
    return;
  }
  if (text.length == 0) {
    [self disableSubmit];
  } else {
    [self enableSubmit];
  }
}

- (void)textViewDidChange:(UITextView *)textView {
  if (textView.markedTextRange) {
    return;
  }
  [self figureTextCount:textView.text ?: @""];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  if ([text rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet].location != NSNotFound) return NO;
  if (text.length > 0) {
    NSString *originText = textView.text ?: @"";
    NSString *finalStr = [originText stringByReplacingCharactersInRange:range withString:text];
    if (finalStr.length > self.textLimit) {
      NEHandleInputLimitExceeded(self.view, self.textLimit);
      return NO;
    }
  }
  return YES;
}

- (UIView *)backView {
  if (!_backView) {
    _backView = [[UIView alloc] init];
  }
  return _backView;
}

- (TeamNameViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[TeamNameViewModel alloc] init];
  }
  return _viewModel;
}

- (UILabel *)countLabel {
  if (!_countLabel) {
    _countLabel = [[UILabel alloc] init];
    _countLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _countLabel.textColor = UIColor.ne_emptyTitleColor;
    _countLabel.font = [NEConstant defaultTextFont:12.0];
    _countLabel.userInteractionEnabled = NO;
    _countLabel.accessibilityIdentifier = @"id.flag";
  }
  return _countLabel;
}

- (UITextView *)textInputView {
  if (!_textInputView) {
    _textInputView = [[UITextView alloc] init];
    _textInputView.translatesAutoresizingMaskIntoConstraints = NO;
    _textInputView.backgroundColor = UIColor.clearColor;
    _textInputView.textColor = [NEConstant hexRGB:0x333333];
    _textInputView.font = [NEConstant defaultTextFont:14.0];
    _textInputView.delegate = self;
    _textInputView.accessibilityIdentifier = @"id.nickname";
  }
  return _textInputView;
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

@end
