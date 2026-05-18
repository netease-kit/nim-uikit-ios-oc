// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomContactViewController.h"
#import "CustomContactTableViewCell.h"
#import "CustomView.h"
#import <NEContactUIKitOC/ContactConst.h>
#import <NEContactUIKitOC/ContactInfo.h>
#import <NEContactUIKitOC/ContactSection.h>
#import <NEContactUIKitOC/ContactUIConfig.h>
#import <NEContactUIKitOC/ContactViewModel.h>
#import <NEChatKitOC/NEConstant.h>

@interface CustomContactViewController ()
@property (nonatomic, strong) CustomView *customTopViewInner;
@property (nonatomic, strong) CustomView *customBottomViewInner;
@end

@implementation CustomContactViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  [ContactUIConfig shared].showHeader = NO;
  [ContactUIConfig shared].headerData = ^(__unused NEBaseContactViewController *vc,
                                         NSMutableArray<ContactHeadItem *> *items) {
    if (items.count > 0) {
      ContactHeadItem *item = items.firstObject;
      item.name = @"收到的验证消息";
    }
  };

  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.delegate = self;
    self.cellRegisterDic = [@{
      @(ContactCellTypeContactPerson) : [ContactTableViewCell class],
      @(ContactCellTypeContactOthers) : [ContactTableViewCell class],
      @(ContactCellTypeContactCustom) : [CustomContactTableViewCell class],
    } mutableCopy];
  }
  return self;
}

- (void)searchAction {
  self.bodyTopViewHeight = 80;
  self.bodyBottomViewHeight = 80;
}

- (void)didClickAddBtn {
  self.bodyTopViewHeight = 0;
  self.bodyBottomViewHeight = 0;
}

- (void)onDataLoaded {
  if (self.viewModel.contactSections.count <= 1) {
    return;
  }
  ContactSection *section = self.viewModel.contactSections[1];
  for (ContactInfo *info in section.contacts) {
    info.contactCellType = ContactCellTypeContactCustom;
  }
  [self.tableView reloadData];
}

- (CustomView *)customTopViewInner {
  if (!_customTopViewInner) {
    _customTopViewInner =
        [[CustomView alloc] initWithFrame:CGRectMake(0, 10, NEConstant.screenWidth, 40)];
    _customTopViewInner.backgroundColor = UIColor.blueColor;
  }
  return _customTopViewInner;
}

- (CustomView *)customBottomViewInner {
  if (!_customBottomViewInner) {
    _customBottomViewInner =
        [[CustomView alloc] initWithFrame:CGRectMake(0, 10, NEConstant.screenWidth, 40)];
    _customBottomViewInner.backgroundColor = UIColor.greenColor;
  }
  return _customBottomViewInner;
}

@end
