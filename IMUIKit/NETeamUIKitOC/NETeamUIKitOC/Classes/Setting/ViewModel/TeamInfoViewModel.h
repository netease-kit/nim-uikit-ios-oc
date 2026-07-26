// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/TeamRepo.h>

@class SettingCellModel;

NS_ASSUME_NONNULL_BEGIN

@protocol NETeamInfoDelegate <NSObject>
- (void)teamInfoDidUpdate:(V2NIMTeam *)team;
@end

@interface TeamInfoViewModel : NSObject <NETeamListener>

@property (nonatomic, strong) NSMutableArray<SettingCellModel *> *cellDatas;
@property (nonatomic, strong) TeamRepo *teamRepo;
@property (nonatomic, strong, nullable) V2NIMTeam *v2Team;
@property (nonatomic, weak, nullable) id<NETeamInfoDelegate> delegate;

- (void)getData:(nullable V2NIMTeam *)team;

@end

NS_ASSUME_NONNULL_END
