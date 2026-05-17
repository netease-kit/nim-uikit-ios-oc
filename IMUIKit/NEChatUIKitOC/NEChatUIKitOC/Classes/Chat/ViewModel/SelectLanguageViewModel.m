// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "SelectLanguageViewModel.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import "NETranslateLanguageManager.h"

@implementation NElanguageCellModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _language = @"";
    _isSelect = NO;
    _cornerType = CornerTypeNone;
  }
  return self;
}

@end

@implementation SelectLanguageViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _datas = [NSMutableArray array];
  }
  return self;
}

- (void)setupData:(BOOL)isFun {
  NSArray<NSString *> *languageDatas = [NETranslateLanguageManager shared].languageDatas;
  if (!languageDatas) {
    languageDatas = @[];
  }

  if (isFun) {
    for (NSInteger index = 0; index < languageDatas.count; index++) {
      NElanguageCellModel *model = [[NElanguageCellModel alloc] init];
      model.language = languageDatas[index];
      if (index == 0) {
        model.cornerType = CornerTypeTopLeft | CornerTypeTopRight;
      } else if (index == languageDatas.count - 1) {
        model.cornerType = CornerTypeBottomLeft | CornerTypeBottomRight;
      }
      [self.datas addObject:model];
    }
  } else {
    for (NSInteger index = 0; index < languageDatas.count; index++) {
      NElanguageCellModel *model = [[NElanguageCellModel alloc] init];
      model.language = languageDatas[index];
      [self.datas addObject:model];
    }
  }
}

@end
