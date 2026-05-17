// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEP2PSecurityWarningView.h"
#import "AppKey.h"
#import <NEChatKitOC/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

static NSString *const kReportAddress = @"https://yunxin.163.com/survey/report";

static UIColor *P2PSecurityWarningColor(NSUInteger hex) {
  return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                         green:((hex >> 8) & 0xFF) / 255.0
                          blue:(hex & 0xFF) / 255.0
                         alpha:1.0];
}

@implementation NEP2PSecurityWarningView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  [self addSubview:self.backView];
  [NSLayoutConstraint activateConstraints:@[
    [self.backView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.backView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [self.backView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.backView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
  ]];
}

- (UIView *)backView {
  if (!_backView) {
    _backView = [[UIView alloc] init];
    _backView.translatesAutoresizingMaskIntoConstraints = NO;
    _backView.backgroundColor = P2PSecurityWarningColor(0xFFF5E1);

    UIImageView *errorImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"error"]];
    errorImageView.translatesAutoresizingMaskIntoConstraints = NO;
    errorImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_backView addSubview:errorImageView];
    [NSLayoutConstraint activateConstraints:@[
      [errorImageView.centerYAnchor constraintEqualToAnchor:_backView.centerYAnchor],
      [errorImageView.leftAnchor constraintEqualToAnchor:_backView.leftAnchor constant:16],
      [errorImageView.widthAnchor constraintEqualToConstant:16],
      [errorImageView.heightAnchor constraintEqualToConstant:16],
    ]];

    ExpandButton *removeButton = [[ExpandButton alloc] init];
    [removeButton setImage:[coreLoader() loadImage:@"remove"] forState:UIControlStateNormal];
    removeButton.translatesAutoresizingMaskIntoConstraints = NO;
    removeButton.contentMode = UIViewContentModeScaleToFill;
    [removeButton addTarget:self action:@selector(removeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [_backView addSubview:removeButton];
    [NSLayoutConstraint activateConstraints:@[
      [removeButton.centerYAnchor constraintEqualToAnchor:_backView.centerYAnchor],
      [removeButton.rightAnchor constraintEqualToAnchor:_backView.rightAnchor constant:-16],
      [removeButton.widthAnchor constraintEqualToConstant:16],
      [removeButton.heightAnchor constraintEqualToConstant:16],
    ]];

    [_backView addSubview:self.warningTextView];
    [NSLayoutConstraint activateConstraints:@[
      [self.warningTextView.topAnchor constraintEqualToAnchor:_backView.topAnchor],
      [self.warningTextView.bottomAnchor constraintEqualToAnchor:_backView.bottomAnchor],
      [self.warningTextView.leftAnchor constraintEqualToAnchor:errorImageView.rightAnchor constant:0],
      [self.warningTextView.rightAnchor constraintEqualToAnchor:removeButton.leftAnchor constant:4],
    ]];

    [_backView bringSubviewToFront:removeButton];
  }
  return _backView;
}

- (UITextView *)warningTextView {
  if (!_warningTextView) {
    _warningTextView = [[UITextView alloc] init];
    _warningTextView.translatesAutoresizingMaskIntoConstraints = NO;
    _warningTextView.backgroundColor = UIColor.clearColor;
    _warningTextView.textColor = P2PSecurityWarningColor(0xEB9718);
    _warningTextView.font = [UIFont systemFontOfSize:16];
    _warningTextView.textAlignment = NSTextAlignmentJustified;
    _warningTextView.contentMode = UIViewContentModeCenter;
    _warningTextView.editable = NO;
    _warningTextView.scrollEnabled = NO;
    _warningTextView.selectable = YES;
    _warningTextView.delegate = self;
    _warningTextView.accessibilityIdentifier = @"id.securityWarning";

    NSMutableAttributedString *warning =
        [[NSMutableAttributedString alloc] initWithString:NELocalizable(@"security_warning") ?: @""];
    NSAttributedString *report =
        [[NSAttributedString alloc] initWithString:NELocalizable(@"click_to_report") ?: @""
                                        attributes:@{
                                          NSLinkAttributeName : kReportAddress,
                                        }];
    [warning appendAttributedString:report];
    _warningTextView.attributedText = warning;
  }
  return _warningTextView;
}

- (void)removeButtonAction {
  if ([self.delegate respondsToSelector:@selector(didClickRemoveButton)]) {
    [self.delegate didClickRemoveButton];
  }
}

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithURL:(NSURL *)URL
                  inRange:(NSRange)characterRange
              interaction:(UITextItemInteraction)interaction {
  (void)textView;
  (void)characterRange;
  (void)interaction;
  NEWKWebViewController *controller =
      [[NEWKWebViewController alloc] initWithUrl:URL.absoluteString title:URL.absoluteString];
  UIViewController *parent = [self neParentContainerViewController];
  [parent.navigationController pushViewController:controller animated:YES];
  return NO;
}

@end
