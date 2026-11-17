// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEUserHeaderView.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "NEAdaptiveDeviceGate.h"

@interface NEUserHeaderView ()
@property(nonatomic, strong) NSUUID *avatarRequestIdentifier;
@property(nonatomic, assign) BOOL didSetupUI;
@property(nonatomic, copy) NSString *avatarUID;
@property(nonatomic, copy) NSString *avatarURL;
@property(nonatomic, assign) BOOL avatarLoading;
@end

@implementation NEUserHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  if (self.didSetupUI) return;
  self.didSetupUI = YES;
  self.accessibilityIdentifier = @"id.avatar";
  self.contentMode = UIViewContentModeScaleAspectFill;
  self.userInteractionEnabled = YES;
  self.clipsToBounds = NO;
  self.backgroundColor = [UIColor clearColor];

  [self addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
  ]];
}

- (void)configHeadDataWithHeadUrl:(NSString *)headUrl name:(NSString *)name uid:(NSString *)uid {
  headUrl = [headUrl isKindOfClass:[NSString class]] ? headUrl : nil;
  name = [name isKindOfClass:[NSString class]] ? name : @"";
  uid = [uid isKindOfClass:[NSString class]] ? uid : @"";

  if (![NEAdaptiveDeviceGate adaptiveHostActive]) {
    NSUUID *requestIdentifier = [NSUUID UUID];
    self.avatarRequestIdentifier = requestIdentifier;
    __weak typeof(self) weakSelf = self;
    if (headUrl.length > 0) {
      [self setTitle:@""];
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || ![self.avatarRequestIdentifier isEqual:requestIdentifier]) return;
        [self sd_setImageWithURL:[NSURL URLWithString:headUrl] completed:nil];
      });
      self.backgroundColor = [UIColor clearColor];
    } else {
      NSString *display = name.length > 0 ? name : uid;
      [self setTitle:display];
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || ![self.avatarRequestIdentifier isEqual:requestIdentifier]) return;
        [self sd_setImageWithURL:nil completed:nil];
      });
      self.backgroundColor = [UIColor colorWithString:uid];
    }
    return;
  }

  if (![NSThread isMainThread]) {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf configHeadDataWithHeadUrl:headUrl name:name uid:uid];
    });
    return;
  }

  NSString *avatar = headUrl.length > 0 ? headUrl : nil;
  BOOL sameUID = (self.avatarUID == nil && uid.length == 0) || [self.avatarUID isEqualToString:uid];
  BOOL sameURL = (self.avatarURL == nil && avatar == nil) ||
                 (self.avatarURL != nil && avatar != nil && [self.avatarURL isEqualToString:avatar]);
  if (sameUID && sameURL && avatar != nil && (self.image != nil || self.avatarLoading)) {
    [self setTitle:@""];
    self.backgroundColor = [UIColor clearColor];
    return;
  }

  NSUUID *requestIdentifier = [NSUUID UUID];
  self.avatarRequestIdentifier = requestIdentifier;
  self.avatarUID = uid;
  self.avatarURL = avatar;
  self.avatarLoading = NO;
  [self sd_cancelCurrentImageLoad];
  self.image = nil;

  if (avatar) {
    [self setTitle:@""];
    self.backgroundColor = [UIColor clearColor];
    self.avatarLoading = YES;
    __weak typeof(self) weakSelf = self;
    [self sd_setImageWithURL:[NSURL URLWithString:avatar]
            placeholderImage:nil
                     options:SDWebImageAvoidAutoSetImage
                   completed:^(UIImage *_Nullable image, NSError *_Nullable error,
                               SDImageCacheType cacheType, NSURL *_Nullable imageURL) {
      __strong typeof(weakSelf) self = weakSelf;
      if (!self || ![self.avatarRequestIdentifier isEqual:requestIdentifier]) return;
      self.avatarLoading = NO;
      self.image = image;
    }];
  } else {
    [self setTitle:name.length > 0 ? name : uid];
    self.backgroundColor = [UIColor colorWithString:uid];
  }
}

- (void)configHeadData:(NSString *)headUrl name:(NSString *)name uid:(NSString *)uid {
  [self configHeadDataWithHeadUrl:headUrl name:name uid:uid];
}

- (void)configStaticImage:(UIImage *)image {
  NSUUID *requestIdentifier = [NSUUID UUID];
  self.avatarRequestIdentifier = requestIdentifier;
  __weak typeof(self) weakSelf = self;
  dispatch_block_t applyImage = ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || ![self.avatarRequestIdentifier isEqual:requestIdentifier]) return;
    self.avatarUID = nil;
    self.avatarURL = nil;
    self.avatarLoading = NO;
    [self sd_cancelCurrentImageLoad];
    [self setTitle:@""];
    self.image = image;
    self.backgroundColor = UIColor.clearColor;
  };
  if (NSThread.isMainThread) applyImage();
  else dispatch_async(dispatch_get_main_queue(), applyImage);
}

- (void)setTitle:(NSString *)name {
  if (name.length == 0) {
    self.titleLabel.text = @"";
    return;
  }
  __block NSInteger remaining = 2;
  __block NSUInteger start = name.length;
  [name enumerateSubstringsInRange:NSMakeRange(0, name.length)
                           options:NSStringEnumerationByComposedCharacterSequences | NSStringEnumerationReverse
                        usingBlock:^(__unused NSString *substring,
                                     NSRange substringRange,
                                     __unused NSRange enclosingRange,
                                     BOOL *stop) {
    start = substringRange.location;
    remaining -= 1;
    if (remaining == 0) *stop = YES;
  }];
  self.titleLabel.text = [name substringFromIndex:start];
}

#pragma mark - Lazy

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.font = [UIFont systemFontOfSize:12];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.adjustsFontSizeToFitWidth = YES;
    _titleLabel.accessibilityIdentifier = @"id.noAvatar";
  }
  return _titleLabel;
}

@end
