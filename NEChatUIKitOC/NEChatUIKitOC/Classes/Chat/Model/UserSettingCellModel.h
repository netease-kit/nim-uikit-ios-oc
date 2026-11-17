// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "MessageEnum.h"
#import <NEBaseUIKitOC/NECustomActionSheetController.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SwitchChangeCompletion)(BOOL isOn);
typedef void (^CellClickBlock)(void);

@interface UserSettingCellModel : NSObject

@property (nonatomic, copy, nullable) NSString *cellName;
@property (nonatomic, copy, nullable) NSString *subTitle;
@property (nonatomic, copy, nullable) SwitchChangeCompletion swichChange;
@property (nonatomic, assign) CGFloat rowHeight;
@property (nonatomic, assign) CornerType cornerType;
@property (nonatomic, copy, nullable) CellClickBlock cellClick;
@property (nonatomic, assign) BOOL switchOpen;
@property (nonatomic, assign) NSInteger type;

@end

NS_ASSUME_NONNULL_END
