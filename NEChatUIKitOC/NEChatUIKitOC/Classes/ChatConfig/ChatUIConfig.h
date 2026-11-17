
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class ChatViewController;
@class NEChatBaseViewController;
@class AIChatViewController;
@class AIChatCellModel;
@class MessageContentModel;
@class NEMoreItemModel;
@class OperationItem;
@class NEResultModel;
@class V2NIMMessage;

/// 头像枚举类型
typedef NS_ENUM(NSInteger, NEChatAvatarType) {
  NEChatAvatarTypeRectangle = 1, // 矩形
  NEChatAvatarTypeCycle = 2,     // 圆形
};

/// 媒体类型（前置声明，避免循环引用）
typedef NS_ENUM(NSInteger, NEMediaType);

#pragma mark - Block Typedefs

typedef void (^NEChatMessageItemClickBlock)(NEChatBaseViewController *controller,
                                            UITableViewCell *cell,
                                            MessageContentModel *_Nullable model);

typedef void (^NEChatInputBarBlock)(ChatViewController *_Nullable controller,
                                    NSMutableArray<UIButton *> *buttons);

typedef void (^NEChatInputPhotoClickBlock)(UIViewController *controller,
                                           NEMediaType mediaType,
                                           NSInteger limit,
                                           void (^completion)(NSArray<NEResultModel *> *results, BOOL isOriginal));

typedef void (^NEChatInputMenuBlock)(ChatViewController *controller,
                                     NSMutableArray<NEMoreItemModel *> *items);

typedef void (^NEChatPopMenuBlock)(ChatViewController *controller,
                                   NSMutableArray<OperationItem *> *items,
                                   MessageContentModel *_Nullable model);

typedef void (^NEChatPopMenuClickBlock)(ChatViewController *controller,
                                        OperationItem *item);

typedef void (^NEChatCustomControllerBlock)(ChatViewController *controller);

typedef void (^NEAIChatViewControllerBlock)(AIChatViewController *controller);

typedef void (^NEAIChatDataLoaderBlock)(NSArray<V2NIMMessage *> *_Nullable contextMessages,
                                        void (^completion)(NSArray<AIChatCellModel *> *_Nullable models, NSError *_Nullable error));

typedef void (^NEAIChatDidClickBlock)(AIChatViewController *controller,
                                      NSArray<V2NIMMessage *> *_Nullable contextMessages);

typedef void (^NEAIChatReloadClickBlock)(AIChatViewController *controller,
                                         NSArray<V2NIMMessage *> *_Nullable contextMessages);

typedef void (^NETitleBarRightClickBlock)(ChatViewController *controller);

#pragma mark - MessageProperties

/// 消息页面的 UI 个性化定制
@interface MessageProperties : NSObject

/// 头像圆角大小
@property(nonatomic, assign) CGFloat avatarCornerRadius;

/// 头像类型
@property(nonatomic, assign) NEChatAvatarType avatarType;

/// 设置聊天消息标记的背景色
@property(nonatomic, strong) UIColor *signalBgColor;

/// 时间颜色
@property(nonatomic, strong) UIColor *timeTextColor;

/// 时间字体大小
@property(nonatomic, assign) CGFloat timeTextSize;

/// 自己发送的消息的字体大小(文本类型)
@property(nonatomic, assign) CGFloat selfMessageTextSize;

/// 接收到的消息的字体大小(文本类型)
@property(nonatomic, assign) CGFloat receiveMessageTextSize;

/// 自己发送的消息的字体颜色(文本类型)
@property(nonatomic, strong) UIColor *selfMessageTextColor;

/// 接收到的消息的字体颜色(文本类型)
@property(nonatomic, strong) UIColor *receiveMessageTextColor;

/// 输入框文本字体颜色
@property(nonatomic, strong) UIColor *inputTextColor;

/// 输入框占位文本字体颜色
@property(nonatomic, strong, nullable) UIColor *inputPlaceholderTextColor;

/// 自己发送的消息体的背景色
@property(nonatomic, strong) UIColor *selfMessageBgColor;

/// 接收到的消息体的背景色
@property(nonatomic, strong) UIColor *receiveMessageBgColor;

/// 自己发送的消息体的背景气泡
@property(nonatomic, strong, nullable) UIImage *selfMessageBgImage;

/// 接收到的消息体的背景气泡
@property(nonatomic, strong, nullable) UIImage *receiveMessageBgImage;

/// 气泡图片拉伸参数（边距偏移），默认 {35, 25, 10, 25}
@property(nonatomic, assign) UIEdgeInsets backgroundImageCapInsets;

/// 标记 backgroundImageCapInsets 是否已被设置
@property(nonatomic, assign) BOOL backgroundImageCapInsetsSet;

/// 不设置头像的用户所展示的文字头像中的文字颜色
@property(nonatomic, strong) UIColor *userNickColor;

/// 不设置头像的用户所展示的文字头像中的文字字体大小
@property(nonatomic, assign) CGFloat userNickTextSize;

/// 标记列表字体大小(文本类型)
@property(nonatomic, assign) CGFloat pinMessageTextSize;

/// 单聊中是否展示已读未读状态
@property(nonatomic, assign) BOOL showP2PMessageStatus;

/// 群聊中是否展示已读未读状态
@property(nonatomic, assign) BOOL showTeamMessageStatus;

/// 群聊中是否展示好友昵称
@property(nonatomic, assign) BOOL showTeamMessageNick;

/// 会话界面是否展示标题栏
@property(nonatomic, assign) BOOL showTitleBar;

/// 是否展示标题栏右侧图标按钮
@property(nonatomic, assign) BOOL showTitleBarRightIcon;

/// 设置标题栏右侧图标按钮展示图标
@property(nonatomic, strong, nullable) UIImage *titleBarRightRes;

/// 标题栏右侧图标的点击事件
@property(nonatomic, copy, nullable) NETitleBarRightClickBlock titleBarRightClick;

/// 设置消息列表背景色，仅消息列表生效
@property(nonatomic, strong, nullable) UIColor *chatTableViewBackgroundColor;

/// 设置聊天界面背景色，包含状态栏、导航栏、消息列表、输入区域，颜色同 chatViewBackgroundColor
@property(nonatomic, assign) BOOL chatViewBackgroundSolid;

@end

#pragma mark - ChatUIConfig

/// 消息模块自定义配置
@interface ChatUIConfig : NSObject

/// 单例
+ (instancetype)shared;

/// 消息页面的 UI 个性化定制（消息点击）
@property(nonatomic, copy, nullable) NEChatMessageItemClickBlock messageItemClick;

/// 消息页面的 UI 个性化定制
@property(nonatomic, strong) MessageProperties *messageProperties;

/// 文本输入框下方 tab 按钮定制
@property(nonatomic, copy, nullable) NEChatInputBarBlock chatInputBar;

/// 【相册】按钮点击事件，可自定义图片选择器
@property(nonatomic, copy, nullable) NEChatInputPhotoClickBlock chatInputPhotoClick;

/// 【更多】区域功能列表
@property(nonatomic, copy, nullable) NEChatInputMenuBlock chatInputMenu;

/// 消息长按弹出菜单回调
@property(nonatomic, copy, nullable) NEChatPopMenuBlock chatPopMenu;

/// 消息长按弹出菜单点击事件回调
@property(nonatomic, copy, nullable) NEChatPopMenuClickBlock popMenuClick;

/// 消息列表的视图控制器回调
@property(nonatomic, copy, nullable) NEChatCustomControllerBlock customController;

/// 消息列表的 AI 助聊视图控制器回调
@property(nonatomic, copy, nullable) NEAIChatViewControllerBlock aiChatViewController;

/// AI 助聊的数据加载器
@property(nonatomic, copy, nullable) NEAIChatDataLoaderBlock aiChatDataLoader;

/// AI 助聊入口按钮点击事件，仅在展开时回调
@property(nonatomic, copy, nullable) NEAIChatDidClickBlock aiChatDidClick;

/// AI 助聊重新加载按钮点击事件
@property(nonatomic, copy, nullable) NEAIChatReloadClickBlock aiChatReloadClick;

/// 发送文件大小限制(单位：MB)
@property(nonatomic, assign) double fileSizeLimit;

/// 图片缩略图尺寸大小，为 0 则使用原图，本地图片默认使用原图
@property(nonatomic, assign) NSInteger imageThumbSize;

/// 群未读显示限制数，默认超过200人不显示已读未读进度
@property(nonatomic, assign) NSInteger maxReadingNum;

/// 撤回消息可重新编辑时间 (单位：min)
@property(nonatomic, assign) NSInteger revokeEditTimeGap;

/// 设置消息可撤回时间 (单位：min)
/// 周期为[2, 7*24*60] 分钟, 超过最大值，修正为最大值，最小值修正到2分钟
- (void)setRevokeTimeGap:(NSInteger)time;

/// 获取消息可撤回时间 (单位：min)
/// 周期为[2, 7*24*60] 分钟
- (NSInteger)getReeditTimeGap;

@end
