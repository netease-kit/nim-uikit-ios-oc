// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// ConversationUIConfig.h
// 会话模块 UI 自定义配置 — 对齐 Swift ConversationUIConfig

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEConversationListModel;

/// 头像枚举类型（对齐 Swift NEConversationAvatarType）
typedef NS_ENUM(NSInteger, NEConversationAvatarType) {
  NEConversationAvatarTypeRectangle = 1, // 矩形
  NEConversationAvatarTypeCycle,          // 圆形
};

#pragma mark - ConversationProperties

/// 会话列表页面的 UI 个性化定制（对齐 Swift ConversationProperties）
@interface ConversationProperties : NSObject

/// 头像圆角大小
@property (nonatomic, assign) CGFloat avatarCornerRadius;

/// 头像类型
@property (nonatomic, assign) NEConversationAvatarType avatarType;

/// 未被置顶的会话项的背景色
@property (nonatomic, strong, nullable) UIColor *itemBackground;

/// 置顶的会话项的背景色
@property (nonatomic, strong, nullable) UIColor *itemStickTopBackground;

/// 会话标题的字体大小
@property (nonatomic, assign) CGFloat itemTitleSize;

/// 会话消息缩略内容的字体大小
@property (nonatomic, assign) CGFloat itemContentSize;

/// 时间字体大小
@property (nonatomic, assign) CGFloat itemDateSize;

/// 会话标题的字体颜色
@property (nonatomic, strong) UIColor *itemTitleColor;

/// 会话消息缩略内容的字体颜色
@property (nonatomic, strong) UIColor *itemContentColor;

/// 会话时间的字体颜色
@property (nonatomic, strong, nullable) UIColor *itemDateColor;

@end

#pragma mark - ConversationUIConfig

/// 会话模块自定义配置（对齐 Swift ConversationUIConfig）
@interface ConversationUIConfig : NSObject

+ (instancetype)shared;

/// 是否展示界面顶部的标题栏
@property (nonatomic, assign) BOOL showTitleBar;

/// 是否展示标题栏左侧图标
@property (nonatomic, assign) BOOL showTitleBarLeftIcon;

/// 是否展示标题栏次最右侧图标
@property (nonatomic, assign) BOOL showTitleBarRight2Icon;

/// 是否展示标题栏最右侧图标
@property (nonatomic, assign) BOOL showTitleBarRightIcon;

/// 标题栏左侧图标
@property (nonatomic, strong, nullable) UIImage *titleBarLeftRes;

/// 标题栏最右侧图标
@property (nonatomic, strong, nullable) UIImage *titleBarRightRes;

/// 标题栏次最右侧图标
@property (nonatomic, strong, nullable) UIImage *titleBarRight2Res;

/// 标题栏的文案
@property (nonatomic, copy, nullable) NSString *titleBarTitle;

/// 标题栏的颜色值
@property (nonatomic, strong, nullable) UIColor *titleBarTitleColor;

/// 会话列表页面的 UI 个性化定制
@property (nonatomic, strong, readonly) ConversationProperties *conversationProperties;

/// 标题栏左侧按钮点击回调
@property (nonatomic, copy, nullable) void (^titleBarLeftClick)(UIViewController *vc);

/// 标题栏右侧按钮（新建）点击回调
@property (nonatomic, copy, nullable) void (^titleBarRightClick)(UIViewController *vc);

/// 标题栏次右侧按钮（搜索）点击回调
@property (nonatomic, copy, nullable) void (^titleBarRight2Click)(UIViewController *vc);

/// 自定义会话列表页面，可向顶部区域挂载自定义视图
@property (nonatomic, copy, nullable) void (^customController)(UIViewController *vc);

/// 会话列表 cell 点击回调
@property (nonatomic, copy, nullable) void (^itemClick)(UIViewController *vc, NEConversationListModel * _Nullable model, NSIndexPath *indexPath);

/// 会话列表 cell 左划置顶按钮文案内容
@property (nonatomic, copy, nullable) NSString *stickTopButtonTitle;
/// 会话列表 cell 左划取消置顶按钮文案内容
@property (nonatomic, copy, nullable) NSString *stickTopButtonCancelTitle;
/// 会话列表 cell 左划置顶按钮背景颜色
@property (nonatomic, strong, nullable) UIColor *stickTopButtonBackgroundColor;
/// 会话列表 cell 左划置顶按钮点击回调
@property (nonatomic, copy, nullable) void (^stickTopButtonClick)(UIViewController *vc, NEConversationListModel * _Nullable model, NSIndexPath *indexPath);

/// 会话列表 cell 左划删除按钮文案内容
@property (nonatomic, copy, nullable) NSString *deleteButtonTitle;
/// 会话列表 cell 左划删除按钮背景颜色
@property (nonatomic, strong, nullable) UIColor *deleteButtonBackgroundColor;
/// 会话列表 cell 左划删除按钮点击回调
@property (nonatomic, copy, nullable) void (^deleteButtonClick)(UIViewController *vc, NEConversationListModel * _Nullable model, NSIndexPath *indexPath);

@end

NS_ASSUME_NONNULL_END
