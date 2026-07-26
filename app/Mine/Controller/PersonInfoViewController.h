// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NECommonUIKitOC/NEBaseViewController.h>
#import <NEChatKit/ContactRepo.h>
#import <NETeamUIKitOC/SettingSectionModel.h>

NS_ASSUME_NONNULL_BEGIN

@class PersonInfoViewController;

@protocol PersonInfoViewModelDelegate <NSObject>
@optional
- (void)didClickHeadImage;
- (void)didClickNickName:(NSString *)name;
- (void)didClickGender;
- (void)didClickBirthday:(NSString *)birth;
- (void)didClickMobile:(NSString *)mobile;
- (void)didClickEmail:(NSString *)email;
- (void)didClickSign:(NSString *)sign;
- (void)didCopyAccount:(NSString *)account;
@end

@interface PersonInfoViewModel : NSObject

@property (nonatomic, strong, nullable) NEUserWithFriend *userInfo;
@property (nonatomic, weak, nullable)   id<PersonInfoViewModelDelegate> delegate;
@property (nonatomic, strong, readonly) NSArray<SettingSectionModel *> *sectionData;

- (void)getData:(void(^)(void))completion;
- (void)refreshData;

- (void)updateSelfAvatar:(NSString *)avatar completion:(void(^)(NSError *_Nullable))completion;
- (void)updateSelfNickName:(NSString *)name completion:(void(^)(NSError *_Nullable))completion;
- (void)updateSelfSex:(V2NIMGender)gender completion:(void(^)(NSError *_Nullable))completion;
- (void)updateSelfBirthday:(NSString *)birthday completion:(void(^)(NSError *_Nullable))completion;
- (void)updateSelfMobile:(NSString *)mobile completion:(void(^)(NSError *_Nullable))completion;
- (void)updateSelfEmail:(NSString *)email completion:(void(^)(NSError *_Nullable))completion;
- (void)updateSelfSign:(NSString *)sign completion:(void(^)(NSError *_Nullable))completion;

@end

/// 对齐 Swift PersonInfoViewController — 个人信息编辑
@interface PersonInfoViewController : NEBaseViewController

@end

NS_ASSUME_NONNULL_END
