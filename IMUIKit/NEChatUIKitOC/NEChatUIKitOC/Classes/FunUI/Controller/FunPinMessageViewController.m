// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunPinMessageViewController.h"
#import "FunForwardAlertViewController.h"
#import "FunMultiForwardViewController.h"
#import "FunTextViewController.h"
#import "ChatMessageHelper.h"
#import "FunChatUIColor.h"

@implementation FunPinMessageViewController

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.pin_content_maxW = (kScreenWidth() - 32);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
    [self.emptyView setEmptyImageWithName:@"fun_user_empty"];
}

- (NSDictionary<NSString *, Class> *)getRegisterCellDic {
    return [ChatMessageHelper getPinCellRegisterDic:YES];
}

- (void)showAction:(NEPinMessageModel *)item {
    NSMutableArray<NECustomAlertAction *> *actions = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;

    NECustomAlertAction *cancelPinAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"operation_cancel_pin") handler:^{
        [weakSelf cancelPinActionClicked:item];
    }];
    [actions addObject:cancelPinAction];

    if (item.message.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
        NECustomAlertAction *copyAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"operation_copy") handler:^{
            [weakSelf copyActionClicked:item];
        }];
        [actions addObject:copyAction];
    }

    if (item.message.messageType != V2NIM_MESSAGE_TYPE_AUDIO) {
        NECustomAlertAction *forwardAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"operation_forward") handler:^{
            [weakSelf forwardActionClicked:item];
        }];
        [actions addObject:forwardAction];
    }

    [self showCustomActionSheet:actions];
}

- (NEBaseForwardAlertViewController *)getForwardAlertController {
    return [[FunForwardAlertViewController alloc] init];
}

- (MultiForwardViewController *)getMultiForwardViewController:(NSString *)messageAttachmentUrl
                                                     filePath:(NSString *)messageAttachmentFilePath
                                                          md5:(NSString *)messageAttachmentMD5 {
    return [[FunMultiForwardViewController alloc] initWithAttachmentUrl:messageAttachmentUrl
                                                    attachmentFilePath:messageAttachmentFilePath
                                                         attachmentMD5:messageAttachmentMD5];
}

- (TextViewController *)getTextViewController:(NSString *)title body:(NSAttributedString *)body {
    FunTextViewController *textViewController = [[FunTextViewController alloc] initWithTitle:title body:body];
    [textViewController updateLinkDetection];
    return textViewController;
}

- (void)didTapTel:(NSURL *)url {
    [self showCustomBottomTelAction:url];
}

- (void)didTapMailto:(NSURL *)url {
    [self showCustomBottomMailAction:url];
}

@end
