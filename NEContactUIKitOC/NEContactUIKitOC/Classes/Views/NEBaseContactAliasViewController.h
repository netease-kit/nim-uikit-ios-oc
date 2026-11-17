// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEContactBaseViewController.h"
#import "ContactUserViewModel.h"

@class NEUserWithFriend;

NS_ASSUME_NONNULL_BEGIN

typedef void (^ContactAliasModifyBlock)(NEUserWithFriend *user);

@interface NEBaseContactAliasViewController : NEContactBaseViewController <UITextFieldDelegate>

@property (nonatomic, copy, nullable) ContactAliasModifyBlock completion;
@property (nonatomic, strong, nullable) NEUserWithFriend *user;
@property (nonatomic, strong, nullable) NSLayoutConstraint *aliasInputTopAnchor;
@property (nonatomic, strong) UITextField *aliasInput;

- (void)setupUI;
- (void)saveAlias;
- (void)textFieldChange;

@end

NS_ASSUME_NONNULL_END
