// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface TeamAvatarViewModel : NSObject

@property (nonatomic, strong, nullable) V2NIMTeamMember *currentTeamMember;

- (void)getCurrentUserTeamMember:(nullable NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion;
- (void)getCurrentUserTeamMember:(nullable NSString *)teamId :(void (^)(NSError * _Nullable error))completion;
- (void)updateTeamAvatar:(NSString *)url teamId:(NSString *)teamId antispamConfig:(nullable V2NIMAntispamConfig *)antispamConfig completion:(void (^)(NSError * _Nullable error))completion;
- (void)updateTeamAvatar:(NSString *)url :(NSString *)teamId :(nullable V2NIMAntispamConfig *)antispamConfig :(void (^)(NSError * _Nullable error))completion;
- (V2NIMUploadFileTask *)createTask:(NSString *)filePath;
- (V2NIMUploadFileTask *)createTask:(NSString *)filePath sceneName:(nullable NSString *)sceneName;
- (V2NIMUploadFileTask *)createTask:(NSString *)filePath :(nullable NSString *)sceneName;
- (void)uploadImageFile:(V2NIMUploadFileTask *)fileTask progress:(nullable void (^)(float progress))progress completion:(nullable void (^)(NSString * _Nullable url, NSError * _Nullable error))completion;
- (void)uploadImageFile:(V2NIMUploadFileTask *)fileTask :(nullable void (^)(float progress))progress :(nullable void (^)(NSString * _Nullable url, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
