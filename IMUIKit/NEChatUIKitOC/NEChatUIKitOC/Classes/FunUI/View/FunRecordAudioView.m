// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunRecordAudioView.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NECommonUIKitOC/NELottieAnimationView.h>
#import "FunChatUIColor.h"
#import "NEChatUIConstant.h"

@interface FunRecordAudioView ()

@property (nonatomic, assign) NSInteger timeCount;
@property (nonatomic, assign) CGFloat progressWidthIncreaseFactor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *progressWidthConstraint;
@property (nonatomic, strong) NELottieAnimationView *lottieView;
@property (nonatomic, strong) UIView *lottieContentView;

@end

@implementation FunRecordAudioView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _maxDuration = 60;
        _lastTimeDuration = 10;
        _maxRecordProgressMargin = 30.0;
        _minRecordProgressWidth = 165.0;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    CGFloat totalWidth = [UIScreen mainScreen].bounds.size.width - self.maxRecordProgressMargin * 2 - self.minRecordProgressWidth;
    CGFloat delta = self.maxDuration - self.lastTimeDuration;
    self.progressWidthIncreaseFactor = totalWidth / delta;

    self.backgroundColor = [[UIColor funRecordAudioViewBg] colorWithAlphaComponent:0.7];

    [self addSubview:self.recordGestureArea];
    [NSLayoutConstraint activateConstraints:@[
        [self.recordGestureArea.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.recordGestureArea.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [self.recordGestureArea.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.recordGestureArea.heightAnchor constraintEqualToConstant:[FunRecordAudioView getGestureHeight]],
    ]];

    [self addSubview:self.recordCloseImage];
    [NSLayoutConstraint activateConstraints:@[
        [self.recordCloseImage.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.recordCloseImage.centerYAnchor constraintEqualToAnchor:self.recordGestureArea.centerYAnchor constant:-152],
        [self.recordCloseImage.widthAnchor constraintEqualToConstant:88.0],
        [self.recordCloseImage.heightAnchor constraintEqualToConstant:88.0],
    ]];

    [self addSubview:self.releaseToSendLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.releaseToSendLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.releaseToSendLabel.bottomAnchor constraintEqualToAnchor:self.recordGestureArea.topAnchor constant:-16],
    ]];

    [self addSubview:self.releaseToCancelLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.releaseToCancelLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.releaseToCancelLabel.bottomAnchor constraintEqualToAnchor:self.recordCloseImage.topAnchor constant:-16],
    ]];

    [self addSubview:self.recordProgressView];
    self.progressWidthConstraint = [self.recordProgressView.widthAnchor constraintEqualToConstant:self.minRecordProgressWidth];
    [NSLayoutConstraint activateConstraints:@[
        [self.recordProgressView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-354],
        [self.recordProgressView.heightAnchor constraintEqualToConstant:80],
        self.progressWidthConstraint,
        [self.recordProgressView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
    ]];

    [self.recordProgressView addSubview:self.lastTimeLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.lastTimeLabel.centerXAnchor constraintEqualToAnchor:self.recordProgressView.centerXAnchor],
        [self.lastTimeLabel.centerYAnchor constraintEqualToAnchor:self.recordProgressView.centerYAnchor],
    ]];

    [self addSubview:self.lottieView];
    [NSLayoutConstraint activateConstraints:@[
        [self.lottieView.centerXAnchor constraintEqualToAnchor:self.recordProgressView.centerXAnchor],
        [self.lottieView.centerYAnchor constraintEqualToAnchor:self.recordProgressView.centerYAnchor],
        [self.lottieView.widthAnchor constraintEqualToConstant:80],
        [self.lottieView.heightAnchor constraintEqualToConstant:40],
    ]];
    [self.lottieView play];

    [self addSubview:self.triangleView];
    [self insertSubview:self.triangleView belowSubview:self.recordProgressView];
    [NSLayoutConstraint activateConstraints:@[
        [self.triangleView.widthAnchor constraintEqualToConstant:21],
        [self.triangleView.heightAnchor constraintEqualToConstant:21],
        [self.triangleView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.triangleView.topAnchor constraintEqualToAnchor:self.recordProgressView.topAnchor constant:60],
    ]];

    __weak typeof(self) weakSelf = self;
    CGFloat finalWidth = [UIScreen mainScreen].bounds.size.width - self.maxRecordProgressMargin * 2;
    NSTimeInterval animDuration = self.maxDuration - self.lastTimeDuration;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.progressWidthConstraint.constant = finalWidth;
        [UIView animateWithDuration:animDuration animations:^{
            [weakSelf layoutIfNeeded];
        }];
    });

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timeCountIncrease) userInfo:nil repeats:YES];
}

+ (CGFloat)getGestureHeight {
    CGFloat windowWidth = [UIScreen mainScreen].bounds.size.width;
    return windowWidth / 375.0 * 128.0;
}

- (void)changeToCancelStyle {
    if (self.releaseToSendLabel.hidden) return;
    self.recordCloseImage.highlighted = YES;
    self.recordGestureArea.highlighted = YES;
    self.releaseToSendLabel.hidden = YES;
    self.releaseToCancelLabel.hidden = NO;
    self.recordProgressView.backgroundColor = [UIColor funRecordAudioProgressCancelColor];
    self.triangleView.backgroundColor = [UIColor funRecordAudioProgressCancelColor];
}

- (void)changeToNormalStyle {
    if (!self.releaseToSendLabel.hidden) return;
    self.recordCloseImage.highlighted = NO;
    self.recordGestureArea.highlighted = NO;
    self.releaseToSendLabel.hidden = NO;
    self.releaseToCancelLabel.hidden = YES;
    self.recordProgressView.backgroundColor = [UIColor funRecordAudioProgressNormalColor];
    self.triangleView.backgroundColor = [UIColor funRecordAudioProgressNormalColor];
}

- (BOOL)isRecordNormalStyle {
    return !self.releaseToSendLabel.hidden;
}

- (void)timeCountIncrease {
    NSInteger lastTime = self.maxDuration - self.timeCount;
    if (lastTime == 0) {
        [self.timer invalidate];
        self.timer = nil;
        [self.delegate didEndRecord:self];
        return;
    }

    if (self.lastTimeDuration >= lastTime) {
        self.lastTimeLabel.hidden = NO;
        if (self.lottieView.isAnimationPlaying) {
            [self.lottieView stop];
            self.lottieView.hidden = YES;
        }
        self.lastTimeLabel.text = [NSString stringWithFormat:chatLocalizable(@"stop_record"), (long)lastTime];
    }
    self.timeCount++;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview != nil) return;
    if (self.timer.isValid) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - Lazy Load

- (NELottieAnimationView *)lottieView {
    if (!_lottieView) {
        _lottieView = [[NELottieAnimationView alloc] initWithName:@"fun_voice_data" bundle:chatBundle()];
        _lottieView.translatesAutoresizingMaskIntoConstraints = NO;
        _lottieView.loopMode = LottieLoopModeLoop;
        _lottieView.contentMode = UIViewContentModeScaleToFill;
    }
    return _lottieView;
}

- (UIView *)triangleView {
    if (!_triangleView) {
        _triangleView = [[UIView alloc] init];
        _triangleView.translatesAutoresizingMaskIntoConstraints = NO;
        _triangleView.backgroundColor = [UIColor funRecordAudioProgressNormalColor];
        _triangleView.transform = CGAffineTransformMakeRotation(M_PI / 4);
    }
    return _triangleView;
}

- (UIView *)recordProgressView {
    if (!_recordProgressView) {
        _recordProgressView = [[UIView alloc] init];
        _recordProgressView.translatesAutoresizingMaskIntoConstraints = NO;
        _recordProgressView.clipsToBounds = YES;
        _recordProgressView.layer.cornerRadius = 16.0;
        _recordProgressView.backgroundColor = [UIColor funRecordAudioProgressNormalColor];
    }
    return _recordProgressView;
}

- (UIImageView *)recordGestureArea {
    if (!_recordGestureArea) {
        _recordGestureArea = [[UIImageView alloc] init];
        _recordGestureArea.translatesAutoresizingMaskIntoConstraints = NO;
        _recordGestureArea.image = chatLoadImage(@"fun_chat_record_gesture_inner");
        _recordGestureArea.highlightedImage = chatLoadImage(@"fun_chat_record_gesture_outter");
        _recordGestureArea.highlighted = NO;
    }
    return _recordGestureArea;
}

- (UIImageView *)recordCloseImage {
    if (!_recordCloseImage) {
        _recordCloseImage = [[UIImageView alloc] init];
        _recordCloseImage.contentMode = UIViewContentModeCenter;
        _recordCloseImage.translatesAutoresizingMaskIntoConstraints = NO;
        _recordCloseImage.image = chatLoadImage(@"fun_chat_record_close_dark");
        _recordCloseImage.highlightedImage = chatLoadImage(@"fun_chat_record_close_light");
        _recordCloseImage.highlighted = NO;
    }
    return _recordCloseImage;
}

- (UILabel *)releaseToSendLabel {
    if (!_releaseToSendLabel) {
        _releaseToSendLabel = [[UILabel alloc] init];
        _releaseToSendLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _releaseToSendLabel.font = [UIFont systemFontOfSize:16.0];
        _releaseToSendLabel.textColor = [UIColor funRecordAudioTextColor];
        _releaseToSendLabel.text = chatLocalizable(@"release_to_send");
        _releaseToSendLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _releaseToSendLabel;
}

- (UILabel *)releaseToCancelLabel {
    if (!_releaseToCancelLabel) {
        _releaseToCancelLabel = [[UILabel alloc] init];
        _releaseToCancelLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _releaseToCancelLabel.font = [UIFont systemFontOfSize:16.0];
        _releaseToCancelLabel.textColor = [UIColor funRecordAudioTextColor];
        _releaseToCancelLabel.text = chatLocalizable(@"release_to_cancel");
        _releaseToCancelLabel.hidden = YES;
        _releaseToCancelLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _releaseToCancelLabel;
}

- (UILabel *)lastTimeLabel {
    if (!_lastTimeLabel) {
        _lastTimeLabel = [[UILabel alloc] init];
        _lastTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _lastTimeLabel.font = [UIFont systemFontOfSize:18.0];
        _lastTimeLabel.textColor = [UIColor funRecordAudioLastTimeColor];
        _lastTimeLabel.textAlignment = NSTextAlignmentCenter;
        _lastTimeLabel.hidden = YES;
    }
    return _lastTimeLabel;
}

@end
