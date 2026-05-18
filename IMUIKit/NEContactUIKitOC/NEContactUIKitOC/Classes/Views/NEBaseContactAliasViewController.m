// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseContactAliasViewController.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/ContactRepo.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import <NEChatKitOC/IMKitConfigCenter.h>
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "ContactConst.h"

@interface NEBaseContactAliasViewController ()
@property (nonatomic, strong) ContactUserViewModel *viewmodel;
@property (nonatomic, assign) NSInteger textLimit;
@end

@implementation NEBaseContactAliasViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _viewmodel = [[ContactUserViewModel alloc] init];
    _textLimit = 15;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

#pragma mark - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.aliasInputTopAnchor.constant = self.topConstant;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
  [self setupUI];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - setupUI

- (void)setupUI {
  [self changeLanguage];
  self.view.backgroundColor = [UIColor ne_lightBackgroundColor];
  [self.navigationView addMoreButtonTarget:self selector:@selector(saveAlias)];
  self.navigationView.backgroundColor = [UIColor ne_lightBackgroundColor];

  [self.view addSubview:self.aliasInput];
  NSString *alias = self.user.friend.alias;
  if (alias && alias.length > 0) {
    self.aliasInput.text = alias;
  }
}

- (void)changeLanguage {
  self.title = contactLocalizable(@"noteName");
  [self.navigationView setMoreButtonTitle:contactLocalizable(@"save")];
  self.aliasInput.placeholder = contactLocalizable(@"input_noteName");
}

#pragma mark - saveAlias

- (void)saveAlias {
  [self.view endEditing:YES];

  NSString *text = self.aliasInput.text;
  if (text && text.length > 0 && [[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
    [self.view ne_makeToast:contactLocalizable(@"space_not_support") duration:2 position:YXToastPositionCenter];
    self.aliasInput.text = @"";
    return;
  }

  __weak typeof(self) weakSelf = self;
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }

  self.user.friend.alias = self.aliasInput.text;

  NSString *uid = self.user.user.accountId;
  NSString *alias = self.aliasInput.text;
  if (uid && alias) {
    [self.view makeToastActivity:YXToastPositionCenter];
    [self.viewmodel updateAlias:uid alias:alias completion:^(NSError * _Nullable error) {
      [weakSelf.view ne_hideToastActivity];
      if (error) {
        [weakSelf.view ne_makeToast:error.localizedDescription duration:2 position:YXToastPositionCenter];
      } else {
        if (weakSelf.completion && weakSelf.user) {
          weakSelf.completion(weakSelf.user);
        }
        [weakSelf.navigationController popViewControllerAnimated:YES];
      }
    }];
  }
}

#pragma mark - textFieldChange

- (void)textFieldChange {
  if (self.aliasInput.markedTextRange == nil) {
    NSString *text = self.aliasInput.text;
    if (text && (NSInteger)text.length > self.textLimit) {
      self.aliasInput.text = [text substringToIndex:self.textLimit];
    }
    return;
  }
}

#pragma mark - Lazy Init

- (UITextField *)aliasInput {
  if (!_aliasInput) {
    _aliasInput = [[UITextField alloc] init];
    _aliasInput.backgroundColor = [UIColor whiteColor];
    _aliasInput.clipsToBounds = YES;
    _aliasInput.font = [UIFont systemFontOfSize:16.0];
    _aliasInput.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *leftSpace = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 0)];
    _aliasInput.leftView = leftSpace;
    _aliasInput.leftViewMode = UITextFieldViewModeAlways;
    _aliasInput.delegate = self;
    _aliasInput.clearButtonMode = UITextFieldViewModeAlways;
    [_aliasInput addTarget:self action:@selector(textFieldChange) forControlEvents:UIControlEventEditingChanged];
    UIButton *clearButton = [_aliasInput valueForKey:@"_clearButton"];
    if (clearButton) {
      clearButton.accessibilityIdentifier = @"id.clear";
    }
    _aliasInput.accessibilityIdentifier = @"id.editText";
  }
  return _aliasInput;
}

@end
