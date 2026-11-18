// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEBaseMultiSelectViewController.h"
#import <NEBaseUIKitOC/SearchTextField.h>
#import "ContactConst.h"
#import "NormalContactUIColor.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>



#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKit.h>

static NSString * const NEForwardMultiSelectedRouterCompat = @"imkit://contact/tab/selector.result";

@interface NEBaseMultiSelectViewController ()
@property (nonatomic, strong, readwrite) MultiSelectViewModel *viewModel;
@property (nonatomic, strong) UILabel *recentLabel;
@end

@implementation NEBaseMultiSelectViewController

- (instancetype)initWithFilterUsers:(NSSet<NSString *> *)filterUsers {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _filterUsers = filterUsers;
    _limit = 9;
    _selectedContentViewHeight = 59;
    _recentContentViewHeight = 145;
    _themeColor = [UIColor ne_defaultPrimaryColor];
    _titleText = contactLocalizable(@"select");
    _sureButtonText = commonLocalizable(@"sure");
    _selectedArray = [NSMutableArray array];
    _recentArray = [NSMutableArray array];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  self.view.layer.cornerRadius = 8;
  self.view.layer.borderWidth = 0.2;
  self.view.layer.borderColor = [UIColor lightGrayColor].CGColor;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
  [self setupUI];
  [self changeLanguage];
  self.currentTableView = self.recentTableView;
  [self loadAllData];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptivePresentationDidChange" object:self];
}

- (void)loadAllData {
  __weak typeof(self) weakSelf = self;
  [self.viewModel loadAllData:self.filterUsers completion:^(NSError * _Nullable error) {
    [weakSelf setEmptyViewText:weakSelf.searchText];

    if (weakSelf.viewModel.sessions) {
      weakSelf.emptyView.hidden = weakSelf.viewModel.sessions.count > 0;
      [weakSelf.currentTableView reloadData];
    }

    NSArray<MultiSelectModel *> *recentSessions = [weakSelf.viewModel loadRecentForward];
    if (recentSessions && recentSessions.count > 0) {
      weakSelf.recentArray = [recentSessions mutableCopy];
      [weakSelf.recentCollectionView reloadData];
    } else {
      weakSelf.recentContentView.hidden = YES;
      weakSelf.recentContentViewHeightAnchor.constant = 16;
    }
  }];
}

- (void)loadData:(NSInteger)index {
  __weak typeof(self) weakSelf = self;
  [self.viewModel loadDataAtIndex:index filters:self.filterUsers completion:^(NSError * _Nullable error) {
    [weakSelf.viewModel searchText:weakSelf.searchText ?: @""];
    [weakSelf setEmptyViewText:weakSelf.searchText];
    [weakSelf.currentTableView reloadData];
    weakSelf.emptyView.hidden = weakSelf.viewModel.sessions.count > 0;
  }];
}

- (void)setupTitle {
  self.navigationController.navigationBarHidden = YES;
  self.navigationView.hidden = YES;

  [self.view addSubview:self.cancelButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.cancelButton.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [self.cancelButton.widthAnchor constraintEqualToConstant:40],
    [self.cancelButton.heightAnchor constraintEqualToConstant:32],
  ]];

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  titleLabel.text = self.titleText;
  titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
  titleLabel.textAlignment = NSTextAlignmentCenter;
  titleLabel.textColor = [UIColor ne_darkText];
  [self.view addSubview:titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [titleLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
    [titleLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [titleLabel.heightAnchor constraintEqualToConstant:18],
    [self.cancelButton.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
  ]];

  [self.view addSubview:self.multiSelectButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.multiSelectButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [self.multiSelectButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
    [self.multiSelectButton.widthAnchor constraintEqualToConstant:[NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 100 : 40],
    [self.multiSelectButton.heightAnchor constraintEqualToConstant:18],
  ]];

  [self.view addSubview:self.sureButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.sureButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [self.sureButton.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
    [self.sureButton.widthAnchor constraintEqualToConstant:[NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 100 : 76],
    [self.sureButton.heightAnchor constraintEqualToConstant:32],
  ]];
}

- (void)changeLanguage {
  self.titleText = contactLocalizable(@"select");
  self.sureButtonText = commonLocalizable(@"sure");
  self.searchTextField.placeholder = commonLocalizable(@"search");
  self.recentLabel.text = contactLocalizable(@"recent_forward");
  [self.cancelButton setTitle:nil forState:UIControlStateNormal];
  [self.cancelButton setImage:[CommonUIConfig shared].backArrowImage forState:UIControlStateNormal];
  self.cancelButton.accessibilityLabel = commonLocalizable(@"cancel");
  [self.multiSelectButton setTitle:contactLocalizable(@"multi_select") forState:UIControlStateNormal];
  [self.recentButton setTitle:contactLocalizable(@"recent_session") forState:UIControlStateNormal];
  [self.friendButton setTitle:contactLocalizable(@"my_friends") forState:UIControlStateNormal];
  [self.teamButton setTitle:contactLocalizable(@"my_teams") forState:UIControlStateNormal];
  [self refreshSelectCount];
  [self setEmptyViewText:self.searchText];
}

- (void)setupUI {
  [self setupTitle];

  [self.view addSubview:self.searchTextField];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchTextField.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:58],
    [self.searchTextField.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [self.searchTextField.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [self.searchTextField.heightAnchor constraintEqualToConstant:32],
  ]];

  [self.view addSubview:self.selectedContentView];
  self.selectedContentViewHeightAnchor = [self.selectedContentView.heightAnchor constraintEqualToConstant:0];
  self.selectedContentViewHeightAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.selectedContentView.topAnchor constraintEqualToAnchor:self.searchTextField.bottomAnchor],
    [self.selectedContentView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [self.selectedContentView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
  ]];

  [self.view addSubview:self.recentContentView];
  self.recentContentViewHeightAnchor = [self.recentContentView.heightAnchor constraintEqualToConstant:self.recentContentViewHeight];
  self.recentContentViewHeightAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.recentContentView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [self.recentContentView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [self.recentContentView.topAnchor constraintEqualToAnchor:self.selectedContentView.bottomAnchor],
  ]];

  [self.view addSubview:self.sessionContentView];
  [NSLayoutConstraint activateConstraints:@[
    [self.sessionContentView.topAnchor constraintEqualToAnchor:self.recentContentView.bottomAnchor],
    [self.sessionContentView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.sessionContentView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.sessionContentView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

#pragma mark - Action

- (void)searchTextFieldChange:(SearchTextField *)textfield {
  NSString *searchText = textfield.text;
  if (!searchText) return;

  self.searchText = searchText;
  self.recentContentView.hidden = self.recentArray.count == 0 || searchText.length > 0;
  self.recentContentViewHeightAnchor.constant = self.recentContentView.hidden ? 16 : self.recentContentViewHeight;

  if (searchText.length == 0) {
    [self loadData:self.tabIndex];
    return;
  }

  UITextRange *textRange = textfield.markedTextRange;
  if (!textRange || textRange.isEmpty) {
    [self loadData:self.tabIndex];
  }
}

- (void)searchTextFieldChangeWithTextfield:(SearchTextField *)textfield {
  [self searchTextFieldChange:textfield];
}

- (void)multiSelectButtonAction:(UIButton *)sender {
  self.isMultiSelect = YES;
  self.multiSelectButton.hidden = YES;
  self.sureButton.hidden = NO;
  [self notifyRailActionsChanged];
  [self.recentCollectionView reloadData];
  [self.currentTableView reloadData];
}

- (void)sureButtonAction {
  NSMutableArray *conversationJSONs = [NSMutableArray array];
  for (MultiSelectModel *model in self.selectedArray) {
    NSMutableDictionary *conversationJSON = [NSMutableDictionary dictionary];
    conversationJSON[@"conversationId"] = model.conversationId;
    conversationJSON[@"name"] = model.name;
    conversationJSON[@"avatar"] = model.avatar;
    [conversationJSONs addObject:conversationJSON];
  }

  [[Router shared] use:NEForwardMultiSelectedRouterCompat parameters:@{@"conversations": conversationJSONs} closure:nil];
  [self cancelButtonAction];
}

- (void)cancelButtonAction {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (NEBaseMultiSelectedViewController *)getMultiSelectedViewController:(NSArray<MultiSelectModel *> *)selectedArray {
  return [[NEBaseMultiSelectedViewController alloc] initWithSelectedArray:selectedArray];
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent
                     animated:(BOOL)flag
                   completion:(void (^)(void))completion {
  BOOL isSelectedPage = self.usesAdaptiveContainerPresentation &&
                        [viewControllerToPresent isKindOfClass:[NEBaseMultiSelectedViewController class]];
  if (isSelectedPage) {
    self.definesPresentationContext = YES;
    viewControllerToPresent.modalPresentationStyle = UIModalPresentationOverCurrentContext;
  }
  __weak typeof(self) weakSelf = self;
  [super presentViewController:viewControllerToPresent
                      animated:flag
                    completion:^{
                      if (completion) {
                        completion();
                      }
                      __strong typeof(weakSelf) self = weakSelf;
                      if (!self || !isSelectedPage || !viewControllerToPresent.isViewLoaded) {
                        return;
                      }
                      viewControllerToPresent.view.frame = self.view.bounds;
                      [viewControllerToPresent.view setNeedsLayout];
                      [viewControllerToPresent.view layoutIfNeeded];
                    }];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  UIViewController *presented = self.presentedViewController;
  if (!self.usesAdaptiveContainerPresentation || !presented.isViewLoaded) {
    return;
  }
  CGRect target = self.view.bounds;
  if (!CGRectEqualToRect(presented.view.frame, target)) {
    presented.view.frame = target;
    [presented.view setNeedsLayout];
    [presented.view layoutIfNeeded];
  }
}

- (void)selectedCollectionViewAction {
  NEBaseMultiSelectedViewController *selectedVC = [self getMultiSelectedViewController:self.selectedArray];
  selectedVC.delegate = self;
  [self presentViewController:selectedVC animated:YES completion:nil];
}

- (void)setTabButtonLine:(NSInteger)index {
  self.tabIndex = index;
  self.selectedLineLeftAnchor.constant = self.recentButton.frame.size.width * index;

  NSInteger i = 0;
  for (UIView *view in self.tabContentView.subviews) {
    if ([view isKindOfClass:[UIButton class]]) {
      ((UIButton *)view).selected = (i == index);
      i++;
    }
  }

  NSInteger j = 0;
  for (UIView *view in self.tableViewContentView.subviews) {
    if ([view isKindOfClass:[UITableView class]]) {
      if (j == index) {
        self.currentTableView = (UITableView *)view;
      }
      view.hidden = (j != index);
      j++;
    }
  }

  [UIView animateWithDuration:0.5 animations:^{
    [self.view layoutIfNeeded];
  }];

  [self loadData:index];
}

- (void)setEmptyViewText:(NSString *)text {
  if (self.searchText && self.searchText.length > 0) {
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:commonLocalizable(@"no_search_result"), self.searchText]];
    NSRange range = [att.mutableString rangeOfString:self.searchText];
    [att addAttribute:NSForegroundColorAttributeName value:self.themeColor range:range];
    self.emptyView.message = att.string;
    return;
  }

  switch (self.tabIndex) {
    case 1:
      self.emptyView.message = contactLocalizable(@"no_friend");
      break;
    case 2:
      self.emptyView.message = contactLocalizable(@"team_empty");
      break;
    default:
      self.emptyView.message = contactLocalizable(@"session_empty");
      break;
  }
}

- (void)recentButtonAction {
  if (self.tabIndex == 0) return;
  [self setTabButtonLine:0];
}

- (void)friendButtonAction {
  if (self.tabIndex == 1) return;
  [self setTabButtonLine:1];
}

- (void)teamButtonAction {
  if (self.tabIndex == 2) return;
  [self setTabButtonLine:2];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return (tableView == self.currentTableView) ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (tableView == self.currentTableView) ? self.viewModel.sessions.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView == self.currentTableView) {
    MultiSelectModel *info = self.viewModel.sessions[indexPath.row];
    NEBaseSelectCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NEBaseSelectCell class]) forIndexPath:indexPath];
    [cell showSelect:self.isMultiSelect];
    [cell setModel:info];
    cell.searchText = self.searchText;
    return cell;
  }
  return [[UITableViewCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  MultiSelectModel *info = self.viewModel.sessions[indexPath.row];
  if (info.isSelected) {
    [self didUnselectContact:info];
  } else {
    if ((NSInteger)self.selectedArray.count >= self.limit) {
      [self.view ne_makeToast:[NSString stringWithFormat:contactLocalizable(@"choose_max_limit"), (long)self.limit]];
      return;
    }
    [self didSelectContact:info];
  }
  [self.view endEditing:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  [self.view endEditing:YES];
}

#pragma mark - Collection View

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (collectionView == self.recentCollectionView) return self.recentArray.count;
  if (collectionView == self.selectedCollectionView) return self.selectedArray.count;
  return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (collectionView == self.recentCollectionView) {
    return CGSizeMake(72, self.isMultiSelect ? 84 : 60);
  } else if (collectionView == self.selectedCollectionView) {
    return CGSizeMake(46, self.selectedContentViewHeight);
  }
  return CGSizeZero;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  MultiSelectModel *contactInfo = [[MultiSelectModel alloc] init];
  if (collectionView == self.recentCollectionView) {
    contactInfo = self.recentArray[indexPath.row];
  } else if (collectionView == self.selectedCollectionView) {
    contactInfo = self.selectedArray[indexPath.row];
  }

  NEBaseSelectedCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([NEBaseSelectedCell class]) forIndexPath:indexPath];
  [cell configure:contactInfo];

  if ([cell isKindOfClass:[NEBaseRecentSelectCell class]]) {
    [(NEBaseRecentSelectCell *)cell showSelect:self.isMultiSelect];
  }

  return cell ?: [[UICollectionViewCell alloc] init];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  MultiSelectModel *contactInfo = [[MultiSelectModel alloc] init];
  if (collectionView == self.recentCollectionView) {
    contactInfo = self.recentArray[indexPath.row];
    if (contactInfo.isSelected) {
      [self didUnselectContact:contactInfo];
    } else {
      [self didSelectContact:contactInfo];
    }
  } else if (collectionView == self.selectedCollectionView) {
    contactInfo = self.selectedArray[indexPath.row];
    [self didUnselectContact:contactInfo];
  }
}

#pragma mark - Select/Unselect

- (void)didSelectContact:(MultiSelectModel *)model {
  model.isSelected = YES;
  BOOL found = NO;
  for (MultiSelectModel *c in self.selectedArray) {
    if (c == model) { found = YES; break; }
  }
  if (!found) {
    [self.selectedArray addObject:model];
    if (!self.isMultiSelect) {
      [self sureButtonAction];
      return;
    }
    if (self.selectedContentViewHeightAnchor.constant <= 0) {
      self.selectedContentView.hidden = NO;
      self.selectedContentViewHeightAnchor.constant = self.selectedContentViewHeight;
    }
  }

  [self.recentCollectionView reloadData];
  [self.selectedCollectionView reloadData];
  [self.currentTableView reloadData];
  [self refreshSelectCount];
}

- (void)didUnselectContact:(MultiSelectModel *)model {
  model.isSelected = NO;
  NSMutableArray *toRemove = [NSMutableArray array];
  for (MultiSelectModel *c in self.selectedArray) {
    if (c == model) [toRemove addObject:c];
  }
  [self.selectedArray removeObjectsInArray:toRemove];
  if (self.selectedArray.count <= 0) {
    self.selectedContentView.hidden = YES;
    self.selectedContentViewHeightAnchor.constant = 0;
  }

  [self.recentCollectionView reloadData];
  [self.selectedCollectionView reloadData];
  [self.currentTableView reloadData];
  [self refreshSelectCount];
}

- (void)refreshSelectCount {
  if (self.selectedArray.count > 0) {
    self.sureButton.enabled = YES;
    [self.sureButton setTitle:[NSString stringWithFormat:@"%@(%lu)", self.sureButtonText, (unsigned long)self.selectedArray.count] forState:UIControlStateNormal];
  } else {
    self.sureButton.enabled = NO;
    [self.sureButton setTitle:self.sureButtonText forState:UIControlStateNormal];
  }
  [self notifyRailActionsChanged];
}

- (void)notifyRailActionsChanged {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"NENavigationViewDidChangeActions"
                                                      object:self];
}

#pragma mark - NEBaseMultiSelectedViewControllerDelegate

- (void)removeButtonAction:(MultiSelectModel *)model {
  if (model) {
    [self didUnselectContact:model];
  }
}

#pragma mark - Lazy Init

- (MultiSelectViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[MultiSelectViewModel alloc] init];
  }
  return _viewModel;
}

- (SearchTextField *)searchTextField {
  if (!_searchTextField) {
    _searchTextField = [[NESingleLineSearchTextField alloc] init];
    UIImageView *leftImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"textField_search_icon"]];
    _searchTextField.contentMode = UIViewContentModeCenter;
    _searchTextField.leftView = leftImageView;
    _searchTextField.leftViewMode = UITextFieldViewModeAlways;
    _searchTextField.placeholder = commonLocalizable(@"search");
    _searchTextField.font = [UIFont systemFontOfSize:14];
    _searchTextField.textColor = [UIColor ne_darkText];
    _searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    _searchTextField.layer.cornerRadius = 8;
    _searchTextField.backgroundColor = [UIColor ne_lightBackgroundColor];
    _searchTextField.clearButtonMode = UITextFieldViewModeAlways;
    _searchTextField.returnKeyType = UIReturnKeySearch;
    [_searchTextField addTarget:self action:@selector(searchTextFieldChange:) forControlEvents:UIControlEventEditingChanged];
    UIButton *clearButton = [_searchTextField valueForKey:@"_clearButton"];
    if ([clearButton isKindOfClass:[UIButton class]]) {
      clearButton.accessibilityIdentifier = @"id.clear";
    }
    _searchTextField.accessibilityIdentifier = @"id.search";
  }
  return _searchTextField;
}

- (UIView *)selectedContentView {
  if (!_selectedContentView) {
    _selectedContentView = [[UIView alloc] init];
    _selectedContentView.translatesAutoresizingMaskIntoConstraints = NO;
    _selectedContentView.backgroundColor = [UIColor clearColor];
    _selectedContentView.hidden = YES;

    [_selectedContentView addSubview:self.selectedCollectionView];
    [NSLayoutConstraint activateConstraints:@[
      [self.selectedCollectionView.centerYAnchor constraintEqualToAnchor:_selectedContentView.centerYAnchor],
      [self.selectedCollectionView.leftAnchor constraintEqualToAnchor:_selectedContentView.leftAnchor constant:-10],
      [self.selectedCollectionView.rightAnchor constraintEqualToAnchor:_selectedContentView.rightAnchor constant:-30],
      [self.selectedCollectionView.heightAnchor constraintEqualToConstant:36],
    ]];

    UIImageView *arrowRight = [[UIImageView alloc] init];
    arrowRight.translatesAutoresizingMaskIntoConstraints = NO;
    arrowRight.image = [coreLoader() loadImage:@"arrow_right"];
    [_selectedContentView addSubview:arrowRight];
    [NSLayoutConstraint activateConstraints:@[
      [arrowRight.centerYAnchor constraintEqualToAnchor:_selectedContentView.centerYAnchor],
      [arrowRight.rightAnchor constraintEqualToAnchor:_selectedContentView.rightAnchor constant:-5],
    ]];

    UIView *dividerLine = [[UIView alloc] init];
    dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
    dividerLine.backgroundColor = [UIColor ne_backcolor];
    [_selectedContentView addSubview:dividerLine];
    [NSLayoutConstraint activateConstraints:@[
      [dividerLine.bottomAnchor constraintEqualToAnchor:_selectedContentView.bottomAnchor],
      [dividerLine.leftAnchor constraintEqualToAnchor:_selectedContentView.leftAnchor constant:-20],
      [dividerLine.rightAnchor constraintEqualToAnchor:_selectedContentView.rightAnchor constant:20],
      [dividerLine.heightAnchor constraintEqualToConstant:3],
    ]];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectedCollectionViewAction)];
    [_selectedContentView addGestureRecognizer:tap];
  }
  return _selectedContentView;
}

- (UICollectionView *)selectedCollectionView {
  if (!_selectedCollectionView) {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    _selectedCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _selectedCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _selectedCollectionView.backgroundColor = [UIColor clearColor];
    _selectedCollectionView.delegate = self;
    _selectedCollectionView.dataSource = self;
    _selectedCollectionView.allowsMultipleSelection = NO;
    _selectedCollectionView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    _selectedCollectionView.accessibilityIdentifier = @"id.selected";
  }
  return _selectedCollectionView;
}

- (UIView *)recentContentView {
  if (!_recentContentView) {
    _recentContentView = [[UIView alloc] init];
    _recentContentView.translatesAutoresizingMaskIntoConstraints = NO;
    _recentContentView.backgroundColor = [UIColor clearColor];

    [_recentContentView addSubview:self.recentLabel];
    [NSLayoutConstraint activateConstraints:@[
      [self.recentLabel.leftAnchor constraintEqualToAnchor:_recentContentView.leftAnchor],
      [self.recentLabel.topAnchor constraintEqualToAnchor:_recentContentView.topAnchor constant:16],
      [self.recentLabel.rightAnchor constraintEqualToAnchor:_recentContentView.rightAnchor],
      [self.recentLabel.heightAnchor constraintEqualToConstant:14],
    ]];

    [_recentContentView addSubview:self.recentCollectionView];
    [NSLayoutConstraint activateConstraints:@[
      [self.recentCollectionView.topAnchor constraintEqualToAnchor:self.recentLabel.bottomAnchor constant:12],
      [self.recentCollectionView.leftAnchor constraintEqualToAnchor:_recentContentView.leftAnchor constant:-12],
      [self.recentCollectionView.rightAnchor constraintEqualToAnchor:_recentContentView.rightAnchor],
      [self.recentCollectionView.heightAnchor constraintEqualToConstant:84],
    ]];

    UIView *dividerLine = [[UIView alloc] init];
    dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
    dividerLine.backgroundColor = [UIColor ne_backcolor];
    [_recentContentView addSubview:dividerLine];
    [NSLayoutConstraint activateConstraints:@[
      [dividerLine.bottomAnchor constraintEqualToAnchor:_recentContentView.bottomAnchor],
      [dividerLine.leftAnchor constraintEqualToAnchor:_recentContentView.leftAnchor constant:-20],
      [dividerLine.rightAnchor constraintEqualToAnchor:_recentContentView.rightAnchor constant:20],
      [dividerLine.heightAnchor constraintEqualToConstant:3],
    ]];
  }
  return _recentContentView;
}

- (UILabel *)recentLabel {
  if (!_recentLabel) {
    _recentLabel = [[UILabel alloc] init];
    _recentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _recentLabel.text = contactLocalizable(@"recent_forward");
    _recentLabel.font = [UIFont systemFontOfSize:12];
    _recentLabel.textColor = [UIColor ne_emptyTitleColor];
  }
  return _recentLabel;
}

- (UICollectionView *)recentCollectionView {
  if (!_recentCollectionView) {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    _recentCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _recentCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _recentCollectionView.backgroundColor = [UIColor clearColor];
    _recentCollectionView.delegate = self;
    _recentCollectionView.dataSource = self;
    _recentCollectionView.allowsMultipleSelection = NO;
    _recentCollectionView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    _recentCollectionView.accessibilityIdentifier = @"id.selected";
  }
  return _recentCollectionView;
}

- (UIView *)tabContentView {
  if (!_tabContentView) {
    _tabContentView = [[UIView alloc] init];
    _tabContentView.translatesAutoresizingMaskIntoConstraints = NO;
    _tabContentView.backgroundColor = [UIColor clearColor];

    CGFloat tabWidthRatio = [IMKitConfigCenter shared].enableTeam ? 1.0 / 3.0 : 1.0 / 2.0;
    NSLayoutConstraint *recentWidthConstraint =
        NEAdaptiveDeviceGate.adaptiveHostActive
            ? [self.recentButton.widthAnchor constraintEqualToAnchor:_tabContentView.widthAnchor multiplier:tabWidthRatio]
            : [self.recentButton.widthAnchor constraintEqualToConstant:[UIScreen mainScreen].bounds.size.width * tabWidthRatio];

    [_tabContentView addSubview:self.recentButton];
    [NSLayoutConstraint activateConstraints:@[
      [self.recentButton.topAnchor constraintEqualToAnchor:_tabContentView.topAnchor],
      [self.recentButton.leftAnchor constraintEqualToAnchor:_tabContentView.leftAnchor],
      [self.recentButton.heightAnchor constraintEqualToConstant:48],
      recentWidthConstraint,
    ]];

    [_tabContentView addSubview:self.friendButton];
    [NSLayoutConstraint activateConstraints:@[
      [self.friendButton.topAnchor constraintEqualToAnchor:self.recentButton.topAnchor],
      [self.friendButton.leftAnchor constraintEqualToAnchor:self.recentButton.rightAnchor],
      [self.friendButton.widthAnchor constraintEqualToAnchor:self.recentButton.widthAnchor],
      [self.friendButton.heightAnchor constraintEqualToAnchor:self.recentButton.heightAnchor],
    ]];

    if ([IMKitConfigCenter shared].enableTeam) {
      [_tabContentView addSubview:self.teamButton];
      [NSLayoutConstraint activateConstraints:@[
        [self.teamButton.topAnchor constraintEqualToAnchor:self.recentButton.topAnchor],
        [self.teamButton.leftAnchor constraintEqualToAnchor:self.friendButton.rightAnchor],
        [self.teamButton.widthAnchor constraintEqualToAnchor:self.recentButton.widthAnchor],
        [self.teamButton.heightAnchor constraintEqualToAnchor:self.recentButton.heightAnchor],
      ]];
    }

    UIView *selectLine = [[UIView alloc] init];
    selectLine.translatesAutoresizingMaskIntoConstraints = NO;
    selectLine.backgroundColor = [UIColor ne_navLineColor];
    [_tabContentView addSubview:selectLine];
    [NSLayoutConstraint activateConstraints:@[
      [selectLine.leftAnchor constraintEqualToAnchor:_tabContentView.leftAnchor],
      [selectLine.rightAnchor constraintEqualToAnchor:_tabContentView.rightAnchor],
      [selectLine.bottomAnchor constraintEqualToAnchor:self.recentButton.bottomAnchor constant:0],
      [selectLine.heightAnchor constraintEqualToConstant:1],
    ]];

    UIView *selectedLine = [[UIView alloc] init];
    selectedLine.translatesAutoresizingMaskIntoConstraints = NO;
    selectedLine.backgroundColor = self.themeColor;
    [_tabContentView addSubview:selectedLine];
    self.selectedLineLeftAnchor = [selectedLine.leftAnchor constraintEqualToAnchor:_tabContentView.leftAnchor];
    [NSLayoutConstraint activateConstraints:@[
      [selectedLine.bottomAnchor constraintEqualToAnchor:self.recentButton.bottomAnchor constant:0],
      [selectedLine.heightAnchor constraintEqualToConstant:2],
      [selectedLine.widthAnchor constraintEqualToAnchor:self.recentButton.widthAnchor],
      self.selectedLineLeftAnchor,
    ]];
  }
  return _tabContentView;
}

- (UITableView *)recentTableView {
  if (!_recentTableView) {
    _recentTableView = [self createTableView];
  }
  return _recentTableView;
}

- (UITableView *)friendTableView {
  if (!_friendTableView) {
    _friendTableView = [self createTableView];
    _friendTableView.hidden = YES;
  }
  return _friendTableView;
}

- (UITableView *)teamTableView {
  if (!_teamTableView) {
    _teamTableView = [self createTableView];
    _teamTableView.hidden = YES;
  }
  return _teamTableView;
}

- (UITableView *)createTableView {
  UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  tableView.translatesAutoresizingMaskIntoConstraints = NO;
  tableView.backgroundColor = [UIColor clearColor];
  tableView.sectionIndexColor = [UIColor ne_greyText];
  tableView.delegate = self;
  tableView.dataSource = self;
  tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
  tableView.estimatedRowHeight = 0;
  tableView.estimatedSectionHeaderHeight = 0;
  tableView.estimatedSectionFooterHeight = 0;
  if (@available(iOS 15.0, *)) {
    tableView.sectionHeaderTopPadding = 0.0;
  }
  return tableView;
}

- (UIView *)tableViewContentView {
  if (!_tableViewContentView) {
    _tableViewContentView = [[UIView alloc] init];
    _tableViewContentView.translatesAutoresizingMaskIntoConstraints = NO;

    [_tableViewContentView addSubview:self.recentTableView];
    [NSLayoutConstraint activateConstraints:@[
      [self.recentTableView.topAnchor constraintEqualToAnchor:_tableViewContentView.topAnchor],
      [self.recentTableView.leftAnchor constraintEqualToAnchor:_tableViewContentView.leftAnchor],
      [self.recentTableView.rightAnchor constraintEqualToAnchor:_tableViewContentView.rightAnchor],
      [self.recentTableView.bottomAnchor constraintEqualToAnchor:_tableViewContentView.bottomAnchor],
    ]];

    [_tableViewContentView addSubview:self.friendTableView];
    [NSLayoutConstraint activateConstraints:@[
      [self.friendTableView.topAnchor constraintEqualToAnchor:_tableViewContentView.topAnchor],
      [self.friendTableView.leftAnchor constraintEqualToAnchor:_tableViewContentView.leftAnchor],
      [self.friendTableView.rightAnchor constraintEqualToAnchor:_tableViewContentView.rightAnchor],
      [self.friendTableView.bottomAnchor constraintEqualToAnchor:_tableViewContentView.bottomAnchor],
    ]];

    [_tableViewContentView addSubview:self.teamTableView];
    [NSLayoutConstraint activateConstraints:@[
      [self.teamTableView.topAnchor constraintEqualToAnchor:_tableViewContentView.topAnchor],
      [self.teamTableView.leftAnchor constraintEqualToAnchor:_tableViewContentView.leftAnchor],
      [self.teamTableView.rightAnchor constraintEqualToAnchor:_tableViewContentView.rightAnchor],
      [self.teamTableView.bottomAnchor constraintEqualToAnchor:_tableViewContentView.bottomAnchor],
    ]];
  }
  return _tableViewContentView;
}

- (UIView *)sessionContentView {
  if (!_sessionContentView) {
    _sessionContentView = [[UIView alloc] init];
    _sessionContentView.translatesAutoresizingMaskIntoConstraints = NO;

    [_sessionContentView addSubview:self.emptyView];
    [NSLayoutConstraint activateConstraints:@[
      [self.emptyView.topAnchor constraintEqualToAnchor:_sessionContentView.topAnchor constant:-40],
      [self.emptyView.bottomAnchor constraintEqualToAnchor:_sessionContentView.bottomAnchor],
      [self.emptyView.leftAnchor constraintEqualToAnchor:_sessionContentView.leftAnchor],
      [self.emptyView.rightAnchor constraintEqualToAnchor:_sessionContentView.rightAnchor],
    ]];

    [_sessionContentView addSubview:self.tabContentView];
    [NSLayoutConstraint activateConstraints:@[
      [self.tabContentView.leftAnchor constraintEqualToAnchor:_sessionContentView.leftAnchor],
      [self.tabContentView.rightAnchor constraintEqualToAnchor:_sessionContentView.rightAnchor],
      [self.tabContentView.topAnchor constraintEqualToAnchor:_sessionContentView.topAnchor],
      [self.tabContentView.heightAnchor constraintEqualToConstant:48],
    ]];

    [_sessionContentView addSubview:self.tableViewContentView];
    [NSLayoutConstraint activateConstraints:@[
      [self.tableViewContentView.topAnchor constraintEqualToAnchor:_sessionContentView.topAnchor constant:48],
      [self.tableViewContentView.leftAnchor constraintEqualToAnchor:_sessionContentView.leftAnchor],
      [self.tableViewContentView.rightAnchor constraintEqualToAnchor:_sessionContentView.rightAnchor],
      [self.tableViewContentView.bottomAnchor constraintEqualToAnchor:_sessionContentView.bottomAnchor],
    ]];
  }
  return _sessionContentView;
}

- (NEUnifiedBackButton *)cancelButton {
  if (!_cancelButton) {
    _cancelButton = [[NEUnifiedBackButton alloc] initWithAccessibilityLabel:commonLocalizable(@"cancel")];
    _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    _cancelButton.accessibilityIdentifier = @"id.cancel";
    [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
  }
  return _cancelButton;
}

- (ExpandButton *)multiSelectButton {
  if (!_multiSelectButton) {
    _multiSelectButton = [[ExpandButton alloc] initWithFrame:CGRectZero];
    _multiSelectButton.translatesAutoresizingMaskIntoConstraints = NO;
    _multiSelectButton.accessibilityIdentifier = @"id.multiSelect";
    [_multiSelectButton setTitle:contactLocalizable(@"multi_select") forState:UIControlStateNormal];
    [_multiSelectButton setTitleColor:[UIColor ne_greyText] forState:UIControlStateNormal];
    _multiSelectButton.titleLabel.font = [UIFont systemFontOfSize:16];
    _multiSelectButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_multiSelectButton addTarget:self action:@selector(multiSelectButtonAction:) forControlEvents:UIControlEventTouchUpInside];
  }
  return _multiSelectButton;
}

- (ExpandButton *)sureButton {
  if (!_sureButton) {
    _sureButton = [[ExpandButton alloc] init];
    _sureButton.translatesAutoresizingMaskIntoConstraints = NO;
    _sureButton.accessibilityIdentifier = @"id.sureButton";
    [_sureButton setTitle:self.sureButtonText forState:UIControlStateNormal];
    [_sureButton setTitleColor:[UIColor ne_defaultPrimaryColor] forState:UIControlStateNormal];
    _sureButton.titleLabel.font = [UIFont systemFontOfSize:16];
    _sureButton.layer.cornerRadius = 4;
    [_sureButton addTarget:self action:@selector(sureButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _sureButton.hidden = YES;
    _sureButton.enabled = NO;
  }
  return _sureButton;
}

- (UIButton *)recentButton {
  if (!_recentButton) {
    _recentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _recentButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [_recentButton setTitle:contactLocalizable(@"recent_session") forState:UIControlStateNormal];
    [_recentButton setTitleColor:[UIColor ne_darkText] forState:UIControlStateNormal];
    [_recentButton setTitleColor:self.themeColor forState:UIControlStateHighlighted];
    [_recentButton setTitleColor:self.themeColor forState:UIControlStateSelected];
    _recentButton.backgroundColor = [UIColor whiteColor];
    _recentButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_recentButton addTarget:self action:@selector(recentButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _recentButton.accessibilityIdentifier = @"id.recentButton";
    _recentButton.selected = YES;
  }
  return _recentButton;
}

- (UIButton *)friendButton {
  if (!_friendButton) {
    _friendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _friendButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [_friendButton setTitle:contactLocalizable(@"my_friends") forState:UIControlStateNormal];
    [_friendButton setTitleColor:[UIColor ne_darkText] forState:UIControlStateNormal];
    [_friendButton setTitleColor:self.themeColor forState:UIControlStateHighlighted];
    [_friendButton setTitleColor:self.themeColor forState:UIControlStateSelected];
    _friendButton.translatesAutoresizingMaskIntoConstraints = NO;
    _friendButton.backgroundColor = [UIColor whiteColor];
    [_friendButton addTarget:self action:@selector(friendButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _friendButton.accessibilityIdentifier = @"id.friendButton";
  }
  return _friendButton;
}

- (UIButton *)teamButton {
  if (!_teamButton) {
    _teamButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _teamButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [_teamButton setTitle:contactLocalizable(@"my_teams") forState:UIControlStateNormal];
    [_teamButton setTitleColor:[UIColor ne_darkText] forState:UIControlStateNormal];
    [_teamButton setTitleColor:self.themeColor forState:UIControlStateHighlighted];
    [_teamButton setTitleColor:self.themeColor forState:UIControlStateSelected];
    _teamButton.translatesAutoresizingMaskIntoConstraints = NO;
    _teamButton.backgroundColor = [UIColor whiteColor];
    [_teamButton addTarget:self action:@selector(teamButtonAction) forControlEvents:UIControlEventTouchUpInside];
    _teamButton.accessibilityIdentifier = @"id.teamButton";
  }
  return _teamButton;
}

@end
