// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ForwardAlertViewController.h"

@implementation ForwardSessionCell

- (void)setupUI {
    [super setupUI];
    self.sessionHeaderView.layer.cornerRadius = 16;
}

@end

@implementation ForwardAlertViewController

- (void)setupUI {
    [super setupUI];
    self.oneSessionHeadView.layer.cornerRadius = 16.0;
    [self.sessionCollectionView registerClass:[ForwardSessionCell class] forCellWithReuseIdentifier:NSStringFromClass([ForwardSessionCell class])];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ForwardSessionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([ForwardSessionCell class]) forIndexPath:indexPath];
    if (cell) {
        return [self setCellModel:cell indexPath:indexPath];
    }
    return [[UICollectionViewCell alloc] init];
}

@end
