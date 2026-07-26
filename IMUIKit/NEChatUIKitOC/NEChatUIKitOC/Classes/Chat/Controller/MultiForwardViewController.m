// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MultiForwardViewController.h"
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/NERouterUrl.h>
#import <NIMSDK/NIMSDK.h>
#import <objc/runtime.h>
#import "ChatUIConfig.h"
#import "NEChatUIKitClient.h"
#import "NEBaseChatMessageCell.h"
#import "NEBaseChatMessageTipCell.h"
#import "MessageTipsModel.h"
#import "MessageContentModel.h"
#import "MessageVideoModel.h"
#import "MessageLocationModel.h"
#import "NEChatBaseCell.h"
#import "ChatMessageHelper.h"
#import "ChatNavigationView.h"
#import <NEChatKit/NEPathUtils.h>
#import <NEChatKit/NECustomUtils.h>
#import <NECommonUIKitOC/NEWKWebViewController.h>
#import <NECommonUIKitOC/VideoPlayerViewController.h>
#import <NECommonUIKitOC/PhotoBrowserController.h>
#import "NEAudioSessionManager.h"
#import "NEChatUIConstant.h"
#import <NEChatKit/NEChatDetectNetworkTool.h>

@interface MultiForwardViewController ()
@property (nonatomic, copy) NSString *messageAttachmentUrl;
@property (nonatomic, copy) NSString *messageAttachmentFilePath;
@property (nonatomic, copy) NSString *messageAttachmentMD5;
@end

static Class NEMultiForwardResolveTableViewCellClass(id cellValue) {
    Class cellClass = Nil;
    if ([cellValue isKindOfClass:[NSString class]]) {
        cellClass = NSClassFromString((NSString *)cellValue);
    } else if (cellValue && object_isClass(cellValue)) {
        cellClass = (Class)cellValue;
    }

    if (cellClass && [cellClass isSubclassOfClass:[UITableViewCell class]]) {
        return cellClass;
    }
    return Nil;
}

@implementation MultiForwardViewController

- (instancetype)initWithAttachmentUrl:(NSString *)attachmentUrl
                   attachmentFilePath:(NSString *)attachmentFilePath
                        attachmentMD5:(NSString *)attachmentMD5 {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _messageAttachmentFilePath = attachmentFilePath ?: @"";
        _messageAttachmentUrl = attachmentUrl;
        _messageAttachmentMD5 = attachmentMD5;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    __weak typeof(self) weakSelf = self;
    [[NEChatDetectNetworkTool shareInstance] netWorkReachability:^(NEReachabilityStatus status) {
        if (status == NEReachabilityStatusNotReachable) {
            weakSelf.brokenNetworkView.hidden = NO;
        } else {
            weakSelf.brokenNetworkView.hidden = YES;
        }
    }];
}

- (void)backEvent {
    [super backEvent];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewModel.delegate = self;
    [self commonUI];
    [self loadData];
}

- (void)commonUI {
    self.title = chatLocalizable(@"chat_history");
    self.navigationView.backgroundColor = UIColor.whiteColor;
    self.navigationView.titleBarBottomLine.hidden = NO;
    self.navigationView.moreButton.hidden = YES;
    [self.navigationView addBackButtonTarget:self selector:@selector(backEvent)];
    self.view.backgroundColor = UIColor.whiteColor;

    [self.tableView registerClass:[NEBaseChatMessageCell class]
           forCellReuseIdentifier:NSStringFromClass([NEBaseChatMessageCell class])];

    if (![self.cellRegisterDic isKindOfClass:[NSMutableDictionary class]]) {
        self.cellRegisterDic = [self.cellRegisterDic mutableCopy] ?: [NSMutableDictionary dictionary];
    }

    NSDictionary *customCells = [[NEChatUIKitClient instance] getRegisterCustomCell];
    for (NSString *key in customCells) {
        self.cellRegisterDic[key] = customCells[key];
    }

    for (NSString *key in [self.cellRegisterDic allKeys]) {
        Class cellClass = NEMultiForwardResolveTableViewCellClass(self.cellRegisterDic[key]);
        if (cellClass) {
            [self.tableView registerClass:cellClass forCellReuseIdentifier:key];
        } else {
            [self.cellRegisterDic removeObjectForKey:key];
        }
    }

    [self.view addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
        [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];

    [self.view addSubview:self.brokenNetworkView];
    [NSLayoutConstraint activateConstraints:@[
        [self.brokenNetworkView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
        [self.brokenNetworkView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.brokenNetworkView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.brokenNetworkView.heightAnchor constraintEqualToConstant:self.brokenNetworkViewHeight],
    ]];
}

- (void)loadData {
    [self.view neMakeToastActivity:NEToastPositionCenter];
    __weak typeof(self) weakSelf = self;
    [self.viewModel loadData:self.messageAttachmentUrl
                    filePath:self.messageAttachmentFilePath
                         md5:self.messageAttachmentMD5
                  completion:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.view neHideToastActivity];
            if (error) {
                NSError *err = (NSError *)error;
                if (err.code == 0 && err.domain.length > 0) {
                    [weakSelf.view ne_makeToast:err.domain];
                } else {
                    [weakSelf.view ne_makeToast:chatLocalizable(@"multiForward_open_failed")];
                }
                [weakSelf.navigationController popViewControllerAnimated:YES];
            } else {
                [weakSelf.tableView reloadData];
            }
        });
    }];
}

- (void)showErrorToast:(NSError *)error {
    if (error) {
        if (error.code == protocolSendFailed || error.code == -1009) {
            [self.view ne_makeToast:commonLocalizable(@"network_error")];
        } else {
            [self.view ne_makeToast:error.localizedDescription];
        }
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self;
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.messages.count) {
        return [[UITableViewCell alloc] init];
    }
    id<MessageModel> model = self.viewModel.messages[indexPath.row];
    if (![(id)model conformsToProtocol:@protocol(MessageModel)]) {
        return [[UITableViewCell alloc] init];
    }
    if (!model.inMultiForward) {
        model.inMultiForward = YES;
    }
    model.isPined = NO;

    NSString *reuseId = @"";
    NSString *key = [NSString stringWithFormat:@"%ld", (long)model.type];

    if (model.type == MessageTypeCustom) {
        NSInteger customType = model.customType;
        if (customType == customMultiForwardType) {
            reuseId = [NSString stringWithFormat:@"%ld", (long)MessageTypeMultiForward];
        } else if (customType == customRichTextType) {
            reuseId = [NSString stringWithFormat:@"%ld", (long)MessageTypeRichText];
        } else if ([[NEChatUIKitClient instance] getRegisterCustomCell][[NSString stringWithFormat:@"%ld", customType]] != nil) {
            reuseId = [NSString stringWithFormat:@"%ld", customType];
        } else {
            reuseId = NSStringFromClass([NEBaseChatMessageCell class]);
        }
    } else if (model.type == MessageTypeNotification || model.type == MessageTypeTip) {
        reuseId = [NSString stringWithFormat:@"%ld", (long)MessageTypeTime];
    } else if (self.cellRegisterDic[key] != nil) {
        reuseId = key;
    } else {
        reuseId = NSStringFromClass([NEBaseChatMessageCell class]);
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId forIndexPath:indexPath];
    if ([cell isKindOfClass:[NEBaseChatMessageTipCell class]]) {
        NEBaseChatMessageTipCell *tipCell = (NEBaseChatMessageTipCell *)cell;
        if ([model isKindOfClass:[MessageTipsModel class]]) {
            [tipCell setModel:(MessageTipsModel *)model];
        }
        return tipCell;
    } else if ([cell isKindOfClass:[NEBaseChatMessageCell class]]) {
        NEBaseChatMessageCell *msgCell = (NEBaseChatMessageCell *)cell;
        if ([model isKindOfClass:[MessageContentModel class]]) {
            MessageContentModel *contentModel = (MessageContentModel *)model;
            msgCell.singleLeft = YES;
            [msgCell setModel:contentModel isSend:NO];
            [msgCell setSelect:contentModel enableSelect:NO];
            msgCell.delegate = self;
        }
        return msgCell;
    } else if ([cell isKindOfClass:[NEChatBaseCell class]] && [model isKindOfClass:[MessageContentModel class]]) {
        NEChatBaseCell *baseCell = (NEChatBaseCell *)cell;
        [baseCell setModel:(MessageContentModel *)model isSend:NO];
        return cell;
    } else {
        return [[NEBaseChatMessageCell alloc] init];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.messages.count) {
        return 0;
    }
    id<MessageModel> model = self.viewModel.messages[indexPath.row];
    if (![(id)model conformsToProtocol:@protocol(MessageModel)]) {
        return 0;
    }
    return [model cellHeight] + chat_content_margin;
}

- (MultiForwardViewController *)getMultiForwardViewController:(NSString *)messageAttachmentUrl
                                                     filePath:(NSString *)messageAttachmentFilePath
                                                          md5:(NSString *)messageAttachmentMD5 {
    return [[MultiForwardViewController alloc] initWithAttachmentUrl:messageAttachmentUrl
                                                  attachmentFilePath:messageAttachmentFilePath
                                                       attachmentMD5:messageAttachmentMD5];
}

#pragma mark - ChatBaseCellDelegate

- (void)didTapMessageView:(UITableViewCell *)cell
                    model:(MessageContentModel *)model
               replyModel:(id<MessageModel> )replyModel {
    if ([ChatUIConfig shared].messageItemClick) {
        [ChatUIConfig shared].messageItemClick(self, cell, model);
        return;
    }
    if (model.isRevoked) {
        return;
    }
    [self didTapMessage:cell model:model replyIndex:-1];
}

- (void)didTapMessage:(UITableViewCell *)cell
                model:(MessageContentModel *)model
           replyIndex:(NSInteger)replyIndex {
    if (model.type == MessageTypeImage) {
        if (![model.message.attachment isKindOfClass:[V2NIMMessageImageAttachment class]]) return;
        V2NIMMessageImageAttachment *imageObject = (V2NIMMessageImageAttachment *)model.message.attachment;
        if (imageObject) {
            NSString *imageUrl = @"";
            if (imageObject.url) {
                imageUrl = imageObject.url;
            } else if (imageObject.path && [[NSFileManager defaultManager] fileExistsAtPath:imageObject.path]) {
                imageUrl = imageObject.path;
            }
            if (imageUrl.length > 0) {
                NSInteger currenIndex = 0;
                NSArray<NSString *> *showImages = [ChatMessageHelper getUrls:model
                                                                    messages:(NSArray<MessageContentModel *> *)self.viewModel.messages
                                                                 currentIndex:&currenIndex];
                PhotoBrowserController *showController = [[PhotoBrowserController alloc] initWithUrls:showImages url:imageUrl currenIndex:currenIndex];
                showController.modalPresentationStyle = UIModalPresentationOverFullScreen;
                [self presentViewController:showController animated:NO completion:nil];
            }
        }
    } else if (model.type == MessageTypeVideo) {
        if (![model.message.attachment isKindOfClass:[V2NIMMessageVideoAttachment class]]) return;
        V2NIMMessageVideoAttachment *object = (V2NIMMessageVideoAttachment *)model.message.attachment;
        if (object) {
            [NEAudioSessionManager.shared switchToSpeaker];
            [NEAudioSessionManager.shared stopProximityMonitoring];
            NSString *path = object.path ?: [ChatMessageHelper createFilePath:model.message];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                NSURL *url = [NSURL fileURLWithPath:path];
                VideoPlayerViewController *videoPlayer = [[VideoPlayerViewController alloc] init];
                videoPlayer.modalPresentationStyle = UIModalPresentationOverFullScreen;
                videoPlayer.videoUrl = url;
                videoPlayer.totalTime = (NSInteger)object.duration;
                [self presentViewController:videoPlayer animated:YES completion:nil];
            } else {
                if (replyIndex >= 0 && replyIndex < [self.tableView numberOfRowsInSection:0]) {
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:replyIndex inSection:0]
                                         atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                }
                [self downloadFileWithCell:cell model:model url:object.url path:path];
            }
        }
    } else if (model.type == MessageTypeLocation) {
        if ([model isKindOfClass:[MessageLocationModel class]]) {
            MessageLocationModel *locationModel = (MessageLocationModel *)model;
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            params[@"type"] = @(NEMapTypeDetail);
            params[@"nav"] = self.navigationController;
            params[@"lat"] = locationModel.lat;
            params[@"lng"] = locationModel.lng;
            params[@"locationTitle"] = locationModel.title;
            params[@"subTitle"] = locationModel.subTitle;
            [Router.shared use:NERouterUrl.LocationVCRouter parameters:params closure:nil];
        }
    } else if (model.type == MessageTypeFile) {
        if (![model.message.attachment isKindOfClass:[V2NIMMessageFileAttachment class]]) return;
        V2NIMMessageFileAttachment *object = (V2NIMMessageFileAttachment *)model.message.attachment;
        if (object) {
            NSString *path = object.path ?: [ChatMessageHelper createFilePath:model.message];
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                if (replyIndex >= 0 && replyIndex < [self.tableView numberOfRowsInSection:0]) {
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:replyIndex inSection:0]
                                         atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                }
                [self downloadFileWithCell:cell model:model url:object.url path:path];
            } else {
                NSURL *url = [NSURL fileURLWithPath:path];
                self.interactionController.URL = url;
                self.interactionController.delegate = self;
                if (![self.interactionController presentPreviewAnimated:YES]) {
                    [self.interactionController presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
                }
            }
        }
    } else if (model.type == MessageTypeCustom) {
        if (model.customType == customMultiForwardType) {
            NSDictionary *data = [NECustomUtils dataOfCustomMessage:model.message.attachment];
            if (data) {
                NSString *url = data[@"url"];
                NSString *md5 = data[@"md5"];
                NSString *fileDirectory = [NEPathUtils getDirectoryForDocuments:imkitDir];
                if (!fileDirectory) return;
                NSString *fileName = [multiForwardFileName stringByAppendingString:model.message.messageClientId ?: @""];
                NSString *filePath = [fileDirectory stringByAppendingString:fileName];
                MultiForwardViewController *multiForwardVC = [self getMultiForwardViewController:url filePath:filePath md5:md5];
                [self.navigationController pushViewController:multiForwardVC animated:YES];
            }
        }
    }
}

- (void)downloadFileWithCell:(UITableViewCell *)cell
                       model:(MessageContentModel *)model
                         url:(NSString *)url
                        path:(NSString *)path {
    if (!url || ![model isKindOfClass:[MessageVideoModel class]]) {
        [NEALog infoLog:NSStringFromClass([self class]) desc:@"MessageFileModel not exit"];
        return;
    }
    MessageVideoModel *fileModel = (MessageVideoModel *)model;
    if (fileModel.state == DownloadStateDownalod) {
        [NEALog infoLog:NSStringFromClass([self class]) desc:@"downLoad state, click ingore"];
        return;
    }
    fileModel.state = DownloadStateDownalod;
    if ([cell isKindOfClass:[NEBaseChatMessageCell class]]) {
        [(NEBaseChatMessageCell *)cell setModel:fileModel isSend:NO];
    }

    __weak typeof(self) weakSelf = self;
    [self.viewModel downLoad:url filePath:path progress:^(NSUInteger progress) {
        fileModel.progress = progress;
        [fileModel.cell uploadProgress:progress];
    } completion:^(NSString *localPath, NSError *error) {
        [weakSelf showErrorToast:error];
        if (localPath) {
            fileModel.state = DownloadStateSuccess;
        }
    }];
}

- (void)didTapDetectedLink:(UITableViewCell *)cell model:(MessageContentModel *)model url:(NSURL *)url {
    if ([url.scheme isEqualToString:@"mailto"]) {
        [self didTapMailto:url];
    } else if ([url.scheme isEqualToString:@"tel"]) {
        [self didTapTel:url];
    } else {
        NEWKWebViewController *ctrl = [[NEWKWebViewController alloc] initWithUrl:url.absoluteString title:url.absoluteString];
        [self.navigationController pushViewController:ctrl animated:YES];
    }
}

- (void)didTapTel:(NSURL *)url {
    [self showBottomTelAction:url];
}

- (void)didTapMailto:(NSURL *)url {
    [self showBottomMailAction:url];
}

- (void)didTapAvatarView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didLongPressAvatar:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didLongPressMessageView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapResendView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapReeditButton:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapReadView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapSelectButton:(UITableViewCell *)cell model:(MessageContentModel *)model {}

#pragma mark - Lazy Properties

- (MultiForwardViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[MultiForwardViewModel alloc] init];
    }
    return _viewModel;
}

- (NSMutableDictionary *)cellRegisterDic {
    if (!_cellRegisterDic) {
        _cellRegisterDic = [NSMutableDictionary dictionary];
    }
    return _cellRegisterDic;
}

- (CGFloat)brokenNetworkViewHeight {
    if (_brokenNetworkViewHeight == 0) {
        _brokenNetworkViewHeight = 36;
    }
    return _brokenNetworkViewHeight;
}

- (UIDocumentInteractionController *)interactionController {
    if (!_interactionController) {
        _interactionController = [[UIDocumentInteractionController alloc] init];
    }
    return _interactionController;
}

- (NEBrokenNetworkView *)brokenNetworkView {
    if (!_brokenNetworkView) {
        _brokenNetworkView = [[NEBrokenNetworkView alloc] init];
        _brokenNetworkView.translatesAutoresizingMaskIntoConstraints = NO;
        _brokenNetworkView.hidden = YES;
    }
    return _brokenNetworkView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = UIColor.clearColor;
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0.0;
        }
    }
    return _tableView;
}

@end
