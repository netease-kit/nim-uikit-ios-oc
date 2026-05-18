// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "PersonInfoViewController.h"
#import "InputPersonInfoController.h"
#import "BirthdayDatePickerView.h"
#import "AppKey.h"
#import "NEStyleManager.h"
#import <NEChatUIKitOC/ChatUIConfig.h>
#import <NEChatKitOC/ChatConstant.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/NECoreIM2Constant.h>
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import <NEChatKitOC/NEAppLanguageUtil.h>
#import <NEChatKitOC/NEResultModel.h>
#import <NEChatKitOC/NEPathUtils.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NENavigationView.h>
#import <NEChatKitOC/ContactRepo.h>
#import <NEChatKitOC/ResourceRepo.h>
#import <NEChatUIKitOC/FunChatUIColor.h>
#import <NETeamUIKitOC/SettingCellModel.h>
#import <NETeamUIKitOC/SettingSectionModel.h>
#import <NETeamUIKitOC/NEBaseTeamSettingCell.h>
#import "CustomThemeCells.h"
#import <NIMSDK/NIMSDK.h>
#import <Photos/Photos.h>

#pragma mark - PersonInfoViewModel

@interface PersonInfoViewModel ()
@property (nonatomic, strong, readwrite) NSArray<SettingSectionModel *> *sectionData;
@end

@implementation PersonInfoViewModel

- (void)getData:(void(^)(void))completion {
  NSString *accountId = [[IMKitClient instance] account];
  NEUserWithFriend *userFriend = [[NEFriendUserCache shared] getFriendInfo:accountId];
  if (userFriend) {
    self.userInfo = userFriend;
    [self refreshData];
    if (completion) {
      completion();
    }
    return;
  }

  __weak typeof(self) weakSelf = self;
  [[ContactRepo shared] getUserListFromCloud:@[accountId] completion:^(NSArray<NEUserWithFriend *> *users, NSError *error) {
    (void)error;
    weakSelf.userInfo = users.firstObject;
    [weakSelf refreshData];
    dispatch_async(dispatch_get_main_queue(), ^{
      if (completion) {
        completion();
      }
    });
  }];
}

- (void)refreshData {
  NSMutableArray<SettingSectionModel *> *sections = [NSMutableArray array];
  [sections addObject:[self getFirstSection]];
  [sections addObject:[self getSecondSection]];
  self.sectionData = sections.copy;
}

- (SettingSectionModel *)getFirstSection {
  SettingSectionModel *model = [[SettingSectionModel alloc] init];
  NEUserWithFriend *mineInfo = self.userInfo;
  if (!mineInfo) {
    return model;
  }

  __weak typeof(self) weakSelf = self;

  SettingCellModel *headImageItem = [[SettingCellModel alloc] init];
  headImageItem.type = SettingCellTypeSettingHeaderCell;
  headImageItem.cellName = NELocalizable(@"headImage");
  headImageItem.headerUrl = self.userInfo.user.avatar;
  headImageItem.defaultHeadData = [self.userInfo showName];
  headImageItem.subTitle = self.userInfo.user.accountId;
  headImageItem.rowHeight = 64.0;
  headImageItem.cellClick = ^{
    [weakSelf.delegate didClickHeadImage];
  };

  SettingCellModel *nickNameItem = [[SettingCellModel alloc] init];
  nickNameItem.type = SettingCellTypeSettingSubtitleCell;
  nickNameItem.cellName = NELocalizable(@"nickname");
  nickNameItem.titleWidth = 90.0;
  nickNameItem.subTitle = [mineInfo showName];
  nickNameItem.rowHeight = 46.0;
  NSString *nickNameValue = nickNameItem.subTitle ?: @"";
  nickNameItem.cellClick = ^{
    [weakSelf.delegate didClickNickName:nickNameValue];
  };

  SettingCellModel *accountItem = [[SettingCellModel alloc] init];
  accountItem.type = SettingCellTypeSettingSubtitleCustomCell;
  accountItem.cellName = NELocalizable(@"account");
  accountItem.titleWidth = 60.0;
  accountItem.subTitle = mineInfo.user.accountId;
  accountItem.rowHeight = 46.0;
  accountItem.rightCustomViewIcon = [UIImage imageNamed:@"copy_icon"];
  accountItem.customViewClick = ^{
    [weakSelf.delegate didCopyAccount:mineInfo.user.accountId ?: @""];
  };

  SettingCellModel *sexItem = [[SettingCellModel alloc] init];
  sexItem.type = SettingCellTypeSettingSubtitleCell;
  sexItem.cellName = NELocalizable(@"gender");
  sexItem.titleWidth = 60.0;
  sexItem.rowHeight = 46.0;
  switch (mineInfo.user.gender) {
    case V2NIM_GENDER_MALE:
      sexItem.subTitle = NELocalizable(@"male");
      break;
    case V2NIM_GENDER_FEMALE:
      sexItem.subTitle = NELocalizable(@"female");
      break;
    default:
      sexItem.subTitle = NELocalizable(@"unknown");
      break;
  }
  sexItem.cellClick = ^{
    [weakSelf.delegate didClickGender];
  };

  SettingCellModel *birthdayItem = [[SettingCellModel alloc] init];
  birthdayItem.type = SettingCellTypeSettingSubtitleCell;
  birthdayItem.cellName = NELocalizable(@"birthday");
  birthdayItem.titleWidth = 80.0;
  birthdayItem.subTitle = mineInfo.user.birthday;
  birthdayItem.rowHeight = 46.0;
  birthdayItem.cellClick = ^{
    [weakSelf.delegate didClickBirthday:mineInfo.user.birthday ?: @""];
  };

  SettingCellModel *telephoneItem = [[SettingCellModel alloc] init];
  telephoneItem.type = SettingCellTypeSettingSubtitleCell;
  telephoneItem.cellName = NELocalizable(@"phone");
  telephoneItem.titleWidth = 60.0;
  telephoneItem.subTitle = mineInfo.user.mobile;
  telephoneItem.rowHeight = 46.0;
  NSString *mobileValue = telephoneItem.subTitle ?: @"";
  telephoneItem.cellClick = ^{
    [weakSelf.delegate didClickMobile:mobileValue];
  };

  SettingCellModel *emailItem = [[SettingCellModel alloc] init];
  emailItem.type = SettingCellTypeSettingSubtitleCell;
  emailItem.cellName = NELocalizable(@"email");
  emailItem.titleWidth = 60.0;
  emailItem.subTitle = mineInfo.user.email;
  emailItem.rowHeight = 46.0;
  NSString *emailValue = emailItem.subTitle ?: @"";
  emailItem.cellClick = ^{
    [weakSelf.delegate didClickEmail:emailValue];
  };

  [model.cellModels addObjectsFromArray:@[
    headImageItem,
    nickNameItem,
    accountItem,
    sexItem,
    birthdayItem,
    telephoneItem,
    emailItem,
  ]];
  [model setCornerType];
  return model;
}

- (SettingSectionModel *)getSecondSection {
  SettingSectionModel *model = [[SettingSectionModel alloc] init];
  NEUserWithFriend *mineInfo = self.userInfo;
  if (!mineInfo) {
    return model;
  }

  SettingCellModel *signItem = [[SettingCellModel alloc] init];
  signItem.type = SettingCellTypeSettingSubtitleCell;
  signItem.cellName = NELocalizable(@"individuality_sign");
  signItem.subTitle = mineInfo.user.sign;
  signItem.rowHeight = 46.0;
  signItem.titleWidth = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 76.0 : 64.0;
  __weak typeof(self) weakSelf = self;
  NSString *signValue = signItem.subTitle ?: @"";
  signItem.cellClick = ^{
    [weakSelf.delegate didClickSign:signValue];
  };

  [model.cellModels addObject:signItem];
  [model setCornerType];
  return model;
}

- (void)doUpdateProfile:(V2NIMUserUpdateParams *)params completion:(void(^)(NSError *_Nullable))completion {
  [[ContactRepo shared] updateSelfUserProfile:params completion:^(NSError *error) {
    if (completion) {
      completion(error);
    }
  }];
}

- (void)updateSelfAvatar:(NSString *)avatar completion:(void(^)(NSError *_Nullable))completion {
  V2NIMUserUpdateParams *params = [[V2NIMUserUpdateParams alloc] init];
  params.avatar = avatar;
  [self doUpdateProfile:params completion:completion];
}

- (void)updateSelfNickName:(NSString *)name completion:(void(^)(NSError *_Nullable))completion {
  V2NIMUserUpdateParams *params = [[V2NIMUserUpdateParams alloc] init];
  params.name = name.length ? name : [[IMKitClient instance] account];
  [self doUpdateProfile:params completion:completion];
}

- (void)updateSelfSex:(V2NIMGender)gender completion:(void(^)(NSError *_Nullable))completion {
  V2NIMUserUpdateParams *params = [[V2NIMUserUpdateParams alloc] init];
  params.gender = gender;
  [self doUpdateProfile:params completion:completion];
}

- (void)updateSelfBirthday:(NSString *)birthday completion:(void(^)(NSError *_Nullable))completion {
  V2NIMUserUpdateParams *params = [[V2NIMUserUpdateParams alloc] init];
  params.birthday = birthday;
  [self doUpdateProfile:params completion:completion];
}

- (void)updateSelfMobile:(NSString *)mobile completion:(void(^)(NSError *_Nullable))completion {
  V2NIMUserUpdateParams *params = [[V2NIMUserUpdateParams alloc] init];
  params.mobile = mobile;
  [self doUpdateProfile:params completion:completion];
}

- (void)updateSelfEmail:(NSString *)email completion:(void(^)(NSError *_Nullable))completion {
  V2NIMUserUpdateParams *params = [[V2NIMUserUpdateParams alloc] init];
  params.email = email;
  [self doUpdateProfile:params completion:completion];
}

- (void)updateSelfSign:(NSString *)sign completion:(void(^)(NSError *_Nullable))completion {
  V2NIMUserUpdateParams *params = [[V2NIMUserUpdateParams alloc] init];
  params.sign = sign;
  [self doUpdateProfile:params completion:completion];
}

@end

#pragma mark - PersonInfoViewController

@interface PersonInfoViewController () <UITableViewDataSource, UITableViewDelegate,
UIImagePickerControllerDelegate, UINavigationControllerDelegate, NEContactListener,
PersonInfoViewModelDelegate>

@property (nonatomic, strong) PersonInfoViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) BirthdayDatePickerView *pickerView;
@property (nonatomic, strong) NSDictionary<NSNumber *, Class> *cellClassDic;

@end

@implementation PersonInfoViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = NELocalizable(@"person_info");
  self.viewModel = [[PersonInfoViewModel alloc] init];
  self.viewModel.delegate = self;
  [[ContactRepo shared] addContactListener:self];

  if ([NEStyleManager.instance isNormalStyle]) {
    self.view.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationView.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor ne_backgroundColor];
  } else {
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
  }
  self.navigationView.moreButton.hidden = YES;

  [self setupSubviews];
  __weak typeof(self) weakSelf = self;
  [self.viewModel getData:^{
    [weakSelf.tableView reloadData];
  }];
}

- (void)dealloc {
  [[ContactRepo shared] removeContactListener:self];
}

- (void)setupSubviews {
  self.cellClassDic = @{
    @(SettingCellTypeSettingSubtitleCell): [CustomTeamSettingSubtitleCell class],
    @(SettingCellTypeSettingSubtitleCustomCell): [CustomTeamSettingRightCustomCell class],
    @(SettingCellTypeSettingHeaderCell): [CustomTeamSettingHeaderCell class],
  };

  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.backgroundColor = UIColor.clearColor;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.separatorColor = UIColor.clearColor;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
  self.tableView.estimatedRowHeight = 0;
  self.tableView.estimatedSectionHeaderHeight = 0;
  self.tableView.estimatedSectionFooterHeight = 0;
  if (@available(iOS 15.0, *)) {
    self.tableView.sectionHeaderTopPadding = 0;
  }

  for (NSNumber *key in self.cellClassDic) {
    [self.tableView registerClass:self.cellClassDic[key]
           forCellReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)key.integerValue]];
  }

  [self.view addSubview:self.tableView];

  CGFloat top = self.topConstant + ([NEStyleManager.instance isNormalStyle] ? 12.0 : 0.0);
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:top],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

- (void)rebuildSections {
  [self.viewModel refreshData];
  [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  (void)tableView;
  return self.viewModel.sectionData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  (void)tableView;
  if ((NSUInteger)section < self.viewModel.sectionData.count) {
    return self.viewModel.sectionData[section].cellModels.count;
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  NEBaseTeamSettingCell *cell =
      [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%ld", (long)model.type]
                                      forIndexPath:indexPath];
  [cell configure:model];
  return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  return model.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  (void)tableView;
  if (section == 0) {
    return 0.0;
  }
  if ((NSUInteger)section < self.viewModel.sectionData.count &&
      self.viewModel.sectionData[section].cellModels.count > 0) {
    return 12.0;
  }
  return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  (void)tableView;
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = [UIColor ne_lightBackgroundColor];
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  UIView *footerView = [[UIView alloc] init];
  footerView.backgroundColor = UIColor.clearColor;
  return footerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  if (model.cellClick) {
    model.cellClick();
  }
}

#pragma mark - Actions

- (BOOL)isValidEmail:(NSString *)email {
  NSString *emailRegex = @"^\\w+@\\w+\\.[a-zA-Z]{2,}";
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  return [predicate evaluateWithObject:email];
}

- (void)handleProfileError:(NSError *)error defaultKey:(NSString *)defaultKey {
  if (!error) {
    return;
  }
  if (error.code == antiErrorCode) {
    [self showToastInWindow:NELocalizable(@"anti_error")];
    return;
  }
  [self showToastInWindow:NELocalizable(defaultKey)];
}

- (void)handleProfileResult:(NSError *)error defaultKey:(NSString *)defaultKey {
  if (error) {
    [self handleProfileError:error defaultKey:defaultKey];
    return;
  }
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)copyAccount:(NSString *)account {
  if (account.length == 0) {
    return;
  }
  [UIPasteboard generalPasteboard].string = account;
  [self showToast:commonLocalizable(@"copy_success")];
}

- (void)pushInputVC:(NEEditType)type current:(NSString *)current {
  InputPersonInfoController *vc = [[InputPersonInfoController alloc] init];
  [vc configTitle:type];
  vc.contentText = current;
  __weak typeof(self) weakSelf = self;
  vc.callBack = ^(NSString *editText) {
    [weakSelf handleInputResult:editText type:type];
  };
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)handleInputResult:(NSString *)text type:(NEEditType)type {
  if (type == NEEditTypeEmail && text.length > 0 && ![self isValidEmail:text]) {
    [self showToastInWindow:NELocalizable(@"change_email_failure")];
    return;
  }

  __weak typeof(self) weakSelf = self;
  if (type == NEEditTypeNickName) {
    [self.viewModel updateSelfNickName:text completion:^(NSError *error) {
      [weakSelf handleProfileResult:error defaultKey:@"setting_nickname_failure"];
    }];
  } else if (type == NEEditTypeCellphone) {
    [self.viewModel updateSelfMobile:text completion:^(NSError *error) {
      [weakSelf handleProfileResult:error defaultKey:@"change_phone_failure"];
    }];
  } else if (type == NEEditTypeEmail) {
    [self.viewModel updateSelfEmail:text completion:^(NSError *error) {
      [weakSelf handleProfileResult:error defaultKey:@"change_email_failure"];
    }];
  } else if (type == NEEditTypeSpecialSign) {
    [self.viewModel updateSelfSign:text completion:^(NSError *error) {
      [weakSelf handleProfileResult:error defaultKey:@"change_sign_failure"];
    }];
  }
}

- (void)showAlertWithFirstContent:(NSString *)firstContent
                    secondContent:(NSString *)secondContent
                      selectValue:(void(^)(NSInteger value))selectValue {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleActionSheet];
  alert.modalPresentationStyle = UIModalPresentationPopover;

  UIAlertAction *firstAction = [UIAlertAction actionWithTitle:firstContent
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(__unused UIAlertAction *action) {
    if (selectValue) {
      selectValue(0);
    }
  }];
  [firstAction setValue:[UIColor colorWithRed:0x33 / 255.0 green:0x33 / 255.0 blue:0x33 / 255.0 alpha:1.0]
                 forKey:@"_titleTextColor"];
  firstAction.accessibilityIdentifier = @"id.action1";

  UIAlertAction *secondAction = [UIAlertAction actionWithTitle:secondContent
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(__unused UIAlertAction *action) {
    if (selectValue) {
      selectValue(1);
    }
  }];
  [secondAction setValue:[UIColor colorWithRed:0x33 / 255.0 green:0x33 / 255.0 blue:0x33 / 255.0 alpha:1.0]
                  forKey:@"_titleTextColor"];
  secondAction.accessibilityIdentifier = @"id.action2";

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [cancelAction setValue:[UIColor colorWithRed:0x33 / 255.0 green:0x33 / 255.0 blue:0x33 / 255.0 alpha:1.0]
                  forKey:@"_titleTextColor"];
  cancelAction.accessibilityIdentifier = @"id.action3";

  [alert addAction:firstAction];
  [alert addAction:secondAction];
  [alert addAction:cancelAction];
  [self fixAlertOnIpad:alert];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showCustomAlertWithFirstContent:(NSString *)firstContent
                          secondContent:(NSString *)secondContent
                            selectValue:(void(^)(NSInteger value))selectValue {
  NECustomAlertAction *firstAction = [NECustomAlertAction actionWithTitle:firstContent handler:^{
    if (selectValue) {
      selectValue(0);
    }
  }];
  NECustomAlertAction *secondAction = [NECustomAlertAction actionWithTitle:secondContent handler:^{
    if (selectValue) {
      selectValue(1);
    }
  }];
  [self showCustomActionSheet:@[firstAction, secondAction]];
}

- (void)didClickHeadImage {
  [self showAvatarPicker];
}

- (void)didClickNickName:(NSString *)name {
  [self pushInputVC:NEEditTypeNickName current:name ?: @""];
}

- (void)didClickGender {
  [self showGenderPicker];
}

- (void)didClickBirthday:(NSString *)birth {
  [self showBirthdayPicker:birth ?: @""];
}

- (void)didClickMobile:(NSString *)mobile {
  [self pushInputVC:NEEditTypeCellphone current:mobile ?: @""];
}

- (void)didClickEmail:(NSString *)email {
  [self pushInputVC:NEEditTypeEmail current:email ?: @""];
}

- (void)didClickSign:(NSString *)sign {
  [self pushInputVC:NEEditTypeSpecialSign current:sign ?: @""];
}

- (void)didCopyAccount:(NSString *)account {
  [self copyAccount:account];
}

- (void)showGenderPicker {
  __weak typeof(self) weakSelf = self;
  void (^updateGender)(NSInteger) = ^(NSInteger value) {
    V2NIMGender genderValue = value == 0 ? V2NIM_GENDER_MALE : V2NIM_GENDER_FEMALE;
    [weakSelf.viewModel updateSelfSex:genderValue completion:^(NSError *error) {
      if (!error) {
        return;
      }
      if (error.code == antiErrorCode) {
        [weakSelf showToastInWindow:NELocalizable(@"anti_error")];
      } else if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else {
        [weakSelf showToast:NELocalizable(@"change_gender_failure")];
      }
    }];
  };

  if ([NEStyleManager.instance isNormalStyle]) {
    [self showAlertWithFirstContent:NELocalizable(@"male")
                      secondContent:NELocalizable(@"female")
                        selectValue:updateGender];
    return;
  }

  [self showCustomAlertWithFirstContent:NELocalizable(@"male")
                          secondContent:NELocalizable(@"female")
                            selectValue:updateGender];
}

- (void)showBirthdayPicker:(NSString *)current {
  self.pickerView = [[BirthdayDatePickerView alloc] initWithFrame:CGRectZero];
  self.pickerView.translatesAutoresizingMaskIntoConstraints = NO;
  if (current.length > 0) {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    NSDate *date = [formatter dateFromString:current];
    if (date) {
      [self.pickerView.picker setDate:date animated:YES];
    }
  }

  __weak typeof(self) weakSelf = self;
  self.pickerView.timeCallBack = ^(NSString *time) {
    if (!time.length) {
      return;
    }
    [weakSelf.viewModel updateSelfBirthday:time completion:^(NSError *error) {
      if (!error) {
        return;
      }
      if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else {
        [weakSelf showToast:NELocalizable(@"setting_birthday_failure")];
      }
    }];
  };
  [self.view addSubview:self.pickerView];
  [NSLayoutConstraint activateConstraints:@[
    [self.pickerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.pickerView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.pickerView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.pickerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

- (void)handleSelectedAvatarResults:(NSArray<NEResultModel *> *)results {
  for (NEResultModel *model in results) {
    if (model.asset.mediaType == PHAssetMediaTypeVideo) {
      [self showToast:commonLocalizable(@"only_support_choose_image")];
      return;
    }
    if (model.asset.mediaType == PHAssetMediaTypeImage && results.count > avatarImageCountLimit) {
      [self showToast:[NSString stringWithFormat:commonLocalizable(@"image_count_over_limit"), (int)avatarImageCountLimit]];
      return;
    }
    [self uploadHeadImage:model.image];
  }
}

- (void)showAvatarPicker {
  __weak typeof(self) weakSelf = self;
  NEChatInputPhotoClickBlock callback = [ChatUIConfig shared].chatInputPhotoClick;
  if (callback) {
    if ([NEStyleManager.instance isNormalStyle]) {
      UIAlertAction *takingPicturesAction = [UIAlertAction actionWithTitle:commonLocalizable(@"take_picture")
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(__unused UIAlertAction *action) {
        [weakSelf goCamera:weakSelf editing:YES isVideo:NO];
      }];
      UIAlertAction *photoAction = [UIAlertAction actionWithTitle:commonLocalizable(@"select_from_album")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(__unused UIAlertAction *action) {
        callback(weakSelf, NEMediaTypeImage, avatarImageCountLimit, ^(NSArray<NEResultModel *> *results, __unused BOOL isOriginal) {
          [weakSelf handleSelectedAvatarResults:results];
        });
      }];
      UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                             style:UIAlertActionStyleCancel
                                                           handler:nil];
      [self showActionSheet:@[takingPicturesAction, photoAction, cancelAction]];
      return;
    }

    NECustomAlertAction *takingPicturesAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"take_picture") handler:^{
      [weakSelf goCamera:weakSelf editing:YES isVideo:NO];
    }];
    NECustomAlertAction *photoAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"select_from_album") handler:^{
      callback(weakSelf, NEMediaTypeImage, avatarImageCountLimit, ^(NSArray<NEResultModel *> *results, __unused BOOL isOriginal) {
        [weakSelf handleSelectedAvatarResults:results];
      });
    }];
    [self showCustomActionSheet:@[takingPicturesAction, photoAction]];
    return;
  }

  if ([NEStyleManager.instance isNormalStyle]) {
    [self showBottomAlert:self editing:YES checkNetwork:YES clickedAction:nil presentCompletion:nil];
  } else {
    [self showCustomBottomAlert:self editing:YES checkNetwork:YES];
  }
}

- (void)uploadHeadImage:(UIImage *)image {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
  NSString *accountId = [[IMKitClient instance] account] ?: @"";
  NSString *filePath = [NEPathUtils getDirectoryForDocuments:[NSString stringWithFormat:@"%@image/", imkitDir]];
  if (imageData.length <= 0 || filePath.length <= 0 || accountId.length <= 0) {
    return;
  }

  [self.view ne_makeToastActivity:NEToastPositionCenter];
  filePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_avatar.jpg", accountId]];
  if (![imageData writeToFile:filePath atomically:YES]) {
    [self.view ne_hideToastActivity];
    return;
  }

  __weak typeof(self) weakSelf = self;
  V2NIMUploadFileTask *task = [[ResourceRepo shared] createUploadFileTask:filePath sceneName:nil];
  [[ResourceRepo shared] uploadFile:task progress:nil completion:^(NSString * _Nullable url, NSError * _Nullable error) {
    if (!error && url.length > 0) {
      [weakSelf.viewModel updateSelfAvatar:url completion:^(NSError * _Nullable updateError) {
        if (updateError) {
          [weakSelf showToast:NELocalizable(@"setting_head_failure")];
        }
      }];
    }
    [weakSelf.view ne_hideToastActivity];
  }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
  UIImage *image = info[UIImagePickerControllerEditedImage];
  if (!image) {
    image = info[UIImagePickerControllerOriginalImage];
  }
  [picker dismissViewControllerAnimated:YES completion:nil];
  if (!image) {
    return;
  }
  [self uploadHeadImage:image];
}

#pragma mark - NEContactListener

- (void)onContactChange:(NEContactChangeType)changeType contacts:(NSArray<NEUserWithFriend *> *)contacts {
  (void)changeType;
  NSString *accountId = [[IMKitClient instance] account];
  for (NEUserWithFriend *contact in contacts) {
    if ([contact.user.accountId isEqualToString:accountId]) {
      self.viewModel.userInfo = contact;
      [self rebuildSections];
      break;
    }
  }
}

@end
