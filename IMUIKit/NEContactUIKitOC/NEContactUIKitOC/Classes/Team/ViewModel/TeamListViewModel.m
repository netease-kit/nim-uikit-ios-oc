// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamListViewModel.h"
#import <NEChatKitOC/NETeam.h>
#import "ContactConst.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/TeamRepo.h>

@interface TeamListViewModel () <NETeamListener>
@end

@implementation TeamListViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamRepo = [TeamRepo shared];
    _teamList = [NSMutableArray array];
    _refresh = ^{};
    [_teamRepo addTeamListener:self];
  }
  return self;
}

- (void)dealloc {
  [_teamRepo removeTeamListener:self];
}

- (void)getTeamList:(void (^)(NSArray<NETeam *> *_Nullable, NSError *_Nullable))completion {
  NSLog(@"ContactKit log");

  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamList:^(NSArray<V2NIMTeam *> *_Nullable teams, NSError *_Nullable error) {
    if (error) {
      NSLog(@"ContactKit: error %@", error);
      completion(nil, error);
    } else if (teams) {
      [weakSelf.teamList removeAllObjects];
      for (V2NIMTeam *v2team in teams) {
        NETeam *neTeam = [[NETeam alloc] initWithV2TeamInfo:v2team];
        [weakSelf.teamList addObject:neTeam];
      }
      [weakSelf.teamList sortUsingComparator:^NSComparisonResult(NETeam *team1, NETeam *team2) {
        if (team1.createTime > team2.createTime) return NSOrderedAscending;
        if (team1.createTime < team2.createTime) return NSOrderedDescending;
        return NSOrderedSame;
      }];
      completion(weakSelf.teamList, nil);
    }
  }];
}

#pragma mark - NETeamListener

- (void)onTeamAdded:(V2NIMTeam *)team {
  [self.teamList insertObject:[[NETeam alloc] initWithV2TeamInfo:team] atIndex:0];
  self.refresh();
}

- (void)onTeamUpdated:(V2NIMTeam *)team {
  for (NSInteger i = 0; i < (NSInteger)self.teamList.count; i++) {
    NETeam *t = self.teamList[i];
    if ([t.teamId isEqualToString:team.teamId]) {
      self.teamList[i] = [[NETeam alloc] initWithV2TeamInfo:team];
      self.refresh();
      break;
    }
  }
}

- (void)onTeamRemoved:(V2NIMTeam *)team {
  for (NSInteger i = 0; i < (NSInteger)self.teamList.count; i++) {
    NETeam *t = self.teamList[i];
    if ([t.teamId isEqualToString:team.teamId]) {
      [self.teamList removeObjectAtIndex:i];
      self.refresh();
      break;
    }
  }
}

- (void)onTeamCreated:(V2NIMTeam *)team { [self onTeamAdded:team]; }
- (void)onTeamJoined:(V2NIMTeam *)team { [self onTeamAdded:team]; }
- (void)onTeamInfoUpdated:(V2NIMTeam *)team { [self onTeamUpdated:team]; }
- (void)onTeamLeft:(V2NIMTeam *)team isKicked:(BOOL)isKicked { [self onTeamRemoved:team]; }
- (void)onTeamDismissed:(V2NIMTeam *)team { [self onTeamRemoved:team]; }

@end
