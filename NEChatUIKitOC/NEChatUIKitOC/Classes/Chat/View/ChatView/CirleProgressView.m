// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "CirleProgressView.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@interface CirleProgressView ()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation CirleProgressView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        _imageView = [[UIImageView alloc] initWithImage:[UIImage ne_imageNamed:@"chat_unread"]];
        _imageView.frame = self.bounds;
        _imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:_imageView];

        UIBezierPath *borderPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(frame.size.width / 2.0, frame.size.height / 2.0)
                                                                   radius:8
                                                               startAngle:0
                                                                 endAngle:2 * M_PI
                                                                clockwise:NO];
        _borderLayer = [[CAShapeLayer alloc] init];
        _borderLayer.path = borderPath.CGPath;
        _borderLayer.strokeColor = UIColor.ne_defaultPrimaryColor.CGColor;
        _borderLayer.fillColor = UIColor.clearColor.CGColor;
        _borderLayer.lineWidth = 2;
        _borderLayer.frame = self.bounds;
        [self.layer addSublayer:_borderLayer];

        _sectorLayer = [[CAShapeLayer alloc] init];
        _sectorLayer.frame = self.bounds;
        _sectorLayer.fillColor = UIColor.ne_defaultPrimaryColor.CGColor;
        [self.layer addSublayer:_sectorLayer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)setProgress:(float)progress {
    _progress = progress;
    if (progress == 0) {
        _borderLayer.hidden = YES;
        _sectorLayer.hidden = YES;
        _imageView.hidden = NO;
        _imageView.image = [UIImage ne_imageNamed:@"chat_unread"];
    } else if (progress == 1.0) {
        _borderLayer.hidden = YES;
        _sectorLayer.hidden = YES;
        _imageView.hidden = NO;
        _imageView.image = [UIImage ne_imageNamed:@"chat_read_all"];
    } else {
        _imageView.hidden = YES;
        _borderLayer.hidden = NO;
        _sectorLayer.hidden = NO;
        [self drawCircleWithProgress:progress];
    }
}

- (void)drawCircleWithProgress:(float)progress {
    CGPoint center = CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0);
    float start = -M_PI / 2.0;
    float end = start + (progress * 2 * M_PI);
    UIBezierPath *sectorPath = [UIBezierPath bezierPathWithArcCenter:center
                                                               radius:8
                                                           startAngle:start
                                                             endAngle:end
                                                            clockwise:YES];
    [sectorPath addLineToPoint:center];
    _sectorLayer.path = sectorPath.CGPath;
}

@end
