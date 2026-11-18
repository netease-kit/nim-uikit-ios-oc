// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEGrowingTextView.h>

NS_ASSUME_NONNULL_BEGIN

/// 翻译状态枚举
typedef NS_ENUM(NSInteger, TranslateState) {
    TranslateStateIdle = 0,       ///< 空闲
    TranslateStateTranslating,    ///< 处理中
    TranslateStateUse,            ///< 使用
};

@class NEAITranslateView;

@protocol NETranslateViewDelegate <NSObject>

/// 切换语言
- (void)didSwitchLanguageClick:(nullable NSString *)currentLanguage;
/// 关闭
- (void)didCloseClick:(NEAITranslateView *)view;

@optional
/// 高度改变回调
- (void)didChangeViewHeight:(NEAITranslateView *)translateView changeHeight:(CGFloat)changeHeight;
/// 开始翻译
- (void)didStartClick;
/// 点击使用按钮
- (void)didUseTranslate:(NSString *)content;

@end

@interface NEAITranslateView : UIView <NEGrowingTextViewDelegate>

@property (nonatomic, weak, nullable) id<NETranslateViewDelegate> delegate;
@property (nonatomic, weak, nullable) UITextView *chatInputText;
@property (nonatomic, copy) NSString *currentLanguage;
@property (nonatomic, assign) TranslateState translateState;

@property (nonatomic, strong) UILabel *shortLanguageLabel;
@property (nonatomic, strong) UIView *shortLanguageBgView;
@property (nonatomic, strong) UIButton *switchLanguageButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIImageView *closeImageView;
@property (nonatomic, strong) UIView *separatorLine;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIImageView *loadingImageView;
@property (nonatomic, strong) NEGrowingTextView *showTranslateContentText;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIView *loadingAnimationView;

- (void)setupTranslateLanguageUI;
- (CGFloat)getCurrentHeight;
- (void)setTranslateContent:(NSString *)content;
- (void)changeToIdleState:(BOOL)isClearText;
- (void)changeToTranslatingState;
- (void)changeToUseState;
- (void)growingTextView:(id)growingTextView didChangeHeight:(CGFloat)height difference:(CGFloat)difference;

@end

NS_ASSUME_NONNULL_END
