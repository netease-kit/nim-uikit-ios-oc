// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "InputEmoticonContainerView.h"
#import <NEChatKit/NEALog.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import "EmojiPageView.h"
#import "InputEmoticonTabView.h"
#import "NEChatUIConstant.h"
#import "NIMInputEmoticonButton.h"
#import "NIMInputEmoticonManager.h"
#import "UIImage+Chat.h"

static NSString *const kClassTag = @"InputEmoticonContainerView";
static NSInteger const NIMInputStickerPageCapacity = 8;

@interface EmojiPageView (StickerInternal)
- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated;
- (void)reloadDataWithCurrentPage:(NSInteger)page;
@end

@interface InputEmoticonTabView (StickerInternal)
@property (nonatomic, strong) UIColor *accentColor;
- (void)loadItemsWithNormalIcons:(NSArray<UIImage *> *)normalIcons
                   selectedIcons:(NSArray<UIImage *> *)selectedIcons
        selectionBackgroundFlags:(NSArray<NSNumber *> *)selectionBackgroundFlags
              accessibilityValues:(NSArray<NSString *> *)accessibilityValues;
- (void)setSendButtonVisible:(BOOL)visible;
@end

typedef NS_ENUM(NSInteger, NIMInputEmoticonSectionType) {
  NIMInputEmoticonSectionTypeEmoji,
  NIMInputEmoticonSectionTypeSticker,
};

@interface NIMInputEmoticonSection : NSObject
@property (nonatomic, copy, readonly) NSString *sectionID;
@property (nonatomic, copy, nullable, readonly) NSString *title;
@property (nonatomic, assign, readonly) NIMInputEmoticonSectionType type;
@property (nonatomic, assign, readonly) NSInteger pageCount;
@property (nonatomic, strong, readonly) UIImage *normalIcon;
@property (nonatomic, strong, readonly) UIImage *selectedIcon;
@property (nonatomic, strong, readonly) id content;
- (instancetype)initWithSectionID:(NSString *)sectionID
                             title:(nullable NSString *)title
                              type:(NIMInputEmoticonSectionType)type
                         pageCount:(NSInteger)pageCount
                        normalIcon:(UIImage *)normalIcon
                      selectedIcon:(UIImage *)selectedIcon
                           content:(id)content;
@end

@implementation NIMInputEmoticonSection

- (instancetype)initWithSectionID:(NSString *)sectionID
                             title:(nullable NSString *)title
                              type:(NIMInputEmoticonSectionType)type
                         pageCount:(NSInteger)pageCount
                        normalIcon:(UIImage *)normalIcon
                      selectedIcon:(UIImage *)selectedIcon
                           content:(id)content {
  self = [super init];
  if (self) {
    _sectionID = [sectionID copy];
    _title = [title copy];
    _type = type;
    _pageCount = pageCount;
    _normalIcon = normalIcon;
    _selectedIcon = selectedIcon;
    _content = content;
  }
  return self;
}

@end

@interface NIMInputEmoticonSelection : NSObject
@property (nonatomic, copy, readonly) NSString *sectionID;
@property (nonatomic, assign, readonly) NSInteger localPage;
- (instancetype)initWithSectionID:(NSString *)sectionID localPage:(NSInteger)localPage;
@end

@implementation NIMInputEmoticonSelection

- (instancetype)initWithSectionID:(NSString *)sectionID localPage:(NSInteger)localPage {
  self = [super init];
  if (self) {
    _sectionID = [sectionID copy];
    _localPage = localPage;
  }
  return self;
}

@end

@interface NIMInputEmoticonPageMapping : NSObject
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *pageCounts;
@property (nonatomic, assign, readonly) NSInteger totalPages;
- (instancetype)initWithPageCounts:(NSArray<NSNumber *> *)pageCounts;
- (NSInteger)globalIndexForSectionIndex:(NSInteger)sectionIndex localPage:(NSInteger)localPage;
- (BOOL)getSectionIndex:(NSInteger *)sectionIndex
              localPage:(NSInteger *)localPage
         forGlobalIndex:(NSInteger)globalIndex;
@end

@implementation NIMInputEmoticonPageMapping

- (instancetype)initWithPageCounts:(NSArray<NSNumber *> *)pageCounts {
  self = [super init];
  if (self) {
    _pageCounts = [pageCounts copy];
    NSInteger totalPages = 0;
    for (NSNumber *pageCount in pageCounts) {
      totalPages += MAX(0, pageCount.integerValue);
    }
    _totalPages = totalPages;
  }
  return self;
}

- (NSInteger)globalIndexForSectionIndex:(NSInteger)sectionIndex localPage:(NSInteger)localPage {
  if (sectionIndex < 0 || sectionIndex >= (NSInteger)self.pageCounts.count) {
    return NSNotFound;
  }
  NSInteger pageCount = self.pageCounts[sectionIndex].integerValue;
  if (pageCount <= 0) {
    return NSNotFound;
  }
  NSInteger globalIndex = 0;
  for (NSInteger index = 0; index < sectionIndex; index++) {
    globalIndex += MAX(0, self.pageCounts[index].integerValue);
  }
  return globalIndex + MIN(MAX(localPage, 0), pageCount - 1);
}

- (BOOL)getSectionIndex:(NSInteger *)sectionIndex
              localPage:(NSInteger *)localPage
         forGlobalIndex:(NSInteger)globalIndex {
  if (self.totalPages <= 0) {
    return NO;
  }
  NSInteger boundedIndex = MIN(MAX(globalIndex, 0), self.totalPages - 1);
  NSInteger startIndex = 0;
  for (NSInteger index = 0; index < (NSInteger)self.pageCounts.count; index++) {
    NSInteger endIndex = startIndex + MAX(0, self.pageCounts[index].integerValue);
    if (boundedIndex < endIndex) {
      if (sectionIndex) {
        *sectionIndex = index;
      }
      if (localPage) {
        *localPage = boundedIndex - startIndex;
      }
      return YES;
    }
    startIndex = endIndex;
  }
  return NO;
}

@end

@interface NIMInputEmoticonPageIndicatorView : UIView
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<UIView *> *dots;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong) UIColor *accentColor;
- (void)updateWithPageCount:(NSInteger)pageCount
                currentPage:(NSInteger)currentPage
                accentColor:(UIColor *)accentColor;
@end

@implementation NIMInputEmoticonPageIndicatorView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.scrollsToTop = NO;
    _dots = [NSMutableArray array];
    _accentColor = UIColor.ne_defaultPrimaryColor;
    [self addSubview:_scrollView];
    self.accessibilityIdentifier = @"id.emoticonPageIndicator";
  }
  return self;
}

- (void)updateWithPageCount:(NSInteger)pageCount
                currentPage:(NSInteger)currentPage
                accentColor:(UIColor *)accentColor {
  NSInteger safePageCount = MAX(0, pageCount);
  self.currentPage = MIN(MAX(currentPage, 0), MAX(safePageCount - 1, 0));
  self.accentColor = accentColor ?: UIColor.ne_defaultPrimaryColor;
  if ((NSInteger)self.dots.count != safePageCount) {
    for (UIView *dot in self.dots) {
      [dot removeFromSuperview];
    }
    [self.dots removeAllObjects];
    for (NSInteger index = 0; index < safePageCount; index++) {
      UIView *dot = [[UIView alloc] init];
      dot.layer.cornerRadius = 2.5;
      dot.isAccessibilityElement = NO;
      [self.scrollView addSubview:dot];
      [self.dots addObject:dot];
    }
  }
  self.accessibilityValue = safePageCount > 0
      ? [NSString stringWithFormat:@"%ld/%ld", (long)self.currentPage + 1, (long)safePageCount]
      : nil;
  [self setNeedsLayout];
  [self layoutIfNeeded];
  [self ensureCurrentDotVisible];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.scrollView.frame = self.bounds;
  CGFloat dotSize = 5;
  CGFloat dotSpacing = 5;
  CGFloat contentWidth = self.dots.count * dotSize + MAX((NSInteger)self.dots.count - 1, 0) * dotSpacing;
  CGFloat startX = contentWidth < self.bounds.size.width
      ? (self.bounds.size.width - contentWidth) / 2
      : 0;
  for (NSInteger index = 0; index < (NSInteger)self.dots.count; index++) {
    UIView *dot = self.dots[index];
    dot.frame = CGRectMake(startX + index * (dotSize + dotSpacing),
                           (self.bounds.size.height - dotSize) / 2,
                           dotSize,
                           dotSize);
    dot.backgroundColor = index == self.currentPage ? self.accentColor : UIColor.ne_borderColor;
  }
  self.scrollView.contentSize = CGSizeMake(MAX(self.bounds.size.width, contentWidth),
                                           self.bounds.size.height);
}

- (void)ensureCurrentDotVisible {
  if (self.currentPage < 0 || self.currentPage >= (NSInteger)self.dots.count) {
    return;
  }
  CGRect visibleRect = CGRectInset(self.dots[self.currentPage].frame, -5, 0);
  [self.scrollView scrollRectToVisible:visibleRect animated:NO];
}

@end

@interface NIMInputStickerButton : UIButton
@property (nonatomic, copy) NSString *packageID;
@property (nonatomic, strong, nullable) NIMInputSticker *sticker;
@end

@implementation NIMInputStickerButton
@end

@interface InputEmoticonContainerView () <EmojiPageViewDataSource,
                                          EmojiPageViewDelegate,
                                          InputEmoticonTabViewDelegate,
                                          NIMInputEmoticonButtonDelegate>

@property (nonatomic, copy) NSArray<NIMInputEmoticonSection *> *sections;
@property (nonatomic, strong) NIMInputEmoticonPageMapping *pageMapping;
@property (nonatomic, strong, nullable) NIMInputEmoticonSelection *selection;
@property (nonatomic, strong) NSCache<NSURL *, UIImage *> *imageCache;
@property (nonatomic, assign) CGFloat lastLayoutWidth;
@property (nonatomic, assign) CGFloat contentVerticalOffset;
@property (nonatomic, strong) NSLayoutConstraint *contentTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *contentBottomConstraint;
@property (nonatomic, strong) EmojiPageView *emoticonPageView;
@property (nonatomic, strong) NIMInputEmoticonPageIndicatorView *pageIndicatorView;
@property (nonatomic, strong) InputEmoticonTabView *tabView;

@end

@implementation InputEmoticonContainerView

- (instancetype)initWithFrame:(CGRect)frame {
  return [self initWithFrame:frame accentColor:UIColor.ne_defaultPrimaryColor];
}

- (instancetype)initWithFrame:(CGRect)frame accentColor:(UIColor *)accentColor {
  self = [super initWithFrame:frame];
  if (self) {
    _accentColor = accentColor ?: UIColor.ne_defaultPrimaryColor;
    _sections = @[];
    _pageMapping = [[NIMInputEmoticonPageMapping alloc] initWithPageCounts:@[]];
    _imageCache = [[NSCache alloc] init];
    [self setUpSubViews];
    [self loadEmojiData];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _accentColor = UIColor.ne_defaultPrimaryColor;
    _sections = @[];
    _pageMapping = [[NIMInputEmoticonPageMapping alloc] initWithPageCounts:@[]];
    _imageCache = [[NSCache alloc] init];
    [self setUpSubViews];
    [self loadEmojiData];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setAccentColor:(UIColor *)accentColor {
  _accentColor = accentColor ?: UIColor.ne_defaultPrimaryColor;
  self.tabView.accentColor = _accentColor;
  [self renderSelection];
}

- (void)setContentVerticalOffset:(CGFloat)contentVerticalOffset {
  _contentVerticalOffset = contentVerticalOffset;
  self.contentTopConstraint.constant = contentVerticalOffset;
  self.contentBottomConstraint.constant = contentVerticalOffset;
  self.clipsToBounds = contentVerticalOffset >= 0;
}

- (void)setUpSubViews {
  self.clipsToBounds = YES;
  [self addSubview:self.emoticonPageView];
  [self addSubview:self.pageIndicatorView];
  [self addSubview:self.tabView];

  self.contentTopConstraint = [self.emoticonPageView.topAnchor constraintEqualToAnchor:self.topAnchor];
  self.contentBottomConstraint = [self.tabView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor];
  [NSLayoutConstraint activateConstraints:@[
    self.contentTopConstraint,
    [self.emoticonPageView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.emoticonPageView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.emoticonPageView.heightAnchor constraintEqualToConstant:159],
    [self.pageIndicatorView.topAnchor constraintEqualToAnchor:self.emoticonPageView.bottomAnchor],
    [self.pageIndicatorView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.pageIndicatorView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.pageIndicatorView.heightAnchor constraintEqualToConstant:6],
    [self.tabView.topAnchor constraintEqualToAnchor:self.pageIndicatorView.bottomAnchor],
    self.contentBottomConstraint,
    [self.tabView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.tabView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.tabView.heightAnchor constraintEqualToConstant:35],
  ]];

  self.tabView.accentColor = self.accentColor;
  [self layoutIfNeeded];
}

- (EmojiPageView *)emoticonPageView {
  if (!_emoticonPageView) {
    _emoticonPageView = [[EmojiPageView alloc]
        initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 159)];
    _emoticonPageView.translatesAutoresizingMaskIntoConstraints = NO;
    _emoticonPageView.dataSource = self;
    _emoticonPageView.pageViewDelegate = self;
  }
  return _emoticonPageView;
}

- (NIMInputEmoticonPageIndicatorView *)pageIndicatorView {
  if (!_pageIndicatorView) {
    _pageIndicatorView = [[NIMInputEmoticonPageIndicatorView alloc] init];
    _pageIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _pageIndicatorView;
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

- (void)layoutSubviews {
  [super layoutSubviews];
  if (self.bounds.size.width <= 0 || fabs(self.bounds.size.width - self.lastLayoutWidth) <= 0.5) {
    return;
  }
  self.lastLayoutWidth = self.bounds.size.width;
  [self rebuildSectionsPreservingSelection:self.selection];
}

- (void)loadEmojiData {
  self.lastLayoutWidth = self.bounds.size.width;
  [self rebuildSectionsPreservingSelection:nil];
}

- (void)rebuildSectionsPreservingSelection:(nullable NIMInputEmoticonSelection *)previousSelection {
  NIMInputEmoticonCatalog *defaultCatalog = [self loadDefaultCatalog];
  if (!defaultCatalog) {
    self.sections = @[];
    self.pageMapping = [[NIMInputEmoticonPageMapping alloc] initWithPageCounts:@[]];
    self.selection = nil;
    [self.tabView loadItemsWithNormalIcons:@[]
                             selectedIcons:@[]
                  selectionBackgroundFlags:@[]
                       accessibilityValues:@[]];
    [self.pageIndicatorView updateWithPageCount:0 currentPage:0 accentColor:self.accentColor];
    [self.emoticonPageView reloadDataWithCurrentPage:0];
    return;
  }

  UIImage *defaultNormalIcon = [UIImage ne_bundleImage:defaultCatalog.icon ?: @""] ?: [[UIImage alloc] init];
  UIImage *defaultSelectedIcon = [UIImage ne_bundleImage:defaultCatalog.iconPressed ?: @""] ?: [[UIImage alloc] init];
  NIMInputEmoticonSection *defaultSection = [[NIMInputEmoticonSection alloc]
      initWithSectionID:defaultCatalog.catalogID ?: NIMKit_EmojiCatalog
                  title:defaultCatalog.title
                   type:NIMInputEmoticonSectionTypeEmoji
              pageCount:defaultCatalog.pagesCount
             normalIcon:defaultNormalIcon
           selectedIcon:defaultSelectedIcon
                content:defaultCatalog];
  NSMutableArray<NIMInputEmoticonSection *> *updatedSections =
      [NSMutableArray arrayWithObject:defaultSection];
  self.sections = [updatedSections copy];
  NSMutableArray<NSNumber *> *pageCounts = [NSMutableArray array];
  for (NIMInputEmoticonSection *section in self.sections) {
    [pageCounts addObject:@(section.pageCount)];
  }
  self.pageMapping = [[NIMInputEmoticonPageMapping alloc] initWithPageCounts:pageCounts];

  NIMInputEmoticonSection *selectedSection = nil;
  if (previousSelection) {
    for (NIMInputEmoticonSection *section in self.sections) {
      if ([section.sectionID isEqualToString:previousSelection.sectionID]) {
        selectedSection = section;
        break;
      }
    }
  }
  if (selectedSection) {
    self.selection = [[NIMInputEmoticonSelection alloc]
        initWithSectionID:selectedSection.sectionID
                localPage:MIN(previousSelection.localPage, selectedSection.pageCount - 1)];
  } else {
    self.selection = [[NIMInputEmoticonSelection alloc]
        initWithSectionID:defaultSection.sectionID
                localPage:0];
  }

  NSMutableArray<UIImage *> *normalIcons = [NSMutableArray array];
  NSMutableArray<UIImage *> *selectedIcons = [NSMutableArray array];
  NSMutableArray<NSNumber *> *selectionBackgroundFlags = [NSMutableArray array];
  NSMutableArray<NSString *> *accessibilityValues = [NSMutableArray array];
  for (NIMInputEmoticonSection *section in self.sections) {
    [normalIcons addObject:section.selectedIcon];
    [selectedIcons addObject:section.selectedIcon];
    [selectionBackgroundFlags addObject:@YES];
    [accessibilityValues addObject:section.title ?: section.sectionID];
  }
  [self.tabView loadItemsWithNormalIcons:normalIcons
                           selectedIcons:selectedIcons
                selectionBackgroundFlags:selectionBackgroundFlags
                      accessibilityValues:accessibilityValues];
  NSInteger targetPage = [self globalPageForSelection:self.selection];
  [self.emoticonPageView reloadDataWithCurrentPage:targetPage == NSNotFound ? 0 : targetPage];
  [self renderSelection];
}

- (nullable NIMInputEmoticonCatalog *)loadDefaultCatalog {
  NIMInputEmoticonCatalog *catalog =
      [[NIMInputEmoticonManager shared] emoticonCatalogWithID:NIMKit_EmojiCatalog];
  if (!catalog) {
    [NEALog errorLog:kClassTag desc:@"default emoji catalog is nil"];
    return nil;
  }
  // 未布局时回退共享宽度（随 scene 几何变化），不直接读屏幕常量。
  CGFloat layoutWidth = self.bounds.size.width > 0
      ? self.bounds.size.width
      : NEConstant.screenWidth;
  catalog.layout = [[NIMInputEmoticonLayout alloc] initWithWidth:layoutWidth];
  catalog.pagesCount = [self numberOfPagesWithEmoticon:catalog];
  return catalog.pagesCount > 0 ? catalog : nil;
}

- (NSInteger)numberOfPagesWithEmoticon:(nullable NIMInputEmoticonCatalog *)catalog {
  NSInteger emotionCount = (NSInteger)catalog.emoticons.count;
  NSInteger itemCount = catalog.layout.itemCountInPage;
  if (emotionCount <= 0 || itemCount <= 0) {
    [NEALog errorLog:kClassTag desc:@"emoji layout count is invalid"];
    return 0;
  }
  return (emotionCount + itemCount - 1) / itemCount;
}

- (void)resetToFirstEmojiPage {
  if (self.sections.count == 0) {
    return;
  }
  [self.emoticonPageView scrollToPage:0 animated:NO];
}

- (NSInteger)sectionIndexForID:(NSString *)sectionID {
  for (NSInteger index = 0; index < (NSInteger)self.sections.count; index++) {
    if ([self.sections[index].sectionID isEqualToString:sectionID]) {
      return index;
    }
  }
  return NSNotFound;
}

- (NSInteger)globalPageForSelection:(nullable NIMInputEmoticonSelection *)selection {
  if (!selection) {
    return NSNotFound;
  }
  NSInteger sectionIndex = [self sectionIndexForID:selection.sectionID];
  return [self.pageMapping globalIndexForSectionIndex:sectionIndex localPage:selection.localPage];
}

- (void)setSelectionWithSectionIndex:(NSInteger)sectionIndex
                           localPage:(NSInteger)localPage
                              scroll:(BOOL)scroll {
  if (sectionIndex < 0 || sectionIndex >= (NSInteger)self.sections.count) {
    return;
  }
  NIMInputEmoticonSection *section = self.sections[sectionIndex];
  self.selection = [[NIMInputEmoticonSelection alloc]
      initWithSectionID:section.sectionID
              localPage:MIN(MAX(localPage, 0), section.pageCount - 1)];
  [self renderSelection];
  if (scroll) {
    NSInteger targetPage = [self globalPageForSelection:self.selection];
    if (targetPage != NSNotFound) {
      [self.emoticonPageView scrollToPage:targetPage];
    }
  }
}

- (void)renderSelection {
  NSInteger sectionIndex = [self sectionIndexForID:self.selection.sectionID];
  if (sectionIndex == NSNotFound) {
    return;
  }
  NIMInputEmoticonSection *section = self.sections[sectionIndex];
  [self.tabView selectTabIndex:sectionIndex];
  [self.tabView setSendButtonVisible:section.type == NIMInputEmoticonSectionTypeEmoji];
  [self.pageIndicatorView updateWithPageCount:section.pageCount
                                  currentPage:self.selection.localPage
                                  accentColor:self.accentColor];
}

- (UIView *)emojiPageViewForCatalog:(NIMInputEmoticonCatalog *)catalog page:(NSInteger)page {
  UIView *pageView = [[UIView alloc] init];
  NIMInputEmoticonLayout *layout = catalog.layout;
  if (!layout || catalog.emoticons.count == 0 || layout.columes <= 0) {
    return pageView;
  }

  CGFloat startX = (layout.cellWidth - layout.imageWidth) / 2 + NIMKit_EmojiLeftMargin;
  CGFloat startY = (layout.cellHeight - layout.imageHeight) / 2 + NIMKit_EmojiTopMargin;
  NSInteger begin = page * layout.itemCountInPage;
  NSInteger end = MIN(begin + layout.itemCountInPage, (NSInteger)catalog.emoticons.count);
  if (begin >= end) {
    return pageView;
  }

  for (NSInteger itemIndex = begin; itemIndex < end; itemIndex++) {
    NSInteger indexInPage = itemIndex - begin;
    NIMInputEmoticonButton *button = [NIMInputEmoticonButton
        iconButtonWithData:catalog.emoticons[itemIndex]
                 catalogID:catalog.catalogID ?: @""
                  delegate:self];
    NSInteger row = indexInPage / layout.columes;
    NSInteger column = indexInPage % layout.columes;
    button.frame = CGRectMake(column * layout.cellWidth + startX,
                              row * layout.cellHeight + startY,
                              layout.imageWidth,
                              layout.imageHeight);
    [pageView addSubview:button];
  }

  if ([catalog.catalogID isEqualToString:NIMKit_EmojiCatalog]) {
    NSInteger deleteIndex = end - begin;
    NSInteger row = deleteIndex / layout.columes;
    NSInteger column = deleteIndex % layout.columes;
    NIMInputEmoticonButton *deleteButton = [[NIMInputEmoticonButton alloc] init];
    deleteButton.exclusiveTouch = YES;
    deleteButton.contentMode = UIViewContentModeCenter;
    deleteButton.delegate = self;
    [deleteButton setImage:[UIImage ne_imageNamed:@"emoji_del_normal"]
                  forState:UIControlStateNormal];
    [deleteButton setImage:[UIImage ne_imageNamed:@"emoji_del_pressed"]
                  forState:UIControlStateHighlighted];
    [deleteButton addTarget:self
                     action:@selector(onDeleteSelected)
           forControlEvents:UIControlEventTouchUpInside];
    deleteButton.accessibilityIdentifier = @"id.emojiDelete";
    deleteButton.frame = CGRectMake(column * layout.cellWidth + startX,
                                    row * layout.cellHeight + startY,
                                    NIMKit_DeleteIconWidth,
                                    NIMKit_DeleteIconHeight);
    [pageView addSubview:deleteButton];
  }
  return pageView;
}

- (UIView *)stickerPageViewForPackage:(NIMInputStickerPackage *)package page:(NSInteger)page {
  UIView *pageView = [[UIView alloc] init];
  NSInteger begin = page * NIMInputStickerPageCapacity;
  NSInteger end = MIN(begin + NIMInputStickerPageCapacity, (NSInteger)package.stickers.count);
  if (begin >= end) {
    return pageView;
  }

  CGFloat contentWidth = MAX(self.emoticonPageView.bounds.size.width, self.bounds.size.width);
  CGFloat cellWidth = (contentWidth - 16) / 4;
  CGFloat cellHeight = MAX(self.emoticonPageView.bounds.size.height, 159) / 2;
  CGFloat buttonLength = MIN(70, MIN(cellWidth, cellHeight) - 8);
  for (NSInteger itemIndex = begin; itemIndex < end; itemIndex++) {
    NSInteger indexInPage = itemIndex - begin;
    NIMInputSticker *sticker = package.stickers[itemIndex];
    NSInteger row = indexInPage / 4;
    NSInteger column = indexInPage % 4;
    NIMInputStickerButton *button = [NIMInputStickerButton buttonWithType:UIButtonTypeCustom];
    button.packageID = package.packageID;
    button.sticker = sticker;
    button.frame = CGRectMake(8 + column * cellWidth + (cellWidth - buttonLength) / 2,
                              row * cellHeight + (cellHeight - buttonLength) / 2,
                              buttonLength,
                              buttonLength);
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.accessibilityIdentifier = [NSString stringWithFormat:@"id.sticker.%@.%@",
                                                                package.packageID,
                                                                sticker.stickerID];
    button.accessibilityValue = sticker.stickerID;
    [button addTarget:self
               action:@selector(onStickerSelected:)
     forControlEvents:UIControlEventTouchUpInside];
    UIImage *image = [self.imageCache objectForKey:sticker.fileURL];
    if (!image) {
      image = [UIImage imageWithContentsOfFile:sticker.fileURL.path];
      if (image) {
        [self.imageCache setObject:image forKey:sticker.fileURL];
      }
    }
    [button setImage:image forState:UIControlStateNormal];
    [pageView addSubview:button];
  }
  return pageView;
}

- (void)onDeleteSelected {
  [self.delegate selectedEmoticon:@"" emotCatalogID:@"" description:@""];
}

- (void)onStickerSelected:(NIMInputStickerButton *)sender {
  NIMInputSticker *displayedSticker = sender.sticker;
  if (!displayedSticker) {
    return;
  }
  for (NIMInputStickerPackage *package in [[NIMInputEmoticonManager shared] stickerPackages]) {
    if (![package.packageID isEqualToString:sender.packageID]) {
      continue;
    }
    for (NIMInputSticker *sticker in package.stickers) {
      if ([sticker.stickerID isEqualToString:displayedSticker.stickerID] &&
          [sticker.fileURL isEqual:displayedSticker.fileURL]) {
        if ([self.delegate respondsToSelector:@selector(didSelectSticker:)]) {
          [self.delegate didSelectSticker:sticker];
        }
        return;
      }
    }
  }
}

- (void)didPressSend:(UIButton *)sender {
  [self.delegate didPressSend:sender];
}

#pragma mark - EmojiPageViewDataSource

- (NSInteger)numberOfPages:(nullable EmojiPageView *)pageView {
  return self.pageMapping.totalPages;
}

- (UIView *)pageView:(nullable EmojiPageView *)pageView index:(NSInteger)index {
  NSInteger sectionIndex = 0;
  NSInteger localPage = 0;
  if (![self.pageMapping getSectionIndex:&sectionIndex
                               localPage:&localPage
                          forGlobalIndex:index] ||
      sectionIndex < 0 || sectionIndex >= (NSInteger)self.sections.count) {
    return [[UIView alloc] init];
  }
  NIMInputEmoticonSection *section = self.sections[sectionIndex];
  if (section.type == NIMInputEmoticonSectionTypeEmoji) {
    return [self emojiPageViewForCatalog:section.content page:localPage];
  }
  return [self stickerPageViewForPackage:section.content page:localPage];
}

#pragma mark - EmojiPageViewDelegate

- (BOOL)needScrollAnimation {
  return YES;
}

- (void)pageViewDidScroll:(nullable EmojiPageView *)pageView {}

- (void)pageViewScrollEnd:(nullable EmojiPageView *)pageView
             currentIndex:(NSInteger)currentIndex
               totolPages:(NSInteger)totolPages {
  NSInteger sectionIndex = 0;
  NSInteger localPage = 0;
  if ([self.pageMapping getSectionIndex:&sectionIndex
                              localPage:&localPage
                         forGlobalIndex:currentIndex]) {
    [self setSelectionWithSectionIndex:sectionIndex localPage:localPage scroll:NO];
  }
}

#pragma mark - InputEmoticonTabViewDelegate

- (void)tabView:(nullable InputEmoticonTabView *)tabView
    didSelectTabIndex:(NSInteger)index {
  [self setSelectionWithSectionIndex:index localPage:0 scroll:YES];
}

#pragma mark - NIMInputEmoticonButtonDelegate

- (void)selectedEmoticon:(NIMInputEmoticon *)emotion catalogID:(NSString *)catalogID {
  if (emotion.emoticonID.length == 0) {
    [NEALog errorLog:kClassTag desc:@"emoticonID is nil"];
    return;
  }
  NSString *description = emotion.type == NIMEmoticonTypeUnicode
      ? (emotion.unicode ?: @"")
      : (emotion.tag ?: @"");
  [self.delegate selectedEmoticon:emotion.emoticonID
                    emotCatalogID:catalogID
                      description:description];
}

@end
