// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEUnderlineFocusView : UIView

@property (nonatomic, strong) UIColor *underlineColor;
@property (nonatomic, assign) CGFloat underlineHeight;
@property (nonatomic, strong, nullable) NSNumber *underlineWidth;
@property (nonatomic, assign) BOOL masksToBounds;
@property (nonatomic, assign) CGFloat cornerRadius;

@end

NS_ASSUME_NONNULL_END
