// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEMessageReactionView;
@class NEMessageReactionGroup;

@protocol NEMessageReactionViewDelegate <NSObject>
- (void)reactionView:(NEMessageReactionView *)view didSelectIndex:(NSInteger)index;
@end

/// Direction-aware, wrapping renderer for immutable message reaction groups.
@interface NEMessageReactionView : UIView

@property (nonatomic, weak, nullable) id<NEMessageReactionViewDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL enabledForDisplay;
@property (nonatomic, assign, readonly) CGFloat naturalWidth;

- (void)configureWithGroups:(NSArray<NEMessageReactionGroup *> *)groups
                    enabled:(BOOL)enabled
                 isOutgoing:(BOOL)isOutgoing;
- (CGFloat)layoutWidthForMaxWidth:(CGFloat)maxWidth;
- (CGFloat)heightForWidth:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
