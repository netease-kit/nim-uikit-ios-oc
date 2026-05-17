// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "OperationItem+NEChatUIKit.h"
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import "NEChatUIConstant.h"

@implementation OperationItem (NEChatUIKit)

+ (instancetype)earpieceItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_earpiece");
  item.imageName = @"op_earpiece";
  item.type = OperationTypeEarpiece;
  return item;
}

+ (instancetype)speakerItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_speaker");
  item.imageName = @"op_speaker";
  item.type = OperationTypeSpeaker;
  return item;
}

+ (instancetype)copyItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_copy");
  item.imageName = @"op_copy";
  item.type = OperationTypeCopy;
  return item;
}

+ (instancetype)replayItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_replay");
  item.imageName = @"op_replay";
  item.type = OperationTypeReply;
  return item;
}

+ (instancetype)forwardItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_forward");
  item.imageName = @"op_forward";
  item.type = OperationTypeForward;
  return item;
}

+ (instancetype)pinItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_pin");
  item.imageName = @"op_pin";
  item.type = OperationTypePin;
  return item;
}

+ (instancetype)removePinItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_cancel_pin");
  item.imageName = @"op_pin";
  item.type = OperationTypeRemovePin;
  return item;
}

+ (instancetype)selectItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_select");
  item.imageName = @"op_select";
  item.type = OperationTypeMultiSelect;
  return item;
}

+ (instancetype)collectionItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_collection");
  item.imageName = @"op_collect";
  item.type = OperationTypeCollection;
  return item;
}

+ (instancetype)topItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_top");
  item.imageName = @"op_top";
  item.type = OperationTypeTop;
  return item;
}

+ (instancetype)untopItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_untop");
  item.imageName = @"op_untop";
  item.type = OperationTypeUntop;
  return item;
}

+ (instancetype)deleteItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_delete");
  item.imageName = @"op_delete";
  item.type = OperationTypeDelete;
  return item;
}

+ (instancetype)recallItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_recall");
  item.imageName = @"op_recall";
  item.type = OperationTypeRecall;
  return item;
}

+ (instancetype)audioToTextItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_to_text");
  item.imageName = @"op_toText";
  item.type = OperationTypeVoiceToText;
  return item;
}

@end

@implementation OperationItem (NEChatUIKitSearch)

+ (instancetype)searchTeamMemberItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"group_memmber");
  item.imageName = @"op_teamMember";
  item.type = OperationTypeSearchTeamMember;
  return item;
}

+ (instancetype)searchImageItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = commonLocalizable(@"images");
  item.imageName = @"photo";
  item.type = OperationTypeSearchImage;
  return item;
}

+ (instancetype)searchVideoItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = commonLocalizable(@"videos");
  item.imageName = @"op_video";
  item.type = OperationTypeSearchVideo;
  return item;
}

+ (instancetype)searchDateItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"operation_date");
  item.imageName = @"op_date";
  item.type = OperationTypeSearchDate;
  return item;
}

+ (instancetype)searchFileItem {
  OperationItem *item = [[OperationItem alloc] init];
  item.text = chatLocalizable(@"chat_file");
  item.imageName = @"op_file";
  item.type = OperationTypeSearchFile;
  return item;
}

@end
