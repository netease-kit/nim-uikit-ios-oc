// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEBaseContactTableViewCell.h"

@class ContactInfo;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseContactSelectedCell : NEBaseContactTableViewCell

@property (nonatomic, strong) UIImageView *sImageView;
@property (nonatomic, strong, nullable) ContactInfo *sModel;

@end

NS_ASSUME_NONNULL_END
