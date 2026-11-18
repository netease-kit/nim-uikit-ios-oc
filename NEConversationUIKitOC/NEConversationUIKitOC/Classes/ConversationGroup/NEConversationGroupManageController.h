// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import <UIKit/UIKit.h>
#import "NEConversationBaseViewController.h"
#import "NEConversationGroupManager.h"
@class NEConversationGroupManager;

NS_ASSUME_NONNULL_BEGIN
@interface NEConversationGroupManageController : NEConversationBaseViewController <ConversationGroupViewModelDelegate, UITableViewDataSource, UITableViewDelegate>
- (instancetype)initWithManager:(NEConversationGroupManager *)manager;
@end

@interface NEConversationGroupAddConversationController : NEConversationBaseViewController <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, copy, nullable) dispatch_block_t complete;
@end

@interface NEConversationGroupSettingController : NEConversationBaseViewController <ConversationGroupViewModelDelegate, UITableViewDataSource, UITableViewDelegate>
@end
NS_ASSUME_NONNULL_END
