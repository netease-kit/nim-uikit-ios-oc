// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import <UIKit/UIKit.h>
@class NEConversationGroupItem;

NS_ASSUME_NONNULL_BEGIN
@protocol NEConversationGroupBarDelegate <NSObject>
- (void)conversationGroupBarDidSelect:(NEConversationGroupItem *)group;
- (void)conversationGroupBarDidRequestManagement;
@end

@interface NEConversationGroupBar : UIView
@property(nonatomic, weak, nullable) id<NEConversationGroupBarDelegate> delegate;
- (void)reloadGroups:(NSArray<NEConversationGroupItem *> *)groups
       selectedGroup:(nullable NEConversationGroupItem *)selectedGroup;
@end
NS_ASSUME_NONNULL_END
