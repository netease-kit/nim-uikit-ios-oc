// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageMultiForwardCell.h"

#import <NEChatKit/NECustomUtils.h>
#import "ChatCellConstantValue.h"
#import "NEChatUIConstant.h"
#import "NEEmotionTool.h"
#import "MessageContentModel.h"
#import "NSString+Chat.h"

static NSString *NEPinMultiForwardCutName(NSString *name) {
    if (![name isKindOfClass:[NSString class]] || name.length == 0) {
        return @"";
    }

    __block NSInteger count = 0;
    [name enumerateSubstringsInRange:NSMakeRange(0, name.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        count += 1;
    }];
    if (count <= 5) {
        return name;
    }

    __block NSInteger prefixCount = 0;
    __block NSUInteger prefixEnd = name.length;
    [name enumerateSubstringsInRange:NSMakeRange(0, name.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        prefixCount += 1;
        if (prefixCount == 2) {
            prefixEnd = NSMaxRange(substringRange);
            *stop = YES;
        }
    }];

    __block NSInteger suffixCount = 0;
    __block NSUInteger suffixStart = 0;
    [name enumerateSubstringsInRange:NSMakeRange(0, name.length)
                             options:NSStringEnumerationByComposedCharacterSequences | NSStringEnumerationReverse
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        suffixCount += 1;
        suffixStart = substringRange.location;
        if (suffixCount == 2) {
            *stop = YES;
        }
    }];

    NSString *left = [name substringToIndex:prefixEnd];
    NSString *right = [name substringFromIndex:suffixStart];
    return [NSString stringWithFormat:@"%@...%@", left, right];
}

@implementation NEBasePinMessageMultiForwardCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        if (_funMargin <= 0) {
            _funMargin = 5.2;
        }
        if (_titleLabelFontSize <= 0) {
            _titleLabelFontSize = 14;
        }
        if (_contentLabelFontSize <= 0) {
            _contentLabelFontSize = 14;
        }
        if (!_contentLabelColor) {
            _contentLabelColor = UIColor.ne_lightText;
        }
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (CGFloat)funMargin {
    return _funMargin > 0 ? _funMargin : 5.2;
}

- (CGFloat)titleLabelFontSize {
    return _titleLabelFontSize > 0 ? _titleLabelFontSize : 14;
}

- (CGFloat)contentLabelFontSize {
    return _contentLabelFontSize > 0 ? _contentLabelFontSize : 14;
}

- (UIColor *)contentLabelColor {
    return _contentLabelColor ?: UIColor.ne_lightText;
}

- (UIImageView *)backViewLeft {
    if (!_backViewLeft) {
        _backViewLeft = [[UIImageView alloc] init];
        _backViewLeft.translatesAutoresizingMaskIntoConstraints = NO;
        _backViewLeft.userInteractionEnabled = YES;
    }
    return _backViewLeft;
}

- (UILabel *)titleLabelLeft1 {
    if (!_titleLabelLeft1) {
        _titleLabelLeft1 = [[UILabel alloc] init];
        _titleLabelLeft1.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelLeft1.accessibilityIdentifier = @"id.name1";
    }
    return _titleLabelLeft1;
}

- (UILabel *)titleLabelLeft2 {
    if (!_titleLabelLeft2) {
        _titleLabelLeft2 = [[UILabel alloc] init];
        _titleLabelLeft2.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabelLeft2.text = chatLocalizable(@"chat_history_by");
        _titleLabelLeft2.textColor = UIColor.ne_darkText;
        _titleLabelLeft2.font = [UIFont systemFontOfSize:self.titleLabelFontSize > 0 ? self.titleLabelFontSize : 14];
        _titleLabelLeft2.accessibilityIdentifier = @"id.name2";
    }
    return _titleLabelLeft2;
}

- (UILabel *)contentLabelLeft1 {
    if (!_contentLabelLeft1) {
        _contentLabelLeft1 = [[UILabel alloc] init];
        _contentLabelLeft1.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeft1.numberOfLines = 3;
        _contentLabelLeft1.accessibilityIdentifier = @"id.content1";
    }
    return _contentLabelLeft1;
}

- (UILabel *)contentLabelLeft2 {
    if (!_contentLabelLeft2) {
        _contentLabelLeft2 = [[UILabel alloc] init];
        _contentLabelLeft2.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeft2.numberOfLines = 2;
        _contentLabelLeft2.accessibilityIdentifier = @"id.content2";
    }
    return _contentLabelLeft2;
}

- (UILabel *)contentLabelLeft3 {
    if (!_contentLabelLeft3) {
        _contentLabelLeft3 = [[UILabel alloc] init];
        _contentLabelLeft3.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabelLeft3.accessibilityIdentifier = @"id.content3";
    }
    return _contentLabelLeft3;
}

- (void)setupUI {
    [super setupUI];
    self.backViewLeft.layer.cornerRadius = 8;
    self.backViewLeft.layer.borderColor = multiForwardborderColor().CGColor;
    self.backViewLeft.layer.borderWidth = 1;

    [self.backView addSubview:self.backViewLeft];
    [NSLayoutConstraint activateConstraints:@[
        [self.backViewLeft.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:16],
        [self.backViewLeft.topAnchor constraintEqualToAnchor:self.line.bottomAnchor constant:12],
        [self.backViewLeft.widthAnchor constraintEqualToConstant:276],
        [self.backViewLeft.heightAnchor constraintEqualToConstant:100],
    ]];

    if (self.contentGesture) {
        [self.backViewLeft addGestureRecognizer:self.contentGesture];
    }
}

- (void)configure:(NEPinMessageModel *)item {
    [super configure:item];
    const CGFloat contentW = 248;
    UIFont *font = [UIFont systemFontOfSize:self.contentLabelFontSize];
    UILabel *titleLabel = self.titleLabelLeft1;
    UILabel *titleLabel2 = self.titleLabelLeft2;
    UILabel *contentLabel1 = self.contentLabelLeft1;
    UILabel *contentLabel2 = self.contentLabelLeft2;
    UILabel *contentLabel3 = self.contentLabelLeft3;

    titleLabel.attributedText = nil;
    titleLabel2.text = chatLocalizable(@"chat_history_by");
    contentLabel1.attributedText = nil;
    contentLabel2.attributedText = nil;
    contentLabel3.attributedText = nil;
    contentLabel1.hidden = NO;
    contentLabel2.hidden = YES;
    contentLabel3.hidden = YES;
    contentLabel1.numberOfLines = 3;
    contentLabel2.numberOfLines = 2;

    NSDictionary *data = [NECustomUtils dataOfCustomMessage:item.chatmodel.message.attachment];
    if (![data isKindOfClass:[NSDictionary class]]) return;

    NSString *sessionName = [data[@"sessionName"] isKindOfClass:[NSString class]] ? data[@"sessionName"] : nil;
    if (sessionName.length > 0) {
        titleLabel.attributedText = [NEEmotionTool getAttWithStr:sessionName
                                                            font:[UIFont systemFontOfSize:self.titleLabelFontSize]
                                                           color:UIColor.ne_darkText
                                                          offset:CGPointMake(0, -4)];
    } else {
        titleLabel2.text = chatLocalizable(@"chat_history");
    }

    NSArray *abstracts = [data[@"abstracts"] isKindOfClass:[NSArray class]] ? data[@"abstracts"] : nil;
    if (!abstracts) return;

    for (NSInteger i = 0; i < MIN(abstracts.count, 3); i++) {
        UILabel *contentLabel = contentLabel1;
        if (i == 1) contentLabel = contentLabel2;
        else if (i == 2) contentLabel = contentLabel3;

        NSDictionary *abstractItem = [abstracts[i] isKindOfClass:[NSDictionary class]] ? abstracts[i] : nil;
        if (!abstractItem) continue;
        NSString *contentText = @"";
        NSString *senderNick = [abstractItem[@"senderNick"] isKindOfClass:[NSString class]] ? abstractItem[@"senderNick"] : nil;
        if (senderNick) {
            senderNick = NEPinMultiForwardCutName(senderNick);
            contentText = senderNick;
            NSString *content = [abstractItem[@"content"] isKindOfClass:[NSString class]] ? abstractItem[@"content"] : nil;
            if (content) {
                contentText = [contentText stringByAppendingFormat:@"：%@", content];
            }
        }

        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 1;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        NSMutableAttributedString *attributedText = [NEEmotionTool getAttWithStr:contentText font:font color:self.contentLabelColor offset:CGPointMake(0, -4)];
        if (attributedText.length > 0) {
            [attributedText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attributedText.length)];
        }
        contentLabel.attributedText = attributedText;
    }

    NSInteger numCount1 = [NSString calculateMaxLinesWithWidth:contentW attributeString:contentLabel1.attributedText font:font];
    if (numCount1 == 1) {
        contentLabel2.numberOfLines = 2;
        contentLabel2.hidden = contentLabel2.attributedText == nil;
        NSInteger numCount2 = [NSString calculateMaxLinesWithWidth:contentW attributeString:contentLabel2.attributedText font:font];
        contentLabel3.hidden = !(contentLabel3.attributedText != nil && numCount2 == 1);
    } else if (numCount1 == 2) {
        contentLabel2.numberOfLines = 1;
        contentLabel2.hidden = contentLabel3.attributedText != nil;
        contentLabel3.hidden = YES;
    } else {
        contentLabel2.hidden = YES;
        contentLabel3.hidden = YES;
    }
}

@end
