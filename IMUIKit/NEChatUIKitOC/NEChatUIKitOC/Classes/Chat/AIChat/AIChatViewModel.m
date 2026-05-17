// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIChatViewModel.h"
#import "ChatUIConfig.h"

@implementation AIChatViewModel

- (void)loadData:(nullable NSArray *)messages completion:(void (^)(NSError * _Nullable))completion {
    if ([ChatUIConfig shared].aiChatDataLoader) {
        __weak typeof(self) weakSelf = self;
        [ChatUIConfig shared].aiChatDataLoader(messages, ^(NSArray<AIChatCellModel *> *models, NSError *error) {
            weakSelf.aiChatData = models;
            if (completion) completion(error);
        });
    } else {
        NSError *error = [NSError errorWithDomain:@"[AIChatViewModel] aiChatDataLoader is nil" code:-1 userInfo:nil];
        if (completion) completion(error);
    }
}

@end
