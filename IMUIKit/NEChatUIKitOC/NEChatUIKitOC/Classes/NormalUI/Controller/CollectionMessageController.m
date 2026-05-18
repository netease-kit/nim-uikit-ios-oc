// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CollectionMessageController.h"
#import "ForwardAlertViewController.h"
#import "NormalMultiForwardViewController.h"
#import "ChatMessageHelper.h"

@implementation CollectionMessageController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.ne_lightBackgroundColor;
    self.navigationView.backgroundColor = UIColor.ne_lightBackgroundColor;
    self.navigationController.navigationBar.backgroundColor = UIColor.ne_lightBackgroundColor;
}

- (NSDictionary<NSString *, Class> *)getRegisterDic {
    return [ChatMessageHelper getCollectionCellRegisterDic:NO];
}

- (NEBaseForwardAlertViewController *)getCollectionForwardAlertController {
    return [[ForwardAlertViewController alloc] init];
}

- (MultiForwardViewController *)getMultiForwardViewController:(NSString *)messageAttachmentUrl
                                                     filePath:(NSString *)messageAttachmentFilePath
                                                          md5:(NSString *)messageAttachmentMD5 {
    return [[NormalMultiForwardViewController alloc] initWithAttachmentUrl:messageAttachmentUrl
                                                     attachmentFilePath:messageAttachmentFilePath
                                                          attachmentMD5:messageAttachmentMD5];
}

@end
