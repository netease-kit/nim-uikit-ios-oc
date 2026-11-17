// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactSelectedViewController.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "ContactSelectedCell.h"
#import "ContactUnCheckCell.h"
#import "ContactSectionView.h"
#import "ContactConst.h"
#import "NormalContactUIColor.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@implementation ContactSelectedViewController

- (instancetype)initWithFilterUsers:(NSSet<NSString *> *)filterUsers {
  self = [super initWithFilterUsers:filterUsers];
  if (self) {
    self.customCells = [@{@(ContactCellTypeContactPerson): [ContactSelectedCell class]} mutableCopy];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setupUI {
  [super setupUI];
  self.view.backgroundColor = [UIColor ne_backcolor];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];

  [self.collectionView registerClass:[ContactUnCheckCell class]
          forCellWithReuseIdentifier:NSStringFromClass([ContactUnCheckCell class])];
  self.tableView.rowHeight = 52;
}

- (void)setupNavRightItem {
  [super setupNavRightItem];
  self.navigationView.moreButton.backgroundColor = [UIColor whiteColor];
  [self.navigationView.moreButton setTitleColor:[UIColor ne_colorWithHexString:@"337EFF"] forState:UIControlStateNormal];
  self.sureButton.backgroundColor = [UIColor whiteColor];
  [self.sureButton setTitleColor:[UIColor ne_colorWithHexString:@"337EFF"] forState:UIControlStateNormal];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  ContactSectionView *sectionView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([ContactSectionView class])];
  sectionView.titleLabel.text = self.viewModel.contactSections[section].initial;
  return sectionView;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  ContactInfo *contactInfo = self.selectArray[indexPath.row];
  ContactUnCheckCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ContactUnCheckCell class])
                                                                       forIndexPath:indexPath];
  [cell configure:contactInfo];
  return cell ?: [[UICollectionViewCell alloc] init];
}

@end
