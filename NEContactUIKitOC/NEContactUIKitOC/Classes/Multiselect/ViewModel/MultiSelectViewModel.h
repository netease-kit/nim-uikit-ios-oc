// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactViewModel.h"
#import "MultiSelectModel.h"

@class ConversationRepo;
@class LocalConversationRepo;
@class TeamRepo;
@class SettingRepo;

NS_ASSUME_NONNULL_BEGIN

@interface MultiSelectViewModel : ContactViewModel

@property (nonatomic, strong) ConversationRepo *conversationRepo;
@property (nonatomic, strong) LocalConversationRepo *localConversationRepo;
@property (nonatomic, strong) TeamRepo *teamRepo;
@property (nonatomic, strong) SettingRepo *settingRepo;
@property (nonatomic, strong) NSMutableArray<MultiSelectModel *> *sessions;

- (instancetype)init;

- (void)loadAllData:(nullable NSSet<NSString *> *)filters
         completion:(void (^)(NSError *_Nullable))completion;
- (void)loadAllData:(nullable NSSet<NSString *> *)filters
                   :(void (^)(NSError *_Nullable))completion;
- (void)loadDataAtIndex:(NSInteger)index
                filters:(nullable NSSet<NSString *> *)filters
             completion:(void (^)(NSError *_Nullable))completion;
- (void)loadData:(NSInteger)index
               :(nullable NSSet<NSString *> *)filters
               :(void (^)(NSError *_Nullable))completion;
- (NSArray<MultiSelectModel *> *)loadRecentForward;
- (void)getConversationList:(nullable NSSet<NSString *> *)filters
                 completion:(void (^)(NSError *_Nullable))completion;
- (void)getConversationList:(nullable NSSet<NSString *> *)filters
                            :(void (^)(NSError *_Nullable))completion;
- (void)getContactListForMultiSelect:(nullable NSSet<NSString *> *)filters
                          completion:(void (^)(NSError *_Nullable))completion;
- (void)getContactList:(nullable NSSet<NSString *> *)filters
                       :(void (^)(NSError *_Nullable))completion;
- (void)getTeamList:(nullable NSSet<NSString *> *)filters
         completion:(void (^)(NSError *_Nullable))completion;
- (void)getTeamList:(nullable NSSet<NSString *> *)filters
                    :(void (^)(NSError *_Nullable))completion;
- (nullable MultiSelectModel *)findFriend:(nullable NSString *)conversationId;
- (nullable MultiSelectModel *)findTeam:(nullable NSString *)conversationId;
- (void)searchText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
