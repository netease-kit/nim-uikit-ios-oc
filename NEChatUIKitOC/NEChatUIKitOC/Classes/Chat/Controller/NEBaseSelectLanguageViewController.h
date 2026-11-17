// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEChatBaseViewController.h"
#import "SelectLanguageViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SelectLanguageDelegate <NSObject>
@optional
- (void)didSelectLanguage:(nullable NSString *)language controller:(nullable UIViewController *)controller;
@end

@interface NEBaseSelectLanguageViewController : NEChatBaseViewController
    <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) SelectLanguageViewModel *viewModel;
@property (nonatomic, weak, nullable) id<SelectLanguageDelegate> delegate;
@property (nonatomic, copy) NSString *currentContent;
@property (nonatomic, strong) UITableView *languageTableView;
/// 列内嵌入时的关闭回调；为 nil 时保持原 modal dismiss 语义。
@property (nonatomic, copy, nullable) void (^columnDismissHandler)(void);

- (void)setupLanguageUI;
- (void)cancelClick;

@end

NS_ASSUME_NONNULL_END
