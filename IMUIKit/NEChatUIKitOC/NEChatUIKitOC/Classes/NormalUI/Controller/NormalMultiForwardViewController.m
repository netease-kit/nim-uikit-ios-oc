// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NormalMultiForwardViewController.h"
#import "ChatMessageHelper.h"
#import "ChatNavigationView.h"

@implementation NormalMultiForwardViewController

- (instancetype)initWithAttachmentUrl:(NSString *)attachmentUrl
                   attachmentFilePath:(NSString *)attachmentFilePath
                        attachmentMD5:(NSString *)attachmentMD5 {
    self = [super initWithAttachmentUrl:attachmentUrl attachmentFilePath:attachmentFilePath attachmentMD5:attachmentMD5];
    if (self) {
        self.cellRegisterDic = [[ChatMessageHelper getChatCellRegisterDic:NO] mutableCopy];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationView.backgroundColor = UIColor.whiteColor;
    self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
}

- (MultiForwardViewController *)getMultiForwardViewController:(NSString *)messageAttachmentUrl
                                                     filePath:(NSString *)messageAttachmentFilePath
                                                          md5:(NSString *)messageAttachmentMD5 {
    return [[NormalMultiForwardViewController alloc] initWithAttachmentUrl:messageAttachmentUrl
                                                     attachmentFilePath:messageAttachmentFilePath
                                                          attachmentMD5:messageAttachmentMD5];
}

@end
