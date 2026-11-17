// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEBrokenNetworkView.h>
#import "NEChatBaseViewController.h"
#import "NEBaseChatMessageCell.h"
#import "MultiForwardViewModel.h"

@class MessageContentModel;

NS_ASSUME_NONNULL_BEGIN

@interface MultiForwardViewController : NEChatBaseViewController
    <UINavigationControllerDelegate,
     UITableViewDataSource,
     UITableViewDelegate,
     ChatBaseCellDelegate,
     UIDocumentInteractionControllerDelegate,
     MultiForwardViewModelDelegate>

@property (nonatomic, strong) MultiForwardViewModel *viewModel;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *cellRegisterDic;
@property (nonatomic, assign) CGFloat brokenNetworkViewHeight;
@property (nonatomic, strong) UIDocumentInteractionController *interactionController;
@property (nonatomic, strong) NEBrokenNetworkView *brokenNetworkView;
@property (nonatomic, strong) UITableView *tableView;

- (instancetype)initWithAttachmentUrl:(nullable NSString *)attachmentUrl
                   attachmentFilePath:(NSString *)attachmentFilePath
                        attachmentMD5:(nullable NSString *)attachmentMD5;

- (void)commonUI;
- (void)loadData;
- (void)showErrorToast:(nullable NSError *)error;
- (MultiForwardViewController *)getMultiForwardViewController:(nullable NSString *)messageAttachmentUrl
                                                     filePath:(NSString *)messageAttachmentFilePath
                                                          md5:(nullable NSString *)messageAttachmentMD5;
- (void)didTapMessage:(nullable UITableViewCell *)cell
                model:(nullable MessageContentModel *)model
           replyIndex:(NSInteger)replyIndex;

@end

NS_ASSUME_NONNULL_END
