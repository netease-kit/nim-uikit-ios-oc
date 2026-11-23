// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NEP2PSecurityWarningViewDelegate <NSObject>
- (void)didClickRemoveButton;
@end

@interface NEP2PSecurityWarningView : UIView <UITextViewDelegate>
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UITextView *warningTextView;
@property (nonatomic, weak, nullable) id<NEP2PSecurityWarningViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
