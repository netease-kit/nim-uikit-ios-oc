// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAITranslateView.h"
#import <NEChatKit/NEChatKitOC.h>
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NELottieAnimationView.h>
#import "NEChatUIConstant.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>

@implementation NEAITranslateView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupTranslateLanguageUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UILabel *)shortLanguageLabel {
    if (!_shortLanguageLabel) {
        _shortLanguageLabel = [[UILabel alloc] init];
        _shortLanguageLabel.font = [UIFont systemFontOfSize:14];
        _shortLanguageLabel.textColor = UIColor.blackColor;
        _shortLanguageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _shortLanguageLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _shortLanguageLabel;
}

- (UIView *)shortLanguageBgView {
    if (!_shortLanguageBgView) {
        _shortLanguageBgView = [[UIView alloc] init];
        _shortLanguageBgView.translatesAutoresizingMaskIntoConstraints = NO;
        _shortLanguageBgView.backgroundColor = UIColor.whiteColor;
        _shortLanguageBgView.layer.borderColor = [UIColor ne_colorWithHexString:@"#CCCCCC"].CGColor;
        _shortLanguageBgView.layer.borderWidth = 1.0;
        _shortLanguageBgView.layer.cornerRadius = 2.0;
    }
    return _shortLanguageBgView;
}

- (UIButton *)switchLanguageButton {
    if (!_switchLanguageButton) {
        _switchLanguageButton = [[UIButton alloc] init];
        _switchLanguageButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _switchLanguageButton;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] init];
        _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _closeButton;
}

- (UIImageView *)closeImageView {
    if (!_closeImageView) {
        _closeImageView = [[UIImageView alloc] init];
        _closeImageView.image = [coreLoader() loadImage:@"remove"];
        _closeImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _closeImageView;
}

- (UIView *)separatorLine {
    if (!_separatorLine) {
        _separatorLine = [[UIView alloc] init];
        _separatorLine.backgroundColor = [UIColor ne_colorWithHexString:@"#DBDFE2"];
        _separatorLine.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _separatorLine;
}

- (UILabel *)statusLabel {
    if (!_statusLabel) {
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.font = [UIFont systemFontOfSize:14];
        _statusLabel.textColor = UIColor.blackColor;
        _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _statusLabel;
}

- (UIButton *)startButton {
    if (!_startButton) {
        _startButton = [[UIButton alloc] init];
        _startButton.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _startButton;
}

- (NEGrowingTextView *)showTranslateContentText {
    if (!_showTranslateContentText) {
        _showTranslateContentText = [[NEGrowingTextView alloc] init];
        _showTranslateContentText.font = [UIFont systemFontOfSize:14];
        _showTranslateContentText.contentInset = UIEdgeInsetsZero;
        _showTranslateContentText.textColor = UIColor.ne_darkText;
        _showTranslateContentText.clipsToBounds = YES;
        _showTranslateContentText.backgroundColor = UIColor.clearColor;
        _showTranslateContentText.returnKeyType = UIReturnKeySend;
        _showTranslateContentText.editable = NO;
        _showTranslateContentText.delegate = self;
        _showTranslateContentText.maxNumberOfLines = 3;
    }
    return _showTranslateContentText;
}

- (UIImageView *)loadingImageView {
    if (!_loadingImageView) {
        _loadingImageView = [[UIImageView alloc] init];
        _loadingImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _loadingImageView;
}

- (UIView *)loadingAnimationView {
    if (!_loadingAnimationView) {
        _loadingAnimationView = [[NELottieAnimationView alloc] initWithName:@"ne_loading_data" bundle:chatBundle()];
        _loadingAnimationView.translatesAutoresizingMaskIntoConstraints = NO;
        ((NELottieAnimationView *)_loadingAnimationView).loopMode = LottieLoopModeLoop;
        _loadingAnimationView.contentMode = UIViewContentModeScaleAspectFill;
        _loadingAnimationView.accessibilityIdentifier = @"id.loadingView";
        _loadingAnimationView.hidden = YES;
    }
    return _loadingAnimationView;
}

- (void)setCurrentLanguage:(NSString *)currentLanguage {
    NSString *oldValue = _currentLanguage;
    _currentLanguage = currentLanguage;
    if (![oldValue isEqualToString:currentLanguage]) {
        if (currentLanguage.length > 0) {
            NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
            [userDefault setValue:currentLanguage forKey:[NSString stringWithFormat:@"%@_language", [[IMKitClient instance] account]]];
            [userDefault synchronize];
        }
        if (currentLanguage.length > 0) {
            self.shortLanguageLabel.text = [currentLanguage substringToIndex:1];
            [self changeToIdleState:YES];
        } else {
            self.shortLanguageLabel.text = nil;
        }
    }
}

- (void)setupTranslateLanguageUI {
    self.backgroundColor = UIColor.ne_backgroundColor;
    self.clipsToBounds = YES;
    _translateState = TranslateStateIdle;

    [self addSubview:self.shortLanguageBgView];
    [self addSubview:self.shortLanguageLabel];
    [self addSubview:self.switchLanguageButton];
    [self addSubview:self.closeImageView];
    [self addSubview:self.closeButton];
    [self addSubview:self.separatorLine];
    [self addSubview:self.statusLabel];
    [self addSubview:self.loadingAnimationView];
    [self addSubview:self.showTranslateContentText];
    [self addSubview:self.startButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.shortLanguageLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:20],
        [self.shortLanguageLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:10],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.shortLanguageBgView.leftAnchor constraintEqualToAnchor:self.shortLanguageLabel.leftAnchor constant:-8],
        [self.shortLanguageBgView.rightAnchor constraintEqualToAnchor:self.shortLanguageLabel.rightAnchor constant:8],
        [self.shortLanguageBgView.topAnchor constraintEqualToAnchor:self.shortLanguageLabel.topAnchor constant:-2],
        [self.shortLanguageBgView.bottomAnchor constraintEqualToAnchor:self.shortLanguageLabel.bottomAnchor constant:2],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.switchLanguageButton.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.switchLanguageButton.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.switchLanguageButton.bottomAnchor constraintEqualToAnchor:self.shortLanguageLabel.bottomAnchor constant:15],
        [self.switchLanguageButton.rightAnchor constraintEqualToAnchor:self.shortLanguageLabel.rightAnchor constant:12],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.closeImageView.widthAnchor constraintEqualToConstant:20],
        [self.closeImageView.heightAnchor constraintEqualToConstant:20],
        [self.closeImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:7],
        [self.closeImageView.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-12],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.closeButton.widthAnchor constraintEqualToConstant:40],
        [self.closeButton.heightAnchor constraintEqualToConstant:40],
        [self.closeButton.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.closeButton.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.separatorLine.heightAnchor constraintEqualToConstant:1],
        [self.separatorLine.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:12],
        [self.separatorLine.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-12],
        [self.separatorLine.topAnchor constraintEqualToAnchor:self.topAnchor constant:34],
    ]];
    [NSLayoutConstraint activateConstraints:@[
        [self.statusLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-12],
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.separatorLine.bottomAnchor constant:11],
    ]];

    UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
    if (keyWindow) {
        self.showTranslateContentText.frame = CGRectMake(12, 46, CGRectGetWidth(keyWindow.frame) - 112, 20);
    }

    if ([self.loadingAnimationView isKindOfClass:[NELottieAnimationView class]]) {
        [(NELottieAnimationView *)self.loadingAnimationView play];
    }
    [NSLayoutConstraint activateConstraints:@[
        [self.loadingAnimationView.centerYAnchor constraintEqualToAnchor:self.statusLabel.centerYAnchor constant:-1],
        [self.loadingAnimationView.rightAnchor constraintEqualToAnchor:self.statusLabel.leftAnchor constant:-2],
        [self.loadingAnimationView.widthAnchor constraintEqualToConstant:12],
        [self.loadingAnimationView.heightAnchor constraintEqualToConstant:12],
    ]];

    [NSLayoutConstraint activateConstraints:@[
        [self.startButton.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [self.startButton.topAnchor constraintEqualToAnchor:self.separatorLine.bottomAnchor],
        [self.startButton.heightAnchor constraintEqualToConstant:40],
        [self.startButton.widthAnchor constraintEqualToConstant:66],
    ]];
    [self.startButton addTarget:self action:@selector(didStart) forControlEvents:UIControlEventTouchUpInside];

    NSMutableAttributedString *placeholder = [[NSMutableAttributedString alloc] initWithString:chatLocalizable(@"translate_default")];
    [placeholder addAttribute:NSForegroundColorAttributeName value:[UIColor ne_colorWithHexString:@"#AAAAAA"] range:NSMakeRange(0, placeholder.length)];
    [placeholder addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.0] range:NSMakeRange(0, placeholder.length)];
    self.showTranslateContentText.placeholder = placeholder;

    self.statusLabel.attributedText = [self statusAttributedTextWithString:chatLocalizable(@"translate_sure") appendArrow:NO];

    NSString *languageKey = [NSString stringWithFormat:@"%@_language", [[IMKitClient instance] account]];
    NSString *cacheLanguage = [[NSUserDefaults standardUserDefaults] valueForKey:languageKey];
    if (cacheLanguage.length > 0) {
        self.currentLanguage = cacheLanguage;
    } else if ([NETranslateLanguageManager shared].languageDatas.count > 0) {
        NSString *firstLanguage = [NETranslateLanguageManager shared].languageDatas.firstObject;
        if (firstLanguage.length > 0) {
            self.currentLanguage = firstLanguage;
        }
    }

    [self.closeButton addTarget:self action:@selector(didClickClose) forControlEvents:UIControlEventTouchUpInside];
    [self.switchLanguageButton addTarget:self action:@selector(didClickChange) forControlEvents:UIControlEventTouchUpInside];
}

- (NSMutableAttributedString *)statusAttributedTextWithString:(NSString *)text appendArrow:(BOOL)appendArrow {
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:text ?: @""];
    if (appendArrow) {
        UIImage *attachmentImage = [UIImage ne_imageNamed:@"use_arrow"];
        if (attachmentImage) {
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = attachmentImage;
            attachment.bounds = CGRectMake(0, -2, 10, 13);
            [attributeString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
        }
    }
    [attributeString addAttribute:NSForegroundColorAttributeName value:UIColor.ne_normalTheme range:NSMakeRange(0, attributeString.length)];
    [attributeString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.0] range:NSMakeRange(0, attributeString.length)];
    return attributeString;
}

- (void)updateTranslateContentLayout {
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    if (viewWidth <= 0) {
        viewWidth = CGRectGetWidth(UIApplication.sharedApplication.keyWindow.bounds);
    }
    if (viewWidth <= 0) {
        return;
    }

    CGFloat currentHeight = MAX(20.0, CGRectGetHeight(self.showTranslateContentText.frame));
    self.showTranslateContentText.frame = CGRectMake(12, 47, viewWidth - 112, currentHeight);
    [self.showTranslateContentText updateHeight];
}

- (CGFloat)getCurrentHeight {
    return 70;
}

- (void)didClickClose {
    [self.delegate didCloseClick:self];
    [self changeToIdleState:YES];
}

- (void)didClickChange {
    [self.delegate didSwitchLanguageClick:self.currentLanguage];
}

- (void)didStart {
    if (self.translateState == TranslateStateUse) {
        if (self.showTranslateContentText.text) {
            if ([self.delegate respondsToSelector:@selector(didUseTranslate:)]) {
                [self.delegate didUseTranslate:self.showTranslateContentText.text];
            }
        }
        [self changeToIdleState:YES];
        return;
    }
    if (self.translateState != TranslateStateIdle) return;
    if (self.chatInputText) {
        if (self.chatInputText.attributedText.length > 0) {
            if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
                [UIApplication.sharedApplication.keyWindow endEditing:YES];
                [UIApplication.sharedApplication.keyWindow ne_makeToast:commonLocalizable(@"network_error")];
                return;
            }
            if ([self.delegate respondsToSelector:@selector(didStartClick)]) [self.delegate didStartClick];
            [self changeToTranslatingState];
        } else {
            [self changeToIdleState:YES];
        }
    }
}

- (void)setTranslateContent:(NSString *)content {
    if (self.translateState == TranslateStateTranslating) {
        self.showTranslateContentText.text = content;
        [self changeToUseState];
    }
}

- (void)changeToIdleState:(BOOL)isClearText {
    _translateState = TranslateStateIdle;
    if (isClearText) self.showTranslateContentText.text = @"";
    [self updateTranslateContentLayout];
    self.statusLabel.attributedText = [self statusAttributedTextWithString:chatLocalizable(@"translate_sure") appendArrow:NO];
    self.loadingAnimationView.hidden = YES;
    if ([self.loadingAnimationView isKindOfClass:[NELottieAnimationView class]]) {
        [(NELottieAnimationView *)self.loadingAnimationView stop];
    }
}

- (void)changeToTranslatingState {
    _translateState = TranslateStateTranslating;
    self.statusLabel.attributedText = [self statusAttributedTextWithString:chatLocalizable(@"ai_translating") appendArrow:NO];
    self.loadingAnimationView.hidden = NO;
    if ([self.loadingAnimationView isKindOfClass:[NELottieAnimationView class]]) {
        [(NELottieAnimationView *)self.loadingAnimationView play];
    }
}

- (void)changeToUseState {
    _translateState = TranslateStateUse;
    self.statusLabel.attributedText = [self statusAttributedTextWithString:chatLocalizable(@"translate_use") appendArrow:YES];
    self.loadingAnimationView.hidden = YES;
    if ([self.loadingAnimationView isKindOfClass:[NELottieAnimationView class]]) {
        [(NELottieAnimationView *)self.loadingAnimationView stop];
    }
}

- (void)growingTextView:(id)growingTextView didChangeHeight:(CGFloat)height difference:(CGFloat)difference {
    if (self.frame.size.height < 1) {
        // 首次加载 不需要回调，此时回调将导致外部显示异常
        return;
    }
    self.showTranslateContentText.frame = CGRectMake(12, 47, self.frame.size.width - 112, height);
    if ([self.delegate respondsToSelector:@selector(didChangeViewHeight:changeHeight:)]) {
        [self.delegate didChangeViewHeight:self changeHeight:52 + height];
    }
}

@end
