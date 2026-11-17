// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseSelectLanguageViewController.h"
#import "NEBaseLanguageCell.h"
#import "ChatNavigationView.h"

@implementation NEBaseSelectLanguageViewController

- (instancetype)init {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _viewModel = [[SelectLanguageViewModel alloc] init];
        _currentContent = @"";
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.datas.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NEBaseLanguageCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NEBaseLanguageCell class]) forIndexPath:indexPath];
    if (cell) {
        if (indexPath.row >= self.viewModel.datas.count) {
            return cell;
        }
        NElanguageCellModel *model = self.viewModel.datas[indexPath.row];
        model.isSelect = [model.language isEqualToString:self.currentContent];
        [cell configureData:model];
        return cell;
    }
    return [[UITableViewCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.datas.count) {
        return;
    }
    NElanguageCellModel *model = self.viewModel.datas[indexPath.row];
    if ([self.delegate respondsToSelector:@selector(didSelectLanguage:controller:)]) {
        [self.delegate didSelectLanguage:model.language controller:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (!self.columnDismissHandler) {
        [super dismissViewControllerAnimated:flag completion:completion];
        return;
    }
    self.columnDismissHandler();
    if (completion) {
        completion();
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLanguageUI];
}

- (void)setupLanguageUI {
    self.navigationController.navigationBarHidden = YES;
    self.navigationView.hidden = YES;
    self.view.backgroundColor = UIColor.whiteColor;
}

- (void)cancelClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Lazy Properties

- (UITableView *)languageTableView {
    if (!_languageTableView) {
        _languageTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _languageTableView.backgroundColor = UIColor.clearColor;
        _languageTableView.delegate = self;
        _languageTableView.dataSource = self;
        _languageTableView.translatesAutoresizingMaskIntoConstraints = NO;
        _languageTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _languageTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _languageTableView.estimatedRowHeight = 0;
        _languageTableView.estimatedSectionHeaderHeight = 0;
        _languageTableView.estimatedSectionFooterHeight = 0;
        if (@available(iOS 15.0, *)) {
            _languageTableView.sectionHeaderTopPadding = 0.0;
        }
        [_languageTableView registerClass:[NEBaseLanguageCell class]
                   forCellReuseIdentifier:NSStringFromClass([NEBaseLanguageCell class])];
    }
    return _languageTableView;
}

@end
