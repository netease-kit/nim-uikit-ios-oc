// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEBaseChatInputView.h"
#import <NEBaseUIKitOC/SearchTextField.h>
#import "NEChatUIConstant.h"
#import "ChatRecordView.h"
#import "ChatUIConfig.h"
#import "InputEmoticonContainerView.h"
#import "NEChatMoreActionView.h"
#import "NEEmotionTool.h"
#import "NEInputMoreCell.h"
#import "AIChatViewController.h"
#import <NEChatKit/NEChatKit.h>

#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>

@interface InputEmoticonContainerView (NEBaseChatInputLayout)
@property (nonatomic, assign) CGFloat contentVerticalOffset;
@end


NSString *const yxAtMsg = @"yxAitMsg";
NSInteger const atRangeOffset = 1;
NSString *const atSegmentsKey = @"segments";
NSString *const atTextKey = @"text";

@interface NEBaseChatInputView () <ChatRecordViewDelegate, InputEmoticonContainerViewDelegate, UITextViewDelegate, NEMoreViewDelegate, UITextFieldDelegate, AIChatViewDelegate>

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, weak) id<UITextInput> textInput;
@property (nonatomic, assign) BOOL expandButtonInitialized;
@property (nonatomic, assign) BOOL aiChatButtonInitialized;
@property (nonatomic, strong) InputEmoticonContainerView *inputEmoticonContainerView;

@end

@implementation NEBaseChatInputView

@synthesize expandButton = _expandButton;
@synthesize aiChatButton = _aiChatButton;

#pragma mark - Init

- (instancetype)initWithConversationType:(V2NIMConversationType)conversationType {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.conversationType = conversationType;
        [self commonUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - commonUI

- (void)commonUI {
    self.accessibilityIdentifier = @"id.chatInputView";
    _currentType = ChatMenuTypeText;
    _menuHeight = 100.0;
    _contentHeight = 204.0;
    _atRangeCache = [NSMutableDictionary dictionary];
    _nickAccidList = [NSMutableArray array];
    _nickAccidDic = [NSMutableDictionary dictionary];
    _chatInpuMode = ChatInputModeNormal;
    _textLimit = 20;
    _aiChatViewControllerTopConstant = 54;
}

#pragma mark - Lazy Getters

- (UITextView *)textView {
    if (!_textView) {
        NETextView *textView = [[NETextView alloc] init];
        textView.placeholderLabel.numberOfLines = 1;
        _textView = textView;
        _textView.layer.cornerRadius = 8;
        _textView.font = [UIFont systemFontOfSize:16];
        _textView.clipsToBounds = YES;
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.backgroundColor = UIColor.clearColor;
        _textView.returnKeyType = UIReturnKeySend;
        _textView.typingAttributes = @{
            NSForegroundColorAttributeName: ChatUIConfig.shared.messageProperties.inputTextColor,
            NSFontAttributeName: [UIFont systemFontOfSize:16]
        };
        _textView.linkTextAttributes = @{
            NSForegroundColorAttributeName: ChatUIConfig.shared.messageProperties.inputTextColor,
            NSFontAttributeName: [UIFont systemFontOfSize:16]
        };
        _textView.dataDetectorTypes = 0;
        _textView.accessibilityIdentifier = @"id.chatMessageInput";

        // 创建自定义菜单项
        UIMenuItem *lineBreakItem = [[UIMenuItem alloc] initWithTitle:chatLocalizable(@"line_break")
                                                               action:@selector(lineBreakAction)];
        [UIMenuController sharedMenuController].menuItems = @[lineBreakItem];
    }
    return _textView;
}

- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] init];
        _backView.translatesAutoresizingMaskIntoConstraints = NO;
        _backView.backgroundColor = UIColor.clearColor;
        _backView.clipsToBounds = YES;
        _backView.layer.cornerRadius = 8;
    }
    return _backView;
}

- (UIView *)expandButton {
    if (!_expandButton && !self.expandButtonInitialized) {
        self.expandButtonInitialized = YES;
        if (!IMKitConfigCenter.shared.enableRichTextMessage) return nil;
        _expandButton = [[ExpandButton alloc] init];
        _expandButton.translatesAutoresizingMaskIntoConstraints = NO;
        _expandButton.backgroundColor = UIColor.clearColor;
        _expandButton.accessibilityIdentifier = @"id.chatExpandButton";
    }
    return _expandButton;
}

- (void)setExpandButton:(UIView *)expandButton {
    self.expandButtonInitialized = YES;
    _expandButton = expandButton;
}

- (UIView *)aiChatButton {
    if (!_aiChatButton && !self.aiChatButtonInitialized) {
        self.aiChatButtonInitialized = YES;
        if (!IMKitConfigCenter.shared.enableAIChatHelper) return nil;
        _aiChatButton = [[ExpandButton alloc] init];
        _aiChatButton.translatesAutoresizingMaskIntoConstraints = NO;
        _aiChatButton.backgroundColor = UIColor.clearColor;
        _aiChatButton.accessibilityIdentifier = @"id.aiChatButton";
    }
    return _aiChatButton;
}

- (void)setAiChatButton:(UIView *)aiChatButton {
    self.aiChatButtonInitialized = YES;
    _aiChatButton = aiChatButton;
}

- (UIStackView *)stackView {
    if (!_stackView) {
        _stackView = [[UIStackView alloc] init];
        _stackView.accessibilityIdentifier = @"id.chatInputStackView";
    }
    return _stackView;
}

- (ChatRecordView *)recordView {
    if (!_recordView) {
        _recordView = [[ChatRecordView alloc] initWithFrame:CGRectZero];
        _recordView.delegate = self;
    }
    return _recordView;
}

- (UIView *)multipleLineView {
    if (!_multipleLineView) {
        _multipleLineView = [[UIView alloc] init];
        _multipleLineView.translatesAutoresizingMaskIntoConstraints = NO;
        _multipleLineView.backgroundColor = UIColor.whiteColor;
        _multipleLineView.clipsToBounds = NO;
        _multipleLineView.hidden = YES;
        _multipleLineView.layer.cornerRadius = 6.0;
        _multipleLineView.layer.shadowColor = UIColor.blackColor.CGColor;
        _multipleLineView.layer.shadowOpacity = 0.5;
        _multipleLineView.layer.shadowOffset = CGSizeMake(3, 3);
        _multipleLineView.layer.shadowRadius = 5;
        _multipleLineView.layer.masksToBounds = NO;
    }
    return _multipleLineView;
}

- (UITextField *)titleField {
    if (!_titleField) {
        _titleField = [[NESingleLineTextField alloc] init];
        _titleField.translatesAutoresizingMaskIntoConstraints = NO;
        _titleField.font = [UIFont systemFontOfSize:18.0];
        _titleField.textColor = UIColor.ne_darkText;
        _titleField.returnKeyType = UIReturnKeySend;
        // 无障碍/自动化标识：富文本编辑面的标题输入框。
        _titleField.accessibilityIdentifier = @"id.richTextTitle";
        _titleField.clearButtonMode = UITextFieldViewModeNever;
        _titleField.attributedPlaceholder = [[NSAttributedString alloc]
            initWithString:chatLocalizable(@"multiple_line_placleholder")
                attributes:@{NSForegroundColorAttributeName: ChatUIConfig.shared.messageProperties.inputTextColor}];
    }
    return _titleField;
}

- (UIView *)multipleLineExpandButton {
    if (!_multipleLineExpandButton) {
        _multipleLineExpandButton = [[ExpandButton alloc] init];
        _multipleLineExpandButton.translatesAutoresizingMaskIntoConstraints = NO;
        _multipleLineExpandButton.backgroundColor = UIColor.clearColor;
    }
    return _multipleLineExpandButton;
}

- (UIView *)multipleSendButton {
    if (!_multipleSendButton) {
        _multipleSendButton = [[ExpandButton alloc] init];
        _multipleSendButton.translatesAutoresizingMaskIntoConstraints = NO;
        _multipleSendButton.backgroundColor = UIColor.clearColor;
        [(ExpandButton *)_multipleSendButton setImage:chatLoadImage(@"multiple_send_image") forState:UIControlStateNormal];
        // 无障碍/自动化标识：多行编辑态下的发送按钮（此前没有标识，UI 回归无法稳定点按）。
        _multipleSendButton.accessibilityIdentifier = @"id.sendButton";
        _multipleSendButton.isAccessibilityElement = YES;
        _multipleSendButton.accessibilityLabel = chatLocalizable(@"send");
    }
    return _multipleSendButton;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // 再撑一次，实测变成两倍宽（例如 402 → 804），表情网格与页指示器都会溢出；
    CGFloat hostWidth = CGRectGetWidth(self.contentView.bounds);
    CGFloat hostHeight = CGRectGetHeight(self.contentView.bounds);
    if (hostWidth <= 0 || hostHeight <= 0) {
        return;
    }
    BOOL adaptive = NEAdaptiveDeviceGate.adaptiveHostActive;
    if (_emojiView) {
        CGFloat emojiHeight = adaptive ? hostHeight : CGRectGetHeight(_emojiView.frame);
        _emojiView.frame = CGRectMake(0, 0, hostWidth, emojiHeight);
        _inputEmoticonContainerView.frame = _emojiView.bounds;
    }
    if (adaptive && _chatAddMoreView) {
        _chatAddMoreView.translatesAutoresizingMaskIntoConstraints = YES;
        _chatAddMoreView.frame = CGRectMake(0, CGRectGetMinY(_chatAddMoreView.frame), hostWidth, hostHeight);
        [_chatAddMoreView setupConstraints];
    }
}

- (UIView *)emojiView {
    if (!_emojiView) {
        CGFloat hostWidth = CGRectGetWidth(self.bounds) > 0 ? CGRectGetWidth(self.bounds) : kScreenWidth();
        _emojiView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, hostWidth, 200)];
        _emojiView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _emojiView.hidden = YES;
        _emojiView.backgroundColor = UIColor.clearColor;
        [_emojiView addSubview:self.inputEmoticonContainerView];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(missClickEmoj)];
        [_emojiView addGestureRecognizer:tap];
    }
    return _emojiView;
}

- (InputEmoticonContainerView *)inputEmoticonContainerView {
    if (!_inputEmoticonContainerView) {
        CGFloat hostWidth = CGRectGetWidth(self.bounds) > 0 ? CGRectGetWidth(self.bounds) : kScreenWidth();
        _inputEmoticonContainerView = [[InputEmoticonContainerView alloc]
            initWithFrame:CGRectMake(0, 0, hostWidth, 200)
              accentColor:self.emoticonThemeColor];
        _inputEmoticonContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _inputEmoticonContainerView.contentVerticalOffset = self.emoticonContentVerticalOffset;
        _inputEmoticonContainerView.delegate = self;
    }
    return _inputEmoticonContainerView;
}

- (UIColor *)emoticonThemeColor {
    return UIColor.ne_defaultPrimaryColor;
}

- (CGFloat)emoticonContentVerticalOffset {
    return 0;
}

- (NEChatMoreActionView *)chatAddMoreView {
    if (!_chatAddMoreView) {
        CGFloat hostWidth = CGRectGetWidth(self.bounds) > 0 ? CGRectGetWidth(self.bounds) : kScreenWidth();
        _chatAddMoreView = [[NEChatMoreActionView alloc] initWithFrame:CGRectMake(0, 0, hostWidth, 200)];
        _chatAddMoreView.translatesAutoresizingMaskIntoConstraints = NO;
        _chatAddMoreView.hidden = YES;
        _chatAddMoreView.delegate = self;
    }
    return _chatAddMoreView;
}

- (AIChatViewController *)aiChatViewController {
    if (!_aiChatViewController) {
        _aiChatViewController = [[AIChatViewController alloc] init];
        _aiChatViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        _aiChatViewController.view.clipsToBounds = YES;
        _aiChatViewController.delegate = self;
    }
    return _aiChatViewController;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
    }
    return _contentView;
}

- (UIView *)greyView {
    if (!_greyView) {
        _greyView = [[UIView alloc] init];
    }
    return _greyView;
}

#pragma mark - Record / Emoji / More Actions

- (void)addRecordView {
    _currentType = ChatMenuTypeAudio;
    [self.textView resignFirstResponder];
    [self.titleField resignFirstResponder];
    _contentSubView.hidden = YES;
    _contentSubView = self.recordView;
    _contentSubView.hidden = NO;
}

- (void)addEmojiView {
    _currentType = ChatMenuTypeEmoji;
    [self.textView resignFirstResponder];
    [self.titleField resignFirstResponder];
    _contentSubView.hidden = YES;
    _contentSubView = self.emojiView;
    [self.inputEmoticonContainerView resetToFirstEmojiPage];
    _contentSubView.hidden = NO;
}

- (void)addMoreActionView {
    _currentType = ChatMenuTypeAddMore;
    [self.textView resignFirstResponder];
    [self.titleField resignFirstResponder];
    _contentSubView.hidden = YES;
    _contentSubView = self.chatAddMoreView;
    _contentSubView.hidden = NO;
}

#pragma mark - Send Text

- (void)sendText {
    NSString *text = [self getRealSendText:self.textView.attributedText];
    if (!text) return;
    [self.delegate sendText:text attribute:self.textView.attributedText];
    [self clearTextInputAfterSend];
}

- (void)clearTextInputAfterSend {
    self.titleField.text = @"";
    self.textView.text = @"";
    self.textView.selectedRange = NSMakeRange(0, 0);
    [self.textView setContentOffset:CGPointZero animated:NO];
    if ([self.textView respondsToSelector:@selector(refreshPlaceholder)]) {
        [(NETextView *)self.textView refreshPlaceholder];
    }
    [self.textView setNeedsLayout];
}

#pragma mark - At Cache

- (void)clearAtCache {
    [self.nickAccidList removeAllObjects];
    [self.nickAccidDic removeAllObjects];
}

#pragma mark - Real Send Text

- (nullable NSString *)getRealSendText:(NSAttributedString *)attribute {
    if (![attribute isKindOfClass:[NSAttributedString class]]) {
        return nil;
    }
    NSMutableString *muta = [NSMutableString string];
    [attribute enumerateAttributesInRange:NSMakeRange(0, attribute.length)
                                 options:0
                              usingBlock:^(NSDictionary *dics, NSRange range, BOOL *stop) {
        id attachment = dics[NSAttachmentAttributeName];
        if ([attachment isKindOfClass:[NEEmotionAttachment class]]) {
            NEEmotionAttachment *neAttachment = (NEEmotionAttachment *)attachment;
            if (neAttachment.emotion.tag) {
                [muta appendString:neAttachment.emotion.tag];
            }
        } else if (range.location + range.length <= attribute.length) {
            [muta appendString:[attribute attributedSubstringFromRange:range].string];
        }
    }];
    return muta;
}

#pragma mark - Remote Extension

- (nullable NSDictionary *)getRemoteExtension:(nullable NSAttributedString *)attri {
    if (!attri) return nil;
    NSMutableDictionary *atDic = [NSMutableDictionary dictionary];
    NSString *string = attri.string;
    [attri enumerateAttribute:NSForegroundColorAttributeName
                      inRange:NSMakeRange(0, attri.length)
                      options:0
                   usingBlock:^(id value, NSRange findRange, BOOL *stop) {
        if (![value isKindOfClass:[UIColor class]]) return;
        if (![self isEqualToColor:(UIColor *)value color2:UIColor.ne_defaultPrimaryColor]) return;
        if (findRange.location + findRange.length > string.length) return;
        NSString *text = [string substringWithRange:findRange];
        NSString *accid = self.nickAccidDic[text];
        if (accid) {
            id oldDic = atDic[accid];
            NSMutableDictionary *dic = [oldDic isKindOfClass:[NSDictionary class]] ? [oldDic mutableCopy] : [NSMutableDictionary dictionary];
            id oldArray = dic[atSegmentsKey];
            NSMutableArray *array = [oldArray isKindOfClass:[NSArray class]] ? [oldArray mutableCopy] : [NSMutableArray array];
            MessageAtInfoModel *model = [[MessageAtInfoModel alloc] init];
            model.start = findRange.location;
            model.end = model.start + findRange.length;
            id object = [model yx_modelToJSONObject];
            if (object) [array addObject:object];
            dic[atSegmentsKey] = array;
            dic[atTextKey] = [text stringByAppendingString:@" "];
            dic[@"accid"] = accid;
            atDic[accid] = dic;
        }
    }];
    return atDic.count > 0 ? @{yxAtMsg: atDic} : nil;
}

- (nullable NSDictionary *)getAtRemoteExtension:(nullable NSAttributedString *)attri {
    if (!attri) return nil;
    NSMutableDictionary *atDic = [NSMutableDictionary dictionary];
    NSString *string = attri.string;
    [attri enumerateAttribute:NSForegroundColorAttributeName
                      inRange:NSMakeRange(0, attri.length)
                      options:0
                   usingBlock:^(id value, NSRange findRange, BOOL *stop) {
        if (![value isKindOfClass:[UIColor class]]) return;
        if (![self isEqualToColor:(UIColor *)value color2:UIColor.ne_defaultPrimaryColor]) return;
        if (findRange.location + findRange.length > string.length) return;
        NSString *text = [string substringWithRange:findRange];
        NSString *accid = self.nickAccidDic[text];
        if (accid) {
            id oldDic = atDic[accid];
            NSMutableDictionary *dic = [oldDic isKindOfClass:[NSDictionary class]] ? [oldDic mutableCopy] : [NSMutableDictionary dictionary];
            id oldArray = dic[atSegmentsKey];
            NSMutableArray *array = [oldArray isKindOfClass:[NSArray class]] ? [oldArray mutableCopy] : [NSMutableArray array];
            MessageAtInfoModel *model = [[MessageAtInfoModel alloc] init];
            // 计算at前有表情导致索引新增的数量
            NSRange frontRange = NSMakeRange(0, MIN(findRange.location, attri.length));
            NSInteger expandIndex = [self getConvertedExtraIndex:[attri attributedSubstringFromRange:frontRange]];
            model.start = findRange.location + expandIndex;
            NSInteger nameExpandCount = [self getConvertedExtraIndex:[attri attributedSubstringFromRange:findRange]];
            model.end = model.start + findRange.length + nameExpandCount;
            id object = [model yx_modelToJSONObject];
            if (object) [array addObject:object];
            dic[atSegmentsKey] = array;
            dic[atTextKey] = [text stringByAppendingString:@" "];
            dic[@"accid"] = accid;
            atDic[accid] = dic;
        }
    }];
    return atDic.count > 0 ? @{yxAtMsg: atDic} : nil;
}

#pragma mark - Color Comparison

- (BOOL)isEqualToColor:(UIColor *)color1 color2:(UIColor *)color2 {
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    if (![color1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1]) return NO;
    if (![color2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2]) return NO;
    return fabs(r1 - r2) < 0.001 && fabs(g1 - g2) < 0.001 && fabs(b1 - b2) < 0.001 && fabs(a1 - a2) < 0.001;
}

#pragma mark - Button Event

- (void)buttonEvent:(UIButton *)button {
    button.selected = !button.selected;
    if ((button.tag - 5) != 2 && button != self.currentButton) {
        self.currentButton.selected = NO;
        self.currentButton = button;
    }
    switch (button.tag - 5) {
        case 0: [self addRecordView]; break;
        case 1: [self addEmojiView]; break;
        case 2: button.selected = YES; break;
        case 3: [self addMoreActionView]; break;
        default: break;
    }
    [self.delegate willSelectItem:button index:button.tag - 5];
}

#pragma mark - Line Break

- (void)lineBreakAction {
    UITextRange *selectedRange = self.textView.selectedTextRange;
    if (!selectedRange) return;
    [self.textView replaceRange:selectedRange withText:@"\n"];
}

#pragma mark - Miss Click Emoji

- (void)missClickEmoj {
    NSLog(@"click one px space");
}

#pragma mark - Stop Record Animation

- (void)stopRecordAnimation {
    self.greyView.hidden = YES;
    [self.recordView stopRecordAnimation];
}

#pragma mark - InputEmoticonContainerViewDelegate

- (void)selectedEmoticon:(NSString *)emoticonID
           emotCatalogID:(NSString *)emotCatalogID
             description:(NSString *)description {
    if (emoticonID.length == 0) {
        // 删除键
        [self.delegate textViewDidChange];
        [self.textView deleteBackward];
    } else {
        NSRange range = self.textView.selectedRange;
        range.location = MIN(range.location, (NSUInteger)self.textView.attributedText.length);
        NSMutableAttributedString *attribute = [NEEmotionTool getAttWithStr:description
                                                                       font:[UIFont systemFontOfSize:16]
                                                                      color:UIColor.ne_darkText
                                                                     offset:CGPointMake(0, -4)];
        if (!attribute) return;
        NSMutableAttributedString *mutaAttribute = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
        [mutaAttribute insertAttributedString:attribute atIndex:range.location];
        self.textView.attributedText = mutaAttribute;
        self.textView.selectedRange = NSMakeRange(range.location + attribute.length, 0);
        self.textView.font = [UIFont systemFontOfSize:16];

        [self textViewDidChange:self.textView];
        [self.delegate textViewDidChange];
    }
}

- (void)didPressSend:(UIButton *)sender {
    [self sendText];
}

- (void)didSelectSticker:(NIMInputSticker *)sticker {
    if ([self.delegate respondsToSelector:@selector(didSelectSticker:)]) {
        [self.delegate didSelectSticker:sticker];
    }
}

#pragma mark - Check @Message

- (nullable NSValue *)checkRemoveAtMessageWithRange:(NSRange)range attribute:(NSAttributedString *)attribute {
    if (![attribute isKindOfClass:[NSAttributedString class]] || attribute.length == 0 || range.location == NSNotFound) {
        return nil;
    }
    __block NSRange temRange = NSMakeRange(NSNotFound, 0);
    NSInteger start = range.location;
    [attribute enumerateAttribute:NSForegroundColorAttributeName
                          inRange:NSMakeRange(0, attribute.length)
                          options:0
                       usingBlock:^(id value, NSRange findRange, BOOL *stop) {
        if (![value isKindOfClass:[UIColor class]]) return;
        if (![self isEqualToColor:(UIColor *)value color2:UIColor.ne_defaultPrimaryColor]) return;
        if ((NSInteger)findRange.location <= start &&
            start < (NSInteger)(findRange.location + findRange.length + atRangeOffset)) {
            NSUInteger safeLength = MIN(findRange.length + atRangeOffset, attribute.length - findRange.location);
            temRange = NSMakeRange(findRange.location, safeLength);
            *stop = YES;
        }
    }];
    if (temRange.location == NSNotFound) return nil;
    return [NSValue valueWithRange:temRange];
}

- (nullable NSValue *)findShowPositionWithRange:(NSRange)range attribute:(NSAttributedString *)attribute {
    if (![attribute isKindOfClass:[NSAttributedString class]] || attribute.length == 0 || range.location == NSNotFound) {
        return nil;
    }
    __block NSRange showRange = NSMakeRange(NSNotFound, 0);
    NSInteger start = range.location;
    [attribute enumerateAttribute:NSForegroundColorAttributeName
                          inRange:NSMakeRange(0, attribute.length)
                          options:0
                       usingBlock:^(id value, NSRange findRange, BOOL *stop) {
        if (![value isKindOfClass:[UIColor class]]) return;
        if (![self isEqualToColor:(UIColor *)value color2:UIColor.ne_defaultPrimaryColor]) return;
        NSInteger findStart = findRange.location;
        NSInteger findEnd = findRange.location + findRange.length + atRangeOffset;
        if (findStart <= start && start < findEnd) {
            if (findEnd - start > start - findStart) {
                showRange = NSMakeRange(findStart, 0);
            } else {
                NSUInteger safeLength = MIN(findRange.length + atRangeOffset, attribute.length - findRange.location);
                showRange = NSMakeRange(findRange.location, safeLength);
            }
            *stop = YES;
        }
    }];
    if (showRange.location == NSNotFound) return nil;
    return [NSValue valueWithRange:showRange];
}

#pragma mark - Converted Extra Index

- (NSInteger)getConvertedExtraIndex:(NSAttributedString *)attribute {
    if (![attribute isKindOfClass:[NSAttributedString class]] || attribute.length == 0) {
        return 0;
    }
    __block NSInteger count = 0;
    [attribute enumerateAttributesInRange:NSMakeRange(0, attribute.length)
                                 options:0
                              usingBlock:^(NSDictionary *dics, NSRange range, BOOL *stop) {
        id attachment = dics[NSAttachmentAttributeName];
        if ([attachment isKindOfClass:[NEEmotionAttachment class]]) {
            NEEmotionAttachment *neAttachment = (NEEmotionAttachment *)attachment;
            NSInteger tagCount = neAttachment.emotion.tag.length;
            if (tagCount > 0) {
                count = count + tagCount - 1;
            }
        }
    }];
    return count;
}

#pragma mark - Range Conversion

- (nullable NSValue *)convertRangeToNSRange:(nullable UITextRange *)range {
    if (!range) return nil;
    id<UITextInput> input = self.textInput;
    if (!input) return nil;
    UITextPosition *beginning = input.beginningOfDocument;
    NSInteger startIndex = [input offsetFromPosition:beginning toPosition:range.start];
    NSInteger endIndex = [input offsetFromPosition:beginning toPosition:range.end];
    if (startIndex < 0 || endIndex < startIndex) return nil;
    return [NSValue valueWithRange:NSMakeRange(startIndex, endIndex - startIndex)];
}

#pragma mark - Multiple Line Button Actions

- (void)didClickExpandButton {
    if (self.chatInpuMode == ChatInputModeMultipleReturn) {
        [self.multipleLineDelegate didHideMultipleButtonClick];
        return;
    }
    [self.multipleLineDelegate expandButtonDidClick];
}

- (void)didClickHideMultipleButton {
    [self.multipleLineDelegate didHideMultipleButtonClick];
}

- (void)didClickSendButton {
    [self sendText];
}

#pragma mark - AI Chat

- (void)didClickAIChatButton {
    ExpandButton *btn = (ExpandButton *)self.aiChatButton;
    btn.selected = !btn.selected;
    self.stackView.hidden = btn.selected;
    self.contentView.hidden = btn.selected;
    self.contentSubView.hidden = btn.selected;

    if (btn.selected) {
        [self showAIChatView];
    } else {
        [self hideAIChatView];
        [self.multipleLineDelegate aiChatButtonDidClick:self.aiChatViewController open:NO];
    }
}

- (void)showAIChatView {
    self.currentButton.selected = NO;
    [self setLayerContents:YES];

    NEAIChatViewControllerBlock customController = ChatUIConfig.shared.aiChatViewController;
    if (customController) {
        customController(self.aiChatViewController);
    }

    if (self.chatInpuMode != ChatInputModeMultipleReturn) {
        [self addSubview:self.aiChatViewController.view];
        [NSLayoutConstraint activateConstraints:@[
            [self.aiChatViewController.view.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.aiChatViewController.view.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [self.aiChatViewController.view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0],
            [self.aiChatViewController.view.topAnchor constraintEqualToAnchor:self.topAnchor constant:self.aiChatViewControllerTopConstant],
        ]];
    }
    [self.multipleLineDelegate aiChatButtonDidClick:self.aiChatViewController open:YES];
}

- (void)setLayerContents:(BOOL)open {
    // Subclass override
}

- (void)hideAIChatView {
    [self setLayerContents:NO];
    self.stackView.hidden = NO;
    self.contentView.hidden = NO;
    self.contentSubView.hidden = NO;
    ((ExpandButton *)self.aiChatButton).selected = NO;
    [self.aiChatViewController.view removeFromSuperview];
}

#pragma mark - AIChatViewDelegate

- (void)didClickEditButton:(nullable NSString *)text {
    self.textView.text = text;
    [self.textView becomeFirstResponder];
    [self hideAIChatView];
}

- (void)didClickMessageItem:(NSString *)text {
    [self.multipleLineDelegate aiChatMessageDidClick:text];
}

#pragma mark - Multiple Line Mode

- (void)restoreNormalInputStyle {
    self.multipleLineView.hidden = YES;
    if (self.titleField.text.length > 0) {
        _chatInpuMode = ChatInputModeMultipleSend;
    } else {
        _chatInpuMode = ChatInputModeNormal;
    }
}

- (void)changeToMultipleLineStyle {
    _chatInpuMode = ChatInputModeMultipleReturn;
    self.multipleLineView.hidden = NO;
}

#pragma mark - Mute Style

- (void)setMuteInputStyle {
    [self clearAtCache];
    [(UIControl *)self.expandButton setEnabled:NO];
    self.textView.attributedText = nil;
    self.textView.text = nil;
}

- (void)setUnMuteInputStyle {
    [(UIControl *)self.expandButton setEnabled:YES];
}

#pragma mark - Setup Multiple Line View

- (void)setupMultipleLineView {
    [self addSubview:self.multipleLineView];
    self.multipleLineViewHeight = [self.multipleLineView.heightAnchor constraintEqualToConstant:400];
    [NSLayoutConstraint activateConstraints:@[
        self.multipleLineViewHeight,
        [self.multipleLineView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [self.multipleLineView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [self.multipleLineView.topAnchor constraintEqualToAnchor:self.topAnchor constant:4],
    ]];

    [self.multipleLineView addSubview:self.titleField];
    [self.titleField addTarget:self action:@selector(textFieldChange) forControlEvents:UIControlEventEditingChanged];
    self.titleField.delegate = self;
    [NSLayoutConstraint activateConstraints:@[
        [self.titleField.leftAnchor constraintEqualToAnchor:self.multipleLineView.leftAnchor constant:16],
        [self.titleField.rightAnchor constraintEqualToAnchor:self.multipleLineView.rightAnchor constant:-56],
        [self.titleField.topAnchor constraintEqualToAnchor:self.multipleLineView.topAnchor constant:5],
        [self.titleField.heightAnchor constraintEqualToConstant:40],
    ]];

    [self.multipleLineView addSubview:self.multipleLineExpandButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.multipleLineExpandButton.rightAnchor constraintEqualToAnchor:self.multipleLineView.rightAnchor constant:0],
        [self.multipleLineExpandButton.topAnchor constraintEqualToAnchor:self.multipleLineView.topAnchor constant:5],
        [self.multipleLineExpandButton.widthAnchor constraintEqualToConstant:44],
        [self.multipleLineExpandButton.heightAnchor constraintEqualToConstant:40],
    ]];
    [(ExpandButton *)self.multipleLineExpandButton addTarget:self action:@selector(didClickHideMultipleButton) forControlEvents:UIControlEventTouchUpInside];

    UIView *dividerLine = [[UIView alloc] init];
    dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
    dividerLine.backgroundColor = [UIColor ne_colorWithHexString:@"#ECECEC"];
    [self.multipleLineView addSubview:dividerLine];
    [NSLayoutConstraint activateConstraints:@[
        [dividerLine.leftAnchor constraintEqualToAnchor:self.multipleLineView.leftAnchor],
        [dividerLine.rightAnchor constraintEqualToAnchor:self.multipleLineView.rightAnchor],
        [dividerLine.topAnchor constraintEqualToAnchor:self.multipleLineView.topAnchor constant:236],
        [dividerLine.heightAnchor constraintEqualToConstant:1],
    ]];

    [self.multipleLineView addSubview:self.multipleSendButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.multipleSendButton.rightAnchor constraintEqualToAnchor:self.multipleLineView.rightAnchor constant:-16],
        [self.multipleSendButton.topAnchor constraintEqualToAnchor:dividerLine.bottomAnchor constant:8],
        [self.multipleSendButton.widthAnchor constraintEqualToConstant:44],
        [self.multipleSendButton.heightAnchor constraintEqualToConstant:40],
    ]];
    [(ExpandButton *)self.multipleSendButton addTarget:self action:@selector(didClickSendButton) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - TextField Change

- (void)textFieldChange {
    [self.delegate textFieldDidChange:self.titleField.text];
    if (self.titleField.text.length <= 0) {
        [self.delegate titleTextDidClearEmpty];
    }
    if (self.titleField.markedTextRange) {
        // 正在输入拼音等，不做截断
        return;
    }
    if (self.titleField.text && self.titleField.text.length > (NSUInteger)self.textLimit) {
        NEHandleInputLimitExceeded(self, self.textLimit);
        self.titleField.text = [self.titleField.text substringToIndex:self.textLimit];
    }
}

#pragma mark - ChatRecordViewDelegate

- (void)startRecord {
    self.greyView.hidden = NO;
    [self.delegate startRecord];
}

- (void)moveOutView {
    [self.delegate moveOutView];
}

- (void)moveInView {
    [self.delegate moveInView];
}

- (void)endRecord:(BOOL)insideView {
    self.greyView.hidden = YES;
    [self.delegate endRecord:insideView];
}

#pragma mark - NEMoreViewDelegate

- (void)moreViewDidSelectMoreCell:(NEChatMoreActionView *)moreView cell:(NEInputMoreCell *)cell {
    [self.delegate didSelectMoreCell:cell];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [textView.attributedText enumerateAttribute:NSForegroundColorAttributeName
                                        inRange:NSMakeRange(0, textView.attributedText.length)
                                        options:0
                                     usingBlock:^(id value, NSRange findRange, BOOL *stop) {
        if (![value isKindOfClass:[UIColor class]]) return;
        UIColor *findColor = (UIColor *)value;
        if ([self isEqualToColor:findColor color2:UIColor.ne_defaultPrimaryColor]) {
            NSString *string = textView.attributedText.string;
            if (findRange.location + findRange.length <= string.length) {
                NSString *text = [string substringWithRange:findRange];
                if (!self.nickAccidDic[text]) {
                    NSMutableAttributedString *mutableAttri = [[NSMutableAttributedString alloc] initWithAttributedString:textView.attributedText];
                    [mutableAttri addAttribute:NSForegroundColorAttributeName
                                         value:ChatUIConfig.shared.messageProperties.inputTextColor
                                         range:findRange];
                    textView.attributedText = mutableAttri;
                }
            }
        }
    }];
    [self.delegate textFieldDidChange:textView.text];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self.delegate textFieldDidEndEditing:textView.text];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self.delegate textFieldDidBeginEditing:textView.text];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    _currentType = ChatMenuTypeText;
    return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    NSRange range = textView.selectedRange;
    NSValue *findRangeValue = [self findShowPositionWithRange:range attribute:textView.attributedText];
    if (findRangeValue) {
        NSRange findRange = [findRangeValue rangeValue];
        NSUInteger location = MIN(findRange.location + findRange.length, (NSUInteger)textView.attributedText.length);
        textView.selectedRange = NSMakeRange(location, 0);
    }
    if (textView.attributedText.length > 0) {
        NSUInteger location = MIN(textView.selectedRange.location, (NSUInteger)textView.attributedText.length - 1);
        [textView scrollRangeToVisible:NSMakeRange(location, 1)];
    }
    textView.accessibilityValue = [self getRealSendText:textView.attributedText];
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    [textView becomeFirstResponder];

    NSInteger offset = characterRange.location;
    // 修复iOS 14.1，点击空白识别为点击最后一个富文本图片的问题
    if (characterRange.location + characterRange.length == (NSUInteger)textView.text.length) {
        offset += 1;
    }
    offset = MIN(offset, (NSInteger)textView.text.length);

    UITextPosition *newPosition = [textView positionFromPosition:textView.beginningOfDocument offset:offset];
    if (newPosition) {
        textView.selectedTextRange = [textView textRangeFromPosition:newPosition toPosition:newPosition];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSRange mutableRange = range;
    NSUInteger attrLength = textView.attributedText.length;
    if (mutableRange.location > attrLength) {
        mutableRange.location = attrLength;
        mutableRange.length = 0;
    } else if (mutableRange.location + mutableRange.length > attrLength) {
        mutableRange.length = attrLength - mutableRange.location;
    }
    if (@available(iOS 26, *)) {
        if (text.length == 0 && mutableRange.location > 0 && mutableRange.length == 0) {
            mutableRange = NSMakeRange(mutableRange.location - 1, 1);
        }
    }

    textView.typingAttributes = @{
        NSForegroundColorAttributeName: ChatUIConfig.shared.messageProperties.inputTextColor,
        NSFontAttributeName: [UIFont systemFontOfSize:16]
    };

    // 回车发送
    if ((_chatInpuMode == ChatInputModeNormal || _chatInpuMode == ChatInputModeMultipleSend) && [text isEqualToString:@"\n"]) {
        NSString *realText = [self getRealSendText:textView.attributedText];
        if (!realText) {
            [self.delegate textViewDidChange];
            return YES;
        }
        NSString *trimmed = [realText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (trimmed.length == 0) {
            realText = @"";
        }
        [self.delegate sendText:realText attribute:textView.attributedText];
        [self clearTextInputAfterSend];
        return NO;
    }

    // 处理粘贴，表情解析（存在表情则字符数量>=3）
    if (text.length >= 3) {
        NSArray *regularArray = [NEEmotionTool getRegularArray:text];
        if (regularArray && regularArray.count > 0) {
            NSMutableAttributedString *mutaString = [[NSMutableAttributedString alloc] initWithAttributedString:textView.attributedText];
            NSMutableAttributedString *addString = [NEEmotionTool getAttWithStr:text
                                                                           font:[UIFont systemFontOfSize:16]
                                                                         color:UIColor.ne_darkText
                                                                         offset:CGPointMake(0, -4)];
            if (!addString) return YES;
            [mutaString replaceCharactersInRange:mutableRange withAttributedString:addString];
            textView.attributedText = mutaString;
            textView.accessibilityValue = text;
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) return;
                textView.selectedRange = NSMakeRange(mutableRange.location + addString.length, 0);
            });
            [self.delegate textViewDidChange];
            textView.font = [UIFont systemFontOfSize:16];
            return NO;
        }
    }

    // 删除处理
    if (text.length == 0 && mutableRange.length > 0) {
        NSValue *temRangeValue = [self checkRemoveAtMessageWithRange:mutableRange attribute:textView.attributedText];
        if (temRangeValue) {
            NSRange findRange = [temRangeValue rangeValue];
            NSMutableAttributedString *mutableAttri = [[NSMutableAttributedString alloc] initWithAttributedString:textView.attributedText];
            if ((NSUInteger)mutableAttri.length >= findRange.location + findRange.length) {
                NSString *string = textView.attributedText.string;
                NSUInteger rawLength = findRange.length > atRangeOffset ? findRange.length - atRangeOffset : 0;
                NSRange rawRange = NSMakeRange(findRange.location, rawLength);
                if (rawRange.location + rawRange.length <= string.length) {
                    NSString *atText = [string substringWithRange:rawRange];
                    NSString *nick = self.nickAccidDic[atText];
                    if (nick) {
                        [self.nickAccidDic removeObjectForKey:atText];
                        [self.nickAccidList removeObject:nick];
                    }
                }

                if (mutableRange.length == 1) {
                    [mutableAttri replaceCharactersInRange:findRange withString:@""];
                } else if (mutableRange.length - 1 > 0 &&
                           mutableRange.location >= findRange.location &&
                           mutableRange.location <= findRange.location + findRange.length) {
                    NSRange replaceRange = NSMakeRange(mutableRange.location + 1, mutableRange.length - 1);
                    if (replaceRange.location + replaceRange.length <= mutableAttri.length) {
                        [mutableAttri replaceCharactersInRange:replaceRange withString:@""];
                    }
                }

                if (mutableAttri.length <= 0) {
                    textView.attributedText = nil;
                } else {
                    textView.attributedText = mutableAttri;
                }

                if (mutableRange.length == 1) {
                    textView.selectedRange = NSMakeRange(MIN(findRange.location, (NSUInteger)textView.attributedText.length), 0);
                } else {
                    textView.selectedRange = NSMakeRange(MIN(mutableRange.location + 1, (NSUInteger)textView.attributedText.length), 0);
                }
            }
            return NO;
        }
        [self.delegate textViewDidChange];
        return YES;
    } else {
        [self.delegate textChanged:text];
    }
    [self.delegate textViewDidChange];
    return YES;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self.delegate textFieldDidChange:textField.text];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _currentType = ChatMenuTypeText;
    [self.delegate textFieldDidBeginEditing:textField.text];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.titleField && [string isEqualToString:@"\n"]) {
        NSString *realText = [self getRealSendText:self.textView.attributedText] ?: @"";
        [self.delegate sendText:realText attribute:self.textView.attributedText];
        [self clearTextInputAfterSend];
        return NO;
    }
    return YES;
}

@end
