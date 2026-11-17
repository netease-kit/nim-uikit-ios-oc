// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import "ChatCellConstantValue.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseChatTeamMemberCell : UITableViewCell

@property (nonatomic, strong) NEUserHeaderView *headerView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIStackView *nameStackView;
@property (nonatomic, strong, readonly) UIColor *searchHighlightColor;
@property (nonatomic, assign, readonly) CGFloat nameHorizontalSpacing;
@property (nonatomic, assign, readonly) CGFloat nameTrailingInset;

- (void)setupUI;
- (void)configure:(NETeamMemberInfoModel *)model;
- (void)configure:(NETeamMemberInfoModel *)model searchResult:(nullable NETeamMemberSearchResult *)searchResult;
- (void)configureAllWithTitle:(NSString *)title;
- (void)configureAllWithTitle:(NSString *)title image:(nullable UIImage *)image;

@end

NS_ASSUME_NONNULL_END
