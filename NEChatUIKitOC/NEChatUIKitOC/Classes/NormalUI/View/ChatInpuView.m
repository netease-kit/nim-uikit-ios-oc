// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatInpuView.h"
#import "UIImage+Chat.h"
#import "NormalChatUIColor.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import "ChatViewController.h"
#import "NEChatUIConstant.h"
#import "ChatRecordView.h"
#import "NEChatMoreActionView.h"
#import <NEBaseUIKitOC/ExpandButton.h>

@interface NEBaseChatInputView ()

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, weak) id<UITextInput> textInput;

@end

@interface ChatInputView ()

@property (nonatomic, strong, nullable) NSNumber *showAIChatButtonOverride;

@end

@implementation ChatInputView

- (CGFloat)emoticonContentVerticalOffset {
    return -10;
}

- (nullable UIViewController *)ne_parentContainerViewController {
    UIResponder *responder = self;
    while (responder) {
        responder = responder.nextResponder;
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

- (instancetype)initWithConversationType:(V2NIMConversationType)conversationType {
    self = [super initWithConversationType:conversationType];
    return self;
}

- (instancetype)initWithConversationType:(V2NIMConversationType)conversationType
                         showAIChatButton:(BOOL)showAIChatButton {
    self = [self initWithConversationType:conversationType];
    if (self) {
        self.showAIChatButtonOverride = @(showAIChatButton);
        if (!showAIChatButton) {
            [self.aiChatButton removeFromSuperview];
            self.aiChatButton = nil;
            self.textviewRightConstraint.constant = [self getTextviewRightConstraint];
        }
    }
    return self;
}

- (instancetype)init:(V2NIMConversationType)conversationType
     showAIChatButton:(BOOL)showAIChatButton {
    return [self initWithConversationType:conversationType
                         showAIChatButton:showAIChatButton];
}

- (void)commonUI {
    [super commonUI];
    self.backgroundColor = UIColor.normalChatInputViewBg;

    [self addSubview:self.textView];
    self.textView.delegate = self;
    self.textviewLeftConstraint = [self.textView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:7];
    self.textviewRightConstraint = [self.textView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:[self getTextviewRightConstraint]];
    [NSLayoutConstraint activateConstraints:@[
        self.textviewLeftConstraint,
        self.textviewRightConstraint,
        [self.textView.topAnchor constraintEqualToAnchor:self.topAnchor constant:6],
        [self.textView.heightAnchor constraintEqualToConstant:40],
    ]];
    self.textInput = self.textView;

    self.backViewHeightConstraint = [self.backView.heightAnchor constraintEqualToConstant:40];
    [self insertSubview:self.backView belowSubview:self.textView];
    [self setUnMuteInputStyle];
    [NSLayoutConstraint activateConstraints:@[
        [self.backView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:7],
        [self.backView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-7],
        [self.backView.topAnchor constraintEqualToAnchor:self.topAnchor constant:6],
        self.backViewHeightConstraint,
    ]];

    if (self.expandButton) {
        [self addSubview:self.expandButton];
        [NSLayoutConstraint activateConstraints:@[
            [self.expandButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:7],
            [self.expandButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:0],
            [self.expandButton.heightAnchor constraintEqualToConstant:40],
            [self.expandButton.widthAnchor constraintEqualToConstant:44.0],
        ]];
        [(ExpandButton *)self.expandButton setImage:[UIImage ne_imageNamed:@"normal_input_unfold"] forState:UIControlStateNormal];
        [(ExpandButton *)self.expandButton addTarget:self action:@selector(didClickExpandButton) forControlEvents:UIControlEventTouchUpInside];
    }

    if (self.aiChatButton && self.conversationType == V2NIM_CONVERSATION_TYPE_P2P) {
        [self addSubview:self.aiChatButton];
        UIView *rightAnchorView = self.expandButton ?: self;
        CGFloat constant = self.expandButton ? 8 : 0;
        [NSLayoutConstraint activateConstraints:@[
            [self.aiChatButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:7],
            [self.aiChatButton.rightAnchor constraintEqualToAnchor:rightAnchorView.leftAnchor constant:constant],
            [self.aiChatButton.heightAnchor constraintEqualToConstant:40],
            [self.aiChatButton.widthAnchor constraintEqualToConstant:44.0],
        ]];
        [(ExpandButton *)self.aiChatButton setImage:[UIImage ne_imageNamed:@"ai_icon_default"] forState:UIControlStateNormal];
        [(ExpandButton *)self.aiChatButton setImage:[UIImage ne_imageNamed:@"ai_icon_highlight"] forState:UIControlStateSelected];
        [(ExpandButton *)self.aiChatButton addTarget:self action:@selector(didClickAIChatButton) forControlEvents:UIControlEventTouchUpInside];
    } else {
        self.aiChatButton = nil;
    }

    NSArray *imageNames = @[@"mic", @"emoji", @"photo", @"add"];
    NSArray *imageNamesSelected = @[@"mic_selected", @"emoji_selected", @"photo", @"add_selected"];

    NSMutableArray *items = [NSMutableArray array];
    for (NSInteger i = 0; i < imageNames.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage ne_imageNamed:imageNames[i]] forState:UIControlStateNormal];
        [button setImage:[UIImage ne_imageNamed:imageNamesSelected[i]] forState:UIControlStateSelected];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button addTarget:self action:@selector(buttonEvent:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = i + 5;
        button.accessibilityIdentifier = @"id.chatMessageActionItemBtn";
        [items addObject:button];
    }

    if ([ChatUIConfig shared].chatInputBar) {
        ChatViewController *chatVC = (ChatViewController *)[self ne_parentContainerViewController];
        [ChatUIConfig shared].chatInputBar(chatVC, items);
    }

    self.stackView = [[UIStackView alloc] initWithArrangedSubviews:items];
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.stackView.distribution = UIStackViewDistributionFillEqually;
    self.stackView.backgroundColor = UIColor.clearColor;

    self.toolsBarTopMargin = [self.stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:46];
    [self addSubview:self.stackView];
    [NSLayoutConstraint activateConstraints:@[
        [self.stackView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.stackView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [self.stackView.heightAnchor constraintEqualToConstant:54],
        self.toolsBarTopMargin,
    ]];

    self.greyView.translatesAutoresizingMaskIntoConstraints = NO;
    self.greyView.backgroundColor = UIColor.clearColor;
    self.greyView.hidden = YES;
    [self addSubview:self.greyView];
    [NSLayoutConstraint activateConstraints:@[
        [self.greyView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:0],
        [self.greyView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0],
        [self.greyView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:0],
        [self.greyView.heightAnchor constraintEqualToConstant:400],
    ]];

    [self addSubview:self.contentView];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.contentView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [self.contentView.heightAnchor constraintEqualToConstant:self.contentHeight],
        [self.contentView.topAnchor constraintEqualToAnchor:self.stackView.bottomAnchor constant:0],
    ]];

    self.recordView.hidden = YES;
    self.recordView.translatesAutoresizingMaskIntoConstraints = NO;
    self.recordView.delegate = self;
    self.recordView.backgroundColor = UIColor.normalChatRecordViewBg;
    [self.contentView addSubview:self.recordView];
    [NSLayoutConstraint activateConstraints:@[
        [self.recordView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:0],
        [self.recordView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:0],
        [self.recordView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:0],
        [self.recordView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:0],
    ]];

    [self.contentView addSubview:self.emojiView];

    self.chatAddMoreView.backgroundColor = UIColor.normalChatAddMoreViewBg;
    [self.contentView addSubview:self.chatAddMoreView];

    [self setupMultipleLineView];
    [(ExpandButton *)self.multipleLineExpandButton setImage:chatLoadImage(@"normal_input_fold") forState:UIControlStateNormal];
}

- (void)setLayerContents:(BOOL)open {
    [super setLayerContents:open];
    if (open) {
        UIImage *image = [UIImage ne_imageNamed:@"ai_back"];
        if (image.CGImage) {
            self.layer.contents = (__bridge id)image.CGImage;
            self.layer.contentsGravity = kCAGravityResizeAspectFill;
            self.layer.contentsScale = self.traitCollection.displayScale > 0 ? self.traitCollection.displayScale : [UIScreen mainScreen].scale;
        }
    } else {
        self.layer.contents = nil;
    }
}

- (CGFloat)getTextviewRightConstraint {
    NSInteger expandButtonWidth = [IMKitConfigCenter shared].enableRichTextMessage ? 40 : 0;
    BOOL shouldShowAIChatButton = self.showAIChatButtonOverride == nil ||
                                  self.showAIChatButtonOverride.boolValue;
    NSInteger aiChatButtonWidth = shouldShowAIChatButton &&
                                  [IMKitConfigCenter shared].enableAIChatHelper ? 40 : 0;
    NSInteger totalWidth = expandButtonWidth + aiChatButtonWidth;

    if (totalWidth > 0) {
        return -(CGFloat)MIN(totalWidth, 70);
    } else {
        return -7;
    }
}

- (void)didClickAIChatButton {
    CGFloat multiInputOffset = self.chatInpuMode == ChatInputModeNormal ? 0 : 50;
    self.aiChatViewControllerTopConstant = 54 + multiInputOffset;
    [super didClickAIChatButton];
}

- (void)restoreNormalInputStyle {
    [super restoreNormalInputStyle];
    if (!self.expandButton) return;

    self.textView.returnKeyType = UIReturnKeySend;
    NSMutableArray<NSLayoutConstraint *> *textViewConstraints = [NSMutableArray array];
    if (self.textviewLeftConstraint) [textViewConstraints addObject:self.textviewLeftConstraint];
    if (self.textviewRightConstraint) [textViewConstraints addObject:self.textviewRightConstraint];
    [NSLayoutConstraint deactivateConstraints:textViewConstraints];
    [self.textView removeAllAutoLayout];
    [self.textView removeConstraints:self.textView.constraints];
    [self insertSubview:self.textView aboveSubview:self.backView];
    self.textviewLeftConstraint = [self.textView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:7];

    if (self.chatInpuMode == ChatInputModeNormal) {
        self.titleField.hidden = YES;
        self.textviewRightConstraint = [self.textView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:[self getTextviewRightConstraint]];
        [NSLayoutConstraint activateConstraints:@[
            self.textviewLeftConstraint,
            self.textviewRightConstraint,
            [self.textView.topAnchor constraintEqualToAnchor:self.topAnchor constant:6],
            [self.textView.heightAnchor constraintEqualToConstant:40],
        ]];
        self.backViewHeightConstraint.constant = 46;
        self.toolsBarTopMargin.constant = 46;
    } else if (self.chatInpuMode == ChatInputModeMultipleSend) {
        self.titleField.hidden = NO;
        self.textviewRightConstraint = [self.textView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-7];
        [NSLayoutConstraint activateConstraints:@[
            self.textviewLeftConstraint,
            self.textviewRightConstraint,
            [self.textView.topAnchor constraintEqualToAnchor:self.topAnchor constant:45],
            [self.textView.heightAnchor constraintEqualToConstant:45],
        ]];

        [self.titleField removeAllAutoLayout];
        [self insertSubview:self.titleField belowSubview:self.textView];
        UIView *leftAnchor = self.backView;
        UIView *rightAnchorView = self.aiChatButton.superview == self ? self.aiChatButton : self.expandButton;
        [NSLayoutConstraint activateConstraints:@[
            [self.titleField.leftAnchor constraintEqualToAnchor:leftAnchor.leftAnchor constant:4],
            [self.titleField.rightAnchor constraintEqualToAnchor:rightAnchorView.leftAnchor],
            [self.titleField.topAnchor constraintEqualToAnchor:self.backView.topAnchor],
            [self.titleField.heightAnchor constraintEqualToConstant:40],
        ]];

        self.backViewHeightConstraint.constant = 96;
        self.toolsBarTopMargin.constant = 96;
    }
}

- (void)changeToMultipleLineStyle {
    [super changeToMultipleLineStyle];
    [self.textView removeAllAutoLayout];
    [self.multipleLineView addSubview:self.textView];
    [self.textView removeConstraints:self.textView.constraints];
    self.textView.returnKeyType = UIReturnKeyDefault;
    self.titleField.hidden = NO;

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

- (void)setMuteInputStyle {
    [super setMuteInputStyle];
    self.backView.backgroundColor = UIColor.normalChatInputMuteBg;
}

- (void)setUnMuteInputStyle {
    [super setUnMuteInputStyle];
    self.backView.backgroundColor = UIColor.normalChatInputBg;
}

@end
