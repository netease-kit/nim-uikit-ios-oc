// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEAIWordSearchViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEAIWordSearchViewController : UIViewController <NEAIWordSearchViewModelDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (nonatomic, strong) NEAIWordSearchViewModel *viewModel;
@property (nonatomic, copy, nullable) NSString *searchText;
@property (nonatomic, assign) CGFloat margin;
@property (nonatomic, assign) CGFloat titleBarBottomLineHeight;
@property (nonatomic, assign) CGFloat backButtonWidth;
@property (nonatomic, assign) CGFloat moreButtonWidth;
@property (nonatomic, strong) UIColor *themeColor;

- (instancetype)initWithSearchText:(nullable NSString *)searchText;

@end

NS_ASSUME_NONNULL_END
