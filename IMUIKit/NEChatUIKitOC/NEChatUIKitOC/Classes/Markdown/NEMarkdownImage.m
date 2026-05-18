// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEMarkdownImage.h"

NSNotificationName const NEMarkdownImageDidLoadNotification = @"NEMarkdownImageDidLoadNotification";

static NSString * const NEMarkdownImageRegex =
    @"!\\[[^\\[\\]]*\\]\\(\\s*\"?(\\S+?)\"?(?:\\s+\"[^\"]*\")?\\s*\\)";

// MARK: - 全局图片缓存
static NSCache<NSString *, UIImage *> *_imageCache = nil;
static dispatch_once_t _imageCacheOnceToken;

static NSCache<NSString *, UIImage *> *NEMarkdownSharedImageCache(void) {
    dispatch_once(&_imageCacheOnceToken, ^{
        _imageCache = [[NSCache alloc] init];
    });
    return _imageCache;
}

// MARK: - NEMarkdownImageAttachment

@interface NEMarkdownImageAttachment ()
@property (nonatomic, copy, readwrite) NSString *imageURL;
@property (nonatomic, assign, readwrite) CGFloat maxWidth;
@property (nonatomic, assign, readwrite) CGFloat maxHeight;
@property (nonatomic, assign, readwrite) CGSize placeholderSize;
@property (nonatomic, assign, readwrite) BOOL isLoaded;
@property (nonatomic, assign) CGSize displaySize;
@end

@implementation NEMarkdownImageAttachment

- (instancetype)initWithImageURL:(NSString *)imageURL
                        maxWidth:(CGFloat)maxWidth
                       maxHeight:(CGFloat)maxHeight
                 placeholderSize:(CGSize)placeholderSize {
    self = [super initWithData:nil ofType:nil];
    if (self) {
        _imageURL = [imageURL copy];
        _maxWidth = maxWidth;
        _maxHeight = maxHeight;
        _placeholderSize = placeholderSize;
        _displaySize = placeholderSize;
        _isLoaded = NO;
        self.image = [NEMarkdownImageAttachment generatePlaceholder:placeholderSize];
    }
    return self;
}

- (CGRect)attachmentBoundsForTextContainer:(nullable NSTextContainer *)textContainer
                      proposedLineFragment:(CGRect)lineFrag
                             glyphPosition:(CGPoint)position
                            characterIndex:(NSUInteger)charIndex {
    return CGRectMake(0, 0, _displaySize.width, _displaySize.height);
}

- (void)startDownload {
    UIImage *cached = [NEMarkdownSharedImageCache() objectForKey:self.imageURL];
    if (cached) {
        [self applyCachedImage:cached];
        return;
    }

    NSURL *url = [NSURL URLWithString:self.imageURL];
    if (!url) return;

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) return;
        UIImage *downloadedImage = [UIImage imageWithData:data];
        if (!downloadedImage) return;

        [NEMarkdownSharedImageCache() setObject:downloadedImage forKey:weakSelf.imageURL];

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf applyDownloadedImage:downloadedImage];
        });
    }];
    [task resume];
}

- (void)applyCachedImage:(UIImage *)cachedImage {
    CGSize constrainedSize = [NEMarkdownImageAttachment constrainSize:cachedImage.size
                                                            maxWidth:self.maxWidth
                                                           maxHeight:self.maxHeight];
    self.displaySize = constrainedSize;
    self.isLoaded = YES;
    self.image = [NEMarkdownImageAttachment resizeImage:cachedImage toSize:constrainedSize];
}

- (void)applyDownloadedImage:(UIImage *)downloadedImage {
    CGSize constrainedSize = [NEMarkdownImageAttachment constrainSize:downloadedImage.size
                                                            maxWidth:self.maxWidth
                                                           maxHeight:self.maxHeight];
    self.displaySize = constrainedSize;
    self.isLoaded = YES;
    self.image = [NEMarkdownImageAttachment resizeImage:downloadedImage toSize:constrainedSize];

    [[NSNotificationCenter defaultCenter] postNotificationName:NEMarkdownImageDidLoadNotification
                                                        object:nil
                                                      userInfo:@{
        @"url": self.imageURL,
        @"image": self.image ?: [NSNull null]
    }];
}

+ (CGSize)constrainSize:(CGSize)imageSize maxWidth:(CGFloat)maxWidth maxHeight:(CGFloat)maxHeight {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
        return CGSizeMake(maxWidth, maxWidth * 0.6);
    }

    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;

    if (width > maxWidth) {
        height = height * maxWidth / width;
        width = maxWidth;
    }

    if (height > maxHeight) {
        width = width * maxHeight / height;
        height = maxHeight;
    }

    return CGSizeMake(ceil(width), ceil(height));
}

+ (nullable UIImage *)generatePlaceholder:(CGSize)size {
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        // 背景
        [[UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.0] setFill];
        UIBezierPath *bgPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height)
                                                          cornerRadius:4];
        [bgPath fill];
        // 图标
        CGFloat iconSize = MIN(size.width, size.height) * 0.3;
        CGRect iconRect = CGRectMake((size.width - iconSize) / 2,
                                    (size.height - iconSize) / 2,
                                    iconSize, iconSize);
        [[UIColor colorWithRed:0.78 green:0.78 blue:0.78 alpha:1.0] setFill];
        UIBezierPath *iconPath = [UIBezierPath bezierPathWithRoundedRect:iconRect cornerRadius:2];
        [iconPath fill];
    }];
}

+ (nullable UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    }];
}

@end

// MARK: - NEMarkdownImage

@implementation NEMarkdownImage

- (instancetype)init {
    self = [super init];
    if (self) {
        _maxWidth = 200;
        _maxHeight = 300;
        _placeholderSize = CGSizeMake(120, 80);
    }
    return self;
}

- (NSString *)regex {
    return NEMarkdownImageRegex;
}

- (nullable NSRegularExpression *)regularExpressionWithError:(NSError **)error {
    return [NSRegularExpression regularExpressionWithPattern:self.regex options:0 error:error];
}

- (void)parse:(NSMutableAttributedString *)attributedString {
    NSInteger location = 0;
    NSError *error = nil;
    NSRegularExpression *regex = [self regularExpressionWithError:&error];
    if (!regex) return;
    while (YES) {
        NSRange searchRange = NSMakeRange(location, attributedString.length - location);
        NSTextCheckingResult *regexMatch = [regex firstMatchInString:attributedString.string
                                                             options:NSMatchingWithoutAnchoringBounds
                                                               range:searchRange];
        if (!regexMatch) break;
        NSInteger oldLength = attributedString.length;
        [self match:regexMatch attributedString:attributedString];
        NSInteger newLength = attributedString.length;
        location = regexMatch.range.location + regexMatch.range.length + newLength - oldLength;
    }
}

- (void)match:(NSTextCheckingResult *)match attributedString:(NSMutableAttributedString *)attributedString {
    if (match.numberOfRanges <= 1) return;

    NSRange urlRange = [match rangeAtIndex:1];
    NSString *urlStr = [attributedString.string substringWithRange:urlRange];

    NEMarkdownImageAttachment *attachment =
        [[NEMarkdownImageAttachment alloc] initWithImageURL:urlStr
                                                   maxWidth:self.maxWidth
                                                  maxHeight:self.maxHeight
                                            placeholderSize:self.placeholderSize];

    NSAttributedString *imageAttrStr = [NSAttributedString attributedStringWithAttachment:attachment];
    [attributedString replaceCharactersInRange:match.range withAttributedString:imageAttrStr];

    [attachment startDownload];
}

@end
