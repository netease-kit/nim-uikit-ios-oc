// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ChatRecordViewDelegate <NSObject>

- (void)startRecord;
- (void)moveOutView;
- (void)moveInView;
- (void)endRecord:(BOOL)insideView;

@end

@interface ChatRecordView : UIView

@property (nonatomic, weak, nullable) id<ChatRecordViewDelegate> delegate;

- (void)stopRecordAnimation;
- (void)startRecord;
- (void)moveOutView;
- (void)moveInView;
- (void)endRecordWithRecognizer:(UILongPressGestureRecognizer *)recognizer;
- (BOOL)isInRecordViewWithRecognizer:(UILongPressGestureRecognizer *)recognizer;

@end

NS_ASSUME_NONNULL_END
