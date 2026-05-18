// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "PhotoBrowserController.h"
#import "BrowserToolsBar.h"
#import "PhotoBrowserBigImgBackView.h"
#import "ToastImageView.h"
#import "UIView+YXToast.h"
#import "NECommonUIConstant.h"
#import <NEChatKitOC/NEAuthManager.h>
#import <Photos/Photos.h>

@interface PhotoBrowserController () <BrowserToolsBarDelegate>

@property (nonatomic, strong) BrowserToolsBar *toolsBar;
@property (nonatomic, strong) ToastImageView *successView;
@property (nonatomic, strong) PhotoBrowserBigImgBackView *showView;
@property (nonatomic, assign) NSInteger number;

@end

@implementation PhotoBrowserController

- (instancetype)initWithImgs:(NSArray<UIImage *> *)imgs img:(UIImage *)img {
  __block NSInteger number = 0;
  [imgs enumerateObjectsUsingBlock:^(UIImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if ([obj isEqual:img]) {
      number = (NSInteger)idx;
      *stop = YES;
    }
  }];
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _number = number;
    _showView = [[PhotoBrowserBigImgBackView alloc] initWithImgArr:imgs number:number];
  }
  return self;
}

- (instancetype)initWithUrls:(NSArray<NSString *> *)urls url:(NSString *)url {
  NSInteger index = [urls indexOfObject:url];
  return [self initWithUrls:urls url:url currentIndex:(index != NSNotFound ? index : 0)];
}

- (instancetype)initWithUrls:(NSArray<NSString *> *)urls url:(NSString *)url currentIndex:(NSInteger)currentIndex {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _number = currentIndex;
    _showView = [[PhotoBrowserBigImgBackView alloc] initWithUrlArr:urls number:currentIndex];
  }
  return self;
}

- (instancetype)initWithUrls:(NSArray<NSString *> *)urls url:(NSString *)url currenIndex:(NSInteger)currenIndex {
  return [self initWithUrls:urls url:url currentIndex:currenIndex];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.clearColor;
  [self layoutViews];
  [self.showView transformAnimation];
}

- (void)layoutViews {
  [self.view addSubview:self.showView];

  __weak typeof(self) weakSelf = self;
  self.showView.dismissCallBack = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    dispatch_block_t callback = strongSelf.onDismiss;
    [strongSelf dismissViewControllerAnimated:NO completion:^{
      !callback ?: callback();
    }];
  };

  [self.showView addSubview:self.toolsBar];
  [NSLayoutConstraint activateConstraints:@[
    [self.toolsBar.leftAnchor constraintEqualToAnchor:self.showView.leftAnchor],
    [self.toolsBar.rightAnchor constraintEqualToAnchor:self.showView.rightAnchor],
    [self.toolsBar.heightAnchor constraintEqualToConstant:44.0],
    [self.toolsBar.bottomAnchor constraintEqualToAnchor:self.showView.safeAreaLayoutGuide.bottomAnchor constant:-27.0],
  ]];
}

- (void)didCloseClick {
  [self.showView dismissPhotoBrowser];
}

- (void)didSaveClick {
  __weak typeof(self) weakSelf = self;
  [NEAuthManager requestPhotoAuthorization:^(BOOL granted) {
    if (!granted) {
      [weakSelf showToast:commonLocalizable(@"jump_photo_setting")];
      return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf.view neMakeToastActivity:NEToastPositionCenter];
      [weakSelf saveImage];
    });
  }];
}

- (void)saveImage {
  NSInteger index = [self.showView currentIndex];
  __weak typeof(self) weakSelf = self;
  if (self.showView.urlArray.count > 0) {
    NSString *urlString = self.showView.urlArray[index];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
      [self.view neHideToastActivity];
      return;
    }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
      NSData *data = [NSData dataWithContentsOfURL:url];
      if (!data) {
        return;
      }
      PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
      [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:data options:nil];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.view neHideToastActivity];
        if (error) {
          [weakSelf showToast:error.localizedDescription ?: @""];
        } else {
          [weakSelf.view ne_showToast:weakSelf.successView duration:1.5 position:NEToastPositionCenter completion:nil];
        }
      });
    }];
  } else if (self.showView.imgArray.count > 0) {
    UIImage *image = self.showView.imgArray[index];
    UIImageWriteToSavedPhotosAlbum(image,
                                   self,
                                   @selector(saveImage:didFinishSavingWithError:contextInfo:),
                                   nil);
  }
}

- (void)saveImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
  [self.view neHideToastActivity];
  if (error) {
    [self showToast:error.localizedDescription ?: @""];
  } else {
    [self.view ne_showToast:self.successView duration:1.5 position:NEToastPositionCenter completion:nil];
  }
}

- (void)showToast:(NSString *)message {
  if (message.length == 0) {
    return;
  }
  [self.view neMakeToast:message position:NEToastPositionCenter];
}

- (BrowserToolsBar *)toolsBar {
  if (!_toolsBar) {
    _toolsBar = [[BrowserToolsBar alloc] init];
    _toolsBar.delegate = self;
    _toolsBar.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _toolsBar;
}

- (ToastImageView *)successView {
  if (!_successView) {
    _successView = [[ToastImageView alloc] initWithFrame:CGRectMake(0, 0, 118, 120)];
    _successView.contentLabel.text = commonLocalizable(@"save_system_album");
  }
  return _successView;
}

@end
