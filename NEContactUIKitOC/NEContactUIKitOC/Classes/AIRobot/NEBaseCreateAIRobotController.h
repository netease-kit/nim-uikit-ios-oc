// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactBaseViewController.h"
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class CreateAIRobotViewModel;
@class NEUserHeaderView;

@interface NEBaseCreateAIRobotController
    : NEContactBaseViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>

@property(nonatomic, strong) CreateAIRobotViewModel *viewModel;
@property(nonatomic, strong, nullable) V2NIMUserAIBot *editingBot;
@property(nonatomic, copy, nullable) void (^onEditSavedCallback)(V2NIMUserAIBot *bot);
@property(nonatomic, copy, nullable) NSString *defaultName;
@property(nonatomic, copy, nullable) NSString *autoBindQrCode;
@property(nonatomic, weak, nullable) UIViewController *autoBindSourceVC;

@property(nonatomic, strong) UIView *cardView;
@property(nonatomic, strong) UIView *avatarRowView;
@property(nonatomic, strong) UILabel *avatarTitleLabel;
@property(nonatomic, strong) NEUserHeaderView *avatarImageView;
@property(nonatomic, strong) UIImageView *avatarArrowView;
@property(nonatomic, strong) UIView *sectionDivider;
@property(nonatomic, strong) UIView *nameRowView;
@property(nonatomic, strong) UILabel *nameTitleLabel;
@property(nonatomic, strong) UILabel *nicknameValueLabel;
@property(nonatomic, strong) UIImageView *nicknameArrowView;
@property(nonatomic, strong) UITextField *nameTextField;

- (void)setupCreateRobotUI;
- (void)setupCardBorderRadius;
- (UIColor *)pageBackgroundColor;
- (UIColor *)saveButtonColor;
- (CGFloat)cardHorizontalMargin;

- (void)didTapAvatarRow;
- (void)didTapSave;
- (void)didTapNameRow;
- (void)nameTextFieldChanged;
- (void)updateAvatarPlaceholderIfNeeded:(NSString *)name;
- (void)updateAvatarPlaceholderIfNeededWithName:(NSString *)name;

- (void)openPhotoLibrary;
- (void)openCamera;

@end

NS_ASSUME_NONNULL_END
