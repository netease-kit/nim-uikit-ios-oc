// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatMoreActionView.h"
#import "NEInputMoreCell.h"
#import "NEChatUIConstant.h"

@interface NEChatMoreActionView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, assign) NSInteger sectionCount;
@property (nonatomic, assign) NSInteger itemsInSection;
@property (nonatomic, assign) NSInteger rowCount;
@property (nonatomic, strong, nullable) NSArray<NEMoreItemModel *> *data;
@property (nonatomic, strong, nullable) NSMutableDictionary<NSIndexPath *, NSNumber *> *itemIndexs;
@property (nonatomic, strong) UICollectionView *collcetionView;
/// 上一次计算间距时使用的宽度：布局后如果宽度变了需要重算。
@property (nonatomic, assign) CGFloat lastLayoutWidth;
@end

@implementation NEChatMoreActionView

- (UICollectionView *)collcetionView {
    if (!_collcetionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.sectionInset = UIEdgeInsetsMake(0, NEMoreView_Section_Padding, 0, NEMoreView_Section_Padding);
        self.moreFlowLayout = layout;
        _collcetionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collcetionView.backgroundColor = UIColor.clearColor;
        _collcetionView.translatesAutoresizingMaskIntoConstraints = NO;
        _collcetionView.dataSource = self;
        _collcetionView.delegate = self;
        _collcetionView.userInteractionEnabled = YES;
        _collcetionView.pagingEnabled = YES;
        _collcetionView.showsHorizontalScrollIndicator = NO;
        _collcetionView.showsVerticalScrollIndicator = NO;
        _collcetionView.alwaysBounceHorizontal = YES;
        [_collcetionView registerClass:[NEInputMoreCell class] forCellWithReuseIdentifier:NEMoreCell_ReuseId];
    }
    return _collcetionView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _sectionCount = 1;
        _itemsInSection = 4;
        _rowCount = 1;
        [self addSubview:self.collcetionView];
        [self setupConstraints];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)configData:(NSArray<NEMoreItemModel *> *)data {
    self.data = data;
    _rowCount = (data.count > NEMoreView_Column_Count) ? 2 : 1;
    _itemsInSection = NEMoreView_Column_Count * _rowCount;
    _sectionCount = (NSInteger)ceil((double)data.count / (double)_itemsInSection);

    _itemIndexs = [NSMutableDictionary dictionary];
    for (NSInteger curSection = 0; curSection < _sectionCount; curSection++) {
        for (NSInteger itemIndex = 0; itemIndex < _itemsInSection; itemIndex++) {
            NSInteger row = itemIndex % _rowCount;
            NSInteger column = itemIndex / _rowCount;
            NSInteger reIndex = NEMoreView_Column_Count * row + column + curSection * _itemsInSection;
            _itemIndexs[[NSIndexPath indexPathForItem:itemIndex inSection:curSection]] = @(reIndex);
        }
    }
    [self.collcetionView reloadData];
    [self setupConstraints];
}

- (void)setupConstraints {
    CGSize cellSize = [NEInputMoreCell getSize];
    CGFloat collectionHeight = cellSize.height * _rowCount + NEMoreView_Margin * (_rowCount - 1);
    CGFloat hostWidth = self.superview ? CGRectGetWidth(self.superview.bounds) : 0;
    if (hostWidth <= 0) {
        hostWidth = CGRectGetWidth(self.bounds);
    }
    self.collcetionView.frame = CGRectMake(0, 0, hostWidth, collectionHeight);
    if (_rowCount > 1) {
        self.moreFlowLayout.minimumInteritemSpacing = (self.collcetionView.bounds.size.height - cellSize.height * _rowCount) / (_rowCount - 1);
    }
    CGFloat margin = NEMoreView_Section_Padding;
    CGFloat spacing = (hostWidth - cellSize.width * NEMoreView_Column_Count - 2 * margin) / (NEMoreView_Column_Count - 1);
    self.moreFlowLayout.minimumLineSpacing = spacing;
    self.moreFlowLayout.sectionInset = UIEdgeInsetsMake(0, margin, 0, margin);
    self.lastLayoutWidth = hostWidth;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat hostWidth = self.superview ? CGRectGetWidth(self.superview.bounds) : CGRectGetWidth(self.bounds);
    if (fabs(hostWidth - self.lastLayoutWidth) > 0.5) {
        [self setupConstraints];
        [self.moreFlowLayout invalidateLayout];
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _sectionCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _itemsInSection;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NEInputMoreCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NEMoreCell_ReuseId forIndexPath:indexPath];
    NSNumber *index = _itemIndexs[indexPath];
    if (!index || !_data) return [[UICollectionViewCell alloc] init];
    NEMoreItemModel *itemModel = index.integerValue < _data.count ? _data[index.integerValue] : nil;
    [cell config:itemModel ?: [[NEMoreItemModel alloc] init]];
    return cell ?: [[UICollectionViewCell alloc] init];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NEInputMoreCell *cell = (NEInputMoreCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (cell) [self.delegate moreViewDidSelectMoreCell:self cell:cell];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [NEInputMoreCell getSize];
}

@end
