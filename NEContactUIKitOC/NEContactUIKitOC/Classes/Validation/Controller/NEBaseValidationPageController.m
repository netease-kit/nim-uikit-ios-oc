// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseValidationPageController.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "ContactConst.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/NENavigationView.h>
#import <NEChatKit/IMKitConfigCenter.h>

@interface NEBaseValidationPageController ()
@property(nonatomic, assign) CGFloat validationTabsWidth;
@end

@implementation NEBaseValidationPageController

- (instancetype)init {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _contentControllers = [NSMutableArray array];
    [self getContentControllers];
    _pagingViewController = [[NEPagingViewController alloc] initWithViewControllers:_contentControllers];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _contentControllers = [NSMutableArray array];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
  [self changeLanguage];
  [self initNav];
  [self setupPageContent];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = (self.navigationController.viewControllers.count > 1);
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  for (NEContactBaseViewController *vc in self.contentControllers) {
    [vc viewWillDisappear:animated];
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  if (self.navigationView.superview) {
    [self.view bringSubviewToFront:self.navigationView];
  }
  [self synchronizeValidationTabWidths];
}

- (void)synchronizeValidationTabWidths {
  if (![IMKitConfigCenter shared].enableTeamJoinAgreeModelAuth) return;
  if (!self.pagingViewController || self.contentControllers.count <= 1) return;
  CGFloat width = CGRectGetWidth(self.view.bounds);
  if (width <= 0) return;
  if (fabs(width - self.validationTabsWidth) <= 0.5) return;
  self.validationTabsWidth = width;
  self.pagingViewController.menuItemSize =
      [NEPagingMenuItemSize fixedWidth:width / (CGFloat)self.contentControllers.count height:40];
  [self.pagingViewController.collectionView.collectionViewLayout invalidateLayout];
}

- (void)backEvent {
  [super backEvent];
  for (NEContactBaseViewController *vc in self.contentControllers) {
    [vc backEvent];
  }
}

- (void)appEnterBackground {
  for (NEContactBaseViewController *vc in self.contentControllers) {
    [vc appEnterBackground];
  }
}

- (void)getContentControllers {}

- (void)setupPageContent {
  if (!self.pagingViewController) {
    self.pagingViewController = [[NEPagingViewController alloc] initWithViewControllers:self.contentControllers];
  }

  [self addChildViewController:self.pagingViewController];
  [self.view addSubview:self.pagingViewController.view];
  self.pagingViewController.view.backgroundColor = [UIColor whiteColor];
  self.pagingViewControllerTopAnchor =
    [self.pagingViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
  self.pagingViewControllerTopAnchor.active = YES;
  self.pagingViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [self.pagingViewController.view.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.pagingViewController.view.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.pagingViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  self.pagingViewController.indicatorOptions =
    [NEPagingIndicatorOptions visibleWithHeight:2 zIndex:NSIntegerMax spacing:UIEdgeInsetsZero insets:UIEdgeInsetsZero];
  self.pagingViewController.borderOptions =
    [NEPagingBorderOptions visibleWithHeight:1 zIndex:NSIntegerMax insets:UIEdgeInsetsZero];
  if (![IMKitConfigCenter shared].enableTeamJoinAgreeModelAuth) {
    self.pagingViewController.menuItemSize = [NEPagingMenuItemSize fixedWidth:0 height:0];
  }
  [self synchronizeValidationTabWidths];
  [self.pagingViewController didMoveToParentViewController:self];
}

- (void)initNav {
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.navigationView.backButton.hidden = NO;
  self.navigationView.moreButton.hidden = NO;
  UIImage *backImage = [CommonUIConfig shared].backArrowImage;
  if (backImage) {
    [self.navigationView setBackButtonImage:[backImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
  }
  self.navigationView.backButton.tintColor = [UIColor ne_darkText];
  UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:contactLocalizable(@"clear")
                                                                style:UIBarButtonItemStyleDone
                                                               target:self
                                                               action:@selector(toSetting)];
  clearItem.tintColor = [UIColor ne_colorWithHexString:@"666666"];
  NSMutableDictionary *textAttributes = [NSMutableDictionary dictionary];
  textAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];

  [clearItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
  self.navigationItem.rightBarButtonItem = clearItem;

  [self.navigationView setMoreButtonTitle:contactLocalizable(@"clear")];
  [self.navigationView.moreButton setTitleColor:[UIColor ne_darkText] forState:UIControlStateNormal];
  self.navigationView.titleBarBottomLine.hidden = NO;
}

- (void)changeLanguage {
  self.title = contactLocalizable(@"validation_message");
  [self.navigationItem.rightBarButtonItem setTitle:contactLocalizable(@"clear")];
  [self.navigationView setMoreButtonTitle:contactLocalizable(@"clear")];
  for (NEContactBaseViewController *vc in self.contentControllers) {
    if ([vc respondsToSelector:@selector(changeLanguage)]) {
      [(id)vc changeLanguage];
    }
  }
  if (self.pagingViewController) {
    [self.pagingViewController reloadData];
  }
}

- (void)toSetting {
  // 双屏下验证消息页只占右侧详情列，非当前页的视图仍与整个窗口相交，
  NSInteger index = self.pagingViewController.currentIndex;
  if (index < 0 || index >= (NSInteger)self.contentControllers.count) {
    return;
  }
  [self.contentControllers[index] toSetting];
}

@end
