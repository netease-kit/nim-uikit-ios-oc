// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ContactInfo;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ContactCellDataProtrol

@protocol ContactCellDataProtrol <NSObject>
- (void)setModel:(ContactInfo *)model;
@end

#pragma mark - ContactDataProtrol

@protocol ContactDataProtrol <NSObject>
- (NSString *)getName;
- (nullable NSNumber *)getRowHeight; // CGFloat wrapped in NSNumber, nil if not set
@end

NS_ASSUME_NONNULL_END
