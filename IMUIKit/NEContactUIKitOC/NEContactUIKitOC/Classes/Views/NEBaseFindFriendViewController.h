// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEContactBaseViewController.h"
#import "FindFriendViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseFindFriendViewController : NEContactBaseViewController <UITextFieldDelegate>

@property (nonatomic, strong) FindFriendViewModel *viewModel;
@property (nonatomic, assign) BOOL hasRequest;
@property (nonatomic, strong) UITextField *searchInput;
@property (nonatomic, assign) BOOL isRequesting;
@property (nonatomic, strong, nullable) NSLayoutConstraint *searchBackViewTopAnchor;
@property (nonatomic, strong) UIView *searchBackView;
@property (nonatomic, strong) UIImageView *searchImageView;

- (void)setupUI;
- (void)textFieldChange;
- (void)startSearch:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
