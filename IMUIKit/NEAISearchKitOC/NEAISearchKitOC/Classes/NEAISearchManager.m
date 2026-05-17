// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAISearchManager.h"
#import "AIWordSearch/NEAISearchConstant.h"
#import "AIWordSearch/NEAIWordSearchViewController.h"
#import <NEChatKitOC/ChatConstant.h>
#import <NEChatKitOC/ChatKitClient.h>
#import <NEChatKitOC/OperationItem.h>
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/ViewControllerExtension.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKitOC/IMKitClient.h>

@implementation NEAISearchManager

+ (instancetype)shared {
  static NEAISearchManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NEAISearchManager alloc] initPrivate];
  });
  return instance;
}

- (instancetype)init {
  return [NEAISearchManager shared];
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _serviceName = NEAISearchPlugin ?: @"";
    _versionName = imkitVersion;
    _appKey = [[IMKitClient instance] appKey] ?: @"";
  }
  return self;
}

- (void)setupInit {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [[XKit instance] registerService:self];
    [[IMKitPluginManager shared] registerPlugin:self.serviceName plugin:self];
    [[ChatKitClient shared] buryDataPoints:@"AISearchKit"];
  });
}

- (nullable OperationItem *)registerPlugin:(NSString *)text {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = NEAISearchLocalizable(@"operation_ai_word_search");
  item.image = NEAISearchImageNamed(@"op_ai_word");
  item.type = OperationTypePlugin;

  NSString *selectedText = [text copy] ?: @"";
  item.onClick = ^(UIViewController * _Nullable viewController) {
    if (!viewController) {
      return;
    }

    if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
      [viewController showToast:commonLocalizable(@"network_error")];
      return;
    }

    if (selectedText.length == 0) {
      [viewController showToast:NEAISearchLocalizable(@"not_supported")];
      return;
    }

    NEAIWordSearchViewController *viewControllerToPresent =
        [[NEAIWordSearchViewController alloc] initWithSearchText:selectedText];
    viewControllerToPresent.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [viewController.navigationController presentViewController:viewControllerToPresent
                                                      animated:YES
                                                    completion:nil];
  };
  return item;
}

@end
