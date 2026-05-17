// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TopMessageViewDelegate <NSObject>
- (void)didClickCloseButton;
- (void)didTapTopMessageView;
@end

@interface TopMessageView : UIView

@property (nonatomic, weak, nullable) id<TopMessageViewDelegate> delegate;
@property (nonatomic, strong, nullable) NSLayoutConstraint *topContentLabelLeftAnchor;
@property (nonatomic, copy, nullable) NSString *content;
@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) UIImageView *thumbImageView;
@property (nonatomic, strong) UIImageView *playIcon;
@property (nonatomic, strong) UILabel *topContentLabel;
@property (nonatomic, strong) UIButton *closeButton;

- (void)setTopContentWithName:(nullable NSString *)name content:(nullable NSString *)content url:(nullable NSString *)url isVideo:(BOOL)isVideo hideClose:(BOOL)hideClose;
- (void)updateTopName:(nullable NSString *)name;

@end

NS_ASSUME_NONNULL_END
