// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownTableAttachment.h"

// MARK: - UIView 截图扩展（私有）

@interface UIView (NEMarkdownRenderToImage)
- (nullable UIImage *)ne_renderToImageWithSize:(CGSize)size;
@end

@implementation UIView (NEMarkdownRenderToImage)

- (nullable UIImage *)ne_renderToImageWithSize:(CGSize)size {
    if (self.frame.size.width <= 0 || self.frame.size.height <= 0) {
        self.frame = CGRectMake(0, 0, size.width, size.height);
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [self.layer renderInContext:ctx.CGContext];
    }];
}

@end

// MARK: - NEMarkdownTableAttachment

@interface NEMarkdownTableAttachment ()
@property (nonatomic, strong, readwrite) NEMarkdownTableView *tableView;
@property (nonatomic, assign, readwrite) CGSize tableSize;
@end

@implementation NEMarkdownTableAttachment

- (instancetype)initWithTableView:(NEMarkdownTableView *)tableView size:(CGSize)size {
    self = [super initWithData:nil ofType:nil];
    if (self) {
        _tableView = tableView;
        _tableSize = size;

        // 在主线程预渲染为静态图片（方案 A）
        if ([NSThread isMainThread]) {
            self.image = [tableView ne_renderToImageWithSize:size];
        } else {
            __block UIImage *rendered = nil;
            dispatch_sync(dispatch_get_main_queue(), ^{
                rendered = [tableView ne_renderToImageWithSize:size];
            });
            self.image = rendered;
        }
    }
    return self;
}

- (CGRect)attachmentBoundsForTextContainer:(nullable NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {
    return CGRectMake(0, 0, _tableSize.width, _tableSize.height);
}

- (void)embedIntoTextView:(UITextView *)textView atCharacterIndex:(NSInteger)characterIndex {
    NSLayoutManager *layoutManager = textView.layoutManager;
    NSUInteger glyphIndex = [layoutManager glyphIndexForCharacterAtIndex:characterIndex];
    CGRect glyphRect = [layoutManager boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)
                                               inTextContainer:textView.textContainer];
    glyphRect.origin.x += textView.textContainerInset.left;
    glyphRect.origin.y += textView.textContainerInset.top;

    // 移除旧的包裹视图
    for (UIView *subview in [textView.subviews copy]) {
        if ([subview isKindOfClass:[NEMarkdownTableScrollWrapper class]]) {
            NEMarkdownTableScrollWrapper *wrapper = (NEMarkdownTableScrollWrapper *)subview;
            if (wrapper.attachment == self) {
                [wrapper removeFromSuperview];
            }
        }
    }

    NEMarkdownTableScrollWrapper *wrapper =
        [[NEMarkdownTableScrollWrapper alloc] initWithAttachment:self
                                                      tableView:self.tableView
                                                          frame:glyphRect];
    [textView addSubview:wrapper];
}

@end

// MARK: - NEMarkdownTableScrollWrapper

@implementation NEMarkdownTableScrollWrapper

- (instancetype)initWithAttachment:(NEMarkdownTableAttachment *)attachment
                         tableView:(NEMarkdownTableView *)tableView
                             frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _attachment = attachment;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = YES;
        self.bounces = NO;
        self.scrollEnabled = (tableView.frame.size.width > frame.size.width);

        tableView.frame = CGRectMake(0, 0, tableView.frame.size.width, tableView.frame.size.height);
        [self addSubview:tableView];
        self.contentSize = tableView.frame.size;
    }
    return self;
}

@end
