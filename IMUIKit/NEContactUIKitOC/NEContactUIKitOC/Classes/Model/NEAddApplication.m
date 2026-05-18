// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAddApplication.h"
#import "ContactConst.h"

@implementation NEAddApplication

- (instancetype)initWithApplication:(V2NIMFriendAddApplication *)info {
  self = [super init];
  if (self) {
    _v2Notification = info;
    _displayUserId = info.applicantAccountId;
    _handleStatus = info.status;
    _unreadCount = (info.read == NO) ? 1 : 0;
    _detail = contactLocalizable(@"add_request");
  }
  return self;
}

- (BOOL)isEqualTo:(V2NIMFriendAddApplication *)noti
     compareStatus:(BOOL)compareStatus {
  if ([self.v2Notification.applicantAccountId isEqualToString:noti.applicantAccountId] &&
      [self.v2Notification.recipientAccountId isEqualToString:noti.recipientAccountId]) {
    if (compareStatus) {
      return self.handleStatus == noti.status;
    }
    return YES;
  }
  return NO;
}

- (BOOL)isEqualTo:(V2NIMFriendAddApplication *)noti {
  return [self isEqualTo:noti compareStatus:YES];
}

@end
