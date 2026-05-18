// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunForwardAlertViewController.h"
#import "FunChatUIColor.h"

@implementation FunForwardSessionCell

- (void)setupUI {
    [super setupUI];
    self.sessionHeaderView.layer.cornerRadius = 4;
}

@end

@implementation FunForwardAlertViewController

- (void)setupUI {
    [super setupUI];
    self.tipLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.oneSessionHeadView.layer.cornerRadius = 4.0;
    [self.sureButton setTitleColor:[UIColor funChatThemeColor] forState:UIControlStateNormal];
    [self.sessionCollectionView registerClass:[FunForwardSessionCell class]
                   forCellWithReuseIdentifier:NSStringFromClass([FunForwardSessionCell class])];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FunForwardSessionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([FunForwardSessionCell class]) forIndexPath:indexPath];
    if (cell) {
        return [self setCellModel:cell indexPath:indexPath];
    }
    return [[UICollectionViewCell alloc] init];
}

@end
