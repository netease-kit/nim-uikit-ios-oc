// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/NEBaseViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface StyleCellModel : NSObject
@property (nonatomic, copy)   NSString *styleName;
@property (nonatomic, copy)   NSString *styleImageName;
@property (nonatomic, copy)   NSString *styleTitle;
@property (nonatomic, copy)   NSString *selectedImageName;
@property (nonatomic, assign) BOOL selected;
@end

@interface StyleSelectionCell : UICollectionViewCell
- (void)configData:(StyleCellModel *)model;
+ (CGSize)cellSize;
@end

@interface StyleSelectionViewController : NEBaseViewController

@end

NS_ASSUME_NONNULL_END
