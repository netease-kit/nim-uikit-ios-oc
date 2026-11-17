// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatRecordView.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "NEChatUIConstant.h"

@interface ChatRecordView ()
@property (nonatomic, strong) UIImageView *recordImageView;
@property (nonatomic, strong) UILabel *topTipLabel;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, assign) BOOL outView;
@end

@implementation ChatRecordView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)commonUI {
    _topTipLabel = [[UILabel alloc] init];
    _topTipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _topTipLabel.text = chatLocalizable(@"send_after_let_go");
    _topTipLabel.font = [UIFont systemFontOfSize:12];
    _topTipLabel.textColor = UIColor.ne_lightText;
    _topTipLabel.textAlignment = NSTextAlignmentCenter;
    _topTipLabel.hidden = YES;
    [self addSubview:_topTipLabel];
    [NSLayoutConstraint activateConstraints:@[
        [_topTipLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:0],
        [_topTipLabel.heightAnchor constraintEqualToConstant:23],
        [_topTipLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [_topTipLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    ]];

    _recordImageView = [[UIImageView alloc] init];
    _recordImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _recordImageView.image = [UIImage ne_imageNamed:@"chat_record"];
    _recordImageView.contentMode = UIViewContentModeCenter;
    [self addSubview:_recordImageView];
    [NSLayoutConstraint activateConstraints:@[
        [_recordImageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [_recordImageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:40],
        [_recordImageView.heightAnchor constraintEqualToConstant:103],
        [_recordImageView.widthAnchor constraintEqualToConstant:103],
    ]];

    UIImage *image1 = [UIImage ne_imageNamed:@"record_3"];
    UIImage *image2 = [UIImage ne_imageNamed:@"record_2"];
    UIImage *image3 = [UIImage ne_imageNamed:@"record_1"];
    if (image1 && image2 && image3) {
        _recordImageView.animationImages = @[image1, image2, image3];
    }
    _recordImageView.animationDuration = 0.8;
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(clickLabel:)];
    _recordImageView.userInteractionEnabled = YES;
    [_recordImageView addGestureRecognizer:gesture];

    _tipLabel = [[UILabel alloc] init];
    _tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _tipLabel.text = chatLocalizable(@"press_speak");
    _tipLabel.font = [UIFont systemFontOfSize:12];
    _tipLabel.textColor = UIColor.ne_lightText;
    _tipLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_tipLabel];
    [NSLayoutConstraint activateConstraints:@[
        [_tipLabel.topAnchor constraintEqualToAnchor:_recordImageView.bottomAnchor constant:12],
        [_tipLabel.heightAnchor constraintEqualToConstant:23],
        [_tipLabel.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [_tipLabel.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    ]];
}

- (void)clickLabel:(UILongPressGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self startRecord];
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded:
            [self endRecordWithRecognizer:recognizer];
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self endRecordWithRecognizer:recognizer];
            break;
        default:
            break;
    }
}

- (void)stopRecordAnimation {
    _topTipLabel.hidden = YES;
    [_recordImageView stopAnimating];
}

- (void)startRecord {
    _topTipLabel.hidden = NO;
    [_recordImageView startAnimating];
    [self.delegate startRecord];
}

- (void)moveOutView {
    [self.delegate moveOutView];
}

- (void)moveInView {
    [self.delegate moveInView];
}

- (void)endRecordWithRecognizer:(UILongPressGestureRecognizer *)recognizer {
    [self stopRecordAnimation];
    BOOL inView = [self isInRecordViewWithRecognizer:recognizer];
    [self.delegate endRecord:inView];
}

- (BOOL)isInRecordViewWithRecognizer:(UILongPressGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:recognizer.view];
    if (point.x < 0 || point.x > recognizer.view.bounds.size.width ||
        point.y < 0 || point.y > recognizer.view.bounds.size.height) {
        return NO;
    }
    return YES;
}

@end
