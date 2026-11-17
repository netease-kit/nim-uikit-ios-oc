// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "IntroduceBrandViewController.h"
#import <NEChatKit/NEChatKit.h>
#import "AppKey.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/NENavigationView.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NETeamUIKitOC/SettingCellModel.h>

#pragma mark - IntroduceViewModel

@interface IntroduceViewModel : NSObject

@property (nonatomic, strong) NSArray<SettingCellModel *> *sectionData;

- (void)getData;

@end

@implementation IntroduceViewModel

- (void)getData {
  NSMutableArray<SettingCellModel *> *data = [NSMutableArray array];

  SettingCellModel *versionItem = [[SettingCellModel alloc] init];
  versionItem.cellName = NELocalizable(@"version");
  NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  if (appVersion.length > 0) {
    versionItem.subTitle = [NSString stringWithFormat:@"V%@", appVersion];
  }
  [data addObject:versionItem];

  SettingCellModel *imVersionItem = [[SettingCellModel alloc] init];
  imVersionItem.cellName = NELocalizable(@"im_version");
  imVersionItem.subTitle = [[IMKitClient instance] sdkVersion];
  imVersionItem.type = SettingCellTypeSettingSubtitleCell;
  [data addObject:imVersionItem];

  SettingCellModel *introduceItem = [[SettingCellModel alloc] init];
  introduceItem.cellName = NELocalizable(@"product_intro");
  [data addObject:introduceItem];

  self.sectionData = [data copy];
}

@end

#pragma mark - VersionCell

@interface VersionCell ()
@property (nonatomic, strong) UIView *bottomLine;
@end

@implementation VersionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupSubviews];
  }
  return self;
}

- (void)setupSubviews {
  _titleLabel = [[UILabel alloc] init];
  _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _titleLabel.textColor = [UIColor ne_darkText];
  _titleLabel.font = [UIFont systemFontOfSize:14.0];
  [self.contentView addSubview:_titleLabel];

  _subTitleLabel = [[UILabel alloc] init];
  _subTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _subTitleLabel.textColor = [UIColor ne_darkText];
  _subTitleLabel.font = [UIFont systemFontOfSize:14.0];
  _subTitleLabel.hidden = YES;
  _subTitleLabel.accessibilityIdentifier = @"id.version";
  [self.contentView addSubview:_subTitleLabel];

  _arrowImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
  _arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
  _arrowImageView.hidden = YES;
  [self.contentView addSubview:_arrowImageView];

  _bottomLine = [[UIView alloc] init];
  _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
  _bottomLine.backgroundColor = [UIColor colorWithRed:0xDB / 255.0 green:0xE0 / 255.0 blue:0xE8 / 255.0 alpha:1.0];
  [self.contentView addSubview:_bottomLine];

  [NSLayoutConstraint activateConstraints:@[
    [_titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [_titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

    [_subTitleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
    [_subTitleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

    [_arrowImageView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
    [_arrowImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

    [_bottomLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [_bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [_bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [_bottomLine.heightAnchor constraintEqualToConstant:0.5],
  ]];
}

- (void)setCellType:(IntroduceCellType)cellType {
  _cellType = cellType;
  _subTitleLabel.hidden = (cellType != IntroduceCellTypeVersion);
  _arrowImageView.hidden = (cellType != IntroduceCellTypeProductIntroduce);
}

- (void)configData:(SettingCellModel *)model {
  _titleLabel.text = model.cellName;
  _subTitleLabel.text = model.subTitle;
}

@end

#pragma mark - IntroduceBrandViewController

@interface IntroduceBrandViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IntroduceViewModel *viewModel;
@property (nonatomic, strong) UIImageView *headImageView;
@property (nonatomic, strong) UILabel *headLabel;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation IntroduceBrandViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.viewModel = [[IntroduceViewModel alloc] init];
  [self.viewModel getData];
  [self setupSubviews];
}

- (void)setupSubviews {
  self.title = NELocalizable(@"about_yunxin");
  self.view.backgroundColor = UIColor.whiteColor;
  self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
  self.navigationView.backgroundColor = UIColor.whiteColor;
  self.navigationView.moreButton.hidden = YES;

  self.headImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"yunxin_logo"]];
  self.headImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.headImageView.accessibilityIdentifier = @"id.aboutLogo";
  [self.view addSubview:self.headImageView];

  self.headLabel = [[UILabel alloc] init];
  self.headLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.headLabel.text = NELocalizable(@"brand_des");
  self.headLabel.font = [UIFont systemFontOfSize:20.0];
  self.headLabel.textColor = [UIColor ne_darkText];
  self.headLabel.accessibilityIdentifier = @"id.aboutApp";
  [self.view addSubview:self.headLabel];

  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.backgroundColor = UIColor.whiteColor;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
  self.tableView.estimatedRowHeight = 0;
  self.tableView.estimatedSectionHeaderHeight = 0;
  self.tableView.estimatedSectionFooterHeight = 0;
  [self.tableView registerClass:[VersionCell class] forCellReuseIdentifier:@"VersionCell"];
  if (@available(iOS 15.0, *)) {
    self.tableView.sectionHeaderTopPadding = 0.0;
  }
  [self.view addSubview:self.tableView];

  [NSLayoutConstraint activateConstraints:@[
    [self.headImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.headImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant + 20.0],
    [self.headImageView.widthAnchor constraintEqualToConstant:72.0],
    [self.headImageView.heightAnchor constraintEqualToConstant:53.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.headLabel.centerXAnchor constraintEqualToAnchor:self.headImageView.centerXAnchor],
    [self.headLabel.topAnchor constraintEqualToAnchor:self.headImageView.bottomAnchor constant:10.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.topAnchor constraintEqualToAnchor:self.headImageView.bottomAnchor constant:45.0],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  return self.viewModel.sectionData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  VersionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VersionCell" forIndexPath:indexPath];
  SettingCellModel *model = self.viewModel.sectionData[indexPath.row];
  [cell configData:model];
  cell.cellType = indexPath.row <= 1 ? IntroduceCellTypeVersion : IntroduceCellTypeProductIntroduce;
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  if (indexPath.row == 2) {
    NEWKWebViewController *ctrl =
        [[NEWKWebViewController alloc] initWithUrl:@"https://netease.im/m/"
                                             title:NELocalizable(@"product_intro")];
    [self.navigationController pushViewController:ctrl animated:YES];
  }
}

@end
