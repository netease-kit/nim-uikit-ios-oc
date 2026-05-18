// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunAIRobotDetailController.h"
#import "FunContactUIColor.h"
#import <NEChatKitOC/UIColor+NECommon.h>

static NSInteger const kNEFunAIRobotDetailSeparatorTag = 8311;

@implementation FunAIRobotDetailController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.avatarView.layer.cornerRadius = [self avatarCornerRadius];
  self.avatarView.clipsToBounds = YES;
}

- (UIColor *)pageBackgroundColor {
  return [UIColor funContactNavigationBackgroundColor];
}

- (CGFloat)cardHorizontalMargin {
  return 0.0;
}

- (CGFloat)headerTopMargin {
  return 0.0;
}

- (CGFloat)headerHeight {
  return 82.0;
}

- (CGFloat)avatarSize {
  return 50.0;
}

- (CGFloat)avatarCornerRadius {
  return 5.0;
}

- (CGFloat)sectionSpacing {
  return 8.0;
}

- (CGFloat)rowHeight {
  return 56.0;
}

- (CGFloat)chatSeparatorHeight {
  return 8.0;
}

- (CGFloat)chatRowHeight {
  return 56.0;
}

- (CGFloat)deleteSeparatorHeight {
  return 0.0;
}

- (CGFloat)deleteRowHeight {
  return 56.0;
}

- (UIColor *)chatTextColor {
  return [UIColor funContactUserViewChatTitleTextColor];
}

- (UIFont *)chatLabelFont {
  return [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
}

- (UIFont *)deleteLabelFont {
  return [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
}

- (UIColor *)confirmButtonColor {
  return [UIColor funContactThemeColor];
}

- (void)setupHeaderStyle {
  self.headerView.layer.cornerRadius = 0.0;
  self.headerView.clipsToBounds = NO;
  self.headerView.layer.shadowColor = [UIColor funContactLineBorderColor].CGColor;
  self.headerView.layer.shadowOffset = CGSizeMake(0, 0.5);
  self.headerView.layer.shadowRadius = 0.0;
  self.headerView.layer.shadowOpacity = 1.0;
  self.headerView.layer.masksToBounds = NO;
}

- (void)setupTableStyle {
  self.tableView.layer.cornerRadius = 0.0;
  self.tableView.clipsToBounds = NO;
  self.tableView.backgroundColor = [UIColor clearColor];
}

- (void)setupChatRowStyle {
  self.chatRowView.layer.cornerRadius = 0.0;
  self.chatRowView.clipsToBounds = NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AIRobotDetailCell" forIndexPath:indexPath];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.backgroundColor = [UIColor whiteColor];
  cell.textLabel.text = indexPath.row < self.operationTitles.count ? self.operationTitles[indexPath.row] : @"";
  cell.textLabel.font = [UIFont systemFontOfSize:16.0];
  cell.textLabel.textColor = [UIColor ne_darkText];
  cell.accessoryType = UITableViewCellAccessoryNone;
  cell.accessoryView = [self makeArrowView];
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  UIView *oldSeparator = [cell.contentView viewWithTag:kNEFunAIRobotDetailSeparatorTag];
  [oldSeparator removeFromSuperview];

  UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(16.0,
                                                               [self rowHeight] - 0.5,
                                                               tableView.bounds.size.width - 16.0,
                                                               0.5)];
  separator.backgroundColor = [UIColor funContactLineBorderColor];
  separator.tag = kNEFunAIRobotDetailSeparatorTag;
  [cell.contentView addSubview:separator];
}

@end
