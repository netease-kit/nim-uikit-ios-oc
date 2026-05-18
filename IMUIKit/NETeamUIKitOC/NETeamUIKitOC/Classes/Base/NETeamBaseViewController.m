// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NEConfigManager.h>
#import <NECommonUIKitOC/NECustomActionSheetController.h>
#import <NECommonUIKitOC/NEEmptyDataView.h>
#import <NECommonUIKitOC/ViewControllerExtension.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <Photos/Photos.h>

@interface NETeamBaseViewController ()
@property (nonatomic, strong, readwrite) NEEmptyDataView *emptyView;
@property (nonatomic, strong, readwrite) UIButton *rightNavButton;
@end

@implementation NETeamBaseViewController

- (NEEmptyDataView *)emptyView {
  if (!_emptyView) {
    _emptyView = [[NEEmptyDataView alloc] initWithFrame:CGRectZero];
    _emptyView.translatesAutoresizingMaskIntoConstraints = NO;
    [_emptyView setEmptyImageName:@"emptyView"];
    _emptyView.message = @"";
    _emptyView.userInteractionEnabled = NO;
    _emptyView.hidden = YES;
  }
  return _emptyView;
}

- (UIButton *)rightNavButton {
  if (!_rightNavButton) {
    _rightNavButton = self.navigationView.moreButton;
  }
  return _rightNavButton;
}

- (void)showToast:(NSString *)message {
  [self ne_showToast:message];
}

- (void)showActionSheet:(NSArray<UIAlertAction *> *)actions {
  [self ne_showActionSheet:actions];
}

- (void)showCustomActionSheet:(NSArray<NECustomAlertAction *> *)actions {
  [self ne_showCustomActionSheet:actions];
}

- (void)showAlert:(nullable NSString *)title
          message:(nullable NSString *)message
             sure:(void(^)(UIAlertAction *action))sureBlock {
  [self ne_showAlert:title message:message sure:sureBlock];
}

- (void)showSingleAlert:(nullable NSString *)title
                message:(nullable NSString *)message
                handler:(void(^ _Nullable)(void))handler {
  [self ne_showSingleAlert:title message:message handler:handler];
}

- (void)addRightActionWithImage:(UIImage *)image action:(SEL)action target:(id)target {
  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  BOOL useSystemNav = useSystemNavValue && useSystemNavValue.boolValue;
  if (useSystemNav) {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:image
                                                             style:UIBarButtonItemStylePlain
                                                            target:target
                                                            action:action];
    self.navigationItem.rightBarButtonItem = item;
    return;
  }

  [self.navigationView setMoreButtonImage:image];
  [self.navigationView addMoreButtonTarget:target selector:action];
}

- (void)addRightActionWithTitle:(NSString *)title action:(SEL)action target:(id)target {
  [self addRightActionWithTitle:title action:action target:target color:nil];
}

- (void)addRightActionWithTitle:(NSString *)title action:(SEL)action target:(id)target color:(UIColor *)color {
  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  BOOL useSystemNav = useSystemNavValue && useSystemNavValue.boolValue;
  if (useSystemNav) {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:title
                                                             style:UIBarButtonItemStylePlain
                                                            target:target
                                                            action:action];
    item.tintColor = color ?: UIColor.ne_normalTheme;
    self.navigationItem.rightBarButtonItem = item;
    return;
  }

  [self.navigationView setMoreButtonTitle:title];
  [self.navigationView addMoreButtonTarget:target selector:action];
  self.navigationView.moreButton.hidden = NO;
  [self.navigationView setMoreButtonWidth:90.0];
  if (color) {
    [self.navigationView.moreButton setTitleColor:color forState:UIControlStateNormal];
    [self.rightNavButton setTitleColor:color forState:UIControlStateNormal];
  }
}

- (void)showBottomAlertWithDelegate:(UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate> *)delegate
                            editing:(BOOL)editing
                       checkNetwork:(BOOL)checkNetwork
                      clickedAction:(void (^)(void))clickedAction
                  presentCompletion:(void (^)(void))presentCompletion {
  [self ne_showBottomAlert:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                   editing:editing
              checkNetwork:checkNetwork
             clickedAction:clickedAction
         presentCompletion:presentCompletion];
}

- (void)showCustomBottomAlertWithDelegate:(UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate> *)delegate
                                  editing:(BOOL)editing
                             checkNetwork:(BOOL)checkNetwork {
  [self ne_showCustomBottomAlert:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                         editing:editing
                    checkNetwork:checkNetwork];
}

- (void)goCameraWithDelegate:(UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate> *)delegate
                     editing:(BOOL)editing {
  [self ne_goCamera:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
            editing:editing
            isVideo:NO];
}

- (void)goPhotoAlbumWithDelegate:(UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate> *)delegate
                         editing:(BOOL)editing {
  [self ne_goPhotoAlbum:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                editing:editing
                isVideo:NO];
}

@end
