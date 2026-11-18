// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/TeamRepo.h>
#import <NEChatKit/IMKitClient.h>

@class ConversationSearchListModel;

NS_ASSUME_NONNULL_BEGIN

@interface ConversationSearchViewModel : NSObject <NETeamListener, NEContactListener, NEIMKitClientListener>

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, ConversationSearchListModel *> *teamDic;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, ConversationSearchListModel *> *friendDic;
@property (nonatomic, strong, readonly) NSMutableArray<ConversationSearchListModel *> *friendDatas;
@property (nonatomic, strong, readonly) NSMutableArray<ConversationSearchListModel *> *discussionDatas;
@property (nonatomic, strong, readonly) NSMutableArray<ConversationSearchListModel *> *seniorDatas;

- (void)doSearch:(nullable NSString *)searchText completion:(dispatch_block_t)completion;
- (void)getSearchData:(BOOL)removeTeamData completion:(dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
