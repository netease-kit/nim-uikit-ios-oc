// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEConversationPopListItem : NSObject

@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, copy, nullable) NSString *showName;
@property (nonatomic, strong) UIColor *showNameColor;
@property (nonatomic, copy, nullable) dispatch_block_t completion;

@end

@interface NEConversationBasePopListView : UIView

@property (nonatomic, strong, readonly) UIView *shadowView;
@property (nonatomic, strong, readonly) UIView *popView;
@property (nonatomic, assign) CGFloat buttonHeight;
@property (nonatomic, assign) CGFloat popViewWidth;
@property (nonatomic, assign) CGFloat popViewHeight;
@property (nonatomic, assign) CGFloat popViewRadius;
@property (nonatomic, assign) CGFloat topConstant;
@property (nonatomic, copy) NSArray<NEConversationPopListItem *> *itemDatas;

- (void)removeSelf;

@end

@interface NEConversationNormalPopListView : NEConversationBasePopListView
@end

@interface NEConversationFunPopListView : NEConversationBasePopListView
@end

NS_ASSUME_NONNULL_END
