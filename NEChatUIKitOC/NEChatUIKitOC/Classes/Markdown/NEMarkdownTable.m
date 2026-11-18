// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownTable.h"
#import "NEMarkdownTableAttachment.h"

// MARK: - 内部辅助结构体（用 NSObject 封装）

@interface NEMarkdownTableRegion : NSObject
@property (nonatomic, assign) NSInteger headerLineIndex; // -1 = 无独立表头行
@property (nonatomic, copy) NSArray<NSString *> *headerCellsFromTail;
@property (nonatomic, assign) NSInteger separatorLineIndex;
@property (nonatomic, copy) NSArray<NSNumber *> *dataLineIndices;
@end

@implementation NEMarkdownTableRegion
- (instancetype)init {
    self = [super init];
    _headerLineIndex = -1;
    _headerCellsFromTail = @[];
    _dataLineIndices = @[];
    return self;
}
@end

// MARK: - NEMarkdownTable

@implementation NEMarkdownTable

- (instancetype)initWithMaxWidth:(CGFloat)maxWidth {
    self = [super init];
    if (self) {
        _maxWidth = maxWidth;
        _headerFont = [UIFont boldSystemFontOfSize:14];
        _cellFont = [UIFont systemFontOfSize:14];
        _cellPadding = 8;
        _borderWidth = 0.5;
    }
    return self;
}

- (instancetype)init {
    return [self initWithMaxWidth:[UIScreen mainScreen].bounds.size.width - 72];
}

#pragma mark - NEMarkdownElement（保留兼容性，实际逻辑在 preprocessText 中）

- (NSString *)regex { return @"(?!x)x"; }

- (nullable NSRegularExpression *)regularExpressionWithError:(NSError **)error {
    return [NSRegularExpression regularExpressionWithPattern:self.regex options:0 error:error];
}

- (void)parse:(NSMutableAttributedString *)attributedString {}
- (void)match:(NSTextCheckingResult *)match attributedString:(NSMutableAttributedString *)attributedString {}

#pragma mark - 预处理（纯文本 → NSAttributedString，表格块替换为 Attachment）

- (NSAttributedString *)preprocessText:(NSString *)rawText
                                  font:(UIFont *)font
                                 color:(UIColor *)color {
    NSDictionary *textAttrs = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};

    NSArray<NSString *> *lines = [rawText componentsSeparatedByString:@"\n"];
    NSMutableArray<NEMarkdownTableRegion *> *regions = [NSMutableArray array];
    NSMutableSet<NSNumber *> *coveredLines = [NSMutableSet set];

    for (NSInteger i = 0; i < (NSInteger)lines.count; i++) {
        NSString *trimmed = [lines[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (![self isSeparatorLine:trimmed]) continue;
        if ([coveredLines containsObject:@(i)]) continue;

        NEMarkdownTableRegion *region = [[NEMarkdownTableRegion alloc] init];
        region.separatorLineIndex = i;

        // 向前找表头行
        if (i > 0) {
            NSString *prevTrimmed = [lines[i - 1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([prevTrimmed hasPrefix:@"|"]) {
                region.headerLineIndex = i - 1;
            } else if ([prevTrimmed containsString:@"|"]) {
                region.headerCellsFromTail = [self extractTrailingTableCellsFromLine:prevTrimmed];
            }
        }

        // 向后收集数据行
        NSMutableArray<NSNumber *> *dataIndices = [NSMutableArray array];
        NSInteger j = i + 1;
        while (j < (NSInteger)lines.count) {
            NSString *dataLine = [lines[j] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([dataLine hasPrefix:@"|"] && ![self isSeparatorLine:dataLine]) {
                [dataIndices addObject:@(j)];
                j++;
            } else {
                break;
            }
        }
        region.dataLineIndices = [dataIndices copy];
        [regions addObject:region];

        if (region.headerLineIndex >= 0) [coveredLines addObject:@(region.headerLineIndex)];
        [coveredLines addObject:@(i)];
        for (NSNumber *idx in dataIndices) [coveredLines addObject:idx];
    }

    // 逐行重建
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    NSInteger lineIdx = 0;
    NSArray<NEMarkdownTableRegion *> *sortedRegions =
        [regions sortedArrayUsingComparator:^NSComparisonResult(NEMarkdownTableRegion *a, NEMarkdownTableRegion *b) {
            return a.separatorLineIndex < b.separatorLineIndex ? NSOrderedAscending : NSOrderedDescending;
        }];
    NSInteger regionIdx = 0;

    while (lineIdx < (NSInteger)lines.count) {
        NEMarkdownTableRegion *region = (regionIdx < (NSInteger)sortedRegions.count) ? sortedRegions[regionIdx] : nil;

        if (region) {
            // 处理分隔行：插入 Attachment
            if (lineIdx == region.separatorLineIndex) {
                NEMarkdownTableData *tableData = [self buildTableDataFromRegion:region lines:lines];
                if (tableData) {
                    if (result.length > 0) {
                        [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:textAttrs]];
                    }
                    NEMarkdownTableAttachment *attachment = [self buildAttachmentWithData:tableData];
                    [result appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
                    [result appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:textAttrs]];
                }
                // 跳过整个区间
                NSInteger maxLine = region.separatorLineIndex;
                for (NSNumber *idx in region.dataLineIndices) {
                    maxLine = MAX(maxLine, idx.integerValue);
                }
                lineIdx = maxLine + 1;
                regionIdx++;
                continue;
            }

            // 跳过数据行（已随分隔行处理）
            BOOL isDataLine = NO;
            for (NSNumber *idx in region.dataLineIndices) {
                if (idx.integerValue == lineIdx) { isDataLine = YES; break; }
            }
            if (isDataLine) { lineIdx++; continue; }

            // 处理表头行
            if (lineIdx == region.headerLineIndex) {
                NSString *trimmed = [lines[lineIdx] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if ([trimmed hasPrefix:@"|"]) {
                    // 独立表头行：跳过
                    lineIdx++;
                    continue;
                } else if ([trimmed containsString:@"|"]) {
                    // 混合行：保留 | 之前的文字
                    NSString *beforePipe = [[trimmed componentsSeparatedByString:@"|"].firstObject
                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    if (beforePipe.length > 0) {
                        [result appendAttributedString:[[NSAttributedString alloc]
                            initWithString:[beforePipe stringByAppendingString:@"\n"]
                                attributes:textAttrs]];
                    }
                    lineIdx++;
                    continue;
                }
            }
        }

        // 普通行
        NSString *suffix = (lineIdx < (NSInteger)lines.count - 1) ? @"\n" : @"";
        [result appendAttributedString:[[NSAttributedString alloc]
            initWithString:[lines[lineIdx] stringByAppendingString:suffix]
                attributes:textAttrs]];
        lineIdx++;
    }

    return [result copy];
}

#pragma mark - 私有辅助

- (BOOL)isSeparatorLine:(NSString *)line {
    if (![line hasPrefix:@"|"] || ![line containsString:@"-"]) return NO;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"|:- \t"];
    for (NSInteger i = 0; i < (NSInteger)line.length; i++) {
        unichar c = [line characterAtIndex:i];
        if (![allowed characterIsMember:c]) return NO;
    }
    return YES;
}

- (NSArray<NSString *> *)extractTrailingTableCellsFromLine:(NSString *)line {
    NSRange pipeRange = [line rangeOfString:@"|"];
    if (pipeRange.location == NSNotFound) return @[];
    NSString *tableSection = [line substringFromIndex:pipeRange.location];
    return [self parseCellsFromLine:tableSection];
}

- (NSArray<NSString *> *)parseCellsFromLine:(NSString *)line {
    NSString *s = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([s hasPrefix:@"|"]) s = [s substringFromIndex:1];
    if ([s hasSuffix:@"|"]) s = [s substringToIndex:s.length - 1];
    NSArray<NSString *> *parts = [s componentsSeparatedByString:@"|"];
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *part in parts) {
        [result addObject:[part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    }
    return [result copy];
}

- (NSInteger)parseCellCountFromSeparator:(NSString *)sep {
    NSString *s = [sep stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([s hasPrefix:@"|"]) s = [s substringFromIndex:1];
    if ([s hasSuffix:@"|"]) s = [s substringToIndex:s.length - 1];
    return (NSInteger)[s componentsSeparatedByString:@"|"].count;
}

- (NSArray<NSNumber *> *)parseAlignmentsFromSeparator:(NSString *)sep count:(NSInteger)count {
    NSString *s = [sep stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([s hasPrefix:@"|"]) s = [s substringFromIndex:1];
    if ([s hasSuffix:@"|"]) s = [s substringToIndex:s.length - 1];
    NSArray<NSString *> *parts = [s componentsSeparatedByString:@"|"];

    NSMutableArray<NSNumber *> *result = [NSMutableArray array];
    for (NSString *cell in parts) {
        NSString *c = [cell stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        BOOL l = [c hasPrefix:@":"];
        BOOL r = [c hasSuffix:@":"];
        if (l && r) {
            [result addObject:@(NEMarkdownTableAlignmentCenter)];
        } else if (r) {
            [result addObject:@(NEMarkdownTableAlignmentRight)];
        } else {
            [result addObject:@(NEMarkdownTableAlignmentLeft)];
        }
    }
    while ((NSInteger)result.count < count) [result addObject:@(NEMarkdownTableAlignmentLeft)];
    if ((NSInteger)result.count > count) [result removeObjectsInRange:NSMakeRange(count, result.count - count)];
    return [result copy];
}

- (nullable NEMarkdownTableData *)buildTableDataFromRegion:(NEMarkdownTableRegion *)region
                                                     lines:(NSArray<NSString *> *)lines {
    NSString *sepLine = [lines[region.separatorLineIndex] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSInteger colCount = [self parseCellCountFromSeparator:sepLine];
    if (colCount <= 0) return nil;

    NSArray<NSNumber *> *alignments = [self parseAlignmentsFromSeparator:sepLine count:colCount];

    NSMutableArray<NSString *> *headers = [NSMutableArray array];
    if (region.headerLineIndex >= 0) {
        NSString *hLine = [lines[region.headerLineIndex] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [headers addObjectsFromArray:[self parseCellsFromLine:hLine]];
    } else if (region.headerCellsFromTail.count > 0) {
        [headers addObjectsFromArray:region.headerCellsFromTail];
    } else {
        for (NSInteger i = 1; i <= colCount; i++) {
            [headers addObject:[NSString stringWithFormat:@"列%ld", (long)i]];
        }
    }
    while ((NSInteger)headers.count < colCount) [headers addObject:@""];
    if ((NSInteger)headers.count > colCount) [headers removeObjectsInRange:NSMakeRange(colCount, headers.count - colCount)];

    NSMutableArray<NSArray<NSString *> *> *rows = [NSMutableArray array];
    for (NSNumber *idx in region.dataLineIndices) {
        NSString *dataLine = [lines[idx.integerValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSMutableArray<NSString *> *cells = [[self parseCellsFromLine:dataLine] mutableCopy];
        while ((NSInteger)cells.count < colCount) [cells addObject:@""];
        if ((NSInteger)cells.count > colCount) [cells removeObjectsInRange:NSMakeRange(colCount, cells.count - colCount)];
        [rows addObject:[cells copy]];
    }

    return [[NEMarkdownTableData alloc] initWithHeaders:[headers copy]
                                             alignments:alignments
                                                   rows:[rows copy]];
}

- (NEMarkdownTableAttachment *)buildAttachmentWithData:(NEMarkdownTableData *)data {
    CGFloat tableHeight = [NEMarkdownTableView calculateHeightWithData:data
                                                             maxWidth:_maxWidth
                                                           headerFont:_headerFont
                                                             cellFont:_cellFont
                                                          cellPadding:_cellPadding
                                                          borderWidth:_borderWidth];
    CGSize size = CGSizeMake(_maxWidth, MAX(tableHeight, 1));
    NEMarkdownTableView *tableView = [[NEMarkdownTableView alloc] initWithData:data maxWidth:_maxWidth];
    tableView.headerFont = _headerFont;
    tableView.cellFont = _cellFont;
    tableView.cellPadding = _cellPadding;
    tableView.borderWidth = _borderWidth;
    return [[NEMarkdownTableAttachment alloc] initWithTableView:tableView size:size];
}

@end
