// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatInputView.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import "ChatCellConstantValue.h"
#import "FunChatUIColor.h"
#import "NEChatUIConstant.h"
#import "NEChatMoreActionView.h"
#import <NECommonUIKitOC/ExpandButton.h>
#import <NECommonUIKitOC/UIView+NECorner.h>

@interface NEBaseChatInputView ()

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, weak) id<UITextInput> textInput;

@end

@implementation FunChatInputView

- (instancetype)initWithConversationType:(V2NIMConversationType)conversationType {
    self = [super initWithConversationType:conversationType];
    if (self) {
        _defaultReplyTopSpace = 8;
        _multipleReplyTopSpace = 48;
    }
    return self;
}

- (instancetype)init:(V2NIMConversationType)conversationType {
    return [self initWithConversationType:conversationType];
}

- (void)commonUI {
    if (_defaultReplyTopSpace <= 0) {
        _defaultReplyTopSpace = 8;
    }
    if (_multipleReplyTopSpace <= 0) {
        _multipleReplyTopSpace = 48;
    }
    [super commonUI];
    self.backgroundColor = [UIColor funChatInputViewBg];

    [self addSubview:self.textView];
    self.textView.layer.cornerRadius = 4.0;
    self.textView.delegate = self;
    self.textviewLeftConstraint = [self.textView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:48];
    self.textviewRightConstraint = [self.textView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:[self getTextviewRightConstraint]];
    self.textViewTop = [self.textView.topAnchor constraintEqualToAnchor:self.topAnchor constant:8];

    [NSLayoutConstraint activateConstraints:@[
        self.textviewLeftConstraint,
        self.textviewRightConstraint,
        self.textViewTop,
        [self.textView.heightAnchor constraintEqualToConstant:40],
    ]];
    self.textInput = self.textView;

    self.backViewHeightConstaint = [self.backView.heightAnchor constraintEqualToConstant:40];
    [self insertSubview:self.backView belowSubview:self.textView];
    [self setUnMuteInputStyle];
    [NSLayoutConstraint activateConstraints:@[
        [self.backView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:48],
        [self.backView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-88],
        [self.backView.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
        self.backViewHeightConstaint,
    ]];

    if (self.expandButton) {
        [self addSubview:self.expandButton];
        [NSLayoutConstraint activateConstraints:@[
            [self.expandButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
            [self.expandButton.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:7],
            [self.expandButton.heightAnchor constraintEqualToConstant:40],
            [self.expandButton.widthAnchor constraintEqualToConstant:44],
        ]];
        [(ExpandButton *)self.expandButton setImage:chatLoadImage(@"fun_input_unfold") forState:UIControlStateNormal];
        [(ExpandButton *)self.expandButton addTarget:self action:@selector(didClickExpandButton) forControlEvents:UIControlEventTouchUpInside];
    }

    self.aiChatButton = nil;

    [self insertSubview:self.replyBackView belowSubview:self.backView];
    self.replyViewTopConstraint = [self.replyBackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:self.defaultReplyTopSpace];
    [NSLayoutConstraint activateConstraints:@[
        self.replyViewTopConstraint,
        [self.replyBackView.heightAnchor constraintEqualToConstant:40],
        [self.replyBackView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:48],
        [self.replyBackView.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor],
    ]];

    [self.replyBackView addSubview:self.replyLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.replyLabel.leftAnchor constraintEqualToAnchor:self.replyBackView.leftAnchor constant:5],
        [self.replyLabel.topAnchor constraintEqualToAnchor:self.replyBackView.topAnchor],
        [self.replyLabel.bottomAnchor constraintEqualToAnchor:self.replyBackView.bottomAnchor],
        [self.replyLabel.rightAnchor constraintEqualToAnchor:self.replyBackView.rightAnchor constant:-fun_chat_min_h],
    ]];

    [self.replyBackView addSubview:self.clearBtn];
    [NSLayoutConstraint activateConstraints:@[
        [self.clearBtn.rightAnchor constraintEqualToAnchor:self.replyBackView.rightAnchor],
        [self.clearBtn.bottomAnchor constraintEqualToAnchor:self.replyBackView.bottomAnchor],
        [self.clearBtn.topAnchor constraintEqualToAnchor:self.replyBackView.topAnchor],
        [self.clearBtn.leftAnchor constraintEqualToAnchor:self.replyLabel.rightAnchor],
    ]];
    [self.clearBtn addTarget:self action:@selector(clearReplyMode) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.changeRecordModeBtn];
    [NSLayoutConstraint activateConstraints:@[
        [self.changeRecordModeBtn.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.changeRecordModeBtn.topAnchor constraintEqualToAnchor:self.replyBackView.topAnchor],
        [self.changeRecordModeBtn.bottomAnchor constraintEqualToAnchor:self.replyBackView.bottomAnchor],
        [self.changeRecordModeBtn.rightAnchor constraintEqualToAnchor:self.replyBackView.leftAnchor],
    ]];
    [self.changeRecordModeBtn addTarget:self action:@selector(changeToRecordMode:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.showMoreActionBtn];
    [NSLayoutConstraint activateConstraints:@[
        [self.showMoreActionBtn.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [self.showMoreActionBtn.bottomAnchor constraintEqualToAnchor:self.replyBackView.bottomAnchor],
        [self.showMoreActionBtn.topAnchor constraintEqualToAnchor:self.replyBackView.topAnchor],
        [self.showMoreActionBtn.widthAnchor constraintEqualToConstant:44],
    ]];
    [self.showMoreActionBtn addTarget:self action:@selector(moreBtnClick) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.showEmojBtn];
    [NSLayoutConstraint activateConstraints:@[
        [self.showEmojBtn.rightAnchor constraintEqualToAnchor:self.showMoreActionBtn.leftAnchor],
        [self.showEmojBtn.topAnchor constraintEqualToAnchor:self.replyBackView.topAnchor],
        [self.showEmojBtn.bottomAnchor constraintEqualToAnchor:self.replyBackView.bottomAnchor],
        [self.showEmojBtn.widthAnchor constraintEqualToConstant:44],
    ]];
    [self.showEmojBtn addTarget:self action:@selector(emojBtnClick) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.contentView];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.contentView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [self.contentView.heightAnchor constraintEqualToConstant:self.contentHeight],
        [self.contentView.topAnchor constraintEqualToAnchor:self.replyBackView.bottomAnchor constant:15],
    ]];

    [self.contentView addSubview:self.emojiView];

    self.chatAddMoreView.backgroundColor = [UIColor funChatAddMoreViewBg];
    CGRect frame = self.chatAddMoreView.frame;
    frame.origin.y += 10;
    self.chatAddMoreView.frame = frame;
    [self.contentView addSubview:self.chatAddMoreView];

    UIView *moreActionViewLine = [[UIView alloc] init];
    moreActionViewLine.translatesAutoresizingMaskIntoConstraints = NO;
    [self.chatAddMoreView addSubview:moreActionViewLine];
    self.chatAddMoreView.clipsToBounds = NO;
    moreActionViewLine.frame = CGRectMake(0, -10, self.chatAddMoreView.frame.size.width, 1.0);
    moreActionViewLine.backgroundColor = [UIColor funChatAddMoreActionViewLineColor];

    [self addSubview:self.holdToSpeakView];
    [NSLayoutConstraint activateConstraints:@[
        [self.holdToSpeakView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:48],
        [self.holdToSpeakView.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor],
        [self.holdToSpeakView.topAnchor constraintEqualToAnchor:self.backView.topAnchor],
        [self.holdToSpeakView.bottomAnchor constraintEqualToAnchor:self.backView.bottomAnchor],
    ]];
    self.holdToSpeakView.hidden = YES;

    [self setupMultipleLineView];
    [(ExpandButton *)self.multipleLineExpandButton setImage:chatLoadImage(@"fun_input_fold") forState:UIControlStateNormal];
}

- (CGFloat)getTextviewRightConstraint {
    NSInteger expandButtonWidth = IMKitConfigCenter.shared.enableRichTextMessage ? 32 : 0;
    NSInteger totalWidth = expandButtonWidth + 88;
    return -totalWidth;
}

- (void)changeToRecordMode:(UIButton *)button {
    button.selected = !button.selected;
    if (button.selected) {
        [self showRecordMode];
    } else {
        [self.funDelegate didHideRecordMode];
        [self hideRecordMode];
    }
}

- (void)clearReplyMode {
    self.replyLabel.attributedText = nil;
    [self hideReplyMode];
}

- (void)showRecordMode {
    self.currentType = ChatMenuTypeAudio;
    self.holdToSpeakView.hidden = NO;
    [self hideReplyMode];
    [self hideAIChatView];
    [self.funDelegate recordModeChangeDidClick];
}

- (void)hideRecordMode {
    self.holdToSpeakView.hidden = YES;
    self.changeRecordModeBtn.selected = NO;
    if (self.replyLabel.attributedText.length > 0) {
        [self showReplyMode];
        [self.funDelegate didShowReplyMode];
    }
}

- (void)showReplyMode {
    if (self.chatInpuMode == ChatInputModeNormal) {
        self.replyViewTopConstraint.constant = 52;
    } else {
        self.replyViewTopConstraint.constant = 90;
    }
    if (self.replyLabel.attributedText == nil || self.replyLabel.attributedText.length == 0) {
        [self hideRecordMode];
    }
}

- (void)hideReplyMode {
    if (self.replyViewTopConstraint.constant == self.defaultReplyTopSpace) {
        return;
    }
    if (self.chatInpuMode == ChatInputModeNormal) {
        self.replyViewTopConstraint.constant = 8;
    } else {
        self.replyViewTopConstraint.constant = self.multipleReplyTopSpace;
    }
    [self.funDelegate didHideReplyMode];
}

- (BOOL)isRecordMode {
    return self.changeRecordModeBtn.selected;
}

- (void)moreBtnClick {
    if (self.changeRecordModeBtn.selected && self.chatInpuMode == ChatInputModeMultipleSend) {
        [self.funDelegate didHideRecordMode];
    }
    [self hideRecordMode];
    [self hideAIChatView];
    self.changeRecordModeBtn.selected = NO;
    [self buttonEvent:self.showMoreActionBtn];
}

- (void)emojBtnClick {
    if (self.changeRecordModeBtn.selected && self.chatInpuMode == ChatInputModeMultipleSend) {
        [self.funDelegate didHideRecordMode];
    }
    [self hideRecordMode];
    [self hideAIChatView];
    self.changeRecordModeBtn.selected = NO;
    [self buttonEvent:self.showEmojBtn];
}

- (void)setMuteInputStyle {
    [super setMuteInputStyle];
    self.backView.backgroundColor = [UIColor funChatInputMuteBg];
}

- (void)setUnMuteInputStyle {
    [super setUnMuteInputStyle];
    self.backView.backgroundColor = [UIColor funChatInputBg];
}

- (void)setRecordNormalStyle {
    self.backViewHeightConstaint.constant = 40;
    self.textViewTop.constant = 8;
    self.replyViewTopConstraint.constant = self.defaultReplyTopSpace;
}

- (void)resotreMutipleModeFromRecordMode {
    self.backViewHeightConstaint.constant = 80;
    self.textViewTop.constant = 40;
    if (self.replyLabel.attributedText.length > 0) {
        self.replyViewTopConstraint.constant = 90;
    } else {
        self.replyViewTopConstraint.constant = self.multipleReplyTopSpace;
    }
}

- (void)restoreNormalInputStyle {
    [super restoreNormalInputStyle];

    if (!self.expandButton) {
        return;
    }

    self.contentSubView.hidden = YES;
    self.textView.returnKeyType = UIReturnKeySend;
    NSMutableArray<NSLayoutConstraint *> *textViewConstraints = [NSMutableArray array];
    if (self.textviewLeftConstraint) [textViewConstraints addObject:self.textviewLeftConstraint];
    if (self.textviewRightConstraint) [textViewConstraints addObject:self.textviewRightConstraint];
    if (self.textViewTop) [textViewConstraints addObject:self.textViewTop];
    [NSLayoutConstraint deactivateConstraints:textViewConstraints];
    [self.textView removeAllAutoLayout];
    [self.textView removeConstraints:self.textView.constraints];
    [self insertSubview:self.textView belowSubview:self.holdToSpeakView];

    if (self.chatInpuMode == ChatInputModeNormal) {
        self.titleField.hidden = YES;
        self.textviewLeftConstraint = [self.textView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:48];
        self.textviewRightConstraint = [self.textView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:[self getTextviewRightConstraint]];
        self.textViewTop = [self.textView.topAnchor constraintEqualToAnchor:self.topAnchor constant:8];
        [NSLayoutConstraint activateConstraints:@[
            self.textviewLeftConstraint,
            self.textviewRightConstraint,
            self.textViewTop,
            [self.textView.heightAnchor constraintEqualToConstant:40],
        ]];
        self.backViewHeightConstaint.constant = 40;
        if (self.replyLabel.attributedText.length > 0) {
            self.replyViewTopConstraint.constant = 51;
        } else {
            self.replyViewTopConstraint.constant = self.defaultReplyTopSpace;
        }
    } else if (self.chatInpuMode == ChatInputModeMultipleSend) {
        self.titleField.hidden = NO;
        [self.titleField removeAllAutoLayout];
        [self insertSubview:self.titleField aboveSubview:self.backView];
        UIView *rightAnchorView = self.aiChatButton.superview == self ? self.aiChatButton : self.expandButton;
        [NSLayoutConstraint activateConstraints:@[
            [self.titleField.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:4],
            [self.titleField.rightAnchor constraintEqualToAnchor:rightAnchorView.leftAnchor constant:2],
            [self.titleField.topAnchor constraintEqualToAnchor:self.backView.topAnchor],
            [self.titleField.heightAnchor constraintEqualToConstant:40],
        ]];

        self.textviewLeftConstraint = [self.textView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:48];
        self.textviewRightConstraint = [self.textView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-88];
        self.textViewTop = [self.textView.topAnchor constraintEqualToAnchor:self.topAnchor constant:40];

        [NSLayoutConstraint activateConstraints:@[
            self.textviewLeftConstraint,
            self.textviewRightConstraint,
            self.textViewTop,
            [self.textView.heightAnchor constraintEqualToConstant:40],
        ]];
        self.backViewHeightConstaint.constant = 80;
        if (self.replyLabel.attributedText.length > 0) {
            self.replyViewTopConstraint.constant = 90;
        } else {
            self.replyViewTopConstraint.constant = self.multipleReplyTopSpace;
        }
    }
}

- (void)changeToMultipleLineStyle {
    [super changeToMultipleLineStyle];
    self.titleField.hidden = NO;
    [self.textView removeAllAutoLayout];
    self.textView.returnKeyType = UIReturnKeyDefault;
    [self.multipleLineView addSubview:self.textView];
    [NSLayoutConstraint activateConstraints:@[
        [self.textView.leftAnchor constraintEqualToAnchor:self.multipleLineView.leftAnchor constant:13],
        [self.textView.rightAnchor constraintEqualToAnchor:self.multipleLineView.rightAnchor constant:-16],
        [self.textView.topAnchor constraintEqualToAnchor:self.multipleLineView.topAnchor constant:48],
        [self.textView.heightAnchor constraintEqualToConstant:183],
    ]];

    if (self.titleField.superview == nil || self.titleField.superview != self.multipleLineView) {
        [self.titleField removeAllAutoLayout];
        [self.multipleLineView addSubview:self.titleField];
        [NSLayoutConstraint activateConstraints:@[
            [self.titleField.leftAnchor constraintEqualToAnchor:self.multipleLineView.leftAnchor constant:16],
            [self.titleField.rightAnchor constraintEqualToAnchor:self.multipleLineView.rightAnchor constant:-56],
            [self.titleField.topAnchor constraintEqualToAnchor:self.multipleLineView.topAnchor constant:5],
            [self.titleField.heightAnchor constraintEqualToConstant:40],
        ]];
    }
}

- (void)setLayerContents:(BOOL)open {
    [super setLayerContents:open];
    if (open) {
        UIImage *image = [UIImage ne_imageNamed:@"fun_ai_back"];
        if (image.CGImage) {
            self.layer.contents = (__bridge id)image.CGImage;
            self.layer.contentsGravity = kCAGravityResizeAspectFill;
            self.layer.contentsScale = [UIScreen mainScreen].scale;
        }
    } else {
        self.layer.contents = nil;
    }
}

- (void)didClickAIChatButton {
    CGFloat replyViewOffset = self.replyLabel.attributedText == nil ? 0 : 40;
    CGFloat multiInputOffset = self.chatInpuMode == ChatInputModeNormal ? 0 : 40;
    self.aiChatViewControllerTopConstant = 54 + replyViewOffset + multiInputOffset;
    [super didClickAIChatButton];
}

#pragma mark - Lazy Load

- (UIView *)replyBackView {
    if (!_replyBackView) {
        _replyBackView = [[UIView alloc] init];
        _replyBackView.translatesAutoresizingMaskIntoConstraints = NO;
        _replyBackView.layer.cornerRadius = 8.0;
        _replyBackView.clipsToBounds = YES;
        _replyBackView.backgroundColor = [UIColor funChatReplyViewBg];
    }
    return _replyBackView;
}

- (UILabel *)replyLabel {
    if (!_replyLabel) {
        _replyLabel = [[UILabel alloc] init];
        _replyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _replyLabel.backgroundColor = [UIColor clearColor];
        _replyLabel.numberOfLines = 2;
        _replyLabel.accessibilityIdentifier = @"id.replyContent";
    }
    return _replyLabel;
}

- (UIButton *)clearBtn {
    if (!_clearBtn) {
        _clearBtn = [[UIButton alloc] init];
        _clearBtn.translatesAutoresizingMaskIntoConstraints = NO;
        _clearBtn.backgroundColor = [UIColor clearColor];
        [_clearBtn setImage:chatLoadImage(@"fun_chat_input_reply_clear") forState:UIControlStateNormal];
        _clearBtn.accessibilityIdentifier = @"id.replyClose";
    }
    return _clearBtn;
}

- (UIButton *)changeRecordModeBtn {
    if (!_changeRecordModeBtn) {
        _changeRecordModeBtn = [[UIButton alloc] init];
        _changeRecordModeBtn.translatesAutoresizingMaskIntoConstraints = NO;
        _changeRecordModeBtn.backgroundColor = [UIColor clearColor];
        [_changeRecordModeBtn setImage:chatLoadImage(@"fun_chat_input_change_record") forState:UIControlStateNormal];
        [_changeRecordModeBtn setImage:chatLoadImage(@"fun_chat_input_keyboard") forState:UIControlStateSelected];
        _changeRecordModeBtn.accessibilityIdentifier = @"id.changeRecordMode";
    }
    return _changeRecordModeBtn;
}

- (UIButton *)showMoreActionBtn {
    if (!_showMoreActionBtn) {
        _showMoreActionBtn = [[UIButton alloc] init];
        _showMoreActionBtn.translatesAutoresizingMaskIntoConstraints = NO;
        _showMoreActionBtn.backgroundColor = [UIColor clearColor];
        _showMoreActionBtn.tag = addMoreBtnTag;
        [_showMoreActionBtn setImage:chatLoadImage(@"fun_chat_input_show_more") forState:UIControlStateNormal];
        _showMoreActionBtn.accessibilityIdentifier = @"id.inputMore";
    }
    return _showMoreActionBtn;
}

- (UIButton *)showEmojBtn {
    if (!_showEmojBtn) {
        _showEmojBtn = [[UIButton alloc] init];
        _showEmojBtn.translatesAutoresizingMaskIntoConstraints = NO;
        _showEmojBtn.backgroundColor = [UIColor clearColor];
        _showEmojBtn.tag = addEmojBtnTag;
        [_showEmojBtn setImage:chatLoadImage(@"fun_chat_input_show_emoj") forState:UIControlStateNormal];
        _showEmojBtn.accessibilityIdentifier = @"id.inputEmoji";
    }
    return _showEmojBtn;
}

- (UIView *)holdToSpeakView {
    if (!_holdToSpeakView) {
        _holdToSpeakView = [[UIView alloc] init];
        _holdToSpeakView.backgroundColor = [UIColor funChatInputHoldspeakBg];
        _holdToSpeakView.clipsToBounds = YES;
        _holdToSpeakView.translatesAutoresizingMaskIntoConstraints = NO;
        _holdToSpeakView.layer.cornerRadius = 4.0;

        UILabel *label = [[UILabel alloc] init];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.textColor = [UIColor funChatInputHoldspeakTextColor];
        label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        [_holdToSpeakView addSubview:label];
        [NSLayoutConstraint activateConstraints:@[
            [label.centerYAnchor constraintEqualToAnchor:_holdToSpeakView.centerYAnchor],
            [label.centerXAnchor constraintEqualToAnchor:_holdToSpeakView.centerXAnchor],
        ]];
        label.text = chatLocalizable(@"fun_hold_to_talk");
    }
    return _holdToSpeakView;
}

@end
