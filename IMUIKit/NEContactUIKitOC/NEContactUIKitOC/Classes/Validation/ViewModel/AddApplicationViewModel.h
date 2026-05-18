// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "NEAddApplication.h"

@class ContactRepo;

NS_ASSUME_NONNULL_BEGIN

@protocol AddApplicationViewModelDelegate <NSObject>
- (void)tableviewReload;
@end

@interface AddApplicationViewModel : NSObject

@property (nonatomic, strong) ContactRepo *contactRepo;
@property (nonatomic, weak) id<AddApplicationViewModelDelegate> delegate;
@property (nonatomic, strong) NSMutableArray<NEAddApplication *> *friendAddApplications;

- (void)loadApplicationList:(BOOL)firstLoad completion:(void (^)(NSError *_Nullable))completion;
- (void)convertToNEAddApplication:(V2NIMFriendAddApplication *)item
                              move:(BOOL)move
                        completion:(void (^)(NSError *_Nullable))completion;
- (void)setAddApplicationRead:(nullable void (^)(BOOL, NSError *_Nullable))completion;
- (void)changeApplicationStatus:(V2NIMFriendAddApplication *)application
                          status:(V2NIMFriendAddApplicationStatus)status;
- (void)agreeRequest:(V2NIMFriendAddApplication *)application
          completion:(void (^)(NSError *_Nullable))completion;
- (void)refuseRequest:(V2NIMFriendAddApplication *)application
           completion:(void (^)(NSError *_Nullable))completion;
- (void)clearNotification:(void (^)(NSError *_Nullable))completion;

// NEContactListener
- (void)onFriendAddApplication:(V2NIMFriendAddApplication *)application;
- (void)onFriendAddRejected:(V2NIMFriendAddApplication *)rejectionInfo;

@end

NS_ASSUME_NONNULL_END
