// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 表格列对齐方式
typedef NS_ENUM(NSInteger, NEMarkdownTableAlignment) {
    NEMarkdownTableAlignmentLeft = 0,
    NEMarkdownTableAlignmentCenter,
    NEMarkdownTableAlignmentRight,
};

/// 表格数据模型
@interface NEMarkdownTableData : NSObject

@property (nonatomic, copy, readonly) NSArray<NSString *> *headers;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *alignments; // NSNumber wrapping NEMarkdownTableAlignment
@property (nonatomic, copy, readonly) NSArray<NSArray<NSString *> *> *rows;

@property (nonatomic, assign, readonly) NSInteger columnCount;

- (instancetype)initWithHeaders:(NSArray<NSString *> *)headers
                     alignments:(NSArray<NSNumber *> *)alignments
                           rows:(NSArray<NSArray<NSString *> *> *)rows;

@end

/// 表格渲染视图（将 NEMarkdownTableData 渲染为网格表格）
@interface NEMarkdownTableView : UIView

@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, strong) UIColor *headerBackgroundColor;
@property (nonatomic, strong) UIColor *oddRowBackgroundColor;
@property (nonatomic, strong) UIColor *evenRowBackgroundColor;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CGFloat cellPadding;
@property (nonatomic, strong) UIFont *headerFont;
@property (nonatomic, strong) UIFont *cellFont;
@property (nonatomic, strong) UIColor *headerTextColor;
@property (nonatomic, strong) UIColor *cellTextColor;

- (instancetype)initWithData:(NEMarkdownTableData *)data maxWidth:(CGFloat)maxWidth;

/// 计算给定参数下表格的总高度
+ (CGFloat)calculateHeightWithData:(NEMarkdownTableData *)data
                          maxWidth:(CGFloat)maxWidth
                        headerFont:(UIFont *)headerFont
                          cellFont:(UIFont *)cellFont
                       cellPadding:(CGFloat)cellPadding
                       borderWidth:(CGFloat)borderWidth;

@end

NS_ASSUME_NONNULL_END
