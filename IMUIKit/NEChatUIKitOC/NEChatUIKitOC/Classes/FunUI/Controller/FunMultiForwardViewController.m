// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunMultiForwardViewController.h"
#import <NEChatKitOC/NSString+NECommon.h>
#import "ChatMessageHelper.h"
#import "ChatCellConstantValue.h"
#import "MessageTipsModel.h"
#import "FunChatUIColor.h"

@implementation FunMultiForwardViewController

- (instancetype)initWithAttachmentUrl:(nullable NSString *)attachmentUrl
                   attachmentFilePath:(NSString *)attachmentFilePath
                        attachmentMD5:(nullable NSString *)attachmentMD5 {
    self = [super initWithAttachmentUrl:attachmentUrl attachmentFilePath:attachmentFilePath attachmentMD5:attachmentMD5];
    if (self) {
        self.brokenNetworkViewHeight = 48;
        self.cellRegisterDic = [ChatMessageHelper getChatCellRegisterDicWithIsFun:YES];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
    self.brokenNetworkView.errorIconView.hidden = NO;
    self.brokenNetworkView.backgroundColor = [UIColor funChatNetworkBrokenViewBg];
    self.brokenNetworkView.contentLabel.textColor = [UIColor funChatNetworkBrokenTitleColor];
    self.navigationView.backgroundColor = [UIColor funChatBackgroundColor];
    self.navigationView.titleBarBottomLine.backgroundColor = [UIColor funChatNavigationDivideBg];
}

- (MultiForwardViewController *)getMultiForwardViewController:(NSString *)messageAttachmentUrl
                                                     filePath:(NSString *)messageAttachmentFilePath
                                                          md5:(NSString *)messageAttachmentMD5 {
    return [[FunMultiForwardViewController alloc] initWithAttachmentUrl:messageAttachmentUrl
                                                    attachmentFilePath:messageAttachmentFilePath
                                                         attachmentMD5:messageAttachmentMD5];
}

- (void)didTapTel:(NSURL *)url {
    [self showCustomBottomTelAction:url];
}

- (void)didTapMailto:(NSURL *)url {
    [self showCustomBottomMailAction:url];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.messages.count) {
        return 0;
    }
    return [self.viewModel.messages[indexPath.row] cellHeight];
}

- (void)getMessageModel:(id<MessageModel> )model {
    if (model.type == MessageTypeTip || model.type == MessageTypeNotification) {
        if ([model isKindOfClass:[MessageTipsModel class]]) {
            MessageTipsModel *tipModel = (MessageTipsModel *)model;
            if (tipModel.text) {
                tipModel.contentSize = [NSString getRealSize:tipModel.text font:[UIFont systemFontOfSize:14] maxSize:CGSizeMake(chat_text_maxW(), CGFLOAT_MAX)];
                tipModel.height = MAX(tipModel.contentSize.height + chat_content_margin, 28);
            }
        }
        return;
    }

    CGFloat contentWidth = model.contentSize.width;
    CGFloat contentHeight = model.contentSize.height;
    if (contentHeight < fun_chat_min_h) {
        CGFloat subHeight = fun_chat_min_h - contentHeight;
        model.contentSize = CGSizeMake(contentWidth, fun_chat_min_h);
        model.offset = subHeight;
    }

    if (model.type == MessageTypeRtcCallRecord) {
        model.contentSize = CGSizeMake(contentWidth, contentHeight - 2);
        model.offset = -2;
    }
}

@end
