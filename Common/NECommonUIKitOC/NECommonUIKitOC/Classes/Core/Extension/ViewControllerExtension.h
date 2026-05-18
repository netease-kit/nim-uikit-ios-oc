// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class ExpandButton;
@class NECustomAlertAction;

NS_ASSUME_NONNULL_BEGIN

typedef void (^AlertCallBack)(void);

@interface UIViewController (NEViewControllerExtension)

@property (nonatomic, strong) ExpandButton *rightNavButton;
@property (nonatomic, strong) ExpandButton *leftNavButton;

- (void)addLeftImageAction:(nullable UIImage *)image
                  selector:(SEL)selector
                    target:(nullable id)target
                 tintColor:(nullable UIColor *)tintColor;
- (void)addLeftTitleAction:(NSString *)title
                  selector:(SEL)selector
                    target:(nullable id)target
                 tintColor:(nullable UIColor *)tintColor;

- (void)addRightImageAction:(nullable UIImage *)image
                   selector:(SEL)selector
                     target:(nullable id)target
                  tintColor:(nullable UIColor *)tintColor;
- (void)addRightTitleAction:(NSString *)title
                   selector:(SEL)selector
                     target:(nullable id)target
                  tintColor:(nullable UIColor *)tintColor;

- (void)showAlert:(nullable NSString *)title
          message:(nullable NSString *)message
         sureText:(nullable NSString *)sureText
       cancelText:(nullable NSString *)cancelText
    sureTextColor:(nullable UIColor *)sureTextColor
  cancelTextColor:(nullable UIColor *)cancelTextColor
         sureBack:(AlertCallBack)sureBack
       cancelBack:(nullable AlertCallBack)cancelBack;
- (void)showAlert:(nullable NSString *)title
          message:(nullable NSString *)message
             sure:(void(^)(UIAlertAction *action))sureBlock;

- (void)showSingleAlert:(nullable NSString *)title
                message:(nullable NSString *)message
               sureText:(nullable NSString *)sureText
               sureBack:(AlertCallBack)sureBack;
- (void)showSingleAlert:(nullable NSString *)title
                message:(nullable NSString *)message
                handler:(nullable void(^)(void))handler;

- (void)showToast:(NSString *)message;
- (void)showToastInWindow:(NSString *)message;

- (void)showActionSheet:(NSArray<UIAlertAction *> *)actions;
- (void)showCustomActionSheet:(NSArray<NECustomAlertAction *> *)actions;

- (void)showBottomVideoAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                      editing:(BOOL)editing;
- (void)showCustomBottomVideoAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                            editing:(BOOL)editing;

- (void)showBottomFileAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate>)delegate;
- (void)showCustomBottomFileAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate>)delegate;

- (void)showBottomTelAction:(NSURL *)url;
- (void)showCustomBottomTelAction:(NSURL *)url;
- (void)showBottomMailAction:(NSURL *)url;
- (void)showCustomBottomMailAction:(NSURL *)url;

- (void)fixAlertOnIpad:(UIAlertController *)alertViewController;

- (void)showBottomAlert:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                editing:(BOOL)editing
           checkNetwork:(BOOL)checkNetwork
          clickedAction:(nullable void (^)(void))clickedAction
      presentCompletion:(nullable void (^)(void))presentCompletion;
- (void)showCustomBottomAlert:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                      editing:(BOOL)editing
                 checkNetwork:(BOOL)checkNetwork;

- (void)showBottomSelectAlert:(NSString *)firstContent
                secondContent:(NSString *)secondContent
                  selectValue:(void(^)(NSInteger value))selectValue;

- (void)goCamera:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
         editing:(BOOL)editing
         isVideo:(BOOL)isVideo;
- (void)goPhotoAlbum:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
             editing:(BOOL)editing
             isVideo:(BOOL)isVideo;
- (void)showPicker:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
           isVideo:(BOOL)isVideo
           editing:(BOOL)editing;
- (void)goPhotoAlbumWithVideo:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                    completion:(nullable void (^)(void))completion;
- (void)goICloudDocument:(id<UINavigationControllerDelegate, UIDocumentPickerDelegate>)delegate;

// Compatibility aliases for OC base controllers that already implement the public selectors above.
- (void)ne_showAlert:(nullable NSString *)title
             message:(nullable NSString *)message
                sure:(void(^)(UIAlertAction *action))sureBlock;
- (void)ne_showSingleAlert:(nullable NSString *)title
                   message:(nullable NSString *)message
                   handler:(nullable void(^)(void))handler;
- (void)ne_showToast:(NSString *)message;
- (void)ne_showActionSheet:(NSArray<UIAlertAction *> *)actions;
- (void)ne_showCustomActionSheet:(NSArray<NECustomAlertAction *> *)actions;
- (void)ne_showBottomVideoAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                         editing:(BOOL)editing;
- (void)ne_showCustomBottomVideoAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                               editing:(BOOL)editing;
- (void)ne_showBottomFileAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate>)delegate;
- (void)ne_showCustomBottomFileAction:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate>)delegate;
- (void)ne_showBottomTelAction:(NSURL *)url;
- (void)ne_showCustomBottomTelAction:(NSURL *)url;
- (void)ne_showBottomMailAction:(NSURL *)url;
- (void)ne_showCustomBottomMailAction:(NSURL *)url;
- (void)ne_showBottomAlert:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                   editing:(BOOL)editing
              checkNetwork:(BOOL)checkNetwork
             clickedAction:(nullable void (^)(void))clickedAction
         presentCompletion:(nullable void (^)(void))presentCompletion;
- (void)ne_showCustomBottomAlert:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                         editing:(BOOL)editing
                    checkNetwork:(BOOL)checkNetwork;
- (void)ne_goCamera:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
            editing:(BOOL)editing
            isVideo:(BOOL)isVideo;
- (void)ne_goPhotoAlbum:(id<UINavigationControllerDelegate, UIImagePickerControllerDelegate>)delegate
                editing:(BOOL)editing
                isVideo:(BOOL)isVideo;

@end

NS_ASSUME_NONNULL_END
