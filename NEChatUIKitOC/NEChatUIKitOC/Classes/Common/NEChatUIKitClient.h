// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>

@class NEMoreItemModel;
@class ChatViewController;

NS_ASSUME_NONNULL_BEGIN

@interface NEChatUIKitClient : NSObject

/// Singleton instance
@property (class, nonatomic, readonly) NEChatUIKitClient *instance;

/// More-panel action data (photo, takePicture, file, rtc, translate, aiChat…)
@property (nonatomic, strong) NSMutableArray<NEMoreItemModel *> *moreAction;

/// 获取更多面板数据
/// @param sessionType  Conversation type (P2P / team / …)
/// @param viewController  Current ChatViewController
/// @return  Filtered action data
- (NSArray<NEMoreItemModel *> *)getMoreActionDataWithSessionType:(V2NIMConversationType)sessionType
                                                  viewController:(ChatViewController *)viewController;

/// 新增聊天页针对自定义消息的cell扩展，以及现有cell样式覆盖
/// @param registerDic  key: type string, value: UITableViewCell subclass
- (void)regsiterCustomCell:(NSDictionary<NSString *, Class> *)registerDic;

/// 获取已注册的自定义cell字典
- (NSDictionary<NSString *, Class> *)getRegisterCustomCell;

/// 获取图片资源
/// @param imageName  Image name in bundle
- (UIImage * _Nullable)getImageSourceWithImageName:(NSString *)imageName;

/// 获取多语言
/// @param key  Localization key
- (NSString * _Nullable)getLanguageWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
