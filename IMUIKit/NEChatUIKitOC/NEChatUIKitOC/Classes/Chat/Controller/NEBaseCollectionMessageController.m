// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseCollectionMessageController.h"
#import <NEChatKit/NEChatKitOC.h>

#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/NERouterUrl.h>
#import <NIMSDK/NIMSDK.h>
#import <MJRefresh/MJRefresh.h>
#import "ChatMessageHelper.h"
#import <NEChatKit/NEPathUtils.h>
#import <NEChatKit/NECustomUtils.h>
#import <NECommonUIKitOC/NEWKWebViewController.h>
#import <NECommonUIKitOC/VideoPlayerViewController.h>
#import <NECommonUIKitOC/PhotoBrowserController.h>
#import "NEAudioSessionManager.h"
#import "NEChatUIConstant.h"
#import "NEChatUIKitClient.h"
#import "TextViewController.h"
#import "MultiForwardViewController.h"
#import "NEBaseForwardAlertViewController.h"
#import "MessageTextModel.h"
#import "MessageAudioModel.h"
#import "MessageVideoModel.h"
#import "MessageLocationModel.h"
#import "NEBaseCollectionMessageAudioCell.h"
#import "NEBaseCollectionDefaultCell.h"
#import "ChatNavigationView.h"
#import "UIImage+Chat.h"
#import <objc/runtime.h>

@interface NEBaseCollectionMessageController ()
@property (nonatomic, strong) NEBaseCollectionMessageAudioCell *playingCell;
@property (nonatomic, strong) MessageAudioModel *playingModel;
@end

static NSString * const NECollectionForwardMultiSelectedRouter = @"imkit://contact/tab/selector.result";
static NSString * const NECollectionForwardMultiSelectRouter = @"imkit://contact/tab/selector.page";

static Class NECollectionResolveTableViewCellClass(id cellValue) {
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

@implementation NEBaseCollectionMessageController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.contentTableTopAnchor.constant = self.topConstant;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self stopPlay];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadMoreData];
}

- (void)loadMoreData {
    __weak typeof(self) weakSelf = self;
    [self.viewModel loadData:^(NSError * _Nullable error, BOOL finished) {
        if (error) {
            [weakSelf.view ne_makeToast:error.localizedDescription];
            [weakSelf.contentTable.mj_footer endRefreshing];
        } else {
            if (weakSelf.viewModel.collectionDatas.count <= 0) {
                weakSelf.collectionEmptyView.hidden = NO;
            }
            [weakSelf.contentTable reloadData];
            if (!finished) {
                [weakSelf.contentTable.mj_footer endRefreshing];
            } else {
                [weakSelf.contentTable.mj_footer endRefreshingWithNoMoreData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.contentTable.mj_footer = nil;
                });
            }
        }
    }];
}

- (NSDictionary<NSString *, Class> *)getRegisterDic {
    return self.cellClassDic ?: @{};
}

- (void)setupUI {
    self.title = chatLocalizable(@"operation_collection");
    self.navigationView.moreButton.hidden = YES;

    [self.view addSubview:self.contentTable];
    self.contentTableTopAnchor = [self.contentTable.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
    self.contentTableTopAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentTable.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.contentTable.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.contentTable.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self.view addSubview:self.collectionEmptyView];
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionEmptyView.topAnchor constraintEqualToAnchor:self.contentTable.topAnchor],
        [self.collectionEmptyView.leftAnchor constraintEqualToAnchor:self.contentTable.leftAnchor],
        [self.collectionEmptyView.rightAnchor constraintEqualToAnchor:self.contentTable.rightAnchor],
        [self.collectionEmptyView.bottomAnchor constraintEqualToAnchor:self.contentTable.bottomAnchor],
    ]];

    NSDictionary *registerDic = [self getRegisterDic];
    if (!_cellClassDic) _cellClassDic = [NSMutableDictionary dictionary];
    [_cellClassDic addEntriesFromDictionary:registerDic];

    [self.contentTable registerClass:[NEBaseCollectionMessageCell class]
              forCellReuseIdentifier:NSStringFromClass([NEBaseCollectionMessageCell class])];
    for (NSString *key in [_cellClassDic allKeys]) {
        Class cellClass = NECollectionResolveTableViewCellClass(_cellClassDic[key]);
        if (cellClass) {
            _cellClassDic[key] = cellClass;
            [self.contentTable registerClass:cellClass forCellReuseIdentifier:key];
        } else {
            [_cellClassDic removeObjectForKey:key];
        }
    }
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.collectionDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.collectionDatas.count) {
        return [[UITableViewCell alloc] init];
    }
    CollectionMessageModel *model = self.viewModel.collectionDatas[indexPath.row];
    if (![model isKindOfClass:[CollectionMessageModel class]] || !model.chatmodel) {
        return [[UITableViewCell alloc] init];
    }
    NSString *reuseId = [NSString stringWithFormat:@"%ld", (long)model.chatmodel.type];
    if (model.chatmodel.type == MessageTypeCustom) {
        NSInteger customType = model.chatmodel.customType;
        if (customType == customMultiForwardType) {
            reuseId = [NSString stringWithFormat:@"%ld", (long)MessageTypeMultiForward];
        } else if (customType == customRichTextType) {
            reuseId = [NSString stringWithFormat:@"%ld", (long)MessageTypeRichText];
        } else {
            reuseId = NSStringFromClass([NEBaseCollectionDefaultCell class]);
        }
    } else if (_cellClassDic[reuseId] == nil || model.chatmodel.message == nil) {
        reuseId = NSStringFromClass([NEBaseCollectionDefaultCell class]);
    }
    NEBaseCollectionMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId forIndexPath:indexPath];
    cell.delegate = self;
    [cell configureData:model];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat defaultHeight = 143.0;
    if (indexPath.row >= self.viewModel.collectionDatas.count) {
        return 0;
    }
    CollectionMessageModel *model = self.viewModel.collectionDatas[indexPath.row];
    if (![model isKindOfClass:[CollectionMessageModel class]] || !model.chatmodel) {
        return defaultHeight;
    }
    if (model.message == nil) {
        return defaultHeight;
    }
    if (model.chatmodel.type == MessageTypeCustom) {
        if (model.chatmodel.customType == customMultiForwardType) {
            return [model cellHeight:self.collection_content_maxW] - 30;
        } else if (model.chatmodel.customType != customRichTextType) {
            return defaultHeight;
        }
    }
    return [model cellHeight:self.collection_content_maxW];
}

- (void)removeCollectionActionClicked:(CollectionMessageModel *)model {
    __weak typeof(self) weakSelf = self;
    [self showSingleAlert:chatLocalizable(@"collection_delete_confirm") message:nil handler:^{
        [weakSelf didRemoveCollectionActionClicked:model];
    }];
}

- (void)didRemoveCollectionActionClicked:(CollectionMessageModel *)model {
    __weak typeof(self) weakSelf = self;
    if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
        [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
        return;
    }
    if (!model.collection) return;
    [weakSelf.viewModel removeCollection:model.collection completion:^(NSError * _Nullable error) {
        if (error) {
            [weakSelf.view ne_makeToast:commonLocalizable(@"failed_operation")];
        } else {
            [weakSelf.viewModel.collectionDatas removeObjectsAtIndexes:
             [weakSelf.viewModel.collectionDatas indexesOfObjectsPassingTest:^BOOL(CollectionMessageModel *obj, NSUInteger idx, BOOL *stop) {
                return [obj.collection.collectionId isEqualToString:model.collection.collectionId];
            }]];
            if (weakSelf.viewModel.collectionDatas.count <= 0) {
                weakSelf.collectionEmptyView.hidden = NO;
            }
            [weakSelf.view ne_makeToast:chatLocalizable(@"delete_collection_success")];
            [weakSelf.contentTable reloadData];
            if (weakSelf.viewModel.collectionDatas.count < weakSelf.viewModel.pageSize && weakSelf.contentTable.mj_footer != nil) {
                [weakSelf loadMoreData];
            }
        }
    }];
}

- (void)copyCollectionActionClicked:(CollectionMessageModel *)model {
    if (!model.message.text) return;
    [UIPasteboard generalPasteboard].string = model.message.text;
    [self.view ne_makeToast:commonLocalizable(@"copy_success")];
}

- (void)forwardCollectionMessage:(V2NIMMessage *)message conversationName:(NSString *)conversationName {
    __weak typeof(self) weakSelf = self;
    [Router.shared register:NECollectionForwardMultiSelectedRouter closure:^(NSDictionary * _Nonnull param) {
        NSMutableArray<ForwardItem *> *items = [NSMutableArray array];
        NSArray *conversations = param[@"conversations"];
        if (![conversations isKindOfClass:[NSArray class]]) return;
        NSMutableArray<NSString *> *conversationIds = [NSMutableArray array];
        for (id conversationObj in conversations) {
            if (![conversationObj isKindOfClass:[NSDictionary class]]) continue;
            NSDictionary *conversation = (NSDictionary *)conversationObj;
            NSString *conversationId = conversation[@"conversationId"];
            if (conversationId) {
                [conversationIds addObject:conversationId];
                ForwardItem *item = [[ForwardItem alloc] init];
                item.conversationId = conversationId;
                item.name = conversation[@"name"];
                item.avatar = conversation[@"avatar"];
                [items addObject:item];
            }
        }
        NSString *type = chatLocalizable(@"operation_forward");
        [weakSelf showForwardAlertController:items type:type conversationId:message.conversationId conversationName:conversationName sureBlock:^(NSString * _Nullable comment) {
            if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
                [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
                return;
            }
            [weakSelf.viewModel forwardCollectionMessages:message conversationIds:conversationIds comment:comment completion:^(V2NIMSendMessageResult *result, NSError *error, NSUInteger pro) {
                // 转发失败不展示错误信息
            }];
        }];
    }];
    [Router.shared use:NECollectionForwardMultiSelectRouter parameters:@{@"nav": self.navigationController ?: [NSNull null], @"selctorMode": @0} closure:nil];
}

- (void)showForwardAlertController:(NSArray<ForwardItem *> *)items
                              type:(NSString *)type
                    conversationId:(NSString *)conversationId
                  conversationName:(NSString *)conversationName
                         sureBlock:(nullable void (^)(NSString *_Nullable comment))sureBlock {
    NEBaseForwardAlertViewController *forwardAlert = [self getCollectionForwardAlertController];
    [forwardAlert setItems:items];
    forwardAlert.forwardType = type;
    forwardAlert.sureBlock = sureBlock;
    if (conversationName) {
        forwardAlert.senderName = conversationName;
    }
    [self addChildViewController:forwardAlert];
    [self.view addSubview:forwardAlert.view];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow endEditing:YES];
    });
}

- (void)forwardCollectionActionClicked:(CollectionMessageModel *)model {
    if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
        [self.view ne_makeToast:commonLocalizable(@"network_error")];
        return;
    }
    if (model.message) {
        [self forwardCollectionMessage:model.message conversationName:model.conversationName ?: @""];
    }
}

- (void)showActions:(CollectionMessageModel *)model {
    if (!model.collection) return;
    NSMutableArray<UIAlertAction *> *actions = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:chatLocalizable(@"operation_delete_collection") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf removeCollectionActionClicked:model];
    }];
    [actions addObject:deleteAction];

    if (model.message && model.message.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
        UIAlertAction *copyAction = [UIAlertAction actionWithTitle:chatLocalizable(@"operation_copy") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf copyCollectionActionClicked:model];
        }];
        [actions addObject:copyAction];
    }

    if (model.message && model.message.messageType != V2NIM_MESSAGE_TYPE_AUDIO) {
        UIAlertAction *forwardAction = [UIAlertAction actionWithTitle:chatLocalizable(@"operation_forward") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf forwardCollectionActionClicked:model];
        }];
        [actions addObject:forwardAction];
    }

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel") style:UIAlertActionStyleCancel handler:nil];
    [actions addObject:cancelAction];
    [self showActionSheet:actions];
}

- (void)didClickMore:(CollectionMessageModel *)model {
    if (model) {
        [self showActions:model];
    }
}

- (void)showImageView:(CollectionMessageModel *)model {
    if (![model.message.attachment isKindOfClass:[V2NIMMessageImageAttachment class]]) return;
    V2NIMMessageImageAttachment *object = (V2NIMMessageImageAttachment *)model.message.attachment;
    if (object) {
        NSString *imageUrlString = @"";
        if (object.url) {
            imageUrlString = object.url;
        } else if (object.path && [[NSFileManager defaultManager] fileExistsAtPath:object.path]) {
            imageUrlString = object.path;
        }
        if (imageUrlString.length > 0) {
            PhotoBrowserController *showController = [[PhotoBrowserController alloc] initWithUrls:@[imageUrlString] url:imageUrlString];
            showController.modalPresentationStyle = UIModalPresentationOverFullScreen;
            [self presentViewController:showController animated:NO completion:nil];
        }
    }
}

- (void)showVideoView:(CollectionMessageModel *)model {
    if (![model.message.attachment isKindOfClass:[V2NIMMessageVideoAttachment class]]) return;
    V2NIMMessageVideoAttachment *object = (V2NIMMessageVideoAttachment *)model.message.attachment;
    if (object) {
        [self stopPlay];
        [NEAudioSessionManager.shared switchToSpeaker];
        [NEAudioSessionManager.shared stopProximityMonitoring];
        VideoPlayerViewController *player = [[VideoPlayerViewController alloc] init];
        player.totalTime = (NSInteger)object.duration;
        player.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.viewModel.lastClickAuidoMessageId = nil;
        NSString *path = object.path ?: [ChatMessageHelper createFilePath:model.message];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            player.videoUrl = [NSURL fileURLWithPath:path];
            [self presentViewController:player animated:YES completion:nil];
        } else if (object.url) {
            NSURL *remoteUrl = [NSURL URLWithString:object.url];
            if (remoteUrl) {
                player.videoUrl = remoteUrl;
                [self presentViewController:player animated:YES completion:nil];
            }
        }
    }
}

- (void)showMapDetail:(CollectionMessageModel *)model {
    if (model.message.text && [model.message.attachment isKindOfClass:[V2NIMMessageLocationAttachment class]]) {
        V2NIMMessageLocationAttachment *locationObject = (V2NIMMessageLocationAttachment *)model.message.attachment;
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"nav"] = self.navigationController;
        params[@"type"] = @(NEMapTypeDetail);
        params[@"locationTitle"] = model.message.text;
        params[@"subTitle"] = locationObject.address;
        params[@"lat"] = @(locationObject.latitude);
        params[@"lng"] = @(locationObject.longitude);
        [Router.shared use:NERouterUrl.LocationVCRouter parameters:params closure:nil];
    }
}

- (void)showFileDetail:(CollectionMessageModel *)model {
    if (![model.message.attachment isKindOfClass:[V2NIMMessageFileAttachment class]]) return;
    V2NIMMessageFileAttachment *object = (V2NIMMessageFileAttachment *)model.message.attachment;
    if (!object) return;
    if (![model.fileModel isKindOfClass:[CollectionFileModel class]]) {
        [NEALog infoLog:NSStringFromClass([self class]) desc:@"PinMessageFileModel not exit"];
        return;
    }
    CollectionFileModel *fileModel = (CollectionFileModel *)model.fileModel;
    if (fileModel.state == DownloadStateDownalod) {
        [NEALog infoLog:NSStringFromClass([self class]) desc:@"downLoad state, click ingore"];
        return;
    }
    NSString *path = object.path ?: [ChatMessageHelper createFilePath:model.message];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (object.url) {
            [self downloadFile:fileModel urlString:object.url path:path];
        }
    } else {
        NSURL *url = [NSURL fileURLWithPath:path];
        self.interactionController.URL = url;
        self.interactionController.delegate = self;
        if (![self.interactionController presentPreviewAnimated:YES]) {
            [self.interactionController presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
        }
    }
}

- (void)downloadFile:(CollectionFileModel *)fileModel urlString:(NSString *)urlString path:(NSString *)path {
    fileModel.state = DownloadStateDownalod;
    __weak typeof(self) weakSelf = self;
    [self.viewModel downloadFile:urlString filePath:path progress:^(NSUInteger progress) {
        fileModel.progress = progress / (NSUInteger)100;
        if ([fileModel.cell respondsToSelector:@selector(uploadProgress:)]) {
            [fileModel.cell performSelector:@selector(uploadProgress:) withObject:@(fileModel.progress)];
        }
    } completion:^(NSString *localPath, NSError *error) {
        if (error) {
            if (error.code == protocolSendFailed) {
                [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
            } else {
                NSLog(@"%@", error.localizedDescription);
            }
        } else if (localPath) {
            fileModel.state = DownloadStateSuccess;
        }
    }];
}

- (void)showTextView:(CollectionMessageModel *)model {
    if (!model.message || !model.chatmodel.customType) return;
    NSInteger customType = model.chatmodel.customType;
    if (customType == customRichTextType) {
        [self showTextViewController:model];
    } else if (customType == customMultiForwardType) {
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

- (void)didClickContent:(CollectionMessageModel *)model cell:(NEBaseCollectionMessageCell *)cell {
    [NEALog infoLog:NSStringFromClass([self class]) desc:@"didClickContent"];
    if (!model.message) return;
    V2NIMMessageType type = model.message.messageType;
    if (type == V2NIM_MESSAGE_TYPE_AUDIO) {
        [self didPlay:cell model:model];
    } else if (type == V2NIM_MESSAGE_TYPE_IMAGE) {
        [self showImageView:model];
    } else if (type == V2NIM_MESSAGE_TYPE_VIDEO) {
        [self showVideoView:model];
    } else if (type == V2NIM_MESSAGE_TYPE_TEXT) {
        [self showTextViewController:model];
    } else if (type == V2NIM_MESSAGE_TYPE_LOCATION) {
        [self showMapDetail:model];
    } else if (type == V2NIM_MESSAGE_TYPE_FILE) {
        [self showFileDetail:model];
    } else if (type == V2NIM_MESSAGE_TYPE_CUSTOM) {
        [self showTextView:model];
    }
}

- (void)didTapDetectedLink:(CollectionMessageModel *)model cell:(NEBaseCollectionMessageCell *)cell url:(NSURL *)url {
    if (url) {
        if ([url.scheme isEqualToString:@"mailto"]) {
            [self didTapMailto:url];
        } else if ([url.scheme isEqualToString:@"tel"]) {
            [self didTapTel:url];
        } else {
            NEWKWebViewController *ctrl = [[NEWKWebViewController alloc] initWithUrl:url.absoluteString title:url.absoluteString];
            [self.navigationController pushViewController:ctrl animated:YES];
        }
    } else {
        if (model.message.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
            [self showTextViewController:model];
        } else if (model.message.messageType == V2NIM_MESSAGE_TYPE_CUSTOM) {
            [self showTextView:model];
        }
    }
}

- (void)didTapTel:(NSURL *)url {
    [self showBottomTelAction:url];
}

- (void)didTapMailto:(NSURL *)url {
    [self showBottomMailAction:url];
}

- (void)didPlay:(NEBaseCollectionMessageCell *)cell model:(CollectionMessageModel *)model {
    if (!model.message) return;
    if (![model.message.attachment isKindOfClass:[V2NIMMessageAudioAttachment class]]) return;
    V2NIMMessageAudioAttachment *audio = (V2NIMMessageAudioAttachment *)model.message.attachment;
    if (!audio) return;
    NSString *messageId = model.message.messageServerId;
    if (!messageId) return;

    NSString *path = audio.path ?: [ChatMessageHelper createFilePath:model.message];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (audio.url) {
            if ([self.viewModel.audioDownloadSet containsObject:messageId]) {
                return;
            }
            [self.viewModel.audioDownloadSet addObject:messageId];
            self.viewModel.lastClickAuidoMessageId = messageId;
            __weak typeof(self) weakSelf = self;
            [self.viewModel downloadFile:audio.url filePath:path progress:nil completion:^(NSString *localPath, NSError *error) {
                [weakSelf.viewModel.audioDownloadSet removeObject:messageId];
                if (!error) {
                    if ([weakSelf.viewModel.lastClickAuidoMessageId isEqualToString:messageId]) {
                        [weakSelf startPlay:cell model:model];
                    }
                } else {
                    [weakSelf.view ne_makeToast:error.localizedDescription];
                }
            }];
        }
    } else {
        self.viewModel.lastClickAuidoMessageId = nil;
        [self startPlay:cell model:model];
    }
}

- (void)startPlay:(NEBaseCollectionMessageCell *)cell model:(CollectionMessageModel *)model {
    if (![model.chatmodel isKindOfClass:[MessageAudioModel class]]) return;
    MessageAudioModel *audioModel = (MessageAudioModel *)model.chatmodel;
    if (self.playingModel == audioModel) {
        if (self.audioPlayer.isPlaying) {
            [self stopPlay];
        } else {
            [self startPlaying:model.message];
        }
    } else {
        [self stopPlay];
        if ([cell isKindOfClass:[NEBaseCollectionMessageAudioCell class]]) {
            self.playingCell = (NEBaseCollectionMessageAudioCell *)cell;
        }
        if ([model.chatmodel isKindOfClass:[MessageAudioModel class]]) {
            self.playingModel = (MessageAudioModel *)model.chatmodel;
        }
        [self startPlaying:model.message];
    }
}

- (void)startPlaying:(V2NIMMessage *)audioMessage {
    if (!audioMessage) return;
    if (![audioMessage.attachment isKindOfClass:[V2NIMMessageAudioAttachment class]]) return;
    V2NIMMessageAudioAttachment *audio = (V2NIMMessageAudioAttachment *)audioMessage.attachment;
    if (!audio) return;
    [self.playingCell startPlayAnimation];
    NSString *path = audio.path ?: [ChatMessageHelper createFilePath:audioMessage];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSURL *audioURL = [NSURL fileURLWithPath:path];
        NSError *error = nil;
        if ([self.viewModel getHandSetEnable]) {
            [NEAudioSessionManager.shared switchToSpeaker];
        } else {
            [NEAudioSessionManager.shared switchToReceiver];
        }
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:&error];
        if (!error) {
            self.audioPlayer.delegate = self;
            [self.audioPlayer play];
        } else {
            [self.playingCell stopPlayAnimation];
            NSLog(@"Error loading audio: %@", error.localizedDescription);
        }
    } else {
        [self.playingCell stopPlayAnimation];
    }
}

- (void)stopPlay {
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
    }
    [self.playingCell stopPlayAnimation];
    self.playingModel.isPlaying = NO;
    [NEAudioSessionManager.shared stopProximityMonitoring];
}

- (void)showTextViewController:(CollectionMessageModel *)model {
    if (![model.chatmodel isKindOfClass:[MessageTextModel class]]) return;
    MessageTextModel *textModel = (MessageTextModel *)model.chatmodel;
    NSString *title = [NECustomUtils titleOfRichText:textModel.message.attachment];
    NSAttributedString *body = textModel.attributeStr;
    TextViewController *textViewController = [self getTextViewController:title body:body];
    UINavigationController *nav = [[NENavigationController alloc] initWithRootViewController:textViewController];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:NO completion:nil];
}

- (TextViewController *)getTextViewController:(NSString *)title body:(NSAttributedString *)body {
    TextViewController *textViewController = [[TextViewController alloc] initWithTitle:title body:body];
    [textViewController updateLinkDetection];
    return textViewController;
}

- (MultiForwardViewController *)getMultiForwardViewController:(NSString *)messageAttachmentUrl
                                                     filePath:(NSString *)messageAttachmentFilePath
                                                          md5:(NSString *)messageAttachmentMD5 {
    return [[MultiForwardViewController alloc] initWithAttachmentUrl:messageAttachmentUrl
                                                  attachmentFilePath:messageAttachmentFilePath
                                                       attachmentMD5:messageAttachmentMD5];
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self;
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (NEBaseForwardAlertViewController *)getCollectionForwardAlertController {
    return [[NEBaseForwardAlertViewController alloc] init];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self stopPlay];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopPlay];
}

#pragma mark - Lazy Properties

- (UITableView *)contentTable {
    if (!_contentTable) {
        _contentTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _contentTable.translatesAutoresizingMaskIntoConstraints = NO;
        _contentTable.separatorStyle = UITableViewCellSeparatorStyleNone;
        _contentTable.showsVerticalScrollIndicator = NO;
        _contentTable.delegate = self;
        _contentTable.dataSource = self;
        _contentTable.backgroundColor = UIColor.clearColor;
        _contentTable.mj_footer = [MJRefreshAutoFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
        _contentTable.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _contentTable.estimatedRowHeight = 0;
        _contentTable.estimatedSectionHeaderHeight = 0;
        _contentTable.estimatedSectionFooterHeight = 0;
        if (@available(iOS 15.0, *)) {
            _contentTable.sectionHeaderTopPadding = 0.0;
        }
    }
    return _contentTable;
}

- (NEEmptyDataView *)collectionEmptyView {
    if (!_collectionEmptyView) {
        _collectionEmptyView = [[NEEmptyDataView alloc] initWithImageName:@"user_empty"
                                                                  content:chatLocalizable(@"no_collection_message")
                                                                    frame:CGRectZero];
        _collectionEmptyView.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionEmptyView.userInteractionEnabled = NO;
        _collectionEmptyView.hidden = YES;
    }
    return _collectionEmptyView;
}

- (CollectionMessageViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[CollectionMessageViewModel alloc] init];
    }
    return _viewModel;
}

- (CGFloat)collection_content_maxW {
    if (_collection_content_maxW == 0) {
        _collection_content_maxW = kScreenWidth() - 72;
    }
    return _collection_content_maxW;
}

- (UIDocumentInteractionController *)interactionController {
    if (!_interactionController) {
        _interactionController = [[UIDocumentInteractionController alloc] init];
    }
    return _interactionController;
}

- (NSMutableDictionary *)cellClassDic {
    if (!_cellClassDic) {
        _cellClassDic = [NSMutableDictionary dictionary];
    }
    return _cellClassDic;
}

@end
