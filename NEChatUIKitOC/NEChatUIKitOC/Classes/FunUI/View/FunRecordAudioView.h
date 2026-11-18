// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FunRecordAudioView;

@protocol FunChatRecordViewDelegate <NSObject>
- (void)didEndRecord:(FunRecordAudioView *)view;
@end

@interface FunRecordAudioView : UIView

@property (nonatomic, weak, nullable) id<FunChatRecordViewDelegate> delegate;
@property (nonatomic, assign) NSInteger maxDuration;
@property (nonatomic, assign) NSInteger lastTimeDuration;
@property (nonatomic, strong, nullable) NSTimer *timer;
@property (nonatomic, assign) CGFloat maxRecordProgressMargin;
@property (nonatomic, assign) CGFloat minRecordProgressWidth;

@property (nonatomic, strong) UIView *triangleView;
@property (nonatomic, strong) UIView *recordProgressView;
@property (nonatomic, strong) UIImageView *recordGestureArea;
@property (nonatomic, strong) UIImageView *recordCloseImage;
@property (nonatomic, strong) UILabel *releaseToSendLabel;
@property (nonatomic, strong) UILabel *releaseToCancelLabel;
@property (nonatomic, strong) UILabel *lastTimeLabel;

- (void)setupUI;
- (void)changeToCancelStyle;
- (void)changeToNormalStyle;
- (BOOL)isRecordNormalStyle;
- (void)timeCountIncrease;
+ (CGFloat)getGestureHeight;

@end

NS_ASSUME_NONNULL_END
