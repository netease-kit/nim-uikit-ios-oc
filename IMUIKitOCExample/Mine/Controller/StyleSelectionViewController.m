// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "StyleSelectionViewController.h"
#import "NEStyleManager.h"
#import "AppKey.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatUIKitOC/FunChatUIColor.h>
#import <NEBaseUIKitOC/NENavigationView.h>

// ─────────────────────────────────────────────
#pragma mark - StyleCellModel
// ─────────────────────────────────────────────

@implementation StyleCellModel
@end

// ─────────────────────────────────────────────
#pragma mark - StyleSelectionCell
// ─────────────────────────────────────────────

@interface StyleSelectionCell ()
@property (nonatomic, strong) UIImageView *stylePreview;
@property (nonatomic, strong) UILabel     *styleTitleLabel;
@property (nonatomic, strong) UIButton    *selectButton;
@end

@implementation StyleSelectionCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) [self setupSubviews];
  return self;
}

- (void)setupSubviews {
  _stylePreview = [[UIImageView alloc] init];
  _stylePreview.translatesAutoresizingMaskIntoConstraints = NO;
  _stylePreview.layer.cornerRadius = 8;
  _stylePreview.clipsToBounds = YES;
  [self.contentView addSubview:_stylePreview];

  _styleTitleLabel = [[UILabel alloc] init];
  _styleTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _styleTitleLabel.font = [UIFont systemFontOfSize:14];
  _styleTitleLabel.textAlignment = NSTextAlignmentCenter;
  _styleTitleLabel.accessibilityIdentifier = @"id.styleTitle";
  [self.contentView addSubview:_styleTitleLabel];

  _selectButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _selectButton.translatesAutoresizingMaskIntoConstraints = NO;
  [_selectButton setImage:[UIImage imageNamed:@"unclicked"] forState:UIControlStateNormal];
  _selectButton.userInteractionEnabled = NO;
  [self.contentView addSubview:_selectButton];

  [NSLayoutConstraint activateConstraints:@[
    [_stylePreview.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [_stylePreview.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [_stylePreview.widthAnchor constraintEqualToConstant:102],
    [_stylePreview.heightAnchor constraintEqualToConstant:180],

    [_styleTitleLabel.topAnchor constraintEqualToAnchor:_stylePreview.bottomAnchor constant:16],
    [_styleTitleLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [_styleTitleLabel.heightAnchor constraintEqualToConstant:18],

    [_selectButton.topAnchor constraintEqualToAnchor:_styleTitleLabel.bottomAnchor constant:16],
    [_selectButton.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [_selectButton.widthAnchor constraintEqualToConstant:22],
    [_selectButton.heightAnchor constraintEqualToConstant:22],
  ]];
}

- (void)configData:(StyleCellModel *)model {
  _stylePreview.image = [UIImage imageNamed:model.styleImageName];
  _styleTitleLabel.text = model.styleTitle;
  [_selectButton setImage:[UIImage imageNamed:model.selectedImageName] forState:UIControlStateSelected];
  _selectButton.selected = model.selected;
}

+ (CGSize)cellSize {
  return CGSizeMake(102, 252);
}

@end

// ─────────────────────────────────────────────
#pragma mark - StyleSelectionViewController
// ─────────────────────────────────────────────

@interface StyleSelectionViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<StyleCellModel *> *styleData;
@property (nonatomic, assign) NSInteger sectionCount;
@property (nonatomic, assign) NSInteger itemsInSection;
@property (nonatomic, assign) CGFloat topMargin;
@end

@implementation StyleSelectionViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = NELocalizable(@"style_selection");
  self.itemsInSection = 2;
  self.topMargin = 40;

  if ([NEStyleManager.instance isNormalStyle]) {
    self.view.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationView.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor ne_backgroundColor];
  } else {
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
  }
  self.navigationView.moreButton.hidden = YES;

  [self getData];
  [self setupSubviews];
}

- (void)getData {
  BOOL isNormal = [NEStyleManager.instance isNormalStyle];
  self.styleData = @[
    ({
      StyleCellModel *m = [[StyleCellModel alloc] init];
      m.styleName = @"default";
      m.styleImageName = @"style_normal";
      m.styleTitle = NELocalizable(@"style_default");
      m.selected = isNormal;
      m.selectedImageName = @"clicked_normal";
      m;
    }),
    ({
      StyleCellModel *m = [[StyleCellModel alloc] init];
      m.styleName = @"fun";
      m.styleImageName = @"style_fun";
      m.styleTitle = NELocalizable(@"style_fun");
      m.selected = !isNormal;
      m.selectedImageName = @"clicked_fun";
      m;
    }),
  ];
  self.sectionCount = (NSInteger)ceil((double)self.styleData.count / (double)self.itemsInSection);
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
  if (![layout isKindOfClass:[UICollectionViewFlowLayout class]]) {
    return;
  }
  CGFloat width = CGRectGetWidth(self.collectionView.bounds);
  if (width <= 0) {
    return;
  }
  CGSize size = CGSizeMake(width / (CGFloat)self.itemsInSection, [StyleSelectionCell cellSize].height);
  if (!CGSizeEqualToSize(layout.itemSize, size)) {
    layout.itemSize = size;
    [layout invalidateLayout];
  }
}

- (void)setupSubviews {
  CGSize cellSize = [StyleSelectionCell cellSize];
  CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;

  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  layout.itemSize = CGSizeMake(screenWidth / 2, cellSize.height);
  layout.minimumLineSpacing = 0;
  layout.minimumInteritemSpacing = 0;
  layout.sectionInset = UIEdgeInsetsMake(self.topMargin, 0, self.topMargin, 0);

  _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
  _collectionView.backgroundColor = UIColor.whiteColor;
  _collectionView.dataSource = self;
  _collectionView.delegate = self;
  [_collectionView registerClass:[StyleSelectionCell class] forCellWithReuseIdentifier:@"StyleSelectionCell"];
  [self.view addSubview:_collectionView];

  [NSLayoutConstraint activateConstraints:@[
    [_collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
    [_collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [_collectionView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
  ]];

  CGFloat collectionHeight = (cellSize.height + self.topMargin * 2.0) * self.sectionCount;
  CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
  [NSLayoutConstraint activateConstraints:@[
    collectionHeight > screenHeight
      ? [_collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
      : [_collectionView.heightAnchor constraintEqualToConstant:collectionHeight],
  ]];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return self.sectionCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  if (section == self.sectionCount - 1) {
    return self.styleData.count - self.itemsInSection * (self.sectionCount - 1);
  }
  return self.itemsInSection;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  StyleSelectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"StyleSelectionCell" forIndexPath:indexPath];
  NSInteger itemIndex = indexPath.section * self.itemsInSection + indexPath.row;
  [cell configData:self.styleData[itemIndex]];
  return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  NSInteger itemIndex = indexPath.section * self.itemsInSection + indexPath.row;
  BOOL isNormal = [NEStyleManager.instance isNormalStyle];

  if (itemIndex == 0 && !isNormal) {
    [NEStyleManager.instance setNormalStyle];
    [[NSNotificationCenter defaultCenter] postNotificationName:NENotificationChangeUI object:nil];
  } else if (itemIndex == 1 && isNormal) {
    [NEStyleManager.instance setFunStyle];
    [[NSNotificationCenter defaultCenter] postNotificationName:NENotificationChangeUI object:nil];
  }
}

@end
