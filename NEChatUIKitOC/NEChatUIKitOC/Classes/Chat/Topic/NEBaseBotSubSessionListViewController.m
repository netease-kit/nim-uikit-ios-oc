// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEBaseBotSubSessionListViewController.h"

#import "P2PChatViewModel.h"
#import "NEBaseUserSettingViewController.h"
#import "NEChatUIConstant.h"
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NEChatKit.h>

typedef NS_ENUM(NSInteger, NEBotSubSessionEmptyState) {
  NEBotSubSessionEmptyStateNone,
  NEBotSubSessionEmptyStateNoTopic,
  NEBotSubSessionEmptyStateNoSearchResult,
  NEBotSubSessionEmptyStateLoadFailed,
};

static UIButton *NEBotDialogButton(NSString *title, UIColor *titleColor,
                                   UIColor *backgroundColor, id target, SEL action) {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  button.translatesAutoresizingMaskIntoConstraints = NO;
  [button setTitle:title forState:UIControlStateNormal];
  [button setTitleColor:titleColor forState:UIControlStateNormal];
  button.titleLabel.font = [UIFont systemFontOfSize:16];
  button.backgroundColor = backgroundColor;
  button.layer.cornerRadius = 8;
  [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
  return button;
}

static BOOL NEBotStringFitsComposedCharacterLimit(NSString *value, NSUInteger limit) {
  __block NSUInteger count = 0;
  [value enumerateSubstringsInRange:NSMakeRange(0, value.length)
                           options:NSStringEnumerationByComposedCharacterSequences
                        usingBlock:^(NSString *substring, NSRange substringRange,
                                     NSRange enclosingRange, BOOL *stop) {
    count += 1;
    if (count > limit) {
      *stop = YES;
    }
  }];
  return count <= limit;
}

@interface BotSubSessionListCell ()
@property(nonatomic, strong) NSLayoutConstraint *timeWidth;
@property(nonatomic, strong) UIView *iconContainerView;
@property(nonatomic, strong) UIImageView *iconImageView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *summaryLabel;
@property(nonatomic, strong) UILabel *timeLabel;
@property(nonatomic, strong) UIView *unreadDot;
@property(nonatomic, strong) UIView *dividerLine;
@end

@implementation BotSubSessionListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  self.selectionStyle = UITableViewCellSelectionStyleNone;
  self.backgroundColor = UIColor.whiteColor;

  self.iconContainerView = [[UIView alloc] init];
  self.iconContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.iconContainerView.clipsToBounds = NO;
  self.iconImageView = [[UIImageView alloc] initWithImage:chatLoadImage(@"bot_sub_session_icon")];
  self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
  self.titleLabel.textColor = UIColor.ne_darkText;
  self.titleLabel.numberOfLines = 1;
  self.summaryLabel = [[UILabel alloc] init];
  self.summaryLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.summaryLabel.font = [UIFont systemFontOfSize:14];
  self.summaryLabel.textColor = UIColor.ne_greyText;
  self.summaryLabel.numberOfLines = 1;
  self.timeLabel = [[UILabel alloc] init];
  self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.timeLabel.font = [UIFont systemFontOfSize:12];
  self.timeLabel.textColor = UIColor.lightGrayColor;
  self.timeLabel.textAlignment = NSTextAlignmentRight;
  self.unreadDot = [[UIView alloc] init];
  self.unreadDot.translatesAutoresizingMaskIntoConstraints = NO;
  self.unreadDot.backgroundColor = UIColor.systemRedColor;
  self.unreadDot.layer.cornerRadius = 4;
  self.dividerLine = [[UIView alloc] init];
  self.dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
  self.dividerLine.hidden = YES;

  UIStackView *textStack = [[UIStackView alloc] initWithArrangedSubviews:@[
    self.titleLabel, self.summaryLabel
  ]];
  textStack.translatesAutoresizingMaskIntoConstraints = NO;
  textStack.axis = UILayoutConstraintAxisVertical;
  textStack.spacing = 6;

  [self.contentView addSubview:self.iconContainerView];
  [self.iconContainerView addSubview:self.iconImageView];
  [self.iconContainerView addSubview:self.unreadDot];
  [self.contentView addSubview:textStack];
  [self.contentView addSubview:self.timeLabel];
  [self.contentView addSubview:self.dividerLine];
  self.timeWidth = [self.timeLabel.widthAnchor constraintEqualToConstant:0];
  self.timeWidth.active = YES;

  [NSLayoutConstraint activateConstraints:@[
    [self.iconContainerView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16],
    [self.iconContainerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.iconContainerView.widthAnchor constraintEqualToConstant:42],
    [self.iconContainerView.heightAnchor constraintEqualToConstant:42],
    [self.iconImageView.leftAnchor constraintEqualToAnchor:self.iconContainerView.leftAnchor],
    [self.iconImageView.topAnchor constraintEqualToAnchor:self.iconContainerView.topAnchor],
    [self.iconImageView.widthAnchor constraintEqualToConstant:42],
    [self.iconImageView.heightAnchor constraintEqualToConstant:42],
    [textStack.leftAnchor constraintEqualToAnchor:self.iconContainerView.rightAnchor constant:12],
    [textStack.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [textStack.rightAnchor constraintEqualToAnchor:self.timeLabel.leftAnchor constant:-12],
    [self.timeLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:17],
    [self.timeLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16],
    [self.unreadDot.centerXAnchor constraintEqualToAnchor:self.iconContainerView.rightAnchor constant:-6],
    [self.unreadDot.centerYAnchor constraintEqualToAnchor:self.iconContainerView.topAnchor constant:6],
    [self.unreadDot.widthAnchor constraintEqualToConstant:8],
    [self.unreadDot.heightAnchor constraintEqualToConstant:8],
    [self.dividerLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:70],
    [self.dividerLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.dividerLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.dividerLine.heightAnchor constraintEqualToConstant:0.5],
  ]];
}

- (void)applyStyleWithBackgroundColor:(UIColor *)backgroundColor
                         showsDivider:(BOOL)showsDivider
                          dividerColor:(UIColor *)dividerColor {
  self.backgroundColor = backgroundColor;
  self.contentView.backgroundColor = backgroundColor;
  self.dividerLine.backgroundColor = dividerColor;
  self.dividerLine.hidden = !showsDivider;
}

- (void)configureWithItem:(BotSubSessionItem *)item
              sessionName:(NSString *)sessionName
                  keyword:(NSString *)keyword
           highlightColor:(UIColor *)highlightColor {
  NSString *title = [item.topic.topicName ?: @"" stringByTrimmingCharactersInSet:
                     NSCharacterSet.whitespaceAndNewlineCharacterSet];
  NSDictionary *attributes = @{
    NSForegroundColorAttributeName: UIColor.ne_darkText,
    NSFontAttributeName: [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold],
  };
  NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc]
    initWithString:title attributes:attributes];
  NSString *key = [keyword ?: @"" stringByTrimmingCharactersInSet:
                   NSCharacterSet.whitespaceAndNewlineCharacterSet];
  NSRange range = [title rangeOfString:key options:NSCaseInsensitiveSearch];
  if (key.length > 0 && range.location != NSNotFound) {
    [attributed addAttribute:NSForegroundColorAttributeName value:highlightColor range:range];
    [attributed addAttribute:NSBackgroundColorAttributeName value:UIColor.clearColor range:range];
  }
  self.titleLabel.attributedText = attributed;
  self.summaryLabel.text = item.summary ?: @"";
  self.summaryLabel.hidden = item.summary.length == 0;
  self.timeLabel.text = [NSString stringFromTimeInterval:item.updateTime];
  self.timeWidth.constant = 0;
  if (self.timeLabel.text) {
    CGRect rect = [self.timeLabel.text boundingRectWithSize:
                   CGSizeMake(NEConstant.screenWidth, 0)
                                                    options:0
                                                 attributes:@{NSFontAttributeName: self.timeLabel.font}
                                                    context:nil];
    self.timeWidth.constant = rect.size.width + 1;
  }
  self.unreadDot.hidden = !item.hasUnread;
}

@end

@interface BotSubSessionActionSheetController ()
@property(nonatomic, copy, readwrite) NSString *topicTitle;
@property(nonatomic, strong) UIView *sheetView;
@end

@implementation BotSubSessionActionSheetController

- (instancetype)initWithTitle:(NSString *)title {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _topicTitle = [title copy] ?: @"";
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"initWithCoder: has not been implemented"
                               userInfo:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupUI];
}

- (void)setupUI {
  self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(cancelAction)];
  tap.delegate = self;
  [self.view addGestureRecognizer:tap];
  self.sheetView = [[UIView alloc] init];
  self.sheetView.translatesAutoresizingMaskIntoConstraints = NO;
  self.sheetView.backgroundColor = UIColor.whiteColor;
  self.sheetView.layer.cornerRadius = 28;
  self.sheetView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
  self.sheetView.clipsToBounds = YES;
  [self.view addSubview:self.sheetView];

  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  titleLabel.text = self.topicTitle;
  titleLabel.textAlignment = NSTextAlignmentCenter;
  titleLabel.font = [UIFont systemFontOfSize:14];
  titleLabel.textColor = UIColor.ne_greyText;
  UIButton *renameButton = NEBotDialogButton(chatLocalizable(@"bot_sub_session_rename_action"),
                                              UIColor.ne_darkText, UIColor.clearColor,
                                              self, @selector(renameAction));
  UIButton *deleteButton = NEBotDialogButton(chatLocalizable(@"operation_delete"),
                                              [UIColor ne_colorWithHexString:@"#FC596A"],
                                              UIColor.clearColor, self, @selector(deleteAction));
  UIButton *cancelButton = NEBotDialogButton(commonLocalizable(@"cancel"), UIColor.ne_darkText,
                                              UIColor.clearColor, self, @selector(cancelAction));
  UIView *(^divider)(void) = ^UIView *{
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor ne_colorWithHexString:@"#F2F4F5"];
    return view;
  };
  UIView *divider1 = divider();
  UIView *divider2 = divider();
  UIView *gap = divider();
  for (UIView *view in @[titleLabel, divider1, renameButton, divider2, deleteButton, gap, cancelButton]) {
    [self.sheetView addSubview:view];
  }
  [NSLayoutConstraint activateConstraints:@[
    [self.sheetView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.sheetView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.sheetView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [titleLabel.topAnchor constraintEqualToAnchor:self.sheetView.topAnchor],
    [titleLabel.leftAnchor constraintEqualToAnchor:self.sheetView.leftAnchor constant:24],
    [titleLabel.rightAnchor constraintEqualToAnchor:self.sheetView.rightAnchor constant:-24],
    [titleLabel.heightAnchor constraintEqualToConstant:56],
    [divider1.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor],
    [divider1.leftAnchor constraintEqualToAnchor:self.sheetView.leftAnchor],
    [divider1.rightAnchor constraintEqualToAnchor:self.sheetView.rightAnchor],
    [divider1.heightAnchor constraintEqualToConstant:1],
    [renameButton.topAnchor constraintEqualToAnchor:divider1.bottomAnchor],
    [renameButton.leftAnchor constraintEqualToAnchor:self.sheetView.leftAnchor],
    [renameButton.rightAnchor constraintEqualToAnchor:self.sheetView.rightAnchor],
    [renameButton.heightAnchor constraintEqualToConstant:56],
    [divider2.topAnchor constraintEqualToAnchor:renameButton.bottomAnchor],
    [divider2.leftAnchor constraintEqualToAnchor:self.sheetView.leftAnchor],
    [divider2.rightAnchor constraintEqualToAnchor:self.sheetView.rightAnchor],
    [divider2.heightAnchor constraintEqualToConstant:1],
    [deleteButton.topAnchor constraintEqualToAnchor:divider2.bottomAnchor],
    [deleteButton.leftAnchor constraintEqualToAnchor:self.sheetView.leftAnchor],
    [deleteButton.rightAnchor constraintEqualToAnchor:self.sheetView.rightAnchor],
    [deleteButton.heightAnchor constraintEqualToConstant:56],
    [gap.topAnchor constraintEqualToAnchor:deleteButton.bottomAnchor],
    [gap.leftAnchor constraintEqualToAnchor:self.sheetView.leftAnchor],
    [gap.rightAnchor constraintEqualToAnchor:self.sheetView.rightAnchor],
    [gap.heightAnchor constraintEqualToConstant:10],
    [cancelButton.topAnchor constraintEqualToAnchor:gap.bottomAnchor],
    [cancelButton.leftAnchor constraintEqualToAnchor:self.sheetView.leftAnchor],
    [cancelButton.rightAnchor constraintEqualToAnchor:self.sheetView.rightAnchor],
    [cancelButton.heightAnchor constraintEqualToConstant:56],
    [cancelButton.bottomAnchor constraintEqualToAnchor:self.sheetView.safeAreaLayoutGuide.bottomAnchor],
  ]];
}

- (void)renameAction { if (self.onRename) self.onRename(); }
- (void)deleteAction { if (self.onDelete) self.onDelete(); }
- (void)cancelAction { [self dismissViewControllerAnimated:NO completion:nil]; }

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  return ![touch.view isDescendantOfView:self.sheetView];
}

@end

@interface BotSubSessionRenameDialogController ()
@property(nonatomic, copy, readwrite) NSString *initialName;
@property(nonatomic, strong, readwrite) UIColor *saveButtonBackgroundColor;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) NESingleLineTextField *nameField;
@end

@implementation BotSubSessionRenameDialogController

- (instancetype)initWithName:(NSString *)name saveButtonBackgroundColor:(UIColor *)color {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _initialName = [name copy] ?: @"";
    _saveButtonBackgroundColor = color ?: UIColor.ne_defaultPrimaryColor;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"initWithCoder: has not been implemented"
                               userInfo:nil];
}
- (void)viewDidLoad { [super viewDidLoad]; [self setupUI]; }
- (void)viewDidAppear:(BOOL)animated { [super viewDidAppear:animated]; [self.nameField becomeFirstResponder]; }

- (void)setupUI {
  self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
  self.contentView = [[UIView alloc] init];
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  self.contentView.backgroundColor = UIColor.whiteColor;
  self.contentView.layer.cornerRadius = 16;
  self.contentView.clipsToBounds = YES;
  [self.view addSubview:self.contentView];
  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  titleLabel.text = chatLocalizable(@"bot_sub_session_rename_conversation");
  titleLabel.textAlignment = NSTextAlignmentCenter;
  titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
  titleLabel.textColor = UIColor.ne_darkText;
  self.nameField = [[NESingleLineTextField alloc] init];
  self.nameField.translatesAutoresizingMaskIntoConstraints = NO;
  self.nameField.text = self.initialName;
  self.nameField.delegate = self;
  self.nameField.returnKeyType = UIReturnKeyDone;
  self.nameField.clearButtonMode = UITextFieldViewModeWhileEditing;
  self.nameField.font = [UIFont systemFontOfSize:16];
  self.nameField.textColor = UIColor.ne_darkText;
  self.nameField.layer.cornerRadius = 8;
  self.nameField.layer.borderWidth = 1;
  self.nameField.layer.borderColor = [UIColor ne_colorWithHexString:@"#337EFF"].CGColor;
  self.nameField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
  self.nameField.leftViewMode = UITextFieldViewModeAlways;
  self.nameField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
  self.nameField.rightViewMode = UITextFieldViewModeUnlessEditing;
  UIButton *cancelButton = NEBotDialogButton(commonLocalizable(@"cancel"), UIColor.ne_darkText,
                                              [UIColor ne_colorWithHexString:@"#F2F4F5"],
                                              self, @selector(cancelAction));
  UIButton *saveButton = NEBotDialogButton(chatLocalizable(@"bot_sub_session_save"),
                                            UIColor.whiteColor, self.saveButtonBackgroundColor,
                                            self, @selector(saveAction));
  for (UIView *view in @[titleLabel, self.nameField, cancelButton, saveButton]) {
    [self.contentView addSubview:view];
  }
  [NSLayoutConstraint activateConstraints:@[
    [self.contentView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.contentView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-40],
    [self.contentView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.7],
    [titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16],
    [titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:24],
    [titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-24],
    [self.nameField.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:24],
    [self.nameField.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:24],
    [self.nameField.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-24],
    [self.nameField.heightAnchor constraintEqualToConstant:48],
    [cancelButton.topAnchor constraintEqualToAnchor:self.nameField.bottomAnchor constant:16],
    [cancelButton.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:24],
    [cancelButton.heightAnchor constraintEqualToConstant:42],
    [saveButton.topAnchor constraintEqualToAnchor:self.nameField.bottomAnchor constant:16],
    [saveButton.leftAnchor constraintEqualToAnchor:cancelButton.rightAnchor constant:24],
    [saveButton.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-24],
    [saveButton.widthAnchor constraintEqualToAnchor:cancelButton.widthAnchor],
    [saveButton.heightAnchor constraintEqualToConstant:42],
    [saveButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16],
  ]];
}

- (void)cancelAction { [self dismissViewControllerAnimated:NO completion:nil]; }
- (void)saveAction {
  NSString *name = [self.nameField.text ?: @"" stringByTrimmingCharactersInSet:
                    NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if (self.onSave) self.onSave(name);
}
- (void)showToast:(NSString *)message { if (message.length > 0) [self.view ne_makeToast:message]; }
- (BOOL)textFieldShouldReturn:(UITextField *)textField { [self saveAction]; return YES; }
- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string {
  NSString *current = textField.text ?: @"";
  if (NSMaxRange(range) > current.length) return YES;
  NSString *next = [current stringByReplacingCharactersInRange:range withString:string ?: @""];
  return NEBotStringFitsComposedCharacterLimit(next, 20);
}

@end

@interface BotSubSessionDeleteDialogController ()
@property(nonatomic, copy, readwrite) NSString *dialogTitle;
@property(nonatomic, copy, readwrite) NSString *dialogMessage;
@property(nonatomic, strong, readwrite) UIColor *confirmButtonBackgroundColor;
@property(nonatomic, strong) UIView *contentView;
@end

@implementation BotSubSessionDeleteDialogController

- (instancetype)initWithTitle:(NSString *)title
                       message:(NSString *)message
  confirmButtonBackgroundColor:(UIColor *)color {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _dialogTitle = [title copy] ?: @"";
    _dialogMessage = [message copy] ?: @"";
    _confirmButtonBackgroundColor = color ?: UIColor.ne_defaultPrimaryColor;
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"initWithCoder: has not been implemented"
                               userInfo:nil];
}
- (void)viewDidLoad { [super viewDidLoad]; [self setupUI]; }

- (void)setupUI {
  self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
  self.contentView = [[UIView alloc] init];
  self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
  self.contentView.backgroundColor = UIColor.whiteColor;
  self.contentView.layer.cornerRadius = 16;
  self.contentView.clipsToBounds = YES;
  [self.view addSubview:self.contentView];
  UILabel *titleLabel = [[UILabel alloc] init];
  titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  titleLabel.text = self.dialogTitle;
  titleLabel.textAlignment = NSTextAlignmentCenter;
  titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
  titleLabel.textColor = UIColor.ne_darkText;
  UILabel *messageLabel = [[UILabel alloc] init];
  messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
  messageLabel.text = self.dialogMessage;
  messageLabel.textAlignment = NSTextAlignmentCenter;
  messageLabel.font = [UIFont systemFontOfSize:16];
  messageLabel.textColor = UIColor.ne_greyText;
  messageLabel.numberOfLines = 0;
  UIButton *cancelButton = NEBotDialogButton(commonLocalizable(@"cancel"), UIColor.ne_darkText,
                                              [UIColor ne_colorWithHexString:@"#F2F4F5"],
                                              self, @selector(cancelAction));
  UIButton *deleteButton = NEBotDialogButton(chatLocalizable(@"operation_delete"),
                                              UIColor.whiteColor, self.confirmButtonBackgroundColor,
                                              self, @selector(deleteAction));
  for (UIView *view in @[titleLabel, messageLabel, cancelButton, deleteButton]) {
    [self.contentView addSubview:view];
  }
  [NSLayoutConstraint activateConstraints:@[
    [self.contentView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.contentView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-40],
    [self.contentView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.7],
    [titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16],
    [titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:24],
    [titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-24],
    [messageLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:16],
    [messageLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:24],
    [messageLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-24],
    [cancelButton.topAnchor constraintEqualToAnchor:messageLabel.bottomAnchor constant:16],
    [cancelButton.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:24],
    [cancelButton.heightAnchor constraintEqualToConstant:48],
    [deleteButton.topAnchor constraintEqualToAnchor:messageLabel.bottomAnchor constant:16],
    [deleteButton.leftAnchor constraintEqualToAnchor:cancelButton.rightAnchor constant:24],
    [deleteButton.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-24],
    [deleteButton.widthAnchor constraintEqualToAnchor:cancelButton.widthAnchor],
    [deleteButton.heightAnchor constraintEqualToConstant:48],
    [deleteButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-16],
  ]];
}

- (void)cancelAction { [self dismissViewControllerAnimated:NO completion:nil]; }
- (void)deleteAction { if (self.onDelete) self.onDelete(); }

@end

@interface NEBaseBotSubSessionListViewController ()
@property(nonatomic, strong, readwrite) BotSubSessionListViewModel *viewModel;
@property(nonatomic, copy, readwrite) NSString *conversationId;
@property(nonatomic, copy, readwrite) NSString *sessionId;
@property(nonatomic, copy, readwrite) NSString *sessionName;
@property(nonatomic, strong) P2PChatViewModel *titleNameViewModel;
@property(nonatomic, assign) NEBotSubSessionEmptyState emptyState;
@property(nonatomic, assign) NSTimeInterval lastCreateActionTime;
@property(nonatomic, assign) NSTimeInterval lastEnterTopicActionTime;
@property(nonatomic, assign) BOOL loadingTopics;
@end

@implementation NEBaseBotSubSessionListViewController

- (instancetype)initWithConversationId:(NSString *)conversationId
                              sessionId:(NSString *)sessionId
                            sessionName:(NSString *)sessionName {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _conversationId = [conversationId copy] ?: @"";
    _sessionId = [sessionId copy] ?: @"";
    _sessionName = [sessionName copy] ?: @"";
    _viewModel = [[BotSubSessionListViewModel alloc] init];
    _titleNameViewModel = [[P2PChatViewModel alloc] initWithConversationId:_conversationId anchor:nil];
    _emptyState = NEBotSubSessionEmptyStateNoTopic;
    _deleteButtonBackgroundColor = [UIColor ne_colorWithHexString:@"#A8ABB6"];
    _renameButtonBackgroundColor = [UIColor ne_colorWithHexString:@"#337EFF"];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"initWithCoder: has not been implemented"
                               userInfo:nil];
}
- (CGFloat)listTopSpacing { return 12; }
- (UIColor *)pageBackgroundColor { return UIColor.whiteColor; }
- (UIColor *)listItemBackgroundColor { return UIColor.whiteColor; }
- (BOOL)showsListItemDivider { return NO; }
- (UIColor *)listItemDividerColor { return [UIColor ne_colorWithHexString:@"#D8D8D8"]; }
- (NSString *)defaultEmptyImageName { return @"emptyView"; }
- (NSString *)searchEmptyImageName { return self.defaultEmptyImageName; }
- (UIColor *)emptyActionTitleColor { return UIColor.whiteColor; }
- (UIColor *)emptyActionBackgroundColor { return UIColor.ne_defaultPrimaryColor; }
- (UIColor *)searchHighlightColor { return UIColor.ne_defaultPrimaryColor; }

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.tableViewTopAnchor.constant = self.listTopSpacing;
  [self.viewModel refreshListStateIfNeeded];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = [self displaySessionName];
  self.navigationView.moreButton.hidden = NO;
  [self.navigationView setMoreButtonImage:[coreLoader() loadImage:@"three_point"]];
  [self.navigationView setMoreButtonWidth:34];
  [self.navigationView.moreButton removeTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
  [self.navigationView addMoreButtonTarget:self selector:@selector(openSettingPage)];
  self.viewModel.delegate = self;
  [self setupUI];
  [self loadSessionTitle];
  [self refreshData];
}

- (void)toSetting {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
  __weak typeof(self) weakSelf = self;
  [alert addAction:[UIAlertAction actionWithTitle:commonLocalizable(@"add")
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *action) { [weakSelf showCreateAlert]; }]];
  [alert addAction:[UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                           style:UIAlertActionStyleCancel handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)setupUI {
  self.view.backgroundColor = self.pageBackgroundColor;
  self.createTopicButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.createTopicButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.createTopicButton setImage:[chatLoadImage(@"add_black") imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                         forState:UIControlStateNormal];
  self.createTopicButton.accessibilityIdentifier = @"id.createTopic";
  [self.createTopicButton addTarget:self action:@selector(showCreateAlert)
                   forControlEvents:UIControlEventTouchUpInside];
  [self.navigationView.titleBarView addSubview:self.createTopicButton];
  self.navigationView.navTitle.numberOfLines = 1;
  self.navigationView.navTitle.lineBreakMode = NSLineBreakByTruncatingTail;

  self.searchTextField = [[NESingleLineSearchTextField alloc] init];
  self.searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
  self.searchTextField.delegate = self;
  self.searchTextField.placeholder = chatLocalizable(@"bot_sub_session_search_hint");
  self.searchTextField.font = [UIFont systemFontOfSize:14];
  self.searchTextField.textColor = UIColor.ne_darkText;
  self.searchTextField.backgroundColor = [UIColor ne_colorWithHexString:@"#F2F4F5"];
  self.searchTextField.layer.cornerRadius = 8;
  self.searchTextField.clearButtonMode = UITextFieldViewModeAlways;
  self.searchTextField.returnKeyType = UIReturnKeySearch;
  self.searchTextField.leftView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"textField_search_icon"]];
  self.searchTextField.leftViewMode = UITextFieldViewModeAlways;
  self.searchTextField.accessibilityIdentifier = @"id.search";
  UIButton *clearButton = [self.searchTextField valueForKey:@"_clearButton"];
  if ([clearButton isKindOfClass:[UIButton class]]) {
    clearButton.accessibilityIdentifier = @"id.clear";
  }
  [self.searchTextField addTarget:self action:@selector(searchTextChanged)
                  forControlEvents:UIControlEventEditingChanged];

  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 20);
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.rowHeight = 68;
  self.tableView.tableFooterView = [[UIView alloc] init];
  if (@available(iOS 15.0, *)) self.tableView.sectionHeaderTopPadding = 0;
  self.tableView.backgroundColor = self.pageBackgroundColor;

  self.emptyActionButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.emptyActionButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.emptyActionButton.backgroundColor = self.emptyActionBackgroundColor;
  self.emptyActionButton.layer.cornerRadius = 16;
  self.emptyActionButton.titleLabel.font = [UIFont systemFontOfSize:14];
  [self.emptyActionButton setTitleColor:self.emptyActionTitleColor forState:UIControlStateNormal];
  self.emptyActionButton.accessibilityIdentifier = @"id.emptyAction";
  self.emptyActionButton.hidden = YES;
  [self.emptyActionButton addTarget:self action:@selector(handleEmptyActionButtonTap)
                    forControlEvents:UIControlEventTouchUpInside];
  self.emptyView.backgroundColor = self.pageBackgroundColor;
  [self.emptyView setText:chatLocalizable(@"bot_sub_session_empty")];
  UITapGestureRecognizer *retryTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                             action:@selector(handleEmptyViewTap)];
  [self.emptyView addGestureRecognizer:retryTap];
  self.emptyView.userInteractionEnabled = YES;
  [self.emptyView addSubview:self.emptyActionButton];

  [self.view addSubview:self.searchTextField];
  [self.view addSubview:self.tableView];
  [self.view addSubview:self.emptyView];
  CGFloat rightButtonArea = 34 * 2 + self.navigationView.leftMargin + 12;
  CGFloat leftButtonArea = MAX(self.navigationView.backButtonWidthAnchor.constant, 34) +
                           self.navigationView.leftMargin;
  CGFloat titleMaxWidth = UIScreen.mainScreen.bounds.size.width - MAX(leftButtonArea, rightButtonArea) * 2;
  self.tableViewTopAnchor = [self.tableView.topAnchor
    constraintEqualToAnchor:self.searchTextField.bottomAnchor constant:self.listTopSpacing];
  [NSLayoutConstraint activateConstraints:@[
    [self.createTopicButton.widthAnchor constraintEqualToConstant:34],
    [self.createTopicButton.heightAnchor constraintEqualToConstant:32],
    [self.createTopicButton.rightAnchor constraintEqualToAnchor:self.navigationView.moreButton.leftAnchor],
    [self.createTopicButton.centerYAnchor constraintEqualToAnchor:self.navigationView.moreButton.centerYAnchor],
    [self.navigationView.navTitle.widthAnchor constraintLessThanOrEqualToConstant:titleMaxWidth],
    [self.searchTextField.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant + 8],
    [self.searchTextField.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:16],
    [self.searchTextField.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-16],
    [self.searchTextField.heightAnchor constraintEqualToConstant:40],
    self.tableViewTopAnchor,
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor],
    [self.emptyView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor],
    [self.emptyView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
    [self.emptyActionButton.topAnchor constraintEqualToAnchor:self.emptyView.emptyImageView.bottomAnchor constant:40],
    [self.emptyActionButton.centerXAnchor constraintEqualToAnchor:self.emptyView.centerXAnchor],
    [self.emptyActionButton.widthAnchor constraintEqualToConstant:96],
    [self.emptyActionButton.heightAnchor constraintEqualToConstant:32],
  ]];
}

- (void)refreshData {
  self.emptyState = NEBotSubSessionEmptyStateNone;
  self.loadingTopics = YES;
  __weak typeof(self) weakSelf = self;
  [self.viewModel loadDataWithConversationId:self.conversationId sessionId:self.sessionId
                                            :^(NSError *error) {
    __strong typeof(weakSelf) self = weakSelf;
    if (!self) return;
    self.loadingTopics = NO;
    if (error) {
      self.emptyState = NEBotSubSessionEmptyStateLoadFailed;
      [self.emptyView setText:chatLocalizable(@"bot_sub_session_load_failed")];
      [self updateEmptyActionButton];
      self.emptyView.hidden = NO;
    } else {
      [self updateEmptyState];
    }
  }];
}

- (void)onBotSubSessionListReload { [self updateEmptyState]; [self.tableView reloadData]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.displayTopicList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *reuseId = @"bot.sub.session.cell";
  BotSubSessionListCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
  if (!cell) cell = [[BotSubSessionListCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                 reuseIdentifier:reuseId];
  BotSubSessionItem *item = [self.viewModel itemAtIndex:indexPath.row];
  if (item) {
    [cell configureWithItem:item sessionName:self.sessionName keyword:self.viewModel.keyword
             highlightColor:self.searchHighlightColor];
    [cell applyStyleWithBackgroundColor:self.listItemBackgroundColor
                           showsDivider:self.showsListItemDivider
                            dividerColor:self.listItemDividerColor];
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row >= self.viewModel.displayTopicList.count) return;
  NSTimeInterval now = NSDate.date.timeIntervalSince1970;
  if (now - self.lastEnterTopicActionTime < 0.5) return;
  self.lastEnterTopicActionTime = now;
  [self enterTopic:self.viewModel.displayTopicList[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.searchTextField resignFirstResponder];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
    trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath API_AVAILABLE(ios(11.0)) {
  if (indexPath.row >= self.viewModel.displayTopicList.count) return nil;
  V2NIMTopic *topic = self.viewModel.displayTopicList[indexPath.row];
  __weak typeof(self) weakSelf = self;
  UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
    title:chatLocalizable(@"operation_delete") handler:^(UIContextualAction *action, UIView *view,
                                                          void (^completion)(BOOL)) {
    [weakSelf showDeleteAlertWithTopic:topic];
    completion(YES);
  }];
  deleteAction.backgroundColor = self.deleteButtonBackgroundColor;
  UIContextualAction *renameAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
    title:chatLocalizable(@"bot_sub_session_rename_action") handler:^(UIContextualAction *action, UIView *view,
                                                                      void (^completion)(BOOL)) {
    [weakSelf showRenameAlertWithTopic:topic];
    completion(YES);
  }];
  renameAction.backgroundColor = self.renameButtonBackgroundColor;
  UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration
    configurationWithActions:@[deleteAction, renameAction]];
  configuration.performsFirstActionWithFullSwipe = NO;
  return configuration;
}

- (void)showDeleteAlertWithTopic:(V2NIMTopic *)topic {
  NSString *message = [NSString stringWithFormat:chatLocalizable(@"bot_sub_session_delete_topic"),
                       [self.viewModel topicDisplayName:topic]];
  BotSubSessionDeleteDialogController *controller = [[BotSubSessionDeleteDialogController alloc]
    initWithTitle:chatLocalizable(@"bot_sub_session_delete_title") message:message
    confirmButtonBackgroundColor:self.renameButtonBackgroundColor];
  __weak typeof(self) weakSelf = self;
  __weak typeof(controller) weakController = controller;
  controller.onDelete = ^{
    [weakController dismissViewControllerAnimated:NO completion:nil];
    [weakSelf.viewModel removeTopicWithTopic:topic :^(NSError *error) {
      if (error) [weakSelf.view ne_makeToast:chatLocalizable(@"bot_sub_session_delete_failed")];
    }];
  };
  [self presentViewController:controller animated:NO completion:nil];
}

- (void)showRenameAlertWithTopic:(V2NIMTopic *)topic {
  BotSubSessionRenameDialogController *controller = [[BotSubSessionRenameDialogController alloc]
    initWithName:[self.viewModel topicDisplayName:topic]
    saveButtonBackgroundColor:self.renameButtonBackgroundColor];
  __weak typeof(self) weakSelf = self;
  __weak typeof(controller) weakController = controller;
  controller.onSave = ^(NSString *name) {
    if (name.length == 0) {
      [weakController showToast:chatLocalizable(@"bot_sub_session_input_name")];
      return;
    }
    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
      [weakController showToast:commonLocalizable(@"network_error")];
      return;
    }
    [weakSelf.viewModel updateTopicNameWithTopic:topic topicName:name
                                                :^(V2NIMTopic *updated, NSError *error) {
      if (error) [weakController showToast:chatLocalizable(@"bot_sub_session_rename_failed")];
      else [weakController dismissViewControllerAnimated:NO completion:nil];
    }];
  };
  [self presentViewController:controller animated:NO completion:nil];
}

- (void)showCreateAlert {
  NSTimeInterval now = NSDate.date.timeIntervalSince1970;
  if (now - self.lastCreateActionTime < 0.5) return;
  self.lastCreateActionTime = now;
  if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self.view ne_makeToast:chatLocalizable(@"bot_sub_session_offline_create")];
    return;
  }
  [self enterTopic:nil];
}

- (void)searchTextChanged { [self.viewModel updateKeyword:self.searchTextField.text ?: @""]; }
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self.viewModel updateKeyword:textField.text ?: @""];
  [textField resignFirstResponder];
  return YES;
}
- (void)enterTopic:(V2NIMTopic *)topic {}

- (void)openSettingPage {
  NEBaseUserSettingViewController *controller = [self getUserSettingViewController];
  if (!controller) return;
  controller.fromBotSubSession = YES;
  [self.navigationController pushViewController:controller animated:YES];
}

- (NEBaseUserSettingViewController *)getUserSettingViewController { return nil; }
- (NSString *)displaySessionName {
  NSString *name = [self.titleNameViewModel getShowName:self.sessionId showAlias:YES];
  return name.length > 0 ? name : self.sessionId;
}
- (void)loadSessionTitle {
  __weak typeof(self) weakSelf = self;
  [self.titleNameViewModel loadShowName:@[self.sessionId] teamId:nil completion:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      weakSelf.title = [weakSelf displaySessionName];
    });
  }];
}

- (void)updateEmptyState {
  if (self.loadingTopics) {
    self.emptyView.hidden = YES;
    self.emptyActionButton.hidden = YES;
    return;
  }
  if (self.viewModel.displayTopicList.count == 0) {
    if (self.viewModel.keyword.length == 0) {
      self.emptyState = NEBotSubSessionEmptyStateNoTopic;
      [self.emptyView setEmptyImageWithName:self.defaultEmptyImageName];
      [self.emptyView setText:chatLocalizable(@"bot_sub_session_empty")];
    } else {
      self.emptyState = NEBotSubSessionEmptyStateNoSearchResult;
      [self.emptyView setEmptyImageWithName:self.searchEmptyImageName];
      [self.emptyView setText:chatLocalizable(@"bot_sub_session_search_empty")];
    }
    [self updateEmptyActionButton];
    self.emptyView.hidden = NO;
  } else {
    self.emptyState = NEBotSubSessionEmptyStateNone;
    self.emptyView.hidden = YES;
    self.emptyActionButton.hidden = YES;
  }
}

- (void)handleEmptyViewTap {
  if (self.emptyState == NEBotSubSessionEmptyStateLoadFailed) [self refreshData];
}
- (void)handleEmptyActionButtonTap {
  if (self.emptyState == NEBotSubSessionEmptyStateNoTopic) [self showCreateAlert];
  else if (self.emptyState == NEBotSubSessionEmptyStateLoadFailed) [self refreshData];
}
- (void)updateEmptyActionButton {
  if (self.emptyState == NEBotSubSessionEmptyStateNoTopic) {
    [self.emptyActionButton setTitle:chatLocalizable(@"bot_sub_session_create_conversation")
                             forState:UIControlStateNormal];
    self.emptyActionButton.hidden = NO;
  } else if (self.emptyState == NEBotSubSessionEmptyStateLoadFailed) {
    [self.emptyActionButton setTitle:chatLocalizable(@"bot_sub_session_retry")
                             forState:UIControlStateNormal];
    self.emptyActionButton.hidden = NO;
  } else {
    self.emptyActionButton.hidden = YES;
  }
}

@end
