// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCreateAIRobotController.h"
#import "ContactConst.h"
#import "CreateAIRobotViewModel.h"
#import "FunContactUIColor.h"
#import "NormalContactUIColor.h"
#import <NEChatKitOC/AIRepo.h>
#import <NEChatKitOC/NEAIRobotManager.h>
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@interface NEBaseCreateAIRobotController ()

@property(nonatomic, assign) BOOL hasExistingAvatar;

@end

@implementation NEBaseCreateAIRobotController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupCreateRobotUI];

  if (self.editingBot == nil && self.defaultName.length > 0) {
    self.nameTextField.text = self.defaultName;
    self.viewModel.name = self.defaultName;
    self.nicknameValueLabel.text = self.defaultName;
    [self updateAvatarPlaceholderIfNeeded:self.defaultName];
  }

  if (self.editingBot != nil) {
    self.title = contactLocalizable(@"edit_ai_robot");
    NSString *name = self.editingBot.name ?: @"";
    self.nameTextField.text = name;
    self.viewModel.name = name;
    self.nicknameValueLabel.text = name;
    NSString *shortName = name.length > 2 ? [name substringFromIndex:name.length - 2] : name;
    [self.avatarImageView configHeadData:self.editingBot.icon name:shortName uid:self.editingBot.accid ?: @""];
    if (self.editingBot.icon.length > 0) {
      self.hasExistingAvatar = YES;
    }
  }
}

- (void)setupCreateRobotUI {
  self.title = contactLocalizable(@"create_ai_robot");
  self.view.backgroundColor = [self pageBackgroundColor];

  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  if (useSystemNavValue && [useSystemNavValue boolValue]) {
    UIBarButtonItem *saveItem =
        [[UIBarButtonItem alloc] initWithTitle:contactLocalizable(@"save")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(didTapSave)];
    saveItem.tintColor = [self saveButtonColor];
    self.navigationItem.rightBarButtonItem = saveItem;
  } else {
    [self.navigationView setMoreButtonTitle:contactLocalizable(@"save") color:[self saveButtonColor]];
    [self.navigationView addMoreButtonTarget:self selector:@selector(didTapSave)];
  }

  [self.view addSubview:self.cardView];
  [NSLayoutConstraint activateConstraints:@[
    [self.cardView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant + 12.0],
    [self.cardView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:[self cardHorizontalMargin]],
    [self.cardView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-[self cardHorizontalMargin]],
  ]];

  [self.cardView addSubview:self.avatarRowView];
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarRowView.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
    [self.avatarRowView.leftAnchor constraintEqualToAnchor:self.cardView.leftAnchor],
    [self.avatarRowView.rightAnchor constraintEqualToAnchor:self.cardView.rightAnchor],
    [self.avatarRowView.heightAnchor constraintEqualToConstant:74.0],
  ]];

  [self.avatarRowView addSubview:self.avatarTitleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarTitleLabel.leftAnchor constraintEqualToAnchor:self.avatarRowView.leftAnchor constant:16.0],
    [self.avatarTitleLabel.centerYAnchor constraintEqualToAnchor:self.avatarRowView.centerYAnchor],
  ]];

  [self.avatarRowView addSubview:self.avatarArrowView];
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarArrowView.rightAnchor constraintEqualToAnchor:self.avatarRowView.rightAnchor constant:-16.0],
    [self.avatarArrowView.centerYAnchor constraintEqualToAnchor:self.avatarRowView.centerYAnchor],
    [self.avatarArrowView.widthAnchor constraintEqualToConstant:16.0],
    [self.avatarArrowView.heightAnchor constraintEqualToConstant:16.0],
  ]];

  [self.avatarRowView addSubview:self.avatarImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarImageView.rightAnchor constraintEqualToAnchor:self.avatarArrowView.leftAnchor constant:-8.0],
    [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.avatarRowView.centerYAnchor],
    [self.avatarImageView.widthAnchor constraintEqualToConstant:40.0],
    [self.avatarImageView.heightAnchor constraintEqualToConstant:40.0],
  ]];
  [self.avatarImageView configHeadData:nil name:@"" uid:@""];

  [self.cardView addSubview:self.sectionDivider];
  [NSLayoutConstraint activateConstraints:@[
    [self.sectionDivider.topAnchor constraintEqualToAnchor:self.avatarRowView.bottomAnchor],
    [self.sectionDivider.leftAnchor constraintEqualToAnchor:self.cardView.leftAnchor constant:16.0],
    [self.sectionDivider.rightAnchor constraintEqualToAnchor:self.cardView.rightAnchor],
    [self.sectionDivider.heightAnchor constraintEqualToConstant:0.5],
  ]];

  [self.cardView addSubview:self.nameRowView];
  [NSLayoutConstraint activateConstraints:@[
    [self.nameRowView.topAnchor constraintEqualToAnchor:self.sectionDivider.bottomAnchor],
    [self.nameRowView.leftAnchor constraintEqualToAnchor:self.cardView.leftAnchor],
    [self.nameRowView.rightAnchor constraintEqualToAnchor:self.cardView.rightAnchor],
    [self.nameRowView.heightAnchor constraintEqualToConstant:56.0],
    [self.nameRowView.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor],
  ]];

  [self.nameRowView addSubview:self.nameTitleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.nameTitleLabel.leftAnchor constraintEqualToAnchor:self.nameRowView.leftAnchor constant:16.0],
    [self.nameTitleLabel.centerYAnchor constraintEqualToAnchor:self.nameRowView.centerYAnchor],
  ]];

  [self.nameRowView addSubview:self.nicknameArrowView];
  [NSLayoutConstraint activateConstraints:@[
    [self.nicknameArrowView.rightAnchor constraintEqualToAnchor:self.nameRowView.rightAnchor constant:-16.0],
    [self.nicknameArrowView.centerYAnchor constraintEqualToAnchor:self.nameRowView.centerYAnchor],
    [self.nicknameArrowView.widthAnchor constraintEqualToConstant:16.0],
    [self.nicknameArrowView.heightAnchor constraintEqualToConstant:16.0],
  ]];

  [self.nameRowView addSubview:self.nicknameValueLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.nicknameValueLabel.rightAnchor constraintEqualToAnchor:self.nicknameArrowView.leftAnchor constant:-8.0],
    [self.nicknameValueLabel.centerYAnchor constraintEqualToAnchor:self.nameRowView.centerYAnchor],
    [self.nicknameValueLabel.leftAnchor constraintGreaterThanOrEqualToAnchor:self.nameTitleLabel.rightAnchor constant:12.0],
  ]];

  [self setupCardBorderRadius];
}

- (void)setupCardBorderRadius {
  self.cardView.layer.cornerRadius = 8.0;
  self.cardView.clipsToBounds = YES;
}

- (UIColor *)pageBackgroundColor {
  return [UIColor funContactNavigationBackgroundColor];
}

- (UIColor *)saveButtonColor {
  return [UIColor normalContactThemeColor];
}

- (CGFloat)cardHorizontalMargin {
  return 0.0;
}

- (void)didTapAvatarRow {
  UIAlertController *sheet =
      [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
  __weak typeof(self) weakSelf = self;
  [sheet addAction:[UIAlertAction actionWithTitle:commonLocalizable(@"take_picture")
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * _Nonnull action) {
                                            [weakSelf openCamera];
                                          }]];
  [sheet addAction:[UIAlertAction actionWithTitle:commonLocalizable(@"select_from_album")
                                            style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * _Nonnull action) {
                                            [weakSelf openPhotoLibrary];
                                          }]];
  [sheet addAction:[UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                            style:UIAlertActionStyleCancel
                                          handler:nil]];
  UIPopoverPresentationController *popover = sheet.popoverPresentationController;
  if (popover) {
    popover.sourceView = self.avatarRowView;
    popover.sourceRect = self.avatarRowView.bounds;
  }
  [self presentViewController:sheet animated:YES completion:nil];
}

- (void)didTapSave {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }

  [self.view endEditing:YES];
  self.viewModel.name = self.nameTextField.text ?: @"";
  self.view.userInteractionEnabled = NO;

  __weak typeof(self) weakSelf = self;
  if (self.editingBot != nil) {
    NSString *accid = self.editingBot.accid ?: @"";
    [self.viewModel updateRobot:accid completion:^(NSError * _Nullable error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        strongSelf.view.userInteractionEnabled = YES;
        if (error != nil) {
          [strongSelf.view ne_makeToast:robotErrorMessage(error)];
          return;
        }

        [strongSelf.viewModel fetchUpdatedBot:accid completion:^(V2NIMUserAIBot * _Nullable bot) {
          if (bot != nil) {
            [[NEAIRobotManager shared] updateBot:bot];
            if (strongSelf.onEditSavedCallback) {
              strongSelf.onEditSavedCallback(bot);
            }
          }
          [strongSelf.navigationController popViewControllerAnimated:YES];
        }];
      });
    }];
    return;
  }

  [self.viewModel createRobot:^(NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      strongSelf.view.userInteractionEnabled = YES;
      if (error != nil) {
        [strongSelf.view ne_makeToast:contactLocalizable(@"ai_robot_create_failed")];
        return;
      }

      V2NIMUserAIBot *bot = strongSelf.viewModel.createdBot;
      UINavigationController *nav = strongSelf.navigationController;
      if (bot == nil || nav == nil) {
        [strongSelf.navigationController popViewControllerAnimated:YES];
        return;
      }

      [[NEAIRobotManager shared] addBot:bot];
      if (strongSelf.autoBindQrCode.length > 0) {
        strongSelf.view.userInteractionEnabled = NO;
        [[AIRepo shared] bindUserAIBotWithAccid:bot.accid ?: @""
                                          token:bot.token ?: @""
                                         qrCode:strongSelf.autoBindQrCode
                                     completion:^(NSError * _Nullable bindError) {
          dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) bindSelf = weakSelf;
            if (!bindSelf) {
              return;
            }
            bindSelf.view.userInteractionEnabled = YES;
            if (bindError != nil) {
              [bindSelf.view ne_makeToast:robotErrorMessage(bindError)];
              return;
            }

            NSMutableArray<UIViewController *> *controllers = [nav.viewControllers mutableCopy];
            NSIndexSet *indexes = [controllers indexesOfObjectsPassingTest:^BOOL(UIViewController * _Nonnull obj,
                                                                                 NSUInteger idx,
                                                                                 BOOL * _Nonnull stop) {
              return obj == bindSelf || obj == bindSelf.autoBindSourceVC;
            }];
            if (indexes.count > 0) {
              [controllers removeObjectsAtIndexes:indexes];
            }
            [nav setViewControllers:controllers animated:NO];
            [[Router shared] use:ContactAIRobotDetailRouter
                      parameters:@{
                        @"nav": nav,
                        @"bot": bot,
                        @"animated": @YES,
                      }
                         closure:nil];
          });
        }];
      } else {
        [nav popViewControllerAnimated:NO];
        [[Router shared] use:ContactAIRobotDetailRouter
                  parameters:@{
                    @"nav": nav,
                    @"bot": bot,
                    @"animated": @YES,
                  }
                     closure:nil];
      }
    });
  }];
}

- (void)didTapNameRow {
  if (self.navigationController == nil) {
    return;
  }
  __weak typeof(self) weakSelf = self;
  [[Router shared] use:ContactRobotNicknameEditRouter
            parameters:@{
              @"nav": self.navigationController,
              @"currentName": self.nameTextField.text ?: @"",
              @"animated": @YES,
              @"onSaved": ^(NSString *name) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                  return;
                }
                strongSelf.nameTextField.text = name;
                strongSelf.viewModel.name = name;
                strongSelf.nicknameValueLabel.text = name;
                [strongSelf updateAvatarPlaceholderIfNeeded:name];
              },
            }
               closure:nil];
}

- (void)nameTextFieldChanged {
  NSString *name = self.nameTextField.text ?: @"";
  self.viewModel.name = name;
  [self updateAvatarPlaceholderIfNeeded:name];
}

- (void)updateAvatarPlaceholderIfNeeded:(NSString *)name {
  if (self.hasExistingAvatar) {
    return;
  }
  NSString *shortName = name.length > 2 ? [name substringFromIndex:name.length - 2] : name;
  [self.avatarImageView configHeadData:nil name:shortName uid:@""];
}

- (void)openPhotoLibrary {
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  picker.allowsEditing = YES;
  picker.delegate = self;
  [self presentViewController:picker animated:YES completion:nil];
}

- (void)openCamera {
  if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    return;
  }
  UIImagePickerController *picker = [[UIImagePickerController alloc] init];
  picker.sourceType = UIImagePickerControllerSourceTypeCamera;
  picker.allowsEditing = YES;
  picker.delegate = self;
  [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
  [picker dismissViewControllerAnimated:YES completion:nil];

  UIImage *image = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
  if (image == nil) {
    return;
  }
  NSData *data = UIImageJPEGRepresentation(image, 0.8);
  if (data == nil) {
    return;
  }

  NSString *fileName = [NSString stringWithFormat:@"robot_avatar_%lld.jpg",
                                                  (long long)([[NSDate date] timeIntervalSince1970] * 1000)];
  NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
  if (![data writeToFile:path atomically:YES]) {
    return;
  }

  self.viewModel.avatarLocalPath = path;
  self.hasExistingAvatar = YES;
  self.avatarImageView.image = image;
  [self.avatarImageView setTitle:@""];
  self.avatarImageView.backgroundColor = [UIColor clearColor];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [picker dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - Lazy Init

- (CreateAIRobotViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[CreateAIRobotViewModel alloc] init];
  }
  return _viewModel;
}

- (UIView *)cardView {
  if (!_cardView) {
    _cardView = [[UIView alloc] init];
    _cardView.translatesAutoresizingMaskIntoConstraints = NO;
    _cardView.backgroundColor = [UIColor whiteColor];
  }
  return _cardView;
}

- (UIView *)avatarRowView {
  if (!_avatarRowView) {
    _avatarRowView = [[UIView alloc] init];
    _avatarRowView.translatesAutoresizingMaskIntoConstraints = NO;
    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAvatarRow)];
    [_avatarRowView addGestureRecognizer:tap];
  }
  return _avatarRowView;
}

- (UILabel *)avatarTitleLabel {
  if (!_avatarTitleLabel) {
    _avatarTitleLabel = [[UILabel alloc] init];
    _avatarTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _avatarTitleLabel.text = contactLocalizable(@"ai_robot_avatar");
    _avatarTitleLabel.font = [UIFont systemFontOfSize:16.0];
    _avatarTitleLabel.textColor = [UIColor ne_darkText];
  }
  return _avatarTitleLabel;
}

- (NEUserHeaderView *)avatarImageView {
  if (!_avatarImageView) {
    _avatarImageView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _avatarImageView.layer.cornerRadius = 20.0;
    _avatarImageView.clipsToBounds = YES;
    _avatarImageView.titleLabel.font = [UIFont systemFontOfSize:14.0];
    _avatarImageView.titleLabel.textColor = [UIColor whiteColor];
  }
  return _avatarImageView;
}

- (UIImageView *)avatarArrowView {
  if (!_avatarArrowView) {
    _avatarArrowView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
    _avatarArrowView.translatesAutoresizingMaskIntoConstraints = NO;
    _avatarArrowView.contentMode = UIViewContentModeScaleAspectFit;
  }
  return _avatarArrowView;
}

- (UIView *)sectionDivider {
  if (!_sectionDivider) {
    _sectionDivider = [[UIView alloc] init];
    _sectionDivider.translatesAutoresizingMaskIntoConstraints = NO;
    _sectionDivider.backgroundColor = [UIColor funContactLineBorderColor];
  }
  return _sectionDivider;
}

- (UIView *)nameRowView {
  if (!_nameRowView) {
    _nameRowView = [[UIView alloc] init];
    _nameRowView.translatesAutoresizingMaskIntoConstraints = NO;
    UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapNameRow)];
    [_nameRowView addGestureRecognizer:tap];
  }
  return _nameRowView;
}

- (UILabel *)nameTitleLabel {
  if (!_nameTitleLabel) {
    _nameTitleLabel = [[UILabel alloc] init];
    _nameTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameTitleLabel.text = contactLocalizable(@"ai_robot_name");
    _nameTitleLabel.font = [UIFont systemFontOfSize:16.0];
    _nameTitleLabel.textColor = [UIColor ne_darkText];
  }
  return _nameTitleLabel;
}

- (UILabel *)nicknameValueLabel {
  if (!_nicknameValueLabel) {
    _nicknameValueLabel = [[UILabel alloc] init];
    _nicknameValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nicknameValueLabel.font = [UIFont systemFontOfSize:16.0];
    _nicknameValueLabel.textColor = [UIColor ne_colorWithHexString:@"999999"];
    _nicknameValueLabel.textAlignment = NSTextAlignmentRight;
  }
  return _nicknameValueLabel;
}

- (UIImageView *)nicknameArrowView {
  if (!_nicknameArrowView) {
    _nicknameArrowView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
    _nicknameArrowView.translatesAutoresizingMaskIntoConstraints = NO;
    _nicknameArrowView.contentMode = UIViewContentModeScaleAspectFit;
  }
  return _nicknameArrowView;
}

- (UITextField *)nameTextField {
  if (!_nameTextField) {
    _nameTextField = [[UITextField alloc] init];
    _nameTextField.font = [UIFont systemFontOfSize:16.0];
    _nameTextField.textColor = [UIColor ne_darkText];
    _nameTextField.textAlignment = NSTextAlignmentRight;
    _nameTextField.placeholder = contactLocalizable(@"ai_robot_name_placeholder");
    _nameTextField.returnKeyType = UIReturnKeyDone;
    _nameTextField.delegate = self;
    [_nameTextField addTarget:self action:@selector(nameTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
  }
  return _nameTextField;
}

@end
