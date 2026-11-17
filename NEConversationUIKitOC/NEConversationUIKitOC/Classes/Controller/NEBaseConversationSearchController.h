// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationBaseViewController.h"

@class SearchTextField;
@class NEEmptyDataView;
@class ConversationSearchViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseConversationSearchController : NEConversationBaseViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) ConversationSearchViewModel *viewModel;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *searchStr;
@property (nonatomic, strong) NSMutableArray<NSString *> *headTitleArr;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) SearchTextField *searchTextField;
@property (nonatomic, strong) NEEmptyDataView *emptyView;
@property (nonatomic, strong, nullable) NSLayoutConstraint *searchTextFieldTopAnchor;

- (void)initialConfig;
- (void)setupSubviews;
- (void)searchTextFieldChange:(SearchTextField *)textfield;
- (void)searchTextFieldChangeWithTextfield:(SearchTextField *)textfield;

@end

NS_ASSUME_NONNULL_END
