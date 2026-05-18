// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageOperationView.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "OperationCell.h"

@interface MessageOperationView ()
@property (nonatomic, strong) UICollectionView *collcetionView;
@end

@implementation MessageOperationView

- (instancetype)initWithFrame:(CGRect)frame {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(60, 56);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;

    self = [super initWithFrame:frame];
    if (self) {
        _items = [NSMutableArray array];
        _collcetionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collcetionView.backgroundColor = UIColor.whiteColor;
        _collcetionView.translatesAutoresizingMaskIntoConstraints = NO;

        self.backgroundColor = UIColor.whiteColor;
        self.layer.cornerRadius = 8;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowColor = UIColor.ne_operationBorderColor.CGColor;
        self.layer.shadowOpacity = 0.25;
        self.layer.shadowRadius = 8;

        _collcetionView.dataSource = self;
        _collcetionView.delegate = self;
        _collcetionView.userInteractionEnabled = YES;
        [_collcetionView registerClass:[OperationCell class] forCellWithReuseIdentifier:NSStringFromClass([OperationCell class])];
        [self addSubview:_collcetionView];
        [NSLayoutConstraint activateConstraints:@[
            [_collcetionView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8],
            [_collcetionView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8],
            [_collcetionView.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
            [_collcetionView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8],
        ]];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    _collcetionView = [[UICollectionView alloc] initWithFrame:CGRectZero];
    self = [super initWithCoder:coder];
    return self;
}

- (void)setItems:(NSMutableArray<OperationItem *> *)items {
    _items = [items isKindOfClass:[NSArray class]] ? items : [NSMutableArray array];
    [_collcetionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    OperationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([OperationCell class]) forIndexPath:indexPath];
    if (indexPath.row < self.items.count) {
        cell.model = self.items[indexPath.row];
    }
    return cell ?: [[UICollectionViewCell alloc] init];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.items.count) return;
    OperationItem *item = self.items[indexPath.row];
    if (item && [self.delegate respondsToSelector:@selector(didSelectedItem:)]) {
        [self.delegate didSelectedItem:item];
    }
}

@end
