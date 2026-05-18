// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEBaseContactViewCell.h"
#import "ContactProtocols.h"
#import "ContactConst.h"

@class ContactInfo;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseContactTableViewCell : NEBaseContactViewCell <ContactCellDataProtrol>

@property (nonatomic, assign) ContactCellType contactCellType;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UIView *onlineView;
@property (nonatomic, strong) UIView *bottomLine;

- (void)commonUI;
- (void)initSubviewsLayout;
- (void)setConfig;
- (void)setOnline:(BOOL)online;
- (void)setModel:(ContactInfo *)model;

@end

NS_ASSUME_NONNULL_END
