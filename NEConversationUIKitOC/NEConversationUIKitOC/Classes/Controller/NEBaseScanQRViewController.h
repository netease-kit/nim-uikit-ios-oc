// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/NEBaseViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEScanBeamView : UIView

@property (nonatomic, strong) UIColor *beamColor;
@property (nonatomic, strong) UIColor *glowColor;

@end

@interface NEBaseScanQRViewController : NEBaseViewController

/// Return YES if the scan result has been handled and the controller should not resume scanning.
@property (nonatomic, copy, nullable) BOOL (^onScanResult)(NSString *result);

@property (nonatomic, strong, readonly) UIView *previewContainer;
@property (nonatomic, strong, readonly) NEScanBeamView *scanBeamView;

/// Subclasses override these values to provide skin-specific rendering.
@property (nonatomic, strong, readonly) UIColor *scanBeamColor;
@property (nonatomic, strong, readonly) UIColor *scanBeamGlowColor;
@property (nonatomic, assign, readonly) CGFloat scanBeamHeight;
@property (nonatomic, assign, readonly) NSTimeInterval scanAnimationDuration;

- (void)setupScanUI;
- (void)startScanAnimation;
- (void)stopScanAnimation;
- (void)handleScanResult:(NSString *)result;

@end

@interface ScanQRViewController : NEBaseScanQRViewController
@end

@interface FunScanQRViewController : NEBaseScanQRViewController
@end

NS_ASSUME_NONNULL_END
