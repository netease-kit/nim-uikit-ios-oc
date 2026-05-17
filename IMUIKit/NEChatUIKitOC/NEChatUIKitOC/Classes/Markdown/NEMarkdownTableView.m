// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownTableView.h"

// MARK: - NEMarkdownTableData

@implementation NEMarkdownTableData

- (instancetype)initWithHeaders:(NSArray<NSString *> *)headers
                     alignments:(NSArray<NSNumber *> *)alignments
                           rows:(NSArray<NSArray<NSString *> *> *)rows {
    self = [super init];
    if (self) {
        _headers = [headers copy];
        _alignments = [alignments copy];
        _rows = [rows copy];
    }
    return self;
}

- (NSInteger)columnCount {
    return (NSInteger)self.headers.count;
}

@end

// MARK: - NEMarkdownTableView

@interface NEMarkdownTableView ()
@property (nonatomic, strong, nullable) NEMarkdownTableData *tableData;
@end

@implementation NEMarkdownTableView

- (instancetype)initWithData:(NEMarkdownTableData *)data maxWidth:(CGFloat)maxWidth {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _maxWidth = maxWidth;
        _tableData = data;
        [self setupDefaults];
        [self setupTable];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaults];
    }
    return self;
}

- (void)setupDefaults {
    _maxWidth = [UIScreen mainScreen].bounds.size.width - 32;
    _headerBackgroundColor = [UIColor colorWithRed:0.90 green:0.92 blue:0.96 alpha:1.0];
    _oddRowBackgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.98 alpha:1.0];
    _evenRowBackgroundColor = UIColor.whiteColor;
    _borderColor = [UIColor colorWithRed:0.80 green:0.82 blue:0.86 alpha:1.0];
    _borderWidth = 0.5;
    _cellPadding = 8.0;
    _headerFont = [UIFont boldSystemFontOfSize:14];
    _cellFont = [UIFont systemFontOfSize:14];
    _headerTextColor = UIColor.blackColor;
    _cellTextColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0];
}

- (void)setupTable {
    NEMarkdownTableData *data = self.tableData;
    if (!data) return;

    self.backgroundColor = UIColor.clearColor;
    NSInteger colCount = data.columnCount;
    if (colCount <= 0) return;

    CGFloat totalBorderWidth = _borderWidth * (CGFloat)(colCount + 1);
    CGFloat colWidth = MAX(60, (_maxWidth - totalBorderWidth) / (CGFloat)colCount);
    CGFloat tableWidth = colWidth * (CGFloat)colCount + totalBorderWidth;

    __block CGFloat currentY = 0;
    NEMarkdownTableView * __weak weakSelf = self;

    void (^renderRow)(NSArray<NSString *> *, BOOL, NSInteger) =
        ^(NSArray<NSString *> *cells, BOOL isHeader, NSInteger rowIndex) {
        NEMarkdownTableView *s = weakSelf;
        if (!s) return;

        UIFont *font = isHeader ? s.headerFont : s.cellFont;
        UIColor *textColor = isHeader ? s.headerTextColor : s.cellTextColor;
        UIColor *bgColor;
        if (isHeader) {
            bgColor = s.headerBackgroundColor;
        } else {
            bgColor = (rowIndex % 2 == 0) ? s.oddRowBackgroundColor : s.evenRowBackgroundColor;
        }

        // 计算最大行高
        CGFloat maxCellH = 0;
        for (NSInteger colIdx = 0; colIdx < (NSInteger)cells.count; colIdx++) {
            NEMarkdownTableAlignment align = (colIdx < (NSInteger)data.alignments.count)
                ? (NEMarkdownTableAlignment)[data.alignments[colIdx] integerValue]
                : NEMarkdownTableAlignmentLeft;
            CGSize cellSize = [s cellTextSizeForText:cells[colIdx] font:font colWidth:colWidth alignment:align];
            maxCellH = MAX(maxCellH, cellSize.height);
        }
        CGFloat rowHeight = maxCellH + s.cellPadding * 2;

        // 行背景
        UIView *rowBg = [[UIView alloc] initWithFrame:CGRectMake(0, currentY, tableWidth, rowHeight)];
        rowBg.backgroundColor = bgColor;
        [s addSubview:rowBg];

        // 顶部边框线
        UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, currentY, tableWidth, s.borderWidth)];
        topLine.backgroundColor = s.borderColor;
        [s addSubview:topLine];

        // 左边框
        UIView *leftBorder = [[UIView alloc] initWithFrame:CGRectMake(0, currentY, s.borderWidth, rowHeight)];
        leftBorder.backgroundColor = s.borderColor;
        [s addSubview:leftBorder];

        CGFloat currentX = s.borderWidth;

        for (NSInteger colIdx = 0; colIdx < (NSInteger)cells.count; colIdx++) {
            NEMarkdownTableAlignment align = (colIdx < (NSInteger)data.alignments.count)
                ? (NEMarkdownTableAlignment)[data.alignments[colIdx] integerValue]
                : NEMarkdownTableAlignmentLeft;

            UILabel *label = [s makeCellLabelWithText:cells[colIdx] font:font textColor:textColor
                                             colWidth:colWidth alignment:align];
            label.frame = CGRectMake(currentX + s.cellPadding,
                                     currentY + s.cellPadding,
                                     colWidth - s.cellPadding * 2,
                                     rowHeight - s.cellPadding * 2);
            [s addSubview:label];
            currentX += colWidth;

            // 右边框
            UIView *rightBorder = [[UIView alloc] initWithFrame:CGRectMake(currentX, currentY, s.borderWidth, rowHeight)];
            rightBorder.backgroundColor = s.borderColor;
            [s addSubview:rightBorder];
            currentX += s.borderWidth;
        }

        currentY += rowHeight;
    };

    // 渲染表头
    renderRow(data.headers, YES, -1);

    // 渲染数据行
    for (NSInteger i = 0; i < (NSInteger)data.rows.count; i++) {
        NSMutableArray<NSString *> *cells = [data.rows[i] mutableCopy];
        while ((NSInteger)cells.count < colCount) [cells addObject:@""];
        if ((NSInteger)cells.count > colCount) [cells removeObjectsInRange:NSMakeRange(colCount, cells.count - colCount)];
        renderRow([cells copy], NO, i);
    }

    // 底部边框
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, currentY, tableWidth, _borderWidth)];
    bottomLine.backgroundColor = _borderColor;
    [self addSubview:bottomLine];
    currentY += _borderWidth;

    self.frame = CGRectMake(0, 0, tableWidth, currentY);
}

- (UILabel *)makeCellLabelWithText:(NSString *)text
                              font:(UIFont *)font
                         textColor:(UIColor *)textColor
                          colWidth:(CGFloat)colWidth
                         alignment:(NEMarkdownTableAlignment)alignment {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = font;
    label.textColor = textColor;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    switch (alignment) {
        case NEMarkdownTableAlignmentCenter: label.textAlignment = NSTextAlignmentCenter; break;
        case NEMarkdownTableAlignmentRight:  label.textAlignment = NSTextAlignmentRight;  break;
        default:                             label.textAlignment = NSTextAlignmentLeft;   break;
    }
    return label;
}

- (CGSize)cellTextSizeForText:(NSString *)text
                         font:(UIFont *)font
                     colWidth:(CGFloat)colWidth
                    alignment:(NEMarkdownTableAlignment)alignment {
    CGFloat availableWidth = colWidth - _cellPadding * 2;
    CGSize constraintSize = CGSizeMake(availableWidth, CGFLOAT_MAX);
    CGRect boundingRect = [(text ?: @"") boundingRectWithSize:constraintSize
                                                      options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                   attributes:@{NSFontAttributeName: font}
                                                      context:nil];
    return CGSizeMake(availableWidth, ceil(boundingRect.size.height));
}

+ (CGFloat)calculateHeightWithData:(NEMarkdownTableData *)data
                          maxWidth:(CGFloat)maxWidth
                        headerFont:(UIFont *)headerFont
                          cellFont:(UIFont *)cellFont
                       cellPadding:(CGFloat)cellPadding
                       borderWidth:(CGFloat)borderWidth {
    NSInteger colCount = data.columnCount;
    if (colCount <= 0) return 0;

    CGFloat totalBorderWidth = borderWidth * (CGFloat)(colCount + 1);
    CGFloat colWidth = MAX(60, (maxWidth - totalBorderWidth) / (CGFloat)colCount);

    CGFloat (^rowH)(NSArray<NSString *> *, UIFont *) = ^CGFloat(NSArray<NSString *> *cells, UIFont *font) {
        CGFloat maxH = 0;
        CGFloat available = colWidth - cellPadding * 2;
        for (NSString *text in cells) {
            CGRect rect = [(text ?: @"") boundingRectWithSize:CGSizeMake(available, CGFLOAT_MAX)
                                                      options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                   attributes:@{NSFontAttributeName: font}
                                                      context:nil];
            maxH = MAX(maxH, ceil(rect.size.height));
        }
        return maxH + cellPadding * 2;
    };

    CGFloat totalHeight = 0;
    totalHeight += rowH(data.headers, headerFont) + borderWidth;

    for (NSArray<NSString *> *row in data.rows) {
        NSMutableArray *cells = [row mutableCopy];
        while ((NSInteger)cells.count < colCount) [cells addObject:@""];
        if ((NSInteger)cells.count > colCount) [cells removeObjectsInRange:NSMakeRange(colCount, cells.count - colCount)];
        totalHeight += rowH([cells copy], cellFont) + borderWidth;
    }
    totalHeight += borderWidth; // 底部边框
    return totalHeight;
}

@end
