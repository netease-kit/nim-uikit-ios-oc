// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "InputEmoticonContainerView.h"
#import <NEChatKitOC/NEALog.h>
#import "EmojiPageView.h"
#import "InputEmoticonTabView.h"
#import "NIMInputEmoticonButton.h"
#import "NIMInputEmoticonManager.h"
#import "UIImage+Chat.h"
#import "NEChatUIConstant.h"

static NSString *const kClassTag = @"InputEmoticonContainerView";

@interface InputEmoticonContainerView () <EmojiPageViewDataSource, EmojiPageViewDelegate,
                                          InputEmoticonTabViewDelegate,
                                          NIMInputEmoticonButtonDelegate>

@property (nonatomic, strong, nullable) NSArray<NIMInputEmoticonCatalog *> *totalCatalogData;
@property (nonatomic, strong, nullable) NIMInputEmoticonCatalog *currentCatalogData;

@property (nonatomic, strong) EmojiPageView *emoticonPageView;
@property (nonatomic, strong) InputEmoticonTabView *tabView;

@end

@implementation InputEmoticonContainerView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setUpSubViews];
    [self loadEmojiData];
  }
  return self;
}

- (EmojiPageView *)emoticonPageView {
  if (!_emoticonPageView) {
    _emoticonPageView = [[EmojiPageView alloc] initWithFrame:self.bounds];
    _emoticonPageView.translatesAutoresizingMaskIntoConstraints = NO;
    _emoticonPageView.dataSource = self;
    _emoticonPageView.pageViewDelegate = self;
  }
  return _emoticonPageView;
}

- (InputEmoticonTabView *)tabView {
  if (!_tabView) {
    _tabView = [[InputEmoticonTabView alloc] initWithFrame:CGRectZero];
    _tabView.translatesAutoresizingMaskIntoConstraints = NO;
    _tabView.delegate = self;
    [_tabView.sendButton addTarget:self
                            action:@selector(didPressSend:)
                  forControlEvents:UIControlEventTouchUpInside];
  }
  return _tabView;
}

- (void)setUpSubViews {
  [self addSubview:self.emoticonPageView];
  [self addSubview:self.tabView];

  [NSLayoutConstraint activateConstraints:@[
    [self.emoticonPageView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.emoticonPageView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.emoticonPageView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.emoticonPageView.heightAnchor constraintEqualToConstant:159],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.tabView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [self.tabView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.tabView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.tabView.heightAnchor constraintEqualToConstant:35],
  ]];
}

- (void)setTotalCatalogData:(NSArray<NIMInputEmoticonCatalog *> *)totalCatalogData {
  _totalCatalogData = totalCatalogData;
  [self.tabView loadCatalogs:totalCatalogData];
}

- (void)setCurrentCatalogData:(NIMInputEmoticonCatalog *)currentCatalogData {
  _currentCatalogData = currentCatalogData;
  if (currentCatalogData) {
    [self.emoticonPageView scrollToPage:[self pageIndexWithEmoticon:currentCatalogData]];
  }
}

- (void)loadEmojiData {
  NSArray<NIMInputEmoticonCatalog *> *data = [self loadCatalogAndChartlet];
  self.totalCatalogData = data;
  self.currentCatalogData = data.firstObject;
}

- (nullable NSArray<NIMInputEmoticonCatalog *> *)loadCatalogAndChartlet {
  NIMInputEmoticonCatalog *catalog = [self loadDefaultCatalog];
  return catalog ? @[catalog] : nil;
}

- (nullable NIMInputEmoticonCatalog *)loadDefaultCatalog {
  NIMInputEmoticonCatalog *emoticonCatalog =
      [[NIMInputEmoticonManager shared] emoticonCatalogWithID:NIMKit_EmojiCatalog];
  NIMInputEmoticonLayout *layout = [[NIMInputEmoticonLayout alloc] initWithWidth:self.frame.size.width];
  emoticonCatalog.layout = layout;
  emoticonCatalog.pagesCount = [self numberOfPagesWithEmoticon:emoticonCatalog];
  return emoticonCatalog;
}

- (NSInteger)pageIndexWithEmoticon:(NIMInputEmoticonCatalog *)emoticonCatalog {
  NSInteger pageIndex = 0;
  if (self.totalCatalogData) {
    for (NIMInputEmoticonCatalog *emoticon in self.totalCatalogData) {
      if (emoticon == emoticonCatalog) {
        break;
      }
      pageIndex += emoticon.pagesCount;
    }
  }
  return pageIndex;
}

- (NSInteger)pageIndexWithTotalIndex:(NSInteger)index {
  NIMInputEmoticonCatalog *catalog = [self emoticonWithIndex:index];
  NSInteger begin = [self pageIndexWithEmoticon:catalog];
  return index - begin;
}

- (NIMInputEmoticonCatalog *)emoticonWithIndex:(NSInteger)index {
  NSInteger page = 0;
  NIMInputEmoticonCatalog *resultEmotion = [[NIMInputEmoticonCatalog alloc] init];
  if (!self.totalCatalogData) {
    return resultEmotion;
  }
  for (NIMInputEmoticonCatalog *emotion in self.totalCatalogData) {
    NSInteger newPage = page + emotion.pagesCount;
    if (newPage > index) {
      resultEmotion = emotion;
      break;
    }
    page = newPage;
  }
  return resultEmotion;
}

- (NSInteger)numberOfPagesWithEmoticon:(nullable NIMInputEmoticonCatalog *)emoticonCatalog {
  if (emoticonCatalog.emoticons.count > 0 && emoticonCatalog.layout.itemCountInPage > 0) {
    NSInteger emotionsCount = (NSInteger)emoticonCatalog.emoticons.count;
    NSInteger layoutCount = emoticonCatalog.layout.itemCountInPage;
    if (emotionsCount % layoutCount == 0) {
      return emotionsCount / layoutCount;
    } else {
      return emotionsCount / layoutCount + 1;
    }
  } else {
    [NEALog errorLog:kClassTag desc:@"count maybe nil"];
    return 0;
  }
}

- (NSInteger)sumPages {
  NSInteger pagesCount = 0;
  for (NIMInputEmoticonCatalog *catalog in self.totalCatalogData) {
    pagesCount += catalog.pagesCount;
  }
  return pagesCount;
}

- (UIView *)emojiPageView:(EmojiPageView *)pageView
                 emoticon:(NIMInputEmoticonCatalog *)emoticon
                     page:(NSInteger)page {
  UIView *subView = [[UIView alloc] init];
  if (!emoticon.layout) {
    [NEALog errorLog:kClassTag desc:@"layout is nil"];
    return [[UIView alloc] init];
  }
  if (!emoticon.emoticons) {
    [NEALog errorLog:kClassTag desc:@"emoticon.emoticons is nil"];
    return [[UIView alloc] init];
  }

  NIMInputEmoticonLayout *layout = emoticon.layout;
  CGFloat iconHeight = layout.imageHeight;
  CGFloat iconWidth = layout.imageWidth;
  NSInteger startX = (NSInteger)(layout.cellWidth - iconWidth) / 2 + NIMKit_EmojiLeftMargin;
  NSInteger startY = (NSInteger)(layout.cellHeight - iconHeight) / 2 + NIMKit_EmojiTopMargin;
  NSInteger coloumnIndex = 0;
  NSInteger rowIndex = 0;
  NSInteger indexInPage = 0;
  NSInteger begin = page * layout.itemCountInPage;
  NSInteger end = begin + layout.itemCountInPage;
  end = end > (NSInteger)emoticon.emoticons.count ? (NSInteger)emoticon.emoticons.count : end;

  for (NSInteger i = begin; i < end; i++) {
    NIMInputEmoticon *data = emoticon.emoticons[i];
    if (emoticon.catalogID) {
      NIMInputEmoticonButton *button = [NIMInputEmoticonButton iconButtonWithData:data
                                                                        catalogID:emoticon.catalogID
                                                                         delegate:self];
      rowIndex = indexInPage / layout.columes;
      coloumnIndex = indexInPage % layout.columes;
      NSInteger x = coloumnIndex * (NSInteger)layout.cellWidth + startX;
      NSInteger y = rowIndex * (NSInteger)layout.cellHeight + startY;
      button.frame = CGRectMake(x, y, iconWidth, iconHeight);
      [subView addSubview:button];
      indexInPage++;
    }
  }

  if (coloumnIndex == layout.columes - 1) {
    rowIndex++;
    coloumnIndex = -1;
  }

  if ([emoticon.catalogID isEqualToString:NIMKit_EmojiCatalog]) {
    [self addDeleteEmotButtonToView:subView
                       coloumnIndex:coloumnIndex
                           rowIndex:rowIndex
                             startX:startX
                             startY:startY
                          iconWidth:iconWidth
                         iconHeight:iconHeight
                            emotion:emoticon];
  }
  return subView;
}

- (void)addDeleteEmotButtonToView:(UIView *)view
                     coloumnIndex:(NSInteger)coloumnIndex
                         rowIndex:(NSInteger)rowIndex
                           startX:(NSInteger)startX
                           startY:(NSInteger)startY
                        iconWidth:(CGFloat)iconWidth
                       iconHeight:(CGFloat)iconHeight
                          emotion:(NIMInputEmoticonCatalog *)emotion {
  if (!emotion.layout) {
    [NEALog errorLog:kClassTag desc:@"emotion is nil"];
    return;
  }
  NIMInputEmoticonLayout *layout = emotion.layout;

  NIMInputEmoticonButton *deleteIcon = [[NIMInputEmoticonButton alloc] init];
  deleteIcon.userInteractionEnabled = YES;
  deleteIcon.exclusiveTouch = YES;
  deleteIcon.contentMode = UIViewContentModeCenter;
  deleteIcon.delegate = self;
  [deleteIcon setImage:[UIImage ne_imageNamed:@"emoji_del_normal"] forState:UIControlStateNormal];
  [deleteIcon setImage:[UIImage ne_imageNamed:@"emoji_del_pressed"] forState:UIControlStateHighlighted];
  [deleteIcon addTarget:self action:@selector(onIconSelected:) forControlEvents:UIControlEventTouchUpInside];
  deleteIcon.accessibilityIdentifier = @"id.emojiDelete";

  CGFloat newX = (CGFloat)(coloumnIndex + 1) * layout.cellWidth + startX;
  CGFloat newY = (CGFloat)rowIndex * layout.cellHeight + startY;
  deleteIcon.frame = CGRectMake(newX, newY, NIMKit_DeleteIconWidth, NIMKit_DeleteIconHeight);
  [view addSubview:deleteIcon];
}

- (void)onIconSelected:(NIMInputEmoticonButton *)sender {
  [self.delegate selectedEmoticon:@"" emotCatalogID:@"" description:@""];
}

- (void)didPressSend:(UIButton *)sender {
  [self.delegate didPressSend:sender];
}

#pragma mark - EmojiPageViewDataSource

- (NSInteger)numberOfPages:(nullable EmojiPageView *)pageView {
  return [self sumPages];
}

- (UIView *)pageView:(nullable EmojiPageView *)pageView index:(NSInteger)index {
  NSInteger page = 0;
  NIMInputEmoticonCatalog *resultEmotion = [[NIMInputEmoticonCatalog alloc] init];

  if (!self.totalCatalogData || !pageView) {
    [NEALog errorLog:kClassTag desc:@"totalCatalogData is nil"];
    return [[UIView alloc] init];
  }

  for (NIMInputEmoticonCatalog *emotion in self.totalCatalogData) {
    NSInteger newPage = page + emotion.pagesCount;
    if (newPage > index) {
      resultEmotion = emotion;
      break;
    }
    page = newPage;
  }
  return [self emojiPageView:pageView emoticon:resultEmotion page:index - page];
}

#pragma mark - EmojiPageViewDelegate

- (BOOL)needScrollAnimation {
  return YES;
}

- (void)pageViewDidScroll:(nullable EmojiPageView *)pageView {}

- (void)pageViewScrollEnd:(nullable EmojiPageView *)pageView
             currentIndex:(NSInteger)currentIndex
               totolPages:(NSInteger)totolPages {}

#pragma mark - InputEmoticonTabViewDelegate

- (void)tabView:(nullable InputEmoticonTabView *)tabView didSelectTabIndex:(NSInteger)index {}

#pragma mark - NIMInputEmoticonButtonDelegate

- (void)selectedEmoticon:(NIMInputEmoticon *)emotion catalogID:(NSString *)catalogID {
  if (!emotion.emoticonID) {
    [NEALog errorLog:kClassTag desc:@"emoticonID is nil"];
    return;
  }
  if (emotion.type == NIMEmoticonTypeUnicode) {
    [self.delegate selectedEmoticon:emotion.emoticonID
                      emotCatalogID:catalogID
                        description:emotion.unicode ?: @""];
  } else {
    [self.delegate selectedEmoticon:emotion.emoticonID
                      emotCatalogID:catalogID
                        description:emotion.tag ?: @""];
  }
}

@end
