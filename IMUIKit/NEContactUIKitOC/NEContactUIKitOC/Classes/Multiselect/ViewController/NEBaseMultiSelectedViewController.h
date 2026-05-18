// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEContactBaseViewController.h"
#import "NEBaseSelectedListCell.h"
#import "MultiSelectModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NEBaseMultiSelectedViewControllerDelegate <NSObject>
- (void)removeButtonAction:(nullable MultiSelectModel *)model;
@end

@interface NEBaseMultiSelectedViewController : NEContactBaseViewController <UITableViewDelegate, UITableViewDataSource, NEBaseSelectedListCellDelegate>

@property (nonatomic, strong) NSMutableArray<MultiSelectModel *> *selectedArray;
@property (nonatomic, strong, nullable) NSLayoutConstraint *tableViewTopAnchor;
@property (nonatomic, weak, nullable) id<NEBaseMultiSelectedViewControllerDelegate> delegate;
@property (nonatomic, strong) ExpandButton *cancelButton;
@property (nonatomic, strong) UITableView *tableView;

- (instancetype)initWithSelectedArray:(NSArray<MultiSelectModel *> *)selectedArray;
- (void)commonUI;
- (void)setupTitle;
- (void)cancelButtonClick;

@end

NS_ASSUME_NONNULL_END
