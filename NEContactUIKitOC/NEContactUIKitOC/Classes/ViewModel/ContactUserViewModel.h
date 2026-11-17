// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
@class NEUserWithFriend;
@class ContactRepo;

NS_ASSUME_NONNULL_BEGIN

@interface ContactUserViewModel : NSObject

@property (nonatomic, strong) ContactRepo *contactRepo;

- (void)addFriend:(NSString *)account completion:(void (^)(NSError *_Nullable))completion;
- (void)addFriend:(NSString *)account :(void (^)(NSError *_Nullable))completion;
- (void)deleteFriend:(NSString *)account completion:(void (^)(NSError *_Nullable))completion;
- (void)deleteFriendWithAccount:(NSString *)account :(void (^)(NSError *_Nullable))completion;
- (void)removeBlackList:(NSString *)account completion:(void (^)(NSError *_Nullable))completion;
- (void)removeBlackListWithAccount:(NSString *)account :(void (^)(NSError *_Nullable))completion;
- (void)updateAlias:(NSString *)accountId
              alias:(NSString *)alias
         completion:(void (^)(NSError *_Nullable))completion;
- (void)updateAliasWithAccountId:(NSString *)accountId
                           alias:(NSString *)alias
                                :(void (^)(NSError *_Nullable))completion;
- (void)getUserInfo:(NSString *)uid
         completion:(void (^)(NEUserWithFriend *_Nullable, NSError *_Nullable))completion;
- (void)getUserInfo:(NSString *)uid
                    :(void (^)(NEUserWithFriend *_Nullable, NSError *_Nullable))completion;

@end

NS_ASSUME_NONNULL_END
