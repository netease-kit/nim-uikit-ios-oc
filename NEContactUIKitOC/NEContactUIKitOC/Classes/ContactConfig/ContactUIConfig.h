// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class NEBaseContactViewController;
@class ContactInfo;
@class ContactHeadItem;

NS_ASSUME_NONNULL_BEGIN

/// 头像枚举类型
typedef NS_ENUM(NSInteger, NEContactAvatarType) {
  NEContactAvatarTypeRectangle = 1, // 矩形
  NEContactAvatarTypeCycle,         // 圆形
};

#pragma mark - ContactProperties

/// 通讯录页面的 UI 个性化定制
@interface ContactProperties : NSObject

/// 头像圆角大小
@property (nonatomic, assign) CGFloat avatarCornerRadius;
/// 头像类型
@property (nonatomic, assign) NEContactAvatarType avatarType;
/// 通讯录好友标题大小
@property (nonatomic, assign) CGFloat itemTitleSize;
/// 通讯录好友标题颜色
@property (nonatomic, strong) UIColor *itemTitleColor;
/// 通讯录间隔线颜色
@property (nonatomic, strong) UIColor *divideLineColor;
/// 检索标题字体颜色
@property (nonatomic, strong, nullable) UIColor *indexTitleColor;

@end

#pragma mark - ContactUIConfig

/// 通讯录模块自定义配置
@interface ContactUIConfig : NSObject

@property (class, nonatomic, readonly) ContactUIConfig *shared;

/// 标题栏文案
@property (nonatomic, copy, nullable) NSString *title;
/// 标题栏文案颜色
@property (nonatomic, strong, nullable) UIColor *titleColor;
/// 是否展示标题栏
@property (nonatomic, assign) BOOL showTitleBar;
/// 是否展示标题栏的次最右侧图标
@property (nonatomic, assign) BOOL showTitleBarRight2Icon;
/// 是否展示标题栏的最右侧图标
@property (nonatomic, assign) BOOL showTitleBarRightIcon;
/// 标题栏的最右侧图标
@property (nonatomic, strong, nullable) UIImage *titleBarRightRes;
/// 标题栏的次最右侧图标
@property (nonatomic, strong, nullable) UIImage *titleBarRight2Res;
/// 标题栏最右侧按钮点击事件
@property (nonatomic, copy, nullable) void (^titleBarRightClick)(NEBaseContactViewController *vc);
/// 标题栏次最右侧按钮点击事件
@property (nonatomic, copy, nullable) void (^titleBarRight2Click)(NEBaseContactViewController *vc);
/// 是否在通讯录界面显示头部模块
@property (nonatomic, assign) BOOL showHeader;
/// 通讯录列表头部模块的数据回调
@property (nonatomic, copy, nullable) void (^headerData)(NEBaseContactViewController *vc, NSMutableArray<ContactHeadItem *> *items);
/// 通讯录列表头部模块 cell 点击事件
@property (nonatomic, copy, nullable) void (^headerItemClick)(NEBaseContactViewController *vc, ContactInfo *info, NSIndexPath *indexPath);
/// 通讯录列表好友 cell 点击事件
@property (nonatomic, copy, nullable) void (^friendItemClick)(NEBaseContactViewController *vc, ContactInfo *info, NSIndexPath *indexPath);
/// 通讯录好友列表的 UI 个性化定制
@property (nonatomic, strong) ContactProperties *contactProperties;
/// 通讯录列表的视图控制器回调
@property (nonatomic, copy, nullable) void (^customController)(NEBaseContactViewController *vc);

@end

NS_ASSUME_NONNULL_END
