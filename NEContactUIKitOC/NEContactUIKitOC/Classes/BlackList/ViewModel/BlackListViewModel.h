// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
@class NEUserWithFriend;
@class ContactRepo;

NS_ASSUME_NONNULL_BEGIN

@protocol BlackListViewModelDelegate <NSObject>
- (void)tableViewReload;
@end

@interface BlackListViewModel : NSObject

@property (nonatomic, strong) ContactRepo *contactRepo;
@property (nonatomic, strong) NSMutableArray<NEUserWithFriend *> *blockList;
@property (nonatomic, weak) id<BlackListViewModelDelegate> delegate;

- (void)getBlackList;
- (void)removeFromBlackList:(NSString *)account completion:(void (^)(NSError *_Nullable))completion;
- (void)removeFromBlackListWithAccount:(NSString *)account :(void (^)(NSError *_Nullable))completion;
- (void)addBlackList:(NSArray<NEUserWithFriend *> *)users completion:(void (^)(NSError *_Nullable))completion;
- (void)addBlackListWithUsers:(NSArray<NEUserWithFriend *> *)users :(void (^)(NSError *_Nullable))completion;

@end

NS_ASSUME_NONNULL_END
