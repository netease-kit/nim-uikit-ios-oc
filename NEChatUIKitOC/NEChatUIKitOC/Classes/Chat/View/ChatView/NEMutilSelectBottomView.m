// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMutilSelectBottomView.h"
#import "UIImage+Chat.h"
#import "NEChatUIConstant.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEAppLanguageUtil.h>

@interface NEMutilSelectBottomView ()

@property (nonatomic, strong) UIColor *normalLabelColor;
@property (nonatomic, strong) UIColor *disabledLabelColor;

@end

@implementation NEMutilSelectBottomView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _normalLabelColor = UIColor.ne_greyText;
        _disabledLabelColor = [UIColor.ne_greyText colorWithAlphaComponent:0.35];
        [self setupSubview];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UIButton *)singleForwardButton {
    if (!_singleForwardButton) {
        _singleForwardButton = [[UIButton alloc] init];
        _singleForwardButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_singleForwardButton setImage:[UIImage ne_imageNamed:@"select_singleForward"] forState:UIControlStateNormal];
        [_singleForwardButton setImage:[UIImage ne_imageNamed:@"unselect_singleForward"] forState:UIControlStateDisabled];
        [_singleForwardButton addTarget:self action:@selector(singleForwardButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _singleForwardButton;
}

- (UILabel *)singleForwardLabel {
    if (!_singleForwardLabel) {
        _singleForwardLabel = [[UILabel alloc] init];
        _singleForwardLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _singleForwardLabel.text = chatLocalizable(@"select_per_item");
        _singleForwardLabel.textColor = UIColor.ne_greyText;
        _singleForwardLabel.font = [UIFont systemFontOfSize:11];
        _singleForwardLabel.textAlignment = NSTextAlignmentCenter;
        _singleForwardLabel.numberOfLines = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 2 : 1;
    }
    return _singleForwardLabel;
}

- (UIButton *)multiForwardButton {
    if (!_multiForwardButton) {
        _multiForwardButton = [[UIButton alloc] init];
        _multiForwardButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_multiForwardButton setImage:[UIImage ne_imageNamed:@"select_multiForward"] forState:UIControlStateNormal];
        [_multiForwardButton setImage:[UIImage ne_imageNamed:@"unselect_multiForward"] forState:UIControlStateDisabled];
        [_multiForwardButton addTarget:self action:@selector(multiForwardButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _multiForwardButton;
}

- (UILabel *)multiForwardLabel {
    if (!_multiForwardLabel) {
        _multiForwardLabel = [[UILabel alloc] init];
        _multiForwardLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _multiForwardLabel.text = chatLocalizable(@"select_multi");
        _multiForwardLabel.textColor = UIColor.ne_greyText;
        _multiForwardLabel.font = [UIFont systemFontOfSize:11];
        _multiForwardLabel.textAlignment = NSTextAlignmentCenter;
        _multiForwardLabel.numberOfLines = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 2 : 1;
    }
    return _multiForwardLabel;
}

- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [[UIButton alloc] init];
        _deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_deleteButton setImage:[UIImage ne_imageNamed:@"select_delete"] forState:UIControlStateNormal];
        [_deleteButton setImage:[UIImage ne_imageNamed:@"unselect_delete"] forState:UIControlStateDisabled];
        [_deleteButton addTarget:self action:@selector(deleteButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

- (UILabel *)deleteLabel {
    if (!_deleteLabel) {
        _deleteLabel = [[UILabel alloc] init];
        _deleteLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _deleteLabel.text = chatLocalizable(@"operation_delete");
        _deleteLabel.textColor = UIColor.ne_greyText;
        _deleteLabel.font = [UIFont systemFontOfSize:11];
        _deleteLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _deleteLabel;
}

- (void)setupSubview {
    [self addSubview:self.singleForwardButton];
    self.buttonTopAnchor = [self.singleForwardButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:12];
    self.buttonTopAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.singleForwardButton.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.singleForwardButton.widthAnchor constraintEqualToConstant:48],
        [self.singleForwardButton.heightAnchor constraintEqualToConstant:48],
    ]];

    [self addSubview:self.singleForwardLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.singleForwardLabel.topAnchor constraintEqualToAnchor:self.singleForwardButton.bottomAnchor constant:3],
        [self.singleForwardLabel.centerXAnchor constraintEqualToAnchor:self.singleForwardButton.centerXAnchor],
        [self.singleForwardLabel.widthAnchor constraintEqualToConstant:68],
    ]];

    [self addSubview:self.multiForwardButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.multiForwardButton.centerYAnchor constraintEqualToAnchor:self.singleForwardButton.centerYAnchor],
        [self.multiForwardButton.rightAnchor constraintEqualToAnchor:self.singleForwardButton.leftAnchor constant:-52],
        [self.multiForwardButton.widthAnchor constraintEqualToConstant:48],
        [self.multiForwardButton.heightAnchor constraintEqualToConstant:48],
    ]];

    [self addSubview:self.multiForwardLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.multiForwardLabel.centerYAnchor constraintEqualToAnchor:self.singleForwardLabel.centerYAnchor],
        [self.multiForwardLabel.centerXAnchor constraintEqualToAnchor:self.multiForwardButton.centerXAnchor],
        [self.multiForwardLabel.widthAnchor constraintEqualToConstant:68],
    ]];

    [self addSubview:self.deleteButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.deleteButton.centerYAnchor constraintEqualToAnchor:self.singleForwardButton.centerYAnchor],
        [self.deleteButton.leftAnchor constraintEqualToAnchor:self.singleForwardButton.rightAnchor constant:52],
        [self.deleteButton.widthAnchor constraintEqualToConstant:48],
        [self.deleteButton.heightAnchor constraintEqualToConstant:48],
    ]];

    [self addSubview:self.deleteLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.deleteLabel.centerYAnchor constraintEqualToAnchor:self.singleForwardLabel.centerYAnchor],
        [self.deleteLabel.centerXAnchor constraintEqualToAnchor:self.deleteButton.centerXAnchor],
        [self.deleteLabel.widthAnchor constraintEqualToConstant:68],
    ]];
}

- (void)setEnable:(BOOL)enable {
    self.multiForwardButton.enabled = enable;
    self.singleForwardButton.enabled = enable;
    self.deleteButton.enabled = enable;
    UIColor *labelColor = enable ? self.normalLabelColor : self.disabledLabelColor;
    self.multiForwardLabel.textColor = labelColor;
    self.singleForwardLabel.textColor = labelColor;
    self.deleteLabel.textColor = labelColor;
}

- (void)setLabelColor:(UIColor *)color {
    self.normalLabelColor = color ?: UIColor.ne_greyText;
    self.disabledLabelColor = [self.normalLabelColor colorWithAlphaComponent:0.35];
    [self setEnable:self.multiForwardButton.enabled];
}

- (void)multiForwardButtonAction { [self.delegate didClickMultiForwardButton]; }
- (void)singleForwardButtonAction { [self.delegate didClickSingleForwardButton]; }
- (void)deleteButtonAction { [self.delegate didClickDeleteButton]; }

@end
