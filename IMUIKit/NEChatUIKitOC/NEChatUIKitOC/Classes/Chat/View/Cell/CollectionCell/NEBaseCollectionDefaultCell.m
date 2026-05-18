// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionDefaultCell.h"
#import "NEChatUIConstant.h"

@implementation NEBaseCollectionDefaultCell

- (void)configureData:(CollectionMessageModel *)model {
    [super configureData:model];
    self.collectionContentLabel.text = chatLocalizable(@"unkonw_pin_message");
}

@end
