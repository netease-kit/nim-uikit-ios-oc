// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEConversationGroupManageController.h"
#import <NEBaseUIKitOC/SearchTextField.h>
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "NEConversationGroupManager.h"
#import "NEConversationListModel.h"
#import <NEChatKit/NEChatKit-Swift.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/V2NIMConversationExtension.h>
#import <NEBaseUIKitOC/NEEmptyDataView.h>
#import <NEBaseUIKitOC/NEBaseViewController.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/NENavigationView.h>
#import <NEBaseUIKitOC/NEUserHeaderView.h>
#import <NEBaseUIKitOC/ViewControllerExtension.h>
#import <NEBaseUIKitOC/UIView+YXToast.h>
#import <objc/message.h>
#import <NEBaseUIKitOC/NEUnifiedBackButton.h>

static const NSInteger NEConversationGroupNameMaxLength = 20;

static NSUInteger NEGroupCharacterCount(NSString *value) {
  if (![value isKindOfClass:[NSString class]] || value.length == 0) return 0;
  __block NSUInteger count = 0;
  [value enumerateSubstringsInRange:NSMakeRange(0, value.length)
                            options:NSStringEnumerationByComposedCharacterSequences
                         usingBlock:^(__unused NSString *substring,
                                      __unused NSRange substringRange,
                                      __unused NSRange enclosingRange,
                                      __unused BOOL *stop) {
    count += 1;
  }];
  return count;
}

static NSString *NEGroupPrefix(NSString *value, NSUInteger maxLength) {
  if (![value isKindOfClass:[NSString class]] || value.length == 0 || maxLength == 0) return @"";
  __block NSUInteger count = 0;
  __block NSRange prefixRange = NSMakeRange(0, 0);
  [value enumerateSubstringsInRange:NSMakeRange(0, value.length)
                            options:NSStringEnumerationByComposedCharacterSequences
                         usingBlock:^(__unused NSString *substring,
                                      NSRange substringRange,
                                      __unused NSRange enclosingRange,
                                      BOOL *stop) {
    if (count >= maxLength) {
      *stop = YES;
      return;
    }
    count += 1;
    prefixRange.length = NSMaxRange(substringRange);
  }];
  return [value substringWithRange:prefixRange];
}

static NECommonLoader *NEGroupLoader(void) {
  static NECommonLoader *loader;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:[NEConversationGroupManageController class]];
  });
  return loader;
}

static NSString *NEGroupText(NSString *key, NSString *fallback) {
  NSString *value = [NEGroupLoader() localizable:key];
  return value.length > 0 && ![value isEqualToString:key] ? value : fallback;
}

static NSString *NEGroupErrorMessage(NSError *error) {
  if (!error) return NEGroupText(@"failed_operation", @"Operation failed");
  switch (error.code) {
    case 110304:
      return NEGroupText(@"conversation_group_belonged_limit", @"The number of groups this conversation belongs to has exceeded the limit");
    case 110404:
      return NEGroupText(@"conversation_group_conversation_not_exist", @"Conversation does not exist");
    case 116404:
      return NEGroupText(@"conversation_group_not_exist", @"Conversation group does not exist");
    case 116435:
      return NEGroupText(@"conversation_group_limit", @"Conversation group limit reached");
    case 116437:
      return NEGroupText(@"conversation_group_members_limit", @"Group conversation limit reached");
    default:
      return error.localizedDescription.length > 0 ? error.localizedDescription : NEGroupText(@"failed_operation", @"Operation failed");
  }
}

static UIColor *NEGroupColor(NSUInteger rgb) {
  return [UIColor colorWithRed:((rgb >> 16) & 0xFF) / 255.0
                         green:((rgb >> 8) & 0xFF) / 255.0
                          blue:(rgb & 0xFF) / 255.0
                         alpha:1];
}

static BOOL NEGroupIsFunStyle(void) {
  Class styleClass = NSClassFromString(@"NEStyleManager");
  SEL instanceSelector = NSSelectorFromString(@"instance");
  SEL normalSelector = NSSelectorFromString(@"isNormalStyle");
  if (styleClass && [styleClass respondsToSelector:instanceSelector]) {
    id manager = ((id (*)(id, SEL))objc_msgSend)(styleClass, instanceSelector);
    if (manager && [manager respondsToSelector:normalSelector]) {
      return !((BOOL (*)(id, SEL))objc_msgSend)(manager, normalSelector);
    }
  }
  return NO;
}

static UIColor *NEGroupPrimaryColor(void) {
  return NEGroupIsFunStyle() ? UIColor.ne_funTheme : UIColor.ne_defaultPrimaryColor;
}

static UIColor *NEGroupPageColor(void) {
  return NEGroupIsFunStyle() ? NEGroupColor(0xEDEDED) : NEGroupColor(0xF5F7FA);
}

static UIColor *NEGroupLineColor(void) {
  return NEGroupIsFunStyle() ? NEGroupColor(0xE5E5E5) : NEGroupColor(0xEFF1F4);
}

static UIColor *NEGroupAddConversationLineColor(void) {
  return NEGroupIsFunStyle() ? NEGroupColor(0xD8D8D8) : NEGroupLineColor();
}

static NSString *NEGroupConversationShortName(NEConversationListModel *model) {
  if (![model isKindOfClass:[NEConversationListModel class]]) return @"";
  NSString *name = [model.cloudConversation shortName:2];
  if (name.length == 0) name = [model.localConversation shortName:2];
  return name ?: @"";
}

static UIImage *NEGroupImage(NSString *name) {
  return [NEGroupLoader() loadImage:name];
}

static NSString *NEGroupSafeName(NSString *value) {
  if (![value isKindOfClass:[NSString class]]) return @"";
  NSString *name = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (NEGroupCharacterCount(name) <= NEConversationGroupNameMaxLength) return name;
  return NEGroupPrefix(name, NEConversationGroupNameMaxLength);
}

static V2NIMConversationOperationResult *NEGroupSafeOperationResult(id value) {
  return [value isKindOfClass:[V2NIMConversationOperationResult class]] ? value : nil;
}

static BOOL NEGroupOperationSucceeded(id value) {
  V2NIMConversationOperationResult *result = NEGroupSafeOperationResult(value);
  if (!result) return NO;
  V2NIMError *error = [result.error isKindOfClass:[V2NIMError class]] ? result.error : nil;
  // The SDK contract uses a nil error to represent a successful item.
  return !error || error.code == 0 || error.code == 200;
}

static NSError *NEGroupOperationError(id value) {
  V2NIMConversationOperationResult *result = NEGroupSafeOperationResult(value);
  V2NIMError *error = [result.error isKindOfClass:[V2NIMError class]] ? result.error : nil;
  return error.nserror;
}

static void NEGroupShowError(UIViewController *controller, NSError *error) {
  if (!error || !controller) return;
  NSString *message = NEGroupErrorMessage(error);
  SEL showToastSelector = NSSelectorFromString(@"showToast:");
  if ([controller respondsToSelector:showToastSelector]) {
    ((void (*)(id, SEL, NSString *))objc_msgSend)(controller, showToastSelector, message);
  } else if (controller.view) {
    [controller.view ne_makeToast:message];
  }
}

static BOOL NEGroupCanPerformNetworkAction(UIViewController *controller) {
  if (![NEChatDetectNetworkTool.shareInstance isNetworkExplicitlyUnreachable]) return YES;
  NSString *message = commonLocalizable(@"network_error");
  if (message.length == 0 || [message isEqualToString:@"network_error"]) message = @"Network unavailable";
  NEGroupShowError(controller, [NSError errorWithDomain:@"NEConversationUIKitOC.ConversationGroup"
                                                   code:NSURLErrorNotConnectedToInternet
                                               userInfo:@{NSLocalizedDescriptionKey: message}]);
  return NO;
}

@interface NEConversationGroupNameSheetController : UIViewController <UITextFieldDelegate>

- (void)presentAsColumnSheetInParent:(UIViewController *)parent;
- (void)closeSheetAnimated:(BOOL)animated;
- (instancetype)initWithTitle:(NSString *)title
                  initialName:(nullable NSString *)initialName
                  heightRatio:(CGFloat)heightRatio
                   completion:(void (^)(NSString *name))completion;
@end

@class NEConversationGroupNameController;
@interface NEConversationGroupNameController : NEBaseViewController <UITextFieldDelegate>
- (instancetype)initWithCompletion:(void (^)(NSString *name, NEConversationGroupNameController *controller))completion;
@end

@interface NEConversationGroupManageCell : UITableViewCell
@property(nonatomic, copy) dispatch_block_t leftAction;
@property(nonatomic, copy) dispatch_block_t settingAction;
- (void)configure:(NEConversationGroupItem *)group hidden:(BOOL)hidden last:(BOOL)last;
@end

@interface NEConversationGroupManageController () <NEConversationGroupManagerDelegate, UITableViewDragDelegate, UITableViewDropDelegate>
@property(nonatomic, strong) NEConversationGroupManager *manager;
@property(nonatomic, weak, nullable) id<NEConversationGroupManagerDelegate> previousDelegate;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UIButton *createButton;
@end

@interface NEConversationGroupAddConversationController ()
@property(nonatomic, copy, nullable) dispatch_block_t partialFailure;
- (instancetype)initWithManager:(NEConversationGroupManager *)manager
                           group:(NEConversationGroupItem *)group
                     existingIds:(NSSet<NSString *> *)existingIds;
@end

@interface NEConversationGroupSettingController () <NEConversationGroupManagerDelegate>
- (instancetype)initWithManager:(NEConversationGroupManager *)manager group:(NEConversationGroupItem *)group;
@end

#pragma mark - Group management

static void NEConversationPresentGroupNameSheet(UIViewController *host, NEConversationGroupNameSheetController *sheet) {
  if (!host || !sheet) {
    return;
  }
  if ([NEAdaptiveDeviceGate adaptiveHostActive]) {
    [sheet presentAsColumnSheetInParent:host];
  } else {
    [host presentViewController:sheet animated:YES completion:nil];
  }
}

@implementation NEConversationGroupManageController

- (instancetype)initWithManager:(NEConversationGroupManager *)manager {
  self = [super initWithNibName:nil bundle:nil];
  if (self) _manager = manager;
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = NEGroupText(@"conversation_group_title", @"Conversation Groups");
  self.view.backgroundColor = NEGroupPageColor();
  self.navigationView.backgroundColor = NEGroupPageColor();
  self.navigationView.moreButton.hidden = YES;
  if (self.manager.delegate != self) self.previousDelegate = self.manager.delegate;
  self.manager.delegate = self;
  [self setupCreateButton];
  [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if (self.manager.delegate != self) self.previousDelegate = self.manager.delegate;
  self.manager.delegate = self;
  [self.tableView reloadData];
}

- (void)dealloc {
  if (self.manager.delegate == self) self.manager.delegate = self.previousDelegate;
}

- (void)setupCreateButton {
  self.createButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.createButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.createButton.backgroundColor = NEGroupPrimaryColor();
  [self.createButton setTitle:NEGroupText(@"conversation_group_create", @"New Group") forState:UIControlStateNormal];
  [self.createButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
  self.createButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
  self.createButton.layer.cornerRadius = 8;
  [self.createButton addTarget:self action:@selector(createGroupAction) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.createButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.createButton.widthAnchor constraintEqualToConstant:315],
    [self.createButton.heightAnchor constraintEqualToConstant:50],
    [self.createButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.createButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-60],
  ]];
}

- (void)setupTableView {
  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.backgroundColor = UIColor.clearColor;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  // 系统倾向用拖放完成排序：常驻编辑态会让系统重排控件占据尾部，
  // 把右侧设置按钮挤离边缘，因此改用 drag & drop，长按整行即可拖动。
  self.tableView.dragInteractionEnabled = YES;
  self.tableView.dragDelegate = self;
  self.tableView.dropDelegate = self;
  [self.tableView registerClass:[NEConversationGroupManageCell class] forCellReuseIdentifier:@"GroupManageCell"];
  UIView *commonHeader = [self sectionHeaderWithTitle:NEGroupText(@"conversation_group_common", @"Common")];
  commonHeader.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 42);
  self.tableView.tableHeaderView = commonHeader;
  [self.view addSubview:self.tableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.topAnchor constraintEqualToAnchor:self.navigationView.bottomAnchor],
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.createButton.topAnchor constant:-12],
  ]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return section == 0 ? self.manager.visibleGroups.count : self.manager.hiddenGroups.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 54; }
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return section == 0 ? CGFLOAT_MIN : 42;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (section == 0) return nil;
  return [self sectionHeaderWithTitle:NEGroupText(@"conversation_group_hidden", @"Hidden")];
}

- (UIView *)sectionHeaderWithTitle:(NSString *)title {
  UIView *header = [[UIView alloc] init];
  UILabel *label = [[UILabel alloc] init];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.text = title;
  label.textColor = UIColor.ne_greyText;
  label.font = [UIFont systemFontOfSize:13];
  [header addSubview:label];
  [NSLayoutConstraint activateConstraints:@[
    [label.leftAnchor constraintEqualToAnchor:header.leftAnchor constant:16],
    [label.bottomAnchor constraintEqualToAnchor:header.bottomAnchor constant:-8],
  ]];
  return header;
}

- (NEConversationGroupItem *)itemAtIndexPath:(NSIndexPath *)indexPath {
  NSArray *items = indexPath.section == 0 ? self.manager.visibleGroups : self.manager.hiddenGroups;
  if (indexPath.row < 0 || indexPath.row >= items.count) return nil;
  id value = items[indexPath.row];
  return [value isKindOfClass:[NEConversationGroupItem class]] ? value : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NEConversationGroupManageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupManageCell" forIndexPath:indexPath];
  NEConversationGroupItem *group = [self itemAtIndexPath:indexPath];
  [cell configure:group hidden:indexPath.section == 1 last:indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1];
  __weak typeof(self) weakSelf = self;
  cell.leftAction = ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || !group || group.kind == NEConversationGroupKindAll) return;
    [self.manager setGroup:group hidden:indexPath.section == 0];
  };
  cell.settingAction = ^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || group.kind != NEConversationGroupKindCustom) return;
    [self.navigationController pushViewController:[[NEConversationGroupSettingController alloc] initWithManager:self.manager group:group] animated:YES];
  };
  return cell;
}

- (NSArray<UIDragItem *> *)tableView:(UITableView *)tableView
       itemsForBeginningDragSession:(id<UIDragSession>)session
                        atIndexPath:(NSIndexPath *)indexPath {
  NEConversationGroupItem *item = [self itemAtIndexPath:indexPath];
  if (indexPath.section != 0 || !item || !item.canDrag) return @[];
  NSString *name = item.name ?: @"";
  NSItemProvider *provider = [[NSItemProvider alloc] initWithObject:name];
  provider.suggestedName = name;
  return @[ [[UIDragItem alloc] initWithItemProvider:provider] ];
}

- (UITableViewDropProposal *)tableView:(UITableView *)tableView
                   dropSessionDidUpdate:(id<UIDropSession>)session
               withDestinationIndexPath:(nullable NSIndexPath *)destinationIndexPath {
  if (!session.localDragSession) {
    return [[UITableViewDropProposal alloc] initWithDropOperation:UIDropOperationCancel];
  }
  if (destinationIndexPath && destinationIndexPath.section != 0) {
    return [[UITableViewDropProposal alloc] initWithDropOperation:UIDropOperationForbidden];
  }
  return [[UITableViewDropProposal alloc] initWithDropOperation:UIDropOperationMove
                                                         intent:UITableViewDropIntentInsertAtDestinationIndexPath];
}

- (void)tableView:(UITableView *)tableView
    performDropWithCoordinator:(id<UITableViewDropCoordinator>)coordinator {
  if (!coordinator.session.localDragSession) return;
  NSIndexPath *source = coordinator.items.firstObject.sourceIndexPath;
  if (!source || source.section != 0) return;
  NSInteger visibleCount = (NSInteger)self.manager.visibleGroups.count;
  NSIndexPath *destination = coordinator.destinationIndexPath;
  if (!destination) {
    destination = [NSIndexPath indexPathForRow:MAX(0, visibleCount - 1) inSection:0];
  }
  if (destination.section != 0) return;
  // 第一行固定是「全部消息」，拖放目标夹在 [1, 末尾]。
  NSInteger targetRow = MIN(MAX(destination.row, 1), MAX(1, visibleCount - 1));
  [self.manager moveVisibleGroupFromIndex:source.row toIndex:targetRow];
  [tableView reloadData];
}

- (void)createGroupAction {
  __weak typeof(self) weakSelf = self;
  if (NEGroupIsFunStyle()) {
    NEConversationGroupNameController *controller = [[NEConversationGroupNameController alloc]
      initWithCompletion:^(NSString *name, NEConversationGroupNameController *nameController) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self || !NEGroupCanPerformNetworkAction(nameController)) return;
        [self.manager createGroup:name completion:^(V2NIMConversationGroup *group, NSError *error) {
          if (error) NEGroupShowError(nameController, error);
          else [nameController.navigationController popViewControllerAnimated:YES];
        }];
      }];
    [self.navigationController pushViewController:controller animated:YES];
    return;
  }
  __block NEConversationGroupNameSheetController *sheet = nil;
  sheet = [[NEConversationGroupNameSheetController alloc]
    initWithTitle:NEGroupText(@"conversation_group_create", @"New Group")
    initialName:nil
    heightRatio:0.93
    completion:^(NSString *name) {
      __strong typeof(weakSelf) self = weakSelf;
      if (!self || !NEGroupCanPerformNetworkAction(sheet)) return;
      [self.manager createGroup:name completion:^(V2NIMConversationGroup *group, NSError *error) {
        if (error) NEGroupShowError(sheet, error);
        else [sheet closeSheetAnimated:YES];
      }];
    }];
  NEConversationPresentGroupNameSheet(self, sheet);
}



- (void)conversationGroupManagerDidReload {
  [self.tableView reloadData];
  if ([self.previousDelegate respondsToSelector:@selector(conversationGroupManagerDidReload)]) {
    [self.previousDelegate conversationGroupManagerDidReload];
  }
}
- (void)conversationGroupManagerSelectionDidChange {
  [self.tableView reloadData];
  if ([self.previousDelegate respondsToSelector:@selector(conversationGroupManagerSelectionDidChange)]) {
    [self.previousDelegate conversationGroupManagerSelectionDidChange];
  }
}
- (void)conversationGroupDidReload { [self conversationGroupManagerDidReload]; }
- (void)conversationGroupSelectionChanged { [self conversationGroupManagerSelectionDidChange]; }

@end

#pragma mark - Manage cell

@interface NEConversationGroupManageCell ()
@property(nonatomic, strong) UIButton *leftButton;
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UIButton *settingButton;
@property(nonatomic, strong) UIImageView *dragHandle;
@property(nonatomic, strong) UIStackView *accessoryStack;
@property(nonatomic, strong) UIView *divider;
@end

@implementation NEConversationGroupManageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) return nil;
  self.selectionStyle = UITableViewCellSelectionStyleNone;
  self.backgroundColor = UIColor.whiteColor;
  self.contentView.backgroundColor = UIColor.whiteColor;
  _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _nameLabel = [[UILabel alloc] init];
  _settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _dragHandle = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"line.3.horizontal"]];
  _divider = [[UIView alloc] init];
  // 右侧附件放进水平栈：隐藏的项不占位，因此「常用分组的三」与「隐藏分组的齿轮」
  // 始终落在同一条右边缘基线上。
  _accessoryStack = [[UIStackView alloc] initWithArrangedSubviews:@[ _settingButton, _dragHandle ]];
  _accessoryStack.axis = UILayoutConstraintAxisHorizontal;
  _accessoryStack.spacing = 12;
  _accessoryStack.alignment = UIStackViewAlignmentCenter;
  _accessoryStack.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView addSubview:_accessoryStack];
  for (UIView *view in @[_leftButton, _nameLabel, _divider]) {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:view];
  }
  _dragHandle.contentMode = UIViewContentModeCenter;
  _dragHandle.userInteractionEnabled = NO;
  _dragHandle.tintColor = UIColor.ne_greyText;
  _nameLabel.font = [UIFont systemFontOfSize:16];
  _nameLabel.textColor = UIColor.ne_darkText;
  _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  [_leftButton addTarget:self action:@selector(leftTap) forControlEvents:UIControlEventTouchUpInside];
  [_settingButton addTarget:self action:@selector(settingTap) forControlEvents:UIControlEventTouchUpInside];
  [NSLayoutConstraint activateConstraints:@[
    [_leftButton.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16],
    [_leftButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [_leftButton.widthAnchor constraintEqualToConstant:32],
    [_leftButton.heightAnchor constraintEqualToConstant:32],
    [_nameLabel.leftAnchor constraintEqualToAnchor:_leftButton.rightAnchor constant:8],
    [_nameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [_accessoryStack.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16],
    [_accessoryStack.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [_settingButton.widthAnchor constraintEqualToConstant:32],
    [_settingButton.heightAnchor constraintEqualToConstant:32],
    [_dragHandle.widthAnchor constraintEqualToConstant:24],
    [_dragHandle.heightAnchor constraintEqualToConstant:24],
    [_nameLabel.rightAnchor constraintLessThanOrEqualToAnchor:_accessoryStack.leftAnchor constant:-8],
    [_divider.leftAnchor constraintEqualToAnchor:_nameLabel.leftAnchor],
    [_divider.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [_divider.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [_divider.heightAnchor constraintEqualToConstant:0.5],
  ]];
  return self;
}

- (void)prepareForReuse {
  [super prepareForReuse];
  self.leftAction = nil;
  self.settingAction = nil;
}

- (void)configure:(NEConversationGroupItem *)group hidden:(BOOL)hidden last:(BOOL)last {
  self.nameLabel.text = group.name;
  NSString *leftImage = hidden ? @"conversation_group_hidden_add" : (group.kind == NEConversationGroupKindAll ? @"conversation_group_disable" : @"conversation_group_delete");
  [self.leftButton setImage:NEGroupImage(leftImage) forState:UIControlStateNormal];
  self.leftButton.enabled = hidden || group.kind != NEConversationGroupKindAll;
  [self.settingButton setImage:NEGroupImage(@"conversation_group_setting") forState:UIControlStateNormal];
  self.settingButton.hidden = group.kind != NEConversationGroupKindCustom;
  // 常用分组可拖动排序，用系统手柄图标提示；隐藏分组与「全部消息」不显示。
  self.dragHandle.hidden = hidden || !group.canDrag;
  self.divider.backgroundColor = NEGroupLineColor();
  self.divider.hidden = last;
}

- (void)leftTap { if (self.leftAction) self.leftAction(); }
- (void)settingTap { if (self.settingAction) self.settingAction(); }

@end

#pragma mark - Name sheet

@interface NEConversationGroupNameSheetController ()
@property(nonatomic, copy) NSString *sheetTitle;
@property(nonatomic, copy, nullable) NSString *initialName;
@property(nonatomic, copy) void (^completion)(NSString *name);
@property(nonatomic, assign) CGFloat heightRatio;
@property(nonatomic, strong) UIView *container;
@property(nonatomic, strong) UITextField *textField;
@property(nonatomic, strong) UILabel *countLabel;
@property(nonatomic, strong) UIButton *doneButton;
@end

@implementation NEConversationGroupNameSheetController

- (instancetype)initWithTitle:(NSString *)title
                  initialName:(NSString *)initialName
                  heightRatio:(CGFloat)heightRatio
                   completion:(void (^)(NSString *))completion {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _sheetTitle = [title copy];
    _initialName = [initialName copy];
    _completion = [completion copy];
    _heightRatio = heightRatio;
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
  }
  return self;
}

- (void)presentAsColumnSheetInParent:(UIViewController *)parent {
  if (!parent) {
    return;
  }
  self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
  self.view.accessibilityIdentifier = @"id.adaptive.columnOverlay";
  [parent addChildViewController:self];
  self.view.frame = parent.view.bounds;
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [parent.view addSubview:self.view];
  [self didMoveToParentViewController:parent];
  self.view.alpha = 0;
  [UIView animateWithDuration:0.2 animations:^{
    self.view.alpha = 1;
  }];
  [self notifyColumnPresentationChanged];
}

- (void)closeSheetAnimated:(BOOL)animated {
  if (!self.parentViewController) {
    [self dismissViewControllerAnimated:animated completion:nil];
    return;
  }
  void (^finish)(void) = ^{
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    [self notifyColumnPresentationChanged];
  };
  if (!animated) {
    finish();
    return;
  }
  [UIView animateWithDuration:0.2 animations:^{
    self.view.alpha = 0;
  } completion:^(__unused BOOL finished) {
    finish();
  }];
}

- (void)notifyColumnPresentationChanged {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"NEAdaptivePresentationDidChange" object:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.35];
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)];
  tap.cancelsTouchesInView = NO;
  [self.view addGestureRecognizer:tap];
  self.container = [[UIView alloc] init];
  self.container.translatesAutoresizingMaskIntoConstraints = NO;
  self.container.backgroundColor = NEGroupPageColor();
  self.container.layer.cornerRadius = 16;
  self.container.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
  [self.view addSubview:self.container];

  NEUnifiedBackButton *cancel = [[NEUnifiedBackButton alloc] initWithAccessibilityLabel:NEGroupText(@"cancel", @"Cancel")];
  cancel.accessibilityIdentifier = @"id.cancel";
  self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
  UILabel *titleLabel = [[UILabel alloc] init];
  self.textField = [[NESingleLineTextField alloc] init];
  self.countLabel = [[UILabel alloc] init];
  for (UIView *view in @[cancel, self.doneButton, titleLabel, self.textField, self.countLabel]) {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.container addSubview:view];
  }
  [cancel addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
  [self.doneButton setTitle:NEGroupText(@"confirm", @"OK") forState:UIControlStateNormal];
  self.doneButton.accessibilityIdentifier = @"id.sureButton";
  self.doneButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
  [self.doneButton addTarget:self action:@selector(doneAction) forControlEvents:UIControlEventTouchUpInside];
  titleLabel.text = self.sheetTitle;
  titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
  titleLabel.textColor = UIColor.ne_darkText;
  titleLabel.textAlignment = NSTextAlignmentCenter;
  self.textField.text = self.initialName;
  self.textField.placeholder = NEGroupText(@"conversation_group_name_placeholder", @"Enter group name");
  self.textField.delegate = self;
  self.textField.font = [UIFont systemFontOfSize:16];
  self.textField.tintColor = NEGroupPrimaryColor();
  self.textField.backgroundColor = UIColor.whiteColor;
  self.textField.layer.cornerRadius = 8;
  self.textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 1)];
  self.textField.leftViewMode = UITextFieldViewModeAlways;
  self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
  [self.textField addTarget:self action:@selector(textChanged) forControlEvents:UIControlEventEditingChanged];
  self.countLabel.textAlignment = NSTextAlignmentRight;
  self.countLabel.font = [UIFont systemFontOfSize:12];
  self.countLabel.textColor = UIColor.ne_lightText;

  [NSLayoutConstraint activateConstraints:@[
    [self.container.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.container.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.container.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.container.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:self.heightRatio],
    [cancel.leftAnchor constraintEqualToAnchor:self.container.leftAnchor constant:16],
    [cancel.topAnchor constraintEqualToAnchor:self.container.topAnchor constant:16],
    [cancel.widthAnchor constraintEqualToConstant:40],
    [cancel.heightAnchor constraintEqualToConstant:32],
    [self.doneButton.rightAnchor constraintEqualToAnchor:self.container.rightAnchor constant:-16],
    [self.doneButton.centerYAnchor constraintEqualToAnchor:cancel.centerYAnchor],
    [self.doneButton.widthAnchor constraintEqualToConstant:60],
    [self.doneButton.heightAnchor constraintEqualToConstant:32],
    [titleLabel.centerXAnchor constraintEqualToAnchor:self.container.centerXAnchor],
    [titleLabel.centerYAnchor constraintEqualToAnchor:cancel.centerYAnchor],
    [self.textField.topAnchor constraintEqualToAnchor:cancel.bottomAnchor constant:28],
    [self.textField.leftAnchor constraintEqualToAnchor:self.container.leftAnchor constant:16],
    [self.textField.rightAnchor constraintEqualToAnchor:self.container.rightAnchor constant:-16],
    [self.textField.heightAnchor constraintEqualToConstant:52],
    [self.countLabel.topAnchor constraintEqualToAnchor:self.textField.bottomAnchor constant:8],
    [self.countLabel.rightAnchor constraintEqualToAnchor:self.textField.rightAnchor],
  ]];
  [self updateState];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.textField becomeFirstResponder];
}

- (void)backgroundTap:(UITapGestureRecognizer *)tap {
  if (!CGRectContainsPoint(self.container.frame, [tap locationInView:self.view])) [self cancelAction];
}

- (void)cancelAction { [self closeSheetAnimated:YES]; }

- (void)doneAction {
  NSString *name = NEGroupSafeName(self.textField.text);
  if (name.length == 0) return;
  if (self.completion) self.completion(name);
}

- (void)textChanged {
  NSString *text = self.textField.text ?: @"";
  if (NEGroupCharacterCount(text) > NEConversationGroupNameMaxLength) {
    NEHandleInputLimitExceeded(self.view, NEConversationGroupNameMaxLength);
    self.textField.text = NEGroupPrefix(text, NEConversationGroupNameMaxLength);
  }
  [self updateState];
}

- (void)updateState {
  NSString *name = NEGroupSafeName(self.textField.text);
  self.countLabel.text = [NSString stringWithFormat:@"%lu/%ld", (unsigned long)NEGroupCharacterCount(self.textField.text), (long)NEConversationGroupNameMaxLength];
  self.doneButton.enabled = name.length > 0;
  UIColor *color = self.doneButton.enabled ? NEGroupPrimaryColor() : [NEGroupPrimaryColor() colorWithAlphaComponent:0.5];
  [self.doneButton setTitleColor:color forState:UIControlStateNormal];
}

@end

#pragma mark - Fun style name page

@interface NEConversationGroupNameController ()
@property(nonatomic, copy) void (^completion)(NSString *name, NEConversationGroupNameController *controller);
@property(nonatomic, strong) UITextField *textField;
@property(nonatomic, strong) UIButton *clearButton;
@property(nonatomic, strong) UILabel *countLabel;
@end

@implementation NEConversationGroupNameController

- (instancetype)initWithCompletion:(void (^)(NSString *, NEConversationGroupNameController *))completion {
  self = [super initWithNibName:nil bundle:nil];
  if (self) _completion = [completion copy];
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = NEGroupText(@"conversation_group_create", @"New Group");
  self.view.backgroundColor = NEGroupPageColor();
  self.navigationView.backgroundColor = NEGroupPageColor();
  [self.navigationView setMoreButtonTitle:NEGroupText(@"confirm", @"OK") color:NEGroupPrimaryColor()];
  [self.navigationView setMoreButtonWidth:60];
  [self.navigationView addMoreButtonTarget:self selector:@selector(doneAction)];

  UIView *container = [[UIView alloc] init];
  self.textField = [[NESingleLineTextField alloc] init];
  self.clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.countLabel = [[UILabel alloc] init];
  for (UIView *view in @[container, self.textField, self.clearButton, self.countLabel]) {
    view.translatesAutoresizingMaskIntoConstraints = NO;
  }
  container.backgroundColor = UIColor.whiteColor;
  [self.view addSubview:container];
  [container addSubview:self.textField];
  [container addSubview:self.clearButton];
  [container addSubview:self.countLabel];

  self.textField.placeholder = NEGroupText(@"conversation_group_name_placeholder", @"Enter group name");
  self.textField.font = [UIFont systemFontOfSize:20];
  self.textField.textColor = UIColor.ne_darkText;
  self.textField.tintColor = NEGroupPrimaryColor();
  self.textField.delegate = self;
  [self.textField addTarget:self action:@selector(textChanged) forControlEvents:UIControlEventEditingChanged];
  if (@available(iOS 13.0, *)) {
    [self.clearButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
  } else {
    [self.clearButton setTitle:@"x" forState:UIControlStateNormal];
    self.clearButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
  }
  self.clearButton.tintColor = UIColor.ne_lightText;
  [self.clearButton setTitleColor:UIColor.ne_lightText forState:UIControlStateNormal];
  [self.clearButton addTarget:self action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];
  self.countLabel.textAlignment = NSTextAlignmentRight;
  self.countLabel.font = [UIFont systemFontOfSize:14];
  self.countLabel.textColor = UIColor.ne_lightText;

  [NSLayoutConstraint activateConstraints:@[
    [container.topAnchor constraintEqualToAnchor:self.navigationView.bottomAnchor],
    [container.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [container.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [container.heightAnchor constraintEqualToConstant:132],
    [self.textField.topAnchor constraintEqualToAnchor:container.topAnchor],
    [self.textField.leftAnchor constraintEqualToAnchor:container.leftAnchor constant:16],
    [self.textField.rightAnchor constraintEqualToAnchor:self.clearButton.leftAnchor constant:-8],
    [self.textField.heightAnchor constraintEqualToConstant:82],
    [self.clearButton.rightAnchor constraintEqualToAnchor:container.rightAnchor constant:-16],
    [self.clearButton.centerYAnchor constraintEqualToAnchor:self.textField.centerYAnchor],
    [self.clearButton.widthAnchor constraintEqualToConstant:32],
    [self.clearButton.heightAnchor constraintEqualToConstant:32],
    [self.countLabel.topAnchor constraintEqualToAnchor:self.textField.bottomAnchor],
    [self.countLabel.leftAnchor constraintEqualToAnchor:container.leftAnchor constant:16],
    [self.countLabel.rightAnchor constraintEqualToAnchor:container.rightAnchor constant:-16],
    [self.countLabel.heightAnchor constraintEqualToConstant:24],
  ]];
  [self updateState];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.textField becomeFirstResponder];
}

- (void)doneAction {
  NSString *name = NEGroupSafeName(self.textField.text);
  if (name.length > 0 && self.completion) self.completion(name, self);
}

- (void)clearAction {
  self.textField.text = @"";
  [self updateState];
}

- (void)textChanged {
  NSString *text = self.textField.text ?: @"";
  if (NEGroupCharacterCount(text) > NEConversationGroupNameMaxLength) {
    NEHandleInputLimitExceeded(self.view, NEConversationGroupNameMaxLength);
    self.textField.text = NEGroupPrefix(text, NEConversationGroupNameMaxLength);
  }
  [self updateState];
}

- (void)updateState {
  NSUInteger length = NEGroupCharacterCount(self.textField.text);
  self.countLabel.text = [NSString stringWithFormat:@"%lu/%ld", (unsigned long)length, (long)NEConversationGroupNameMaxLength];
  self.clearButton.hidden = length == 0;
  self.navigationView.moreButton.enabled = NEGroupSafeName(self.textField.text).length > 0;
  [self.navigationView setMoreButtonTitle:NEGroupText(@"confirm", @"OK")
                                     color:self.navigationView.moreButton.enabled ? NEGroupPrimaryColor() : [NEGroupPrimaryColor() colorWithAlphaComponent:0.5]];
}

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
  NSString *text = textField.text ?: @"";
  if (NSMaxRange(range) > text.length) return NO;
  NSRange safeRange = [text rangeOfComposedCharacterSequencesForRange:range];
  if (!NSEqualRanges(safeRange, range)) return NO;
  NSString *updated = [text stringByReplacingCharactersInRange:range withString:string ?: @""];
  return NEGroupCharacterCount(updated) <= NEConversationGroupNameMaxLength;
}

@end

#pragma mark - Group settings

@interface NEConversationGroupSettingController ()
@property(nonatomic, strong) NEConversationGroupManager *manager;
@property(nonatomic, strong) NEConversationGroupItem *group;
@property(nonatomic, copy) NSArray<NEConversationListModel *> *members;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UILabel *memberTitle;
@property(nonatomic, strong) UILabel *groupNameDetail;
@property(nonatomic, strong) UIView *emptyView;
@property(nonatomic, assign) int64_t memberOffset;
@property(nonatomic, assign) BOOL memberFinished;
@property(nonatomic, assign) BOOL loadingMembers;
@property(nonatomic, assign) BOOL deletingGroup;
@property(nonatomic, assign) BOOL didReturnAfterDeletingGroup;
@end

@implementation NEConversationGroupSettingController

- (instancetype)initWithManager:(NEConversationGroupManager *)manager group:(NEConversationGroupItem *)group {
  self = [super initWithNibName:nil bundle:nil];
  if (self) { _manager = manager; _group = group; _members = @[]; }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = NEGroupText(@"conversation_group_setting_title", @"Group Settings");
  self.view.backgroundColor = NEGroupPageColor();
  self.navigationView.backgroundColor = NEGroupPageColor();
  [self.navigationView setMoreButtonTitle:NEGroupText(@"delete", @"Delete") color:NEGroupPrimaryColor()];
  [self.navigationView setMoreButtonWidth:60];
  [self.navigationView addMoreButtonTarget:self selector:@selector(deleteGroup)];
  self.manager.delegate = self;
  [self setupContent];
  [self reloadMembers];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.manager.delegate = self;
}

- (UIView *)actionRowWithTitle:(NSString *)title detail:(NSString *)detail image:(UIImage *)image action:(SEL)action disclosure:(BOOL)disclosure {
  UIControl *row = [[UIControl alloc] init];
  row.translatesAutoresizingMaskIntoConstraints = NO;
  row.backgroundColor = UIColor.whiteColor;
  [row addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
  UIImageView *icon = [[UIImageView alloc] initWithImage:image];
  UILabel *titleLabel = [[UILabel alloc] init];
  UILabel *detailLabel = [[UILabel alloc] init];
  UIImageView *arrow = [[UIImageView alloc] initWithImage:disclosure ? [UIImage systemImageNamed:@"chevron.right"] : nil];
  for (UIView *view in @[icon, titleLabel, detailLabel, arrow]) {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [row addSubview:view];
  }
  icon.hidden = image == nil;
  icon.contentMode = UIViewContentModeScaleAspectFit;
  titleLabel.text = title;
  titleLabel.font = [UIFont systemFontOfSize:16];
  titleLabel.textColor = UIColor.ne_darkText;
  detailLabel.text = detail;
  detailLabel.font = [UIFont systemFontOfSize:15];
  detailLabel.textColor = UIColor.ne_lightText;
  detailLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  [titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                              forAxis:UILayoutConstraintAxisHorizontal];
  [detailLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                               forAxis:UILayoutConstraintAxisHorizontal];
  if (disclosure && image == nil) self.groupNameDetail = detailLabel;
  arrow.tintColor = UIColor.ne_lightText;
  [NSLayoutConstraint activateConstraints:@[
    [icon.leftAnchor constraintEqualToAnchor:row.leftAnchor constant:24],
    [icon.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
    [icon.widthAnchor constraintEqualToConstant:image ? 36 : 0],
    [icon.heightAnchor constraintEqualToConstant:image ? 36 : 0],
    [titleLabel.leftAnchor constraintEqualToAnchor:image ? icon.rightAnchor : row.leftAnchor constant:image ? 24 : 24],
    [titleLabel.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
    [arrow.rightAnchor constraintEqualToAnchor:row.rightAnchor constant:-16],
    [arrow.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
    [arrow.widthAnchor constraintEqualToConstant:disclosure ? 8 : 0],
    [detailLabel.rightAnchor constraintEqualToAnchor:arrow.leftAnchor constant:disclosure ? -8 : 0],
    [detailLabel.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
    [titleLabel.rightAnchor constraintLessThanOrEqualToAnchor:detailLabel.leftAnchor constant:-12],
  ]];
  return row;
}

- (void)setupContent {
  UIView *nameRow = [self actionRowWithTitle:NEGroupText(@"conversation_group_name", @"Group Name") detail:self.group.name image:nil action:@selector(renameGroup) disclosure:YES];
  UIView *memberHeader = [[UIView alloc] init];
  memberHeader.translatesAutoresizingMaskIntoConstraints = NO;
  memberHeader.backgroundColor = UIColor.whiteColor;
  self.memberTitle = [[UILabel alloc] init];
  self.memberTitle.translatesAutoresizingMaskIntoConstraints = NO;
  self.memberTitle.font = [UIFont systemFontOfSize:15];
  self.memberTitle.textColor = UIColor.ne_greyText;
  [memberHeader addSubview:self.memberTitle];
  UIView *addRow = [self actionRowWithTitle:NEGroupText(@"conversation_group_add_member", @"Add Conversation")
                                     detail:nil
                                      image:NEGroupImage(NEGroupIsFunStyle() ? @"ic_conversation_group_set_add" : @"conversation_group_add_new")
                                     action:@selector(addMembers)
                                 disclosure:NO];
  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.backgroundColor = UIColor.clearColor;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"GroupMemberCell"];
  self.emptyView = [[UIView alloc] init];
  self.emptyView.translatesAutoresizingMaskIntoConstraints = NO;
  UIImageView *emptyImage = [[UIImageView alloc] initWithImage:NEGroupImage(NEGroupIsFunStyle() ? @"fun_user_empty" : @"user_empty")];
  UILabel *emptyLabel = [[UILabel alloc] init];
  emptyImage.translatesAutoresizingMaskIntoConstraints = NO;
  emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
  emptyLabel.text = NEGroupText(@"session_empty", @"No conversations");
  emptyLabel.textColor = UIColor.ne_lightText;
  emptyLabel.font = [UIFont systemFontOfSize:14];
  emptyLabel.textAlignment = NSTextAlignmentCenter;
  [self.emptyView addSubview:emptyImage];
  [self.emptyView addSubview:emptyLabel];
  for (UIView *view in @[nameRow, memberHeader, addRow, self.tableView, self.emptyView]) [self.view addSubview:view];
  [NSLayoutConstraint activateConstraints:@[
    [nameRow.topAnchor constraintEqualToAnchor:self.navigationView.bottomAnchor],
    [nameRow.leftAnchor constraintEqualToAnchor:self.view.leftAnchor], [nameRow.rightAnchor constraintEqualToAnchor:self.view.rightAnchor], [nameRow.heightAnchor constraintEqualToConstant:52],
    [memberHeader.topAnchor constraintEqualToAnchor:nameRow.bottomAnchor constant:6],
    [memberHeader.leftAnchor constraintEqualToAnchor:self.view.leftAnchor], [memberHeader.rightAnchor constraintEqualToAnchor:self.view.rightAnchor], [memberHeader.heightAnchor constraintEqualToConstant:48],
    [self.memberTitle.leftAnchor constraintEqualToAnchor:memberHeader.leftAnchor constant:24], [self.memberTitle.bottomAnchor constraintEqualToAnchor:memberHeader.bottomAnchor constant:-8],
    [addRow.topAnchor constraintEqualToAnchor:memberHeader.bottomAnchor], [addRow.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [addRow.rightAnchor constraintEqualToAnchor:self.view.rightAnchor], [addRow.heightAnchor constraintEqualToConstant:52],
    [self.tableView.topAnchor constraintEqualToAnchor:addRow.bottomAnchor], [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor], [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor], [self.emptyView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor], [self.emptyView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [emptyImage.topAnchor constraintEqualToAnchor:self.emptyView.topAnchor constant:60], [emptyImage.centerXAnchor constraintEqualToAnchor:self.emptyView.centerXAnchor],
    [emptyImage.widthAnchor constraintEqualToConstant:122], [emptyImage.heightAnchor constraintEqualToConstant:91],
    [emptyLabel.topAnchor constraintEqualToAnchor:emptyImage.bottomAnchor constant:8],
    [emptyLabel.leftAnchor constraintEqualToAnchor:self.emptyView.leftAnchor constant:16],
    [emptyLabel.rightAnchor constraintEqualToAnchor:self.emptyView.rightAnchor constant:-16],
  ]];
  [self updateMemberCount];
}

- (void)reloadMembers {
  self.memberOffset = 0;
  self.memberFinished = NO;
  self.members = @[];
  [self.tableView reloadData];
  [self updateMemberCount];
  [self loadMoreMembers];
}

- (void)loadMoreMembers {
  if (self.memberFinished || self.loadingMembers) return;
  self.loadingMembers = YES;
  __weak typeof(self) weakSelf = self;
  [self.manager loadConversationsForGroup:self.group
                                   offset:self.memberOffset
                                    limit:100
                               completion:^(NSArray<NEConversationListModel *> *items, int64_t nextOffset, BOOL finished, NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    self.loadingMembers = NO;
    self.memberOffset = nextOffset;
    self.memberFinished = finished;
    NSMutableArray *safe = [self.members mutableCopy] ?: [NSMutableArray array];
    for (id value in items ?: @[]) if ([value isKindOfClass:[NEConversationListModel class]]) [safe addObject:value];
    self.members = safe;
    [self.tableView reloadData];
    [self updateMemberCount];
    NEGroupShowError(self, error);
  }];
}

- (void)updateMemberCount {
  self.memberTitle.text = [NSString stringWithFormat:NEGroupText(@"conversation_group_members", @"Conversation List (%ld)"), (long)self.members.count];
  self.emptyView.hidden = self.members.count > 0;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (scrollView == self.tableView &&
      scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height - 80) {
    [self loadMoreMembers];
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.members.count; }
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 64; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupMemberCell" forIndexPath:indexPath];
  for (UIView *view in [cell.contentView.subviews copy]) [view removeFromSuperview];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.contentView.backgroundColor = UIColor.whiteColor;
  if (indexPath.row < 0 || indexPath.row >= self.members.count) return cell;
  id value = self.members[indexPath.row];
  if (![value isKindOfClass:[NEConversationListModel class]]) return cell;
  NEConversationListModel *model = value;
  NEUserHeaderView *avatar = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
  UILabel *name = [[UILabel alloc] init];
  UIButton *remove = [UIButton buttonWithType:UIButtonTypeCustom];
  UIView *line = [[UIView alloc] init];
  for (UIView *view in @[avatar, name, remove, line]) { view.translatesAutoresizingMaskIntoConstraints = NO; [cell.contentView addSubview:view]; }
  avatar.layer.cornerRadius = NEGroupIsFunStyle() ? 4 : 18;
  avatar.clipsToBounds = YES;
  NSString *displayName = [model.name isKindOfClass:[NSString class]] ? model.name : model.conversationId;
  [avatar configHeadData:[model.avatar isKindOfClass:[NSString class]] ? model.avatar : nil name:NEGroupConversationShortName(model) uid:model.conversationId ?: @""];
  name.text = displayName;
  name.font = [UIFont systemFontOfSize:15];
  name.textColor = UIColor.ne_darkText;
  name.lineBreakMode = NSLineBreakByTruncatingTail;
  [name setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
  [remove setTitle:NEGroupText(@"remove", @"Remove") forState:UIControlStateNormal];
  [remove setTitleColor:NEGroupPrimaryColor() forState:UIControlStateNormal];
  remove.titleLabel.font = [UIFont systemFontOfSize:14];
  [remove setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
  remove.layer.cornerRadius = 4;
  remove.layer.borderWidth = 1;
  remove.layer.borderColor = NEGroupPrimaryColor().CGColor;
  remove.tag = indexPath.row;
  [remove addTarget:self action:@selector(removeMember:) forControlEvents:UIControlEventTouchUpInside];
  line.backgroundColor = NEGroupLineColor();
  line.hidden = indexPath.row == self.members.count - 1;
  [NSLayoutConstraint activateConstraints:@[
    [avatar.leftAnchor constraintEqualToAnchor:cell.contentView.leftAnchor constant:24], [avatar.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
    [avatar.widthAnchor constraintEqualToConstant:36], [avatar.heightAnchor constraintEqualToConstant:36],
    [name.leftAnchor constraintEqualToAnchor:avatar.rightAnchor constant:10], [name.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
    [remove.rightAnchor constraintEqualToAnchor:cell.contentView.rightAnchor constant:-24], [remove.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
    [remove.widthAnchor constraintEqualToConstant:64],
    [name.rightAnchor constraintEqualToAnchor:remove.leftAnchor constant:-30],
    [line.leftAnchor constraintEqualToAnchor:name.leftAnchor], [line.rightAnchor constraintEqualToAnchor:cell.contentView.rightAnchor],
    [line.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor], [line.heightAnchor constraintEqualToConstant:1],
  ]];
  return cell;
}

- (void)removeMember:(UIButton *)sender {
  if (!NEGroupCanPerformNetworkAction(self)) return;
  if (sender.tag < 0 || sender.tag >= self.members.count) return;
  id value = self.members[sender.tag];
  if (![value isKindOfClass:[NEConversationListModel class]]) return;
  NEConversationListModel *model = value;
  if (![model.conversationId isKindOfClass:[NSString class]] || model.conversationId.length == 0) return;
  __weak typeof(self) weakSelf = self;
  [self.manager removeConversationIds:@[model.conversationId] fromGroup:self.group completion:^(NSArray *results, NSError *error) {
    NSError *operationError = nil;
    for (id value in [results isKindOfClass:[NSArray class]] ? results : @[]) {
      if (!NEGroupOperationSucceeded(value)) {
        operationError = NEGroupOperationError(value);
        break;
      }
    }
    if (error || operationError) {
      NEGroupShowError(weakSelf, error ?: operationError);
      return;
    }
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    NSMutableArray *next = [self.members mutableCopy] ?: [NSMutableArray array];
    NSIndexSet *indexes = [next indexesOfObjectsPassingTest:^BOOL(NEConversationListModel *item, NSUInteger idx, BOOL *stop) {
      return [item.conversationId isEqualToString:model.conversationId];
    }];
    [next removeObjectsAtIndexes:indexes];
    self.members = next;
    [self.tableView reloadData];
    [self updateMemberCount];
  }];
}

- (void)addMembers {
  if (!NEGroupCanPerformNetworkAction(self)) return;
  __weak typeof(self) weakSelf = self;
  [self.manager loadAllConversationIdsForGroup:self.group completion:^(NSSet<NSString *> *ids, NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    if (error) {
      NEGroupShowError(self, error);
      return;
    }
    NEConversationGroupAddConversationController *controller = [[NEConversationGroupAddConversationController alloc]
      initWithManager:self.manager
                group:self.group
          existingIds:ids ?: [NSSet set]];
    controller.complete = ^{ [weakSelf reloadMembers]; };
    controller.partialFailure = ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self) return;
      NEGroupShowError(self, [NSError errorWithDomain:@"NEConversationUIKitOC.ConversationGroup"
                                                 code:414
                                             userInfo:@{NSLocalizedDescriptionKey: NEGroupText(@"conversation_group_add_partial_failed", @"Some conversations failed to add")}]);
    };
    [self.navigationController pushViewController:controller animated:YES];
  }];
}

- (void)renameGroup {
  if (!NEGroupCanPerformNetworkAction(self)) return;
  __weak typeof(self) weakSelf = self;
  __block NEConversationGroupNameSheetController *sheet = nil;
  sheet = [[NEConversationGroupNameSheetController alloc]
    initWithTitle:NEGroupText(@"conversation_group_edit_name", @"Edit Group Name")
    initialName:self.group.name
    heightRatio:0.9
    completion:^(NSString *name) {
      __strong typeof(weakSelf) self = weakSelf;
      if (!self || !NEGroupCanPerformNetworkAction(sheet)) return;
      [self.manager renameGroup:self.group name:name completion:^(NSError *error) {
        if (error) NEGroupShowError(sheet, error);
        else { self.group.name = name; self.groupNameDetail.text = name; [sheet closeSheetAnimated:YES]; }
      }];
    }];
  NEConversationPresentGroupNameSheet(self, sheet);
}

- (void)deleteGroup {
  if (!NEGroupCanPerformNetworkAction(self)) return;
  __weak typeof(self) weakSelf = self;
  [self showAlert:NEGroupText(@"conversation_group_delete_title", @"Delete group?")
            message:NEGroupText(@"conversation_group_delete_message", @"Conversations in this group will not be deleted.")
           sureText:NEGroupText(@"delete", @"Delete")
         cancelText:NEGroupText(@"cancel", @"Cancel")
      sureTextColor:NEGroupIsFunStyle() ? NEGroupPrimaryColor() : UIColor.ne_redText
    cancelTextColor:nil
           sureBack:^{
    __strong typeof(weakSelf) self = weakSelf;
    if (!self || !NEGroupCanPerformNetworkAction(self)) return;
    self.deletingGroup = YES;
    self.didReturnAfterDeletingGroup = NO;
    [self.manager deleteGroup:self.group completion:^(NSError *error) {
      if (error) {
        self.deletingGroup = NO;
        NEGroupShowError(self, error);
      } else {
        [self returnToGroupManagePageIfNeeded];
      }
    }];
  }
         cancelBack:nil];
}

- (void)conversationGroupManagerDidReload {
  NEConversationGroupItem *latest = nil;
  for (NEConversationGroupItem *item in self.manager.groups) {
    if ([item.groupId isEqualToString:self.group.groupId]) {
      latest = item;
      break;
    }
  }
  if (!latest) {
    if (self.didReturnAfterDeletingGroup) return;
    if (self.deletingGroup) {
      [self returnToGroupManagePageIfNeeded];
      return;
    }
    NEGroupShowError(self, [NSError errorWithDomain:@"NEConversationUIKitOC.ConversationGroup"
                                               code:116404
                                           userInfo:@{NSLocalizedDescriptionKey: NEGroupText(@"conversation_group_not_exist", @"Conversation group does not exist")}]);
    [self.navigationController popViewControllerAnimated:YES];
    return;
  }
  self.group = latest;
  [self.tableView reloadData];
}
- (void)conversationGroupManagerSelectionDidChange {}
- (void)conversationGroupDidReload { [self conversationGroupManagerDidReload]; }
- (void)conversationGroupSelectionChanged { [self conversationGroupManagerSelectionDidChange]; }

- (void)returnToGroupManagePageIfNeeded {
  if (self.didReturnAfterDeletingGroup) return;
  self.didReturnAfterDeletingGroup = YES;
  self.deletingGroup = NO;
  UINavigationController *navigationController = self.navigationController;
  if (!navigationController) return;
  for (UIViewController *controller in navigationController.viewControllers) {
    if ([controller isKindOfClass:[NEConversationGroupManageController class]]) {
      [navigationController popToViewController:controller animated:YES];
      return;
    }
  }
  [navigationController popViewControllerAnimated:YES];
}

@end

#pragma mark - Conversation selection

@interface NEConversationGroupAddConversationController ()
@property(nonatomic, strong) NEConversationGroupManager *manager;
@property(nonatomic, strong) NEConversationGroupItem *group;
@property(nonatomic, copy) NSArray<NEConversationListModel *> *allItems;
@property(nonatomic, copy) NSArray<NEConversationListModel *> *items;
@property(nonatomic, strong) NSMutableSet<NSString *> *selectedIds;
@property(nonatomic, copy) NSSet<NSString *> *existingIds;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) UISearchBar *searchBar;
@property(nonatomic, strong) NEEmptyDataView *emptyView;
@property(nonatomic, copy) NSString *keyword;
@property(nonatomic, assign) int64_t offset;
@property(nonatomic, assign) BOOL finished;
@property(nonatomic, assign) BOOL loading;
@end

@implementation NEConversationGroupAddConversationController

- (instancetype)initWithManager:(NEConversationGroupManager *)manager group:(NEConversationGroupItem *)group existingIds:(NSSet<NSString *> *)existingIds {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _manager = manager; _group = group; _selectedIds = [NSMutableSet set];
    NSMutableSet *safeExistingIds = [NSMutableSet set];
    for (id value in [existingIds isKindOfClass:[NSSet class]] ? existingIds : [NSSet set]) {
      if ([value isKindOfClass:[NSString class]] && [value length] > 0) [safeExistingIds addObject:value];
    }
    _existingIds = safeExistingIds;
    _allItems = @[]; _items = @[]; _keyword = @""; _finished = NO;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = NEGroupPageColor();
  self.navigationView.backgroundColor = NEGroupPageColor();
  self.navigationView.moreButton.hidden = NO;
  [self.navigationView setMoreButtonTitle:NEGroupText(@"confirm", @"OK") color:[NEGroupPrimaryColor() colorWithAlphaComponent:0.5]];
  [self.navigationView setMoreButtonWidth:60];
  [self.navigationView addMoreButtonTarget:self selector:@selector(doneAction)];
  self.searchBar = [[UISearchBar alloc] init];
  self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.searchBar.placeholder = NEGroupText(@"conversation_group_search_hint", @"Please enter the conversation you want to search");
  self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
  self.searchBar.delegate = self;
  self.searchBar.tintColor = NEGroupPrimaryColor();
  self.searchBar.barTintColor = UIColor.whiteColor;
  self.searchBar.backgroundColor = UIColor.whiteColor;
  self.searchBar.backgroundImage = [UIImage new];
  if (@available(iOS 13.0, *)) {
    self.searchBar.searchTextField.backgroundColor = UIColor.whiteColor;
  }
  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.backgroundColor = UIColor.whiteColor;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"GroupSelectionCell"];
  self.emptyView = [[NEEmptyDataView alloc] initWithImageName:(NEGroupIsFunStyle() ? @"fun_user_empty" : @"user_empty")
                                                    content:NEGroupText(@"session_empty", @"No conversations")
                                                      frame:CGRectZero];
  self.emptyView.translatesAutoresizingMaskIntoConstraints = NO;
  self.emptyView.hidden = YES;
  self.emptyView.userInteractionEnabled = NO;
  [self.view addSubview:self.searchBar]; [self.view addSubview:self.tableView]; [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchBar.topAnchor constraintEqualToAnchor:self.navigationView.bottomAnchor],
    [self.searchBar.leftAnchor constraintEqualToAnchor:self.view.leftAnchor], [self.searchBar.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.searchBar.heightAnchor constraintEqualToConstant:52],
    [self.tableView.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor], [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor], [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor], [self.emptyView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor], [self.emptyView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
  ]];
  [self updateTitle];
  [self loadMore];
}

- (void)loadMore {
  if (self.loading || self.finished) return;
  self.loading = YES;
  int64_t requestOffset = self.offset;
  __weak typeof(self) weakSelf = self;
  [[ConversationRepo shared] getConversationList:requestOffset limit:100 completion:^(NSArray<V2NIMConversation *> *conversations, NSNumber *nextOffset, NSNumber *finished, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      __strong typeof(weakSelf) self = weakSelf;
      if (!self) return;
      self.loading = NO;
      if (error) {
        NEGroupShowError(self, error);
        [self refreshEmpty];
        return;
      }
      NSMutableArray *next = [self.allItems mutableCopy] ?: [NSMutableArray array];
      NSMutableSet *loadedIds = [NSMutableSet set];
      for (NEConversationListModel *model in next) if (model.conversationId.length > 0) [loadedIds addObject:model.conversationId];
      for (id value in [conversations isKindOfClass:[NSArray class]] ? conversations : @[]) {
        if (![value isKindOfClass:[V2NIMConversation class]]) continue;
        V2NIMConversation *conversation = value;
        if (![conversation.conversationId isKindOfClass:[NSString class]] || conversation.conversationId.length == 0 ||
            [self.existingIds containsObject:conversation.conversationId] || [loadedIds containsObject:conversation.conversationId]) continue;
        [loadedIds addObject:conversation.conversationId];
        [next addObject:[NEConversationListModel modelWithCloudConversation:conversation]];
      }
      self.allItems = next;
      int64_t resolvedOffset = [nextOffset isKindOfClass:[NSNumber class]] ? nextOffset.longLongValue : requestOffset;
      self.offset = resolvedOffset;
      self.finished = ([finished isKindOfClass:[NSNumber class]] ? finished.boolValue : YES) || resolvedOffset == requestOffset;
      [self applySearch];
      if (self.keyword.length == 0 && !self.finished && next.count < 100) [self loadMore];
    });
  }];
}

- (void)reloadCandidates {
  [self.selectedIds removeAllObjects];
  self.allItems = @[];
  self.items = @[];
  self.offset = 0;
  self.finished = NO;
  self.loading = NO;
  [self updateTitle];
  [self.tableView reloadData];
  [self refreshEmpty];
  [self loadMore];
}

- (void)applySearch {
  if (self.keyword.length == 0) self.items = self.allItems;
  else self.items = [self.allItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id value, NSDictionary *bindings) {
    if (![value isKindOfClass:[NEConversationListModel class]]) return NO;
    NSString *name = [(NEConversationListModel *)value name];
    return [name isKindOfClass:[NSString class]] && [name rangeOfString:self.keyword options:NSCaseInsensitiveSearch].location != NSNotFound;
  }]];
  [self.tableView reloadData];
  [self refreshEmpty];
}

- (void)refreshEmpty {
  self.emptyView.hidden = self.items.count > 0 || self.loading;
}

- (void)updateTitle {
  self.title = [NSString stringWithFormat:NEGroupText(@"conversation_group_add_title", @"Add Conversations(%ld/%ld)"), (long)self.selectedIds.count, (long)100];
  BOOL enabled = self.selectedIds.count > 0;
  [self.navigationView setMoreButtonTitle:NEGroupText(@"confirm", @"OK")
                                     color:enabled ? NEGroupPrimaryColor() : [NEGroupPrimaryColor() colorWithAlphaComponent:0.5]];
  self.navigationView.moreButton.enabled = enabled;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.items.count; }
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return NEGroupIsFunStyle() ? 72 : 62; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupSelectionCell" forIndexPath:indexPath];
  for (UIView *view in [cell.contentView.subviews copy]) [view removeFromSuperview];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  if (indexPath.row < 0 || indexPath.row >= self.items.count) return cell;
  id value = self.items[indexPath.row];
  if (![value isKindOfClass:[NEConversationListModel class]]) return cell;
  NEConversationListModel *model = value;
  NSString *checkImageName = [self.selectedIds containsObject:model.conversationId]
      ? (NEGroupIsFunStyle() ? @"fun_select" : @"select")
      : @"unselect";
  UIImageView *check = [[UIImageView alloc] initWithImage:NEGroupImage(checkImageName)];
  check.contentMode = UIViewContentModeScaleAspectFit;
  NEUserHeaderView *avatar = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
  UILabel *name = [[UILabel alloc] init];
  UIView *line = [[UIView alloc] init];
  for (UIView *view in @[check, avatar, name, line]) { view.translatesAutoresizingMaskIntoConstraints = NO; [cell.contentView addSubview:view]; }
  avatar.layer.cornerRadius = NEGroupIsFunStyle() ? 4 : 24; avatar.clipsToBounds = YES;
  NSString *displayName = [model.name isKindOfClass:[NSString class]] ? model.name : model.conversationId;
  [avatar configHeadData:[model.avatar isKindOfClass:[NSString class]] ? model.avatar : nil name:NEGroupConversationShortName(model) uid:model.conversationId ?: @""];
  name.font = [UIFont systemFontOfSize:16]; name.textColor = UIColor.ne_darkText;
  if (self.keyword.length > 0) {
    NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:displayName ?: @""];
    NSRange range = [(displayName ?: @"") rangeOfString:self.keyword options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound) [attributed addAttribute:NSForegroundColorAttributeName value:NEGroupPrimaryColor() range:range];
    name.attributedText = attributed;
  } else {
    name.text = displayName;
  }
  line.backgroundColor = NEGroupAddConversationLineColor();
  [NSLayoutConstraint activateConstraints:@[
    [check.leftAnchor constraintEqualToAnchor:cell.contentView.leftAnchor constant:16], [check.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
    [check.widthAnchor constraintEqualToConstant:(NEGroupIsFunStyle() ? 22 : 18)],
    [check.heightAnchor constraintEqualToConstant:(NEGroupIsFunStyle() ? 22 : 18)],
    [avatar.leftAnchor constraintEqualToAnchor:check.rightAnchor constant:12], [avatar.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
    [avatar.widthAnchor constraintEqualToConstant:48], [avatar.heightAnchor constraintEqualToConstant:48],
    [name.leftAnchor constraintEqualToAnchor:avatar.rightAnchor constant:12], [name.rightAnchor constraintEqualToAnchor:cell.contentView.rightAnchor constant:-16],
    [name.centerYAnchor constraintEqualToAnchor:avatar.centerYAnchor],
    [line.leftAnchor constraintEqualToAnchor:name.leftAnchor], [line.rightAnchor constraintEqualToAnchor:cell.contentView.rightAnchor],
    [line.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor], [line.heightAnchor constraintEqualToConstant:0.5],
  ]];
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row < 0 || indexPath.row >= self.items.count) return;
  id value = self.items[indexPath.row];
  if (![value isKindOfClass:[NEConversationListModel class]]) return;
  NSString *conversationId = [(NEConversationListModel *)value conversationId];
  if (![conversationId isKindOfClass:[NSString class]] || conversationId.length == 0) return;
  if ([self.selectedIds containsObject:conversationId]) [self.selectedIds removeObject:conversationId];
  else if (self.existingIds.count + self.selectedIds.count < 100) [self.selectedIds addObject:conversationId];
  else {
    NEGroupShowError(self, [NSError errorWithDomain:@"NEConversationUIKitOC.ConversationGroup"
                                               code:116437
                                           userInfo:@{NSLocalizedDescriptionKey: NEGroupText(@"conversation_group_members_limit", @"Group conversation limit reached")}]);
    return;
  }
  [self updateTitle];
  [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
  self.keyword = [searchText isKindOfClass:[NSString class]] ? searchText : @"";
  [self applySearch];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (self.keyword.length == 0 && !self.finished && !self.loading &&
      scrollView.contentOffset.y + scrollView.bounds.size.height > scrollView.contentSize.height - 80) {
    [self loadMore];
  }
}

- (void)cancelAction { [self.navigationController popViewControllerAnimated:YES]; }

- (void)doneAction {
  if (self.selectedIds.count == 0) return;
  if (!NEGroupCanPerformNetworkAction(self)) return;
  __weak typeof(self) weakSelf = self;
  NSUInteger requestedCount = self.selectedIds.count;
  [self.manager addConversationIds:self.selectedIds.allObjects toGroup:self.group completion:^(NSArray *results, NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (error) {
      NEGroupShowError(self, error);
      return;
    }
    NSMutableArray *failedResults = [NSMutableArray array];
    for (id value in [results isKindOfClass:[NSArray class]] ? results : @[]) {
      if (!NEGroupOperationSucceeded(value)) [failedResults addObject:value];
    }
    if (requestedCount > 0 && failedResults.count >= requestedCount) {
      NSError *operationError = NEGroupOperationError(failedResults.firstObject);
      NEGroupShowError(self, operationError ?: [NSError errorWithDomain:@"NEConversationUIKitOC.ConversationGroup"
                                                                    code:414
                                                                userInfo:@{NSLocalizedDescriptionKey: NEGroupText(@"failed_operation", @"Operation failed")}]);
      return;
    }
  if (self.complete) self.complete();
    BOOL hasPartialFailure = failedResults.count > 0;
    [self.navigationController popViewControllerAnimated:YES];
    if (hasPartialFailure && self.partialFailure) self.partialFailure();
  }];
}

@end
