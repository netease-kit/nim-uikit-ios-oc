// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NEChatBaseViewController.h"
#import "CollectionMessageViewModel.h"
#import "NEBaseCollectionMessageCell.h"
#import "CollectionMessageModel.h"
#import "CollectionFileModel.h"
#import "NEBaseForwardAlertViewController.h"

@class TextViewController;
@class MultiForwardViewController;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseCollectionMessageController : NEChatBaseViewController
    <UITableViewDelegate,
     UITableViewDataSource,
     CollectionMessageCellDelegate,
     UIDocumentInteractionControllerDelegate,
     AVAudioPlayerDelegate>

@property (nonatomic, strong, nullable) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentTableTopAnchor;
@property (nonatomic, strong) UITableView *contentTable;
@property (nonatomic, strong) NEEmptyDataView *collectionEmptyView;
@property (nonatomic, strong) CollectionMessageViewModel *viewModel;
@property (nonatomic, assign) CGFloat collection_content_maxW;
@property (nonatomic, strong) UIDocumentInteractionController *interactionController;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *cellClassDic;

- (void)loadMoreData;
- (NSDictionary<NSString *, Class> *)getRegisterDic;
- (void)setupUI;
- (void)removeCollectionActionClicked:(CollectionMessageModel *)model;
- (void)didRemoveCollectionActionClicked:(CollectionMessageModel *)model;
- (void)copyCollectionActionClicked:(CollectionMessageModel *)model;
- (void)forwardCollectionMessage:(V2NIMMessage *)message conversationName:(NSString *)conversationName;
- (void)showForwardAlertController:(NSArray<ForwardItem *> *)items
                              type:(NSString *)type
                    conversationId:(nullable NSString *)conversationId
                  conversationName:(nullable NSString *)conversationName
                         sureBlock:(nullable void (^)(NSString *_Nullable comment))sureBlock;
- (void)showActions:(CollectionMessageModel *)model;
- (void)didClickMore:(nullable CollectionMessageModel *)model;
- (void)showImageView:(nullable CollectionMessageModel *)model;
- (void)showVideoView:(nullable CollectionMessageModel *)model;
- (void)showMapDetail:(nullable CollectionMessageModel *)model;
- (void)showFileDetail:(nullable CollectionMessageModel *)model;
- (void)downloadFile:(CollectionFileModel *)fileModel urlString:(NSString *)urlString path:(NSString *)path;
- (void)showTextView:(nullable CollectionMessageModel *)model;
- (void)didClickContent:(nullable CollectionMessageModel *)model cell:(NEBaseCollectionMessageCell *)cell;
- (void)didTapTel:(NSURL *)url;
- (void)didTapMailto:(NSURL *)url;
- (void)showTextViewController:(nullable CollectionMessageModel *)model;
- (TextViewController *)getTextViewController:(nullable NSString *)title body:(nullable NSAttributedString *)body;
- (MultiForwardViewController *)getMultiForwardViewController:(nullable NSString *)messageAttachmentUrl
                                                     filePath:(NSString *)messageAttachmentFilePath
                                                          md5:(nullable NSString *)messageAttachmentMD5;
- (NEBaseForwardAlertViewController *)getCollectionForwardAlertController;

@end

NS_ASSUME_NONNULL_END
