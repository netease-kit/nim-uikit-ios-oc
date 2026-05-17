// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NECommonUIKitOC/NEBaseViewController.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NEConfigManager.h>
#import <NECommonUIKitOC/NEEmptyDataView.h>
#import <NECommonUIKitOC/NENavigationView.h>

@class NEEmptyDataView;
@class NECustomAlertAction;

NS_ASSUME_NONNULL_BEGIN

@interface NETeamBaseViewController : NEBaseViewController

@property (nonatomic, strong, readonly) NEEmptyDataView *emptyView;
@property (nonatomic, strong, readonly) UIButton *rightNavButton;

- (void)showToast:(NSString *)message;
- (void)showActionSheet:(NSArray<UIAlertAction *> *)actions;
- (void)showCustomActionSheet:(NSArray<NECustomAlertAction *> *)actions;
- (void)showAlert:(nullable NSString *)title
          message:(nullable NSString *)message
             sure:(void(^)(UIAlertAction *action))sureBlock;
- (void)showSingleAlert:(nullable NSString *)title
                message:(nullable NSString *)message
                handler:(void(^ _Nullable)(void))handler;
- (void)addRightActionWithImage:(nullable UIImage *)image action:(SEL)action target:(id)target;
- (void)addRightActionWithTitle:(NSString *)title action:(SEL)action target:(id)target;
- (void)addRightActionWithTitle:(NSString *)title action:(SEL)action target:(id)target color:(nullable UIColor *)color;
- (void)showBottomAlertWithDelegate:(UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate> *)delegate
                            editing:(BOOL)editing
                       checkNetwork:(BOOL)checkNetwork
                      clickedAction:(void (^ _Nullable)(void))clickedAction
                  presentCompletion:(void (^ _Nullable)(void))presentCompletion;
- (void)showCustomBottomAlertWithDelegate:(UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate> *)delegate
                                  editing:(BOOL)editing
                             checkNetwork:(BOOL)checkNetwork;
- (void)goCameraWithDelegate:(UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate> *)delegate
                     editing:(BOOL)editing;
- (void)goPhotoAlbumWithDelegate:(UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate> *)delegate
                         editing:(BOOL)editing;

@end

NS_ASSUME_NONNULL_END
