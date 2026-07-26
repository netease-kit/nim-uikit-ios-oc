// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKitOC.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "NEFusionContactCellModel.h"
#import "FusionContactSelectedViewModel.h"
#import "NEBaseFusionContactSelectedCell.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FusionContactType) {
  FusionContactTypeUser = 0,
  FusionContactTypeAIUser,
};

@protocol FusionContactSelectedDelegate <NSObject>
/// 选择成员列表回调
- (BOOL)didSelectedUser:(NEFusionContactCellModel *)model;
/// 取消选择成员列表回调
- (void)didUnselectedUser:(NEFusionContactCellModel *)model;
@end

@interface NEBaseFusionContactSelectedController : UIViewController <UITableViewDelegate, UITableViewDataSource>

/// cell 注册表
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Class> *fusionRegisterCellDic;

/// 选择器代理
@property (nonatomic, weak, nullable) id<FusionContactSelectedDelegate> delegate;

/// 选择人数限制
@property (nonatomic, assign) NSInteger limit;

/// 选择器成员列表
@property (nonatomic, strong) UITableView *fusionContactTableView;

/// 空占位图
@property (nonatomic, strong) NEEmptyDataView *fusionEmptyView;

- (instancetype)initWithFilterIds:(nullable NSSet<NSString *> *)filterIds type:(FusionContactType)type;

- (void)setupFusionContactSelectedUI;
- (void)setupFusionContactUI;
- (void)loadData;
- (nullable V2NIMUser *)getCellModelUser:(NEFusionContactCellModel *)cellModel;
- (void)unselectModel:(NEFusionContactCellModel *)model;

@end

NS_ASSUME_NONNULL_END
