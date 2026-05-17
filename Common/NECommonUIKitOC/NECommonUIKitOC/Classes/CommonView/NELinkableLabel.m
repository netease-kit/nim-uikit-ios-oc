// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NELinkableLabel.h"

@interface NELinkableLabel ()

@property (nonatomic, assign) NSTextCheckingTypes detectorTypes;
@property (nonatomic, copy) NSDictionary<NSAttributedStringKey, id> *linkAttributes;

@end

@implementation NELinkableLabel

+ (UIColor *)defaultLinkColor {
  if (@available(iOS 13.0, *)) {
    return UIColor.systemBlueColor;
  }
  return [UIColor colorWithRed:0.0 green:122.0 / 255.0 blue:1.0 alpha:1.0];
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setup];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setup];
  }
  return self;
}

- (void)setup {
  UIColor *linkColor = [NELinkableLabel defaultLinkColor];
  self.detectorTypes = NSTextCheckingTypeLink | NSTextCheckingTypePhoneNumber;
  self.linkAttributes = @{
    NSForegroundColorAttributeName : linkColor,
    NSUnderlineColorAttributeName : linkColor,
    NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
  };
  self.userInteractionEnabled = YES;
  self.numberOfLines = 0;

  UITapGestureRecognizer *tap =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
  tap.cancelsTouchesInView = YES;
  [self addGestureRecognizer:tap];
}

- (void)updateLinkDetection {
  NSString *plainText = self.text ?: self.attributedText.string;
  if (plainText.length == 0) {
    self.attributedText = nil;
    return;
  }

  NSMutableAttributedString *baseAttributedString = self.attributedText ?
      [self.attributedText mutableCopy] :
      [[NSMutableAttributedString alloc] initWithString:plainText];

  NSError *error = nil;
  NSDataDetector *detector =
      [NSDataDetector dataDetectorWithTypes:self.detectorTypes error:&error];
  if (!detector || error) {
    self.attributedText = baseAttributedString;
    return;
  }

  NSArray<NSTextCheckingResult *> *matches =
      [detector matchesInString:plainText
                        options:0
                          range:NSMakeRange(0, plainText.length)];

  for (NSTextCheckingResult *match in matches) {
    NSURL *url = [self generateURLForMatch:match];
    if (!url) {
      continue;
    }

    NSMutableArray<NSDictionary *> *pendingUpdates = [NSMutableArray array];
    [baseAttributedString enumerateAttributesInRange:match.range
                                             options:0
                                          usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs,
                                                       NSRange range,
                                                       BOOL *stop) {
      NSMutableDictionary<NSAttributedStringKey, id> *mergedAttributes =
          attrs ? [attrs mutableCopy] : [NSMutableDictionary dictionary];
      [mergedAttributes addEntriesFromDictionary:self.linkAttributes];
      mergedAttributes[NSLinkAttributeName] = url;
      [pendingUpdates addObject:@{
        @"range" : [NSValue valueWithRange:range],
        @"attributes" : mergedAttributes,
      }];
    }];

    for (NSDictionary *update in pendingUpdates) {
      NSRange range = [update[@"range"] rangeValue];
      NSDictionary<NSAttributedStringKey, id> *attributes = update[@"attributes"];
      [baseAttributedString setAttributes:attributes range:range];
    }
  }

  self.attributedText = baseAttributedString;
}

- (nullable NSURL *)generateURLForMatch:(NSTextCheckingResult *)match {
  switch (match.resultType) {
    case NSTextCheckingTypePhoneNumber: {
      if (match.phoneNumber.length == 0) {
        return nil;
      }
      return [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", match.phoneNumber]];
    }
    case NSTextCheckingTypeLink:
      return match.URL;
    default:
      return nil;
  }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
  NSAttributedString *attributedText = self.attributedText;
  if (attributedText.length == 0) {
    return;
  }

  CGPoint point = [gesture locationInView:self];
  NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:self.bounds.size];
  textContainer.lineFragmentPadding = 0;
  textContainer.lineBreakMode = self.lineBreakMode;
  textContainer.maximumNumberOfLines = self.numberOfLines;

  NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
  [layoutManager addTextContainer:textContainer];

  NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedText];
  [textStorage addLayoutManager:layoutManager];

  NSUInteger charIndex =
      [layoutManager characterIndexForPoint:point
                             inTextContainer:textContainer
            fractionOfDistanceBetweenInsertionPoints:nil];

  __block BOOL found = NO;
  [attributedText enumerateAttribute:NSLinkAttributeName
                             inRange:NSMakeRange(0, attributedText.length)
                             options:0
                          usingBlock:^(id value, NSRange range, BOOL *stop) {
    if ([value isKindOfClass:[NSURL class]] && NSLocationInRange(charIndex, range)) {
      found = YES;
      if ([self.delegate respondsToSelector:@selector(didTapLink:)]) {
        [self.delegate didTapLink:(NSURL *)value];
      }
      *stop = YES;
    }
  }];

  if (!found && [self.delegate respondsToSelector:@selector(didTapLink:)]) {
    [self.delegate didTapLink:nil];
  }
}

@end
