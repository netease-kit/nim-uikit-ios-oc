// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "MultiForwardViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NormalMultiForwardViewController : MultiForwardViewController

- (instancetype)initWithAttachmentUrl:(nullable NSString *)attachmentUrl
                   attachmentFilePath:(NSString *)attachmentFilePath
                        attachmentMD5:(nullable NSString *)attachmentMD5;

@end

NS_ASSUME_NONNULL_END
