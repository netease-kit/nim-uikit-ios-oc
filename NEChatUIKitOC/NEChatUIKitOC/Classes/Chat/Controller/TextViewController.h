// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEChatBaseViewController.h"
#import <NEBaseUIKitOC/CopyableLabel.h>
#import <NEBaseUIKitOC/LinkableLabelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface TextViewController : NEChatBaseViewController <LinkableLabelProtocol, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *textView;
@property (nonatomic, strong) CopyableLabel *titleLabel;
@property (nonatomic, strong) CopyableLabel *bodyLabel;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentLabelTopAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentLabelLeftAnchor;

- (instancetype)initWithTitle:(nullable NSString *)title body:(nullable NSAttributedString *)body;
- (void)viewTap;
- (void)setupUI;
- (void)updateLinkDetection;
- (void)didTapTel:(NSURL *)url;
- (void)didTapMailto:(NSURL *)url;

- (void)presentAsColumnChildFrom:(UIViewController *)parent;

@end

NS_ASSUME_NONNULL_END
