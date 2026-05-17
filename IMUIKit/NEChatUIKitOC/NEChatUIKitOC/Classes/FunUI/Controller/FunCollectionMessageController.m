// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunCollectionMessageController.h"
#import "FunForwardAlertViewController.h"
#import "FunMultiForwardViewController.h"
#import "FunTextViewController.h"
#import "ChatMessageHelper.h"
#import "FunChatUIColor.h"

@implementation FunCollectionMessageController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.collection_content_maxW = (kScreenWidth() - 32);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
    [self.collectionEmptyView setEmptyImageWithName:@"fun_user_empty"];
}

- (NSDictionary<NSString *, Class> *)getRegisterDic {
    return [ChatMessageHelper getCollectionCellRegisterDic:YES];
}

- (void)showActions:(CollectionMessageModel *)model {
    NSMutableArray<NECustomAlertAction *> *actions = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;

    NECustomAlertAction *deleteCollectionAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"operation_delete_collection") handler:^{
        [weakSelf removeCollectionActionClicked:model];
    }];
    [actions addObject:deleteCollectionAction];

    if (model.message.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
        NECustomAlertAction *copyAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"operation_copy") handler:^{
            [weakSelf copyCollectionActionClicked:model];
        }];
        [actions addObject:copyAction];
    }

    if (model.message && model.message.messageType != V2NIM_MESSAGE_TYPE_AUDIO) {
        NECustomAlertAction *forwardAction = [NECustomAlertAction actionWithTitle:chatLocalizable(@"operation_forward") handler:^{
            [weakSelf forwardCollectionMessage:model.message conversationName:model.conversationName ?: @""];
        }];
        [actions addObject:forwardAction];
    }

    [self showCustomActionSheet:actions];
}

- (NEBaseForwardAlertViewController *)getCollectionForwardAlertController {
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
