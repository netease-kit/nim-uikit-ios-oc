// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunContactSelectedViewController.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "FunContactSelectedCell.h"
#import "FunContactUnCheckCell.h"
#import "ContactSectionView.h"
#import "ContactUIConfig.h"
#import "ContactConst.h"
#import "FunContactUIColor.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation FunContactSelectedViewController

- (instancetype)initWithFilterUsers:(NSSet<NSString *> *)filterUsers {
  self = [super initWithFilterUsers:filterUsers];
  if (self) {
    self.customCells = @{@(ContactCellTypeContactPerson): [FunContactSelectedCell class]};
    self.view.backgroundColor = [UIColor funContactBackgroundColor];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setupUI {
  self.collectionBackViewTopAnchor.constant = 12;
  [super setupUI];

  [self.emptyView setEmptyImageName:@"fun_user_empty"];
  self.collectionBackView.backgroundColor = [UIColor whiteColor];
  [self.collectionView registerClass:[FunContactUnCheckCell class]
          forCellWithReuseIdentifier:NSStringFromClass([FunContactUnCheckCell class])];
  self.tableView.rowHeight = 64;
}

- (void)setupNavRightItem {
  [super setupNavRightItem];
  [self.navigationView setBackButtonTitle:contactLocalizable(@"close")];
  [self.navigationView setBackButtonWidth:60];
  [self.navigationView.backButton setTitleColor:[UIColor ne_darkText] forState:UIControlStateNormal];
  self.navigationView.moreButton.backgroundColor = [UIColor funContactThemeColor];
  self.sureButton.backgroundColor = [UIColor funContactThemeColor];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  ContactSectionView *sectionView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([ContactSectionView class])];
  sectionView.titleLabel.textColor = [ContactUIConfig shared].contactProperties.indexTitleColor ?: [UIColor ne_greyText];
  sectionView.line.hidden = YES;
  sectionView.titleLabel.text = self.viewModel.contactSections[section].initial;
  return sectionView;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  ContactInfo *contactInfo = self.selectArray[indexPath.row];
  FunContactUnCheckCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([FunContactUnCheckCell class])
                                                                          forIndexPath:indexPath];
  [cell configure:contactInfo];
  return cell ?: [[UICollectionViewCell alloc] init];
}

@end
