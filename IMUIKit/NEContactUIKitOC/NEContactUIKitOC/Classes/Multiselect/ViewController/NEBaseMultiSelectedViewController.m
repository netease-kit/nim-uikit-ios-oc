// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import "NEBaseMultiSelectedViewController.h"
#import "ContactConst.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation NEBaseMultiSelectedViewController

- (instancetype)initWithSelectedArray:(NSArray<MultiSelectModel *> *)selectedArray {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _selectedArray = [selectedArray mutableCopy];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
  [self commonUI];
  [self changeLanguage];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupTitle {
  self.navigationController.navigationBarHidden = YES;
  self.navigationView.hidden = YES;

  [self.view addSubview:self.cancelButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.cancelButton.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [self.cancelButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:16],
    [self.cancelButton.widthAnchor constraintEqualToConstant:[NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 60 : 40],
    [self.cancelButton.heightAnchor constraintEqualToConstant:18],
  ]];

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  titleLabel.text = contactLocalizable(@"selected");
  titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
  titleLabel.textAlignment = NSTextAlignmentCenter;
  titleLabel.textColor = [UIColor ne_darkText];
  [self.view addSubview:titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [titleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:16],
    [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [titleLabel.heightAnchor constraintEqualToConstant:18],
  ]];
}

- (void)commonUI {
  self.view.backgroundColor = [UIColor whiteColor];
  [self setupTitle];

  [self.view addSubview:self.tableView];
  self.tableViewTopAnchor = [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:58];
  self.tableViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-80],
  ]];

  [self.tableView registerClass:[NEBaseSelectedListCell class] forCellReuseIdentifier:NSStringFromClass([NEBaseSelectedListCell class])];

  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:-60],
    [self.emptyView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.emptyView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
  ]];
}

- (void)changeLanguage {
  self.emptyView.message = commonLocalizable(@"no_content");
  [self.cancelButton setTitle:commonLocalizable(@"cancel") forState:UIControlStateNormal];
}

- (void)cancelButtonClick {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.selectedArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  MultiSelectModel *model = self.selectedArray[indexPath.row];
  NEBaseSelectedListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NEBaseSelectedListCell class]) forIndexPath:indexPath];
  [cell setModel:model];
  cell.delegate = self;
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 62;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  MultiSelectModel *model = self.selectedArray[indexPath.row];
  NSLog(@"didSelectRowAt: %@", model);
}

#pragma mark - NEBaseSelectedListCellDelegate

- (void)removeButtonAction:(MultiSelectModel *)model {
  [self.selectedArray removeObject:model];
  self.emptyView.hidden = self.selectedArray.count > 0;
  [self.tableView reloadData];
  [self.delegate removeButtonAction:model];
}

#pragma mark - Lazy Init

- (ExpandButton *)cancelButton {
  if (!_cancelButton) {
    _cancelButton = [[ExpandButton alloc] init];
    _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    _cancelButton.accessibilityIdentifier = @"id.cancel";
    [_cancelButton setTitle:commonLocalizable(@"cancel") forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[UIColor ne_greyText] forState:UIControlStateNormal];
    _cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
  }
  return _cancelButton;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _tableView.estimatedRowHeight = 0;
    _tableView.estimatedSectionHeaderHeight = 0;
    _tableView.estimatedSectionFooterHeight = 0;
    if (@available(iOS 15.0, *)) {
      _tableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _tableView;
}

- (NSMutableArray<MultiSelectModel *> *)selectedArray {
  if (!_selectedArray) {
    _selectedArray = [NSMutableArray array];
  }
  return _selectedArray;
}

@end
