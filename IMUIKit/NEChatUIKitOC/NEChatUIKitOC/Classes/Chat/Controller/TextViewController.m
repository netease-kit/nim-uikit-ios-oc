// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TextViewController.h"
#import "ChatNavigationView.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/NSString+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "NEChatUIConstant.h"
#import <NECommonUIKitOC/NEWKWebViewController.h>
#import "NEEmotionTool.h"

@interface TextViewController ()
@property (nonatomic, assign) CGFloat leftRightMargin;
@property (nonatomic, assign) CGFloat contentMaxWidth;
@end

@implementation TextViewController

- (instancetype)initWithTitle:(NSString *)title body:(NSAttributedString *)body {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _leftRightMargin = 20;
        _contentMaxWidth = kScreenWidth() - _leftRightMargin * 2;

        UIFont *titleFont = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
        UIFont *bodyFont = [UIFont systemFontOfSize:24];

        if (title) {
            self.titleLabel.copyString = title;
            NSAttributedString *titleAtt = [NEEmotionTool getAttWithStr:title
                                                                   font:titleFont
                                                                  color:UIColor.ne_darkText
                                                                 offset:CGPointMake(0, -3)];
            self.titleLabel.attributedText = titleAtt;
        }

        if (body) {
            self.bodyLabel.copyString = body.string;
            self.bodyLabel.attributedText = body;
        }
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _leftRightMargin = 20;
        _contentMaxWidth = kScreenWidth() - _leftRightMargin * 2;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController.viewControllers.count > 0) {
        UIViewController *root = self.navigationController.viewControllers[0];
        if ([root isKindOfClass:[TextViewController class]]) {
            self.navigationController.interactivePopGestureRecognizer.delegate = self;
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.navigationController &&
        [self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)] &&
        gestureRecognizer == self.navigationController.interactivePopGestureRecognizer &&
        self.navigationController.visibleViewController == self.navigationController.viewControllers.firstObject) {
        return NO;
    }
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.navigationView.hidden = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTap)];
    [self.scrollView addGestureRecognizer:tap];
    [self setupUI];
    [self contentSizeToFit];
}

- (void)viewTap {
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)setupUI {
    self.view.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.scrollView];
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [self.scrollView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:0],
        [self.scrollView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:0],
    ]];

    UIFont *titleFont = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    UIFont *bodyFont = [UIFont systemFontOfSize:24];
    self.titleLabel.preferredMaxLayoutWidth = self.contentMaxWidth;
    self.bodyLabel.preferredMaxLayoutWidth = self.contentMaxWidth;

    [self.scrollView addSubview:self.textView];
    self.contentLabelTopAnchor = [self.textView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor];
    self.contentLabelTopAnchor.active = YES;
    self.contentLabelLeftAnchor = [self.textView.leftAnchor constraintEqualToAnchor:self.scrollView.leftAnchor constant:self.leftRightMargin];
    self.contentLabelLeftAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.textView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.textView.rightAnchor constraintEqualToAnchor:self.scrollView.rightAnchor constant:-self.leftRightMargin],
    ]];
}

- (void)contentSizeToFit {
    UIFont *titleFont = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    UIFont *bodyFont = [UIFont systemFontOfSize:24];
    CGSize maxSize = CGSizeMake(self.contentMaxWidth, CGFLOAT_MAX);
    CGRect titleRect = [self.titleLabel.attributedText boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    CGRect bodyRect = [self.bodyLabel.attributedText boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    CGSize titleSize = titleRect.size;
    CGSize bodySize = bodyRect.size;

    CGFloat textHeight = titleSize.height + bodySize.height;
    CGFloat textViewHeight = kScreenHeight() - kNavigationHeight - KStatusBarHeight();
    if (textHeight <= textViewHeight) {
        CGFloat offsetY = (textViewHeight - textHeight) / 2;
        self.contentLabelTopAnchor.constant = offsetY;
    }

    CGFloat textWidth = MAX(titleSize.width, bodySize.width);
    if (textWidth <= self.contentMaxWidth) {
        CGFloat offsetX = (kScreenWidth() - textWidth) / 2;
        self.contentLabelLeftAnchor.constant = offsetX;
    }
    self.scrollView.contentSize = CGSizeMake(textWidth, textHeight);
}

- (void)updateLinkDetection {
    [self.bodyLabel updateLinkDetection];
}

#pragma mark - LinkableLabelProtocol

- (void)didTapLink:(NSURL *)url {
    if (url) {
        if ([url.scheme isEqualToString:@"mailto"]) {
            [self didTapMailto:url];
        } else if ([url.scheme isEqualToString:@"tel"]) {
            [self didTapTel:url];
        } else {
            NEWKWebViewController *ctrl = [[NEWKWebViewController alloc] initWithUrl:url.absoluteString title:url.absoluteString];
            [self.navigationController pushViewController:ctrl animated:YES];
        }
    } else {
        [self viewTap];
    }
}

- (void)didTapTel:(NSURL *)url {
    [self showBottomTelAction:url];
}

- (void)didTapMailto:(NSURL *)url {
    [self showBottomMailAction:url];
}

#pragma mark - Lazy Properties

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.scrollEnabled = YES;
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _scrollView;
}

- (UIView *)textView {
    if (!_textView) {
        _textView = [[UIView alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.backgroundColor = UIColor.clearColor;

        [_textView addSubview:self.titleLabel];
        [NSLayoutConstraint activateConstraints:@[
            [self.titleLabel.topAnchor constraintEqualToAnchor:_textView.topAnchor],
            [self.titleLabel.leftAnchor constraintEqualToAnchor:_textView.leftAnchor],
            [self.titleLabel.rightAnchor constraintEqualToAnchor:_textView.rightAnchor],
        ]];

        [_textView addSubview:self.bodyLabel];
        [NSLayoutConstraint activateConstraints:@[
            [self.bodyLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor],
            [self.bodyLabel.leftAnchor constraintEqualToAnchor:_textView.leftAnchor],
            [self.bodyLabel.rightAnchor constraintEqualToAnchor:_textView.rightAnchor],
            [self.bodyLabel.bottomAnchor constraintEqualToAnchor:_textView.bottomAnchor],
        ]];
    }
    return _textView;
}

- (CopyableLabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[CopyableLabel alloc] init];
        _titleLabel.numberOfLines = 0;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
        _titleLabel.backgroundColor = UIColor.clearColor;
        _titleLabel.textColor = UIColor.ne_darkText;
    }
    return _titleLabel;
}

- (CopyableLabel *)bodyLabel {
    if (!_bodyLabel) {
        _bodyLabel = [[CopyableLabel alloc] init];
        _bodyLabel.numberOfLines = 0;
        _bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _bodyLabel.font = [UIFont systemFontOfSize:24];
        _bodyLabel.backgroundColor = UIColor.clearColor;
        _bodyLabel.textColor = UIColor.ne_darkText;
        _bodyLabel.delegate = self;
    }
    return _bodyLabel;
}

@end
