// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NEMutilSelectBottomViewDelegate <NSObject>
- (void)didClickSingleForwardButton;
- (void)didClickMultiForwardButton;
- (void)didClickDeleteButton;
@end

@interface NEMutilSelectBottomView : UIView

@property (nonatomic, weak, nullable) id<NEMutilSelectBottomViewDelegate> delegate;
@property (nonatomic, strong, nullable) NSLayoutConstraint *buttonTopAnchor;
@property (nonatomic, strong) UIButton *singleForwardButton;
@property (nonatomic, strong) UILabel *singleForwardLabel;
@property (nonatomic, strong) UIButton *multiForwardButton;
@property (nonatomic, strong) UILabel *multiForwardLabel;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UILabel *deleteLabel;

- (void)setupSubview;
- (void)setEnable:(BOOL)enable;
- (void)setLabelColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
