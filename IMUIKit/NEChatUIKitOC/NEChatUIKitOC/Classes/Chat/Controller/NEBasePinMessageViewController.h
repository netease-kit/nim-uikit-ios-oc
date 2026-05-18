// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NEChatBaseViewController.h"
#import "PinMessageViewModel.h"
#import "NEPinMessageModel.h"
#import "NEBasePinMessageCell.h"
#import "PinMessageFileModel.h"

@class TextViewController;
@class MultiForwardViewController;
@class ForwardItem;
@class NEBaseForwardAlertViewController;

NS_ASSUME_NONNULL_BEGIN

extern const NSInteger PinMessageDefaultType;

@interface NEBasePinMessageViewController : NEChatBaseViewController
    <UITableViewDataSource,
     UITableViewDelegate,
     PinMessageViewModelDelegate,
     PinMessageCellDelegate,
     UIDocumentInteractionControllerDelegate,
     NEIMKitClientListener,
     NEChatListener,
     AVAudioPlayerDelegate>

@property (nonatomic, strong) PinMessageViewModel *viewModel;
@property (nonatomic, strong, nullable) AVAudioPlayer *audioPlayer;
@property (nonatomic, copy, nullable) NSString *conversationId;
@property (nonatomic, strong) NSMutableArray<V2NIMMessage *> *onReceiveNewMsgs;
@property (nonatomic, assign) CGFloat pin_content_maxW;
@property (nonatomic, assign) BOOL networkBroken;
@property (nonatomic, assign) BOOL isLoadingData;
@property (nonatomic, strong, nullable) NSLayoutConstraint *tableViewTopAnchor;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIDocumentInteractionController *interactionController;

- (instancetype)initWithConversationId:(NSString *)conversationId;
- (void)loadData;
- (void)setupUI;
- (void)cancelPinActionClicked:(NEPinMessageModel *)item;
- (void)copyActionClicked:(NEPinMessageModel *)item;
- (void)forwardActionClicked:(NEPinMessageModel *)item;
- (void)showAction:(NEPinMessageModel *)item;
- (NEBaseForwardAlertViewController *)getForwardAlertController;
- (void)addForwardAlertController:(NSArray<ForwardItem *> *)items type:(NSString *)type sureBlock:(nullable void (^)(NSString *_Nullable comment))sureBlock;
- (void)forwardMessage:(V2NIMMessage *)message;
- (void)tableViewReload:(BOOL)needLoad;
- (void)didClickMore:(nullable NEPinMessageModel *)model;
- (void)toImageView:(nullable NEPinMessageModel *)model;
- (void)toVideoView:(nullable NEPinMessageModel *)model;
- (void)toMapDetail:(nullable NEPinMessageModel *)model;
- (void)toFileDetail:(nullable NEPinMessageModel *)model;
- (void)downloadFile:(PinMessageFileModel *)fileModel urlString:(NSString *)urlString path:(NSString *)path;
- (void)toTextViewShow:(nullable NEPinMessageModel *)model;
- (void)didClickContent:(nullable NEPinMessageModel *)model cell:(NEBasePinMessageCell *)cell;
- (void)didTapTel:(NSURL *)url;
- (void)didTapMailto:(NSURL *)url;
- (void)didPlay:(nullable NEBasePinMessageCell *)cell model:(nullable NEPinMessageModel *)model;
- (void)startPlay:(nullable NEBasePinMessageCell *)cell model:(nullable NEPinMessageModel *)model;
- (NSDictionary<NSString *, Class> *)getRegisterCellDic;
- (void)showTextViewController:(nullable NEPinMessageModel *)model;
- (TextViewController *)getTextViewController:(nullable NSString *)title body:(nullable NSAttributedString *)body;
- (MultiForwardViewController *)getMultiForwardViewController:(nullable NSString *)messageAttachmentUrl
                                                     filePath:(NSString *)messageAttachmentFilePath
                                                          md5:(nullable NSString *)messageAttachmentMD5;

@end

NS_ASSUME_NONNULL_END
