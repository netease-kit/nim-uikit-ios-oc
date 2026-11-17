// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoBrowserBigImgBackView : UIView

@property (nonatomic, copy, nullable) dispatch_block_t dismissCallBack;
@property (nonatomic, copy, readonly) NSArray<NSString *> *urlArray;
@property (nonatomic, copy, readonly) NSArray<UIImage *> *imgArray;

- (instancetype)initWithUrlArr:(NSArray<NSString *> *)urlArr number:(NSInteger)number;
- (instancetype)initWithImgArr:(NSArray<UIImage *> *)imgArr number:(NSInteger)number;
- (NSInteger)currentIndex;
- (void)dismissPhotoBrowser;
- (void)transformAnimation;

@end

NS_ASSUME_NONNULL_END
