// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NIMInputEmoticonDefine.h"

NS_ASSUME_NONNULL_BEGIN

/// 表情类型
typedef NS_ENUM(NSInteger, NIMEmoticonType) {
  NIMEmoticonTypeFile = 0,     ///< 文件图片
  NIMEmoticonTypeUnicode = 1,  ///< Unicode 字符
};

#pragma mark - NIMInputEmoticon

/// 单个表情数据模型
@interface NIMInputEmoticon : NSObject

/// 表情类型（根据 unicode 是否为空自动判断）
@property (nonatomic, assign, readonly) NIMEmoticonType type;

/// 表情 ID
@property (nonatomic, copy, nullable) NSString *emoticonID;

/// 表情标签（如 [微笑]）
@property (nonatomic, copy, nullable) NSString *tag;

/// 文件名
@property (nonatomic, copy, nullable) NSString *fileName;

/// Unicode 字符串
@property (nonatomic, copy, nullable) NSString *unicode;

@end

#pragma mark - NIMInputEmoticonLayout

/// 表情面板布局参数
@interface NIMInputEmoticonLayout : NSObject

@property (nonatomic, assign) NSInteger rows;            ///< 行数
@property (nonatomic, assign) NSInteger columes;         ///< 列数
@property (nonatomic, assign) NSInteger itemCountInPage; ///< 每页显示数量
@property (nonatomic, assign) CGFloat cellWidth;         ///< 单元格宽
@property (nonatomic, assign) CGFloat cellHeight;        ///< 单元格高
@property (nonatomic, assign) CGFloat imageWidth;        ///< 图片宽
@property (nonatomic, assign) CGFloat imageHeight;       ///< 图片高
@property (nonatomic, strong, nullable) NSNumber *emoji; ///< 是否是 emoji

/// 根据面板宽度初始化布局
/// @param width 面板宽度
- (instancetype)initWithWidth:(CGFloat)width;

@end

#pragma mark - NIMInputEmoticonCatalog

/// 表情分类数据
@interface NIMInputEmoticonCatalog : NSObject

@property (nonatomic, strong, nullable) NIMInputEmoticonLayout *layout;
@property (nonatomic, copy, nullable) NSString *catalogID;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NIMInputEmoticon *> *id2Emoticons;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NIMInputEmoticon *> *tag2Emoticons;
@property (nonatomic, strong, nullable) NSArray<NIMInputEmoticon *> *emoticons;
@property (nonatomic, copy, nullable) NSString *icon;
@property (nonatomic, copy, nullable) NSString *iconPressed;
@property (nonatomic, assign) NSInteger pagesCount;

@end

#pragma mark - NIMInputEmoticonManager

/// 表情管理器单例
@interface NIMInputEmoticonManager : NSObject

+ (instancetype)shared;

/// 是否使用外部自定义资源
@property (nonatomic, assign, readonly) BOOL isCustomEmojResource;

/// 设置自定义表情配置
/// @param array 表情配置数组（NSDictionary 数组，每项含 info 和 data）
- (void)setCustomEmojConfig:(NSArray *)array;

/// 按分类 ID 查找
- (nullable NIMInputEmoticonCatalog *)emoticonCatalogWithID:(NSString *)catalogID;

/// 按 tag 查找表情
- (nullable NIMInputEmoticon *)emoticonByTag:(NSString *)tag;

/// 按 ID 查找表情
- (nullable NIMInputEmoticon *)emoticonByID:(NSString *)emoticonID;

/// 按分类 ID + 表情 ID 查找
- (nullable NIMInputEmoticon *)emoticonByCatalogID:(NSString *)catalogID
                                        emoticonID:(NSString *)emoticonID;

@end

NS_ASSUME_NONNULL_END
