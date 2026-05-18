// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NECommonUIKitOC/NEBaseViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseScanQRViewController : NEBaseViewController

/// Return YES if the scan result has been handled and the controller should not resume scanning.
@property (nonatomic, copy, nullable) BOOL (^onScanResult)(NSString *result);

- (void)handleScanResult:(NSString *)result;

@end

NS_ASSUME_NONNULL_END
