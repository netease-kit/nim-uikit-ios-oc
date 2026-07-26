// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageVideoCell.h"
#import "ChatMessageHelper.h"
#import <AVFoundation/AVFoundation.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <SDWebImage/SDWebImage.h>
#import "MessageVideoModel.h"

static UIImage *NEFunChatVideoCellFirstFrame(NSString *path) {
    if (path.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;

    NSError *error = nil;
    CGImageRef imageRef = [generator copyCGImageAtTime:CMTimeMakeWithSeconds(0, 600)
                                            actualTime:nil
                                                 error:&error];
    if (!imageRef || error) {
        if (imageRef) {
            CGImageRelease(imageRef);
        }
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}

@interface FunChatMessageVideoCell ()
@property (nonatomic, weak) MessageVideoModel *weakModel;
@end

@implementation FunChatMessageVideoCell

- (void)loadVideoCoverIntoImageView:(UIImageView *)contentImageView
                         attachment:(V2NIMMessageVideoAttachment *)videoObject
                            message:(V2NIMMessage *)message {
    NSString *localPath = videoObject.path;
    if (localPath.length == 0) {
        localPath = [ChatMessageHelper createFilePath:message];
    }
    NSString *messageId = message.messageClientId ?: @"";

    __weak typeof(self) weakSelf = self;
    void (^loadLocalFrame)(void) = ^{
        [contentImageView sd_cancelCurrentImageLoad];
        if (localPath.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
            contentImageView.image = nil;
            return;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = NEFunChatVideoCellFirstFrame(localPath);
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *currentMessageId = weakSelf.weakModel.message.messageClientId ?: @"";
                if (messageId.length > 0 && currentMessageId.length > 0 &&
                    ![currentMessageId isEqualToString:messageId]) {
                    return;
                }
                if (image) {
                    contentImageView.image = image;
                }
            });
        });
    };

    NSString *videoUrl = videoObject.url ?: @"";
    NSString *thumbUrl = videoUrl.length > 0 ? [V2NIMStorageUtil videoCoverUrl:videoUrl offset:0] : nil;
    if (thumbUrl.length > 0) {
        [contentImageView sd_setImageWithURL:[NSURL URLWithString:thumbUrl]
                            placeholderImage:nil
                                     options:SDWebImageRetryFailed
                                    progress:nil
                                   completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (!image) {
                loadLocalFrame();
            }
        }];
        return;
    }

    loadLocalFrame();
}

- (void)commonUILeft {
    [super commonUILeft];
    [self.contentImageViewLeft addSubview:self.stateViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.stateViewLeft.centerXAnchor constraintEqualToAnchor:self.contentImageViewLeft.centerXAnchor],
        [self.stateViewLeft.centerYAnchor constraintEqualToAnchor:self.contentImageViewLeft.centerYAnchor],
        [self.stateViewLeft.heightAnchor constraintEqualToConstant:60],
        [self.stateViewLeft.widthAnchor constraintEqualToConstant:60],
    ]];

    [self.contentImageViewLeft addSubview:self.timeViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.timeViewLeft.rightAnchor constraintEqualToAnchor:self.contentImageViewLeft.rightAnchor constant:-7],
        [self.timeViewLeft.bottomAnchor constraintEqualToAnchor:self.contentImageViewLeft.bottomAnchor constant:-7],
    ]];
}

- (void)commonUIRight {
    [super commonUIRight];
    [self.contentImageViewRight addSubview:self.stateViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.stateViewRight.centerXAnchor constraintEqualToAnchor:self.contentImageViewRight.centerXAnchor],
        [self.stateViewRight.centerYAnchor constraintEqualToAnchor:self.contentImageViewRight.centerYAnchor],
        [self.stateViewRight.heightAnchor constraintEqualToConstant:60],
        [self.stateViewRight.widthAnchor constraintEqualToConstant:60],
    ]];

    [self.contentImageViewRight addSubview:self.timeViewRight];
    [NSLayoutConstraint activateConstraints:@[
        [self.timeViewRight.rightAnchor constraintEqualToAnchor:self.contentImageViewRight.rightAnchor constant:-7],
        [self.timeViewRight.bottomAnchor constraintEqualToAnchor:self.contentImageViewRight.bottomAnchor constant:-7],
    ]];
}

- (void)showLeftOrRight:(BOOL)showRight {
    [super showLeftOrRight:showRight];
    self.contentImageViewLeft.hidden = showRight;
    self.timeViewLeft.hidden = showRight;
    self.stateViewLeft.hidden = showRight;
    self.contentImageViewRight.hidden = !showRight;
    self.timeViewRight.hidden = !showRight;
    self.stateViewRight.hidden = !showRight;
}

- (void)setModel:(MessageContentModel *)model isSend:(BOOL)isSend {
    [super setModel:model isSend:isSend];
    UIImageView *contentImageView = isSend ? self.contentImageViewRight : self.contentImageViewLeft;
    UIView *timeView = isSend ? self.timeViewRight : self.timeViewLeft;
    UILabel *timeLabel = isSend ? self.timeLabelRight : self.timeLabelLeft;
    VideoStateView *stateView = isSend ? self.stateViewRight : self.stateViewLeft;
    MessageVideoModel *videoModel = [model isKindOfClass:[MessageVideoModel class]] ? (MessageVideoModel *)model : nil;

    self.weakModel.cell = nil;
    self.weakModel = videoModel;
    self.weakModel.cell = self;

    V2NIMMessageVideoAttachment *videoObject = (V2NIMMessageVideoAttachment *)model.message.attachment;
    if (videoObject) {
        [self loadVideoCoverIntoImageView:contentImageView attachment:videoObject message:model.message];

        if (videoObject.duration > 0) {
            timeView.hidden = NO;
            timeLabel.text = [NSDate ne_getFormatPlayTime:(NSTimeInterval)(videoObject.duration / 1000)];
        } else {
            timeView.hidden = YES;
        }

        if (videoModel) {
            if (videoModel.state == FileStateSuccess) {
                stateView.state = VideoPlayState;
            } else {
                stateView.state = VideoDownloadState;
                [stateView setProgress:(float)videoModel.progress / 100.0];
                if (videoModel.progress >= 100) {
                    videoModel.state = FileStateSuccess;
                }
            }
        }
    }
}

- (void)uploadProgress:(NSUInteger)progress {
    VideoStateView *stateView = self.stateViewLeft.hidden ? self.stateViewRight : self.stateViewLeft;
    [stateView setProgress:(float)progress / 100.0];
}

#pragma mark - Lazy Load

- (VideoStateView *)stateViewLeft {
    if (!_stateViewLeft) {
        _stateViewLeft = [[VideoStateView alloc] init];
        _stateViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _stateViewLeft.backgroundColor = [UIColor clearColor];
    }
    return _stateViewLeft;
}

- (UILabel *)timeLabelLeft {
    if (!_timeLabelLeft) {
        _timeLabelLeft = [[UILabel alloc] init];
        _timeLabelLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabelLeft.textColor = [UIColor whiteColor];
        _timeLabelLeft.font = [UIFont systemFontOfSize:10];
        _timeLabelLeft.textAlignment = NSTextAlignmentCenter;
    }
    return _timeLabelLeft;
}

- (UIView *)timeViewLeft {
    if (!_timeViewLeft) {
        _timeViewLeft = [[UIView alloc] init];
        _timeViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        [_timeViewLeft addSubview:self.timeLabelLeft];
        [NSLayoutConstraint activateConstraints:@[
            [self.timeLabelLeft.leftAnchor constraintEqualToAnchor:_timeViewLeft.leftAnchor constant:4],
            [self.timeLabelLeft.topAnchor constraintEqualToAnchor:_timeViewLeft.topAnchor constant:2],
            [self.timeLabelLeft.rightAnchor constraintEqualToAnchor:_timeViewLeft.rightAnchor constant:-4],
            [self.timeLabelLeft.bottomAnchor constraintEqualToAnchor:_timeViewLeft.bottomAnchor constant:-2],
        ]];
        _timeViewLeft.clipsToBounds = YES;
        _timeViewLeft.layer.cornerRadius = 4.0;
        _timeViewLeft.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    }
    return _timeViewLeft;
}

- (VideoStateView *)stateViewRight {
    if (!_stateViewRight) {
        _stateViewRight = [[VideoStateView alloc] init];
        _stateViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        _stateViewRight.backgroundColor = [UIColor clearColor];
    }
    return _stateViewRight;
}

- (UILabel *)timeLabelRight {
    if (!_timeLabelRight) {
        _timeLabelRight = [[UILabel alloc] init];
        _timeLabelRight.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabelRight.textColor = [UIColor whiteColor];
        _timeLabelRight.font = [UIFont systemFontOfSize:10];
        _timeLabelRight.textAlignment = NSTextAlignmentCenter;
    }
    return _timeLabelRight;
}

- (UIView *)timeViewRight {
    if (!_timeViewRight) {
        _timeViewRight = [[UIView alloc] init];
        _timeViewRight.translatesAutoresizingMaskIntoConstraints = NO;
        [_timeViewRight addSubview:self.timeLabelRight];
        [NSLayoutConstraint activateConstraints:@[
            [self.timeLabelRight.leftAnchor constraintEqualToAnchor:_timeViewRight.leftAnchor constant:4],
            [self.timeLabelRight.topAnchor constraintEqualToAnchor:_timeViewRight.topAnchor constant:2],
            [self.timeLabelRight.rightAnchor constraintEqualToAnchor:_timeViewRight.rightAnchor constant:-4],
            [self.timeLabelRight.bottomAnchor constraintEqualToAnchor:_timeViewRight.bottomAnchor constant:-2],
        ]];
        _timeViewRight.clipsToBounds = YES;
        _timeViewRight.layer.cornerRadius = 4.0;
        _timeViewRight.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
    }
    return _timeViewRight;
}

@end
