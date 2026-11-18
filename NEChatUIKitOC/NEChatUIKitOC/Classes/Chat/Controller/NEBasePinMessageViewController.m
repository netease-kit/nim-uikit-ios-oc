// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageViewController.h"
#import <NEChatKit/NEChatKit.h>
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>

#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/NERouterUrl.h>
#import <NIMSDK/NIMSDK.h>
#import "ChatMessageHelper.h"
#import "ChatNavigationView.h"
#import <NEChatKit/NEPathUtils.h>
#import <NEChatKit/NECustomUtils.h>
#import <NEBaseUIKitOC/NEWKWebViewController.h>
#import <NEBaseUIKitOC/VideoPlayerViewController.h>
#import <NEBaseUIKitOC/PhotoBrowserController.h>
#import "NEAudioSessionManager.h"
#import "NEChatUIConstant.h"
#import "TextViewController.h"
#import "MultiForwardViewController.h"
#import "NEBaseForwardAlertViewController.h"
#import <objc/runtime.h>
#import "MessageTextModel.h"
#import "MessageAudioModel.h"
#import "MessageVideoModel.h"
#import "MessageLocationModel.h"
#import "NEBasePinMessageAudioCell.h"
#import "NEBasePinMessageTextCell.h"
#import "NEBasePinMessageFileCell.h"
#import "ChatViewController.h"

const NSInteger PinMessageDefaultType = 1000;
static NSString * const NEPinPushP2pChatVCRouter = @"imkit://chat/p2pChat.page";
static NSString * const NEPinPushTeamChatVCRouter = @"imkit://chat/teamChat.page";
static NSString * const NEPinForwardMultiSelectedRouter = @"imkit://contact/tab/selector.result";
static NSString * const NEPinForwardMultiSelectRouter = @"imkit://contact/tab/selector.page";

static Class NEPinResolveTableViewCellClass(id cellValue) {
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

static NSArray<NSString *> *NEPinMessageUniqueKeys(V2NIMMessage *message) {
    if (![message isKindOfClass:[V2NIMMessage class]]) {
        return nil;
    }
    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    if (message.messageClientId.length > 0) {
        [keys addObject:[@"client:" stringByAppendingString:message.messageClientId]];
    }
    if (message.messageServerId.length > 0) {
        [keys addObject:[@"server:" stringByAppendingString:message.messageServerId]];
    }
    return keys.count > 0 ? [keys copy] : nil;
}

static BOOL NEPinMessageIsSame(V2NIMMessage *lhs, V2NIMMessage *rhs) {
    if (lhs == rhs) {
        return YES;
    }
    NSArray<NSString *> *lhsKeys = NEPinMessageUniqueKeys(lhs);
    NSArray<NSString *> *rhsKeys = NEPinMessageUniqueKeys(rhs);
    if (lhsKeys.count == 0 || rhsKeys.count == 0) {
        return NO;
    }

    NSSet<NSString *> *lhsKeySet = [NSSet setWithArray:lhsKeys];
    for (NSString *key in rhsKeys) {
        if ([lhsKeySet containsObject:key]) {
            return YES;
        }
    }
    return NO;
}

static void NEPinAppendUniqueMessages(NSMutableArray<V2NIMMessage *> *target, NSArray<V2NIMMessage *> *messages) {
    if (![target isKindOfClass:[NSMutableArray class]] || ![messages isKindOfClass:[NSArray class]]) {
        return;
    }
    for (V2NIMMessage *message in messages) {
        if (![message isKindOfClass:[V2NIMMessage class]]) {
            continue;
        }
        BOOL duplicated = NO;
        for (V2NIMMessage *existingMessage in target) {
            if (NEPinMessageIsSame(existingMessage, message)) {
                duplicated = YES;
                break;
            }
        }
        if (!duplicated) {
            [target addObject:message];
        }
    }
}

@interface NEBasePinMessageViewController ()
@property (nonatomic, strong) NEBasePinMessageAudioCell *playingCell;
@property (nonatomic, strong) MessageAudioModel *playingModel;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Class> *cellClassDic;
@property (nonatomic, assign) CGFloat measuredMessageWidth;
@property (nonatomic, assign) CGFloat messageHorizontalInset;
@end

@implementation NEBasePinMessageViewController

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _conversationId = conversationId;
        [[IMKitClient instance] addLoginListener:self];
        [[ChatRepo shared] addChatListener:self];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)dealloc {
    [[IMKitClient instance] removeLoginListener:self];
    [[ChatRepo shared] removeChatListener:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableViewTopAnchor.constant = self.topConstant;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!NEAdaptiveDeviceGate.adaptiveHostActive) {
        return;
    }
    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    if (width <= 0 || fabs(width - self.measuredMessageWidth) <= 0.5) {
        return;
    }
    if (self.messageHorizontalInset <= 0) {
        self.messageHorizontalInset = MAX(0, kScreenWidth() - self.pin_content_maxW);
    }
    self.measuredMessageWidth = width;
    self.pin_content_maxW = MAX(16, width - self.messageHorizontalInset);
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewModel.delegate = self;
    [self setupUI];
    [self loadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopPlay];
}

- (void)loadData {
    if (!self.conversationId) return;
    __weak typeof(self) weakSelf = self;
    self.isLoadingData = YES;
    [self.viewModel getPinitems:self.conversationId completion:^(NSError * _Nullable error) {
        weakSelf.isLoadingData = NO;
        if (error) {
            NSError *err = (NSError *)error;
            if ([V2NIMConversationIdUtil conversationType:weakSelf.conversationId] == V2NIM_CONVERSATION_TYPE_TEAM && err.code == teamNotExistCode) {
                [weakSelf.view ne_makeToast:commonLocalizable(@"team_not_exist")];
            } else if (err.code == protocolTimeout) {
                [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
            } else {
                [weakSelf.view ne_makeToast:err.localizedDescription];
            }
        } else {
            weakSelf.emptyView.hidden = weakSelf.viewModel.items.count > 0;
            [weakSelf.tableView reloadData];
        }
    }];
}

- (void)setupUI {
    self.title = chatLocalizable(@"operation_pin");
    self.navigationView.moreButton.hidden = YES;

    [self.view addSubview:self.tableView];
    self.tableViewTopAnchor = [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
    self.tableViewTopAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self.emptyView setText:chatLocalizable(@"no_pin_message")];
    [self.view addSubview:self.emptyView];
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor],
        [self.emptyView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
        [self.emptyView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor],
        [self.emptyView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
    ]];

    self.cellClassDic = [[self getRegisterCellDic] mutableCopy];
    [self.tableView registerClass:[NEBasePinMessageTextCell class]
           forCellReuseIdentifier:NSStringFromClass([NEBasePinMessageTextCell class])];
    for (NSString *key in [self.cellClassDic allKeys]) {
        Class cellClass = NEPinResolveTableViewCellClass(self.cellClassDic[key]);
        if (cellClass) {
            self.cellClassDic[key] = cellClass;
            [self.tableView registerClass:cellClass forCellReuseIdentifier:key];
        } else {
            [self.cellClassDic removeObjectForKey:key];
        }
    }
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.items.count) return;
    NEPinMessageModel *item = self.viewModel.items[indexPath.row];
    if (![item isKindOfClass:[NEPinMessageModel class]] || !item.message) return;

    NSMutableArray<V2NIMMessage *> *newMsgs = [NSMutableArray array];
    if (self.navigationController) {
        for (UIViewController *vc in self.navigationController.viewControllers) {
            if ([vc isKindOfClass:[ChatViewController class]]) {
                NSArray *receiveMsgs = ((ChatViewController *)vc).onReceiveNewMsgs;
                newMsgs = [receiveMsgs isKindOfClass:[NSArray class]] ? [receiveMsgs mutableCopy] : [NSMutableArray array];
                break;
            }
        }
    }
    NSMutableSet<NSString *> *existingIds = [NSMutableSet set];
    for (V2NIMMessage *msg in newMsgs) {
        for (NSString *key in NEPinMessageUniqueKeys(msg)) {
            if (key.length > 0) {
                [existingIds addObject:key];
            }
        }
    }
    for (V2NIMMessage *msg in self.onReceiveNewMsgs) {
        NSArray<NSString *> *keys = NEPinMessageUniqueKeys(msg);
        BOOL duplicated = NO;
        for (NSString *key in keys) {
            if (key.length > 0 && [existingIds containsObject:key]) {
                duplicated = YES;
                break;
            }
        }
        if (duplicated) {
            continue;
        }
        [newMsgs addObject:msg];
        for (NSString *key in keys) {
            if (key.length > 0) {
                [existingIds addObject:key];
            }
        }
    }

    if (item.message.conversationType == V2NIM_CONVERSATION_TYPE_P2P) {
        NSString *conversationId = item.message.conversationId;
        [Router.shared use:NEPinPushP2pChatVCRouter
                parameters:@{@"nav": self.navigationController ?: [NSNull null],
                              @"conversationId": conversationId ?: [NSNull null],
                              @"anchor": item.message,
                              @"onReceiveNewMsgs": newMsgs}
                   closure:nil];
        [self.onReceiveNewMsgs removeAllObjects];
    } else if (item.message.conversationType == V2NIM_CONVERSATION_TYPE_TEAM) {
        NSString *conversationId = item.message.conversationId;
        [Router.shared use:NEPinPushTeamChatVCRouter
                parameters:@{@"nav": self.navigationController ?: [NSNull null],
                              @"conversationId": conversationId ?: [NSNull null],
                              @"anchor": item.message,
                              @"onReceiveNewMsgs": newMsgs}
                   closure:nil];
        [self.onReceiveNewMsgs removeAllObjects];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.items.count) return [[UITableViewCell alloc] init];
    NEPinMessageModel *model = self.viewModel.items[indexPath.row];
    if (![model isKindOfClass:[NEPinMessageModel class]] || !model.chatmodel) {
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
            reuseId = NSStringFromClass([NEBasePinMessageTextCell class]);
        }
    } else if (self.cellClassDic[reuseId] == nil) {
        reuseId = NSStringFromClass([NEBasePinMessageTextCell class]);
    }
    NEBasePinMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId forIndexPath:indexPath];
    cell.delegate = self;
    [cell configure:model];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.items.count) return 0;
    NEPinMessageModel *model = self.viewModel.items[indexPath.row];
    if (![model isKindOfClass:[NEPinMessageModel class]] || !model.chatmodel) return 0;
    if (model.chatmodel.customType == customMultiForwardType) {
        return [model cellHeight:self.pin_content_maxW] - 30;
    }
    return [model cellHeight:self.pin_content_maxW];
}

- (void)cancelPinActionClicked:(NEPinMessageModel *)item {
    __weak typeof(self) weakSelf = self;
    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
        [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
        return;
    }
    [weakSelf.viewModel removePinMessage:item.message completion:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        } else {
            [weakSelf.view ne_makeToast:chatLocalizable(@"cancel_pin_success")];
        }
    }];
}

- (void)copyActionClicked:(NEPinMessageModel *)item {
    [UIPasteboard generalPasteboard].string = item.message.text;
    [self.view ne_makeToast:commonLocalizable(@"copy_success")];
}

- (void)forwardActionClicked:(NEPinMessageModel *)item {
    __weak typeof(self) weakSelf = self;
    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
        [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
        return;
    }
    [weakSelf forwardMessage:item.message];
}

- (void)showAction:(NEPinMessageModel *)item {
    if (!item.message) return;
    NSMutableArray<UIAlertAction *> *actions = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    UIAlertAction *cancelPinAction = [UIAlertAction actionWithTitle:chatLocalizable(@"operation_cancel_pin") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf cancelPinActionClicked:item];
    }];
    [actions addObject:cancelPinAction];

    if (item.message.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
        UIAlertAction *copyAction = [UIAlertAction actionWithTitle:chatLocalizable(@"operation_copy") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf copyActionClicked:item];
        }];
        [actions addObject:copyAction];
    }

    if (item.message.messageType != V2NIM_MESSAGE_TYPE_AUDIO) {
        UIAlertAction *forwardAction = [UIAlertAction actionWithTitle:chatLocalizable(@"operation_forward") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf forwardActionClicked:item];
        }];
        [actions addObject:forwardAction];
    }

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel") style:UIAlertActionStyleCancel handler:nil];
    [actions addObject:cancelAction];
    [self showActionSheet:actions];
}

- (NEBaseForwardAlertViewController *)getForwardAlertController {
    return [[NEBaseForwardAlertViewController alloc] init];
}

- (void)addForwardAlertController:(NSArray<ForwardItem *> *)items type:(NSString *)type sureBlock:(nullable void (^)(NSString *_Nullable comment))sureBlock {
    NEBaseForwardAlertViewController *forwardAlert = [self getForwardAlertController];
    [forwardAlert setItems:items];
    forwardAlert.forwardType = type;
    forwardAlert.sureBlock = sureBlock;
    if (self.conversationId) {
        forwardAlert.sessionName = [ChatMessageHelper getSessionName:self.conversationId showAlias:YES];
    }
    [forwardAlert attachToSource:self];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication].keyWindow endEditing:YES];
    });
}

- (void)forwardMessage:(V2NIMMessage *)message {
    __weak typeof(self) weakSelf = self;
    [Router.shared register:NEPinForwardMultiSelectedRouter closure:^(NSDictionary * _Nonnull param) {
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
        [weakSelf addForwardAlertController:items type:type sureBlock:^(NSString * _Nullable comment) {
            if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
                [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
                return;
            }
            [weakSelf.viewModel forwardMessages:message conversationIds:conversationIds comment:comment completion:^(V2NIMSendMessageResult * _Nullable result, NSError * _Nullable error, NSUInteger progress) {
                // 转发失败不展示错误信息
            }];
        }];
    }];
    [Router.shared use:NEPinForwardMultiSelectRouter parameters:@{@"nav": self.navigationController ?: [NSNull null], @"selctorMode": @0} closure:nil];
}

- (void)tableViewReload:(BOOL)needLoad {
    if (needLoad) {
        [self loadData];
    }
    [self.tableView reloadData];
    self.emptyView.hidden = self.viewModel.items.count > 0;
}

- (void)didClickMore:(NEPinMessageModel *)model {
    if (model) {
        [self showAction:model];
    }
}

- (void)toImageView:(NEPinMessageModel *)model {
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
            [self presentAdaptivePreview:showController animated:NO completion:nil];
        }
    }
}

- (void)toVideoView:(NEPinMessageModel *)model {
    if (![model.message.attachment isKindOfClass:[V2NIMMessageVideoAttachment class]]) return;
    V2NIMMessageVideoAttachment *object = (V2NIMMessageVideoAttachment *)model.message.attachment;
    if (object) {
        [self stopPlay];
        [NEAudioSessionManager.shared switchToSpeaker];
        [NEAudioSessionManager.shared stopProximityMonitoring];
        VideoPlayerViewController *player = [[VideoPlayerViewController alloc] init];
        player.totalTime = (NSInteger)object.duration;
        player.modalPresentationStyle = UIModalPresentationOverFullScreen;
        NSString *path = [ChatMessageHelper videoLocalPathForMessage:model.message];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            player.videoUrl = [NSURL fileURLWithPath:path];
            [self presentAdaptivePreview:player animated:YES completion:nil];
        } else if (object.url) {
            NSURL *remoteUrl = [NSURL URLWithString:object.url];
            if (remoteUrl) {
                player.videoUrl = remoteUrl;
                [self presentAdaptivePreview:player animated:YES completion:nil];
            }
        }
    }
}

- (void)toMapDetail:(NEPinMessageModel *)model {
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

- (void)toFileDetail:(NEPinMessageModel *)model {
    if (![model.message.attachment isKindOfClass:[V2NIMMessageFileAttachment class]]) return;
    V2NIMMessageFileAttachment *object = (V2NIMMessageFileAttachment *)model.message.attachment;
    if (!object) return;
    if (![model.pinFileModel isKindOfClass:[PinMessageFileModel class]]) {
        [NEALog infoLog:NSStringFromClass([self class]) desc:@"PinMessageFileModel not exit"];
        return;
    }
    PinMessageFileModel *fileModel = (PinMessageFileModel *)model.pinFileModel;
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
        if ([ChatMessageHelper isImageFileAttachment:object]) {
            PhotoBrowserController *showController = [[PhotoBrowserController alloc] initWithUrls:@[path] url:path];
            showController.modalPresentationStyle = UIModalPresentationOverFullScreen;
            [self presentAdaptivePreview:showController animated:NO completion:nil];
        } else {
            self.interactionController.URL = url;
            self.interactionController.delegate = self;
            if (![self.interactionController presentPreviewAnimated:YES]) {
                [self.interactionController presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
            }
        }
    }
}

- (void)downloadFile:(PinMessageFileModel *)fileModel urlString:(NSString *)urlString path:(NSString *)path {
    fileModel.state = DownloadStateDownalod;
    __weak typeof(self) weakSelf = self;
    [self.viewModel downLoad:urlString filePath:path progress:^(NSUInteger progress) {
        fileModel.progress = progress;
        if (progress >= 100) {
            fileModel.state = DownloadStateSuccess;
        }
        [fileModel.cell uploadProgress:progress];
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

- (void)toTextViewShow:(NEPinMessageModel *)model {
    if (!model.message || !model.chatmodel) return;
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

- (void)didClickContent:(NEPinMessageModel *)model cell:(NEBasePinMessageCell *)cell {
    [NEALog infoLog:NSStringFromClass([self class]) desc:@"didClickContent"];
    if (!model.message) return;
    V2NIMMessageType type = model.message.messageType;
    if (type == V2NIM_MESSAGE_TYPE_AUDIO) {
        [self didPlay:cell model:model];
    } else if (type == V2NIM_MESSAGE_TYPE_IMAGE) {
        [self toImageView:model];
    } else if (type == V2NIM_MESSAGE_TYPE_VIDEO) {
        [self toVideoView:model];
    } else if (type == V2NIM_MESSAGE_TYPE_TEXT) {
        [self showTextViewController:model];
    } else if (type == V2NIM_MESSAGE_TYPE_LOCATION) {
        [self toMapDetail:model];
    } else if (type == V2NIM_MESSAGE_TYPE_FILE) {
        [self toFileDetail:model];
    } else if (type == V2NIM_MESSAGE_TYPE_CUSTOM) {
        [self toTextViewShow:model];
    }
}

- (void)didTapDetectedLink:(NEPinMessageModel *)model cell:(NEBasePinMessageCell *)cell url:(NSURL *)url {
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
            [self toTextViewShow:model];
        }
    }
}

- (void)didTapTel:(NSURL *)url {
    [self showBottomTelAction:url];
}

- (void)didTapMailto:(NSURL *)url {
    [self showBottomMailAction:url];
}

- (void)didPlay:(NEBasePinMessageCell *)cell model:(NEPinMessageModel *)model {
    if (!model.message) return;
    if (![model.message.attachment isKindOfClass:[V2NIMMessageAudioAttachment class]]) return;
    V2NIMMessageAudioAttachment *audio = (V2NIMMessageAudioAttachment *)model.message.attachment;
    if (!audio) return;
    NSString *path = audio.path ?: [ChatMessageHelper createFilePath:model.message];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (audio.url) {
            __weak typeof(self) weakSelf = self;
            [self.viewModel downLoad:audio.url filePath:path progress:nil completion:^(NSString *localPath, NSError *error) {
                if (!error) {
                    [weakSelf startPlay:cell model:model];
                } else {
                    [weakSelf.view ne_makeToast:error.localizedDescription];
                }
            }];
        }
    } else {
        [self startPlay:cell model:model];
    }
}

- (void)startPlay:(NEBasePinMessageCell *)cell model:(NEPinMessageModel *)model {
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
        if ([cell isKindOfClass:[NEBasePinMessageAudioCell class]]) {
            self.playingCell = (NEBasePinMessageAudioCell *)cell;
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
    [self.playingCell startAnimation];
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
            [self.playingCell stopAnimation];
            NSLog(@"Error loading audio: %@", error.localizedDescription);
        }
    } else {
        [self.playingCell stopAnimation];
    }
}

- (void)stopPlay {
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
    }
    [self.playingCell stopAnimation];
    self.playingModel.isPlaying = NO;
    [NEAudioSessionManager.shared stopProximityMonitoring];
}

- (NSDictionary<NSString *, Class> *)getRegisterCellDic {
    return self.cellClassDic ?: @{};
}

- (void)showTextViewController:(NEPinMessageModel *)model {
    if (![model.chatmodel isKindOfClass:[MessageTextModel class]]) return;
    MessageTextModel *textModel = (MessageTextModel *)model.chatmodel;
    NSString *title = [NECustomUtils titleOfRichText:textModel.message.attachment];
    NSAttributedString *body = textModel.attributeStr;
    TextViewController *textViewController = [self getTextViewController:title body:body];
    [textViewController presentAsColumnChildFrom:self];
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
    return [self documentPreviewPresenter];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - NEIMKitClientListener

- (void)onConnectStatus:(V2NIMConnectStatus)status {
    if (status == V2NIM_CONNECT_STATUS_WAITING) {
        self.networkBroken = YES;
    }
    if (status == V2NIM_CONNECT_STATUS_CONNECTED && self.networkBroken) {
        self.networkBroken = NO;
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf loadData];
        });
    }
}

#pragma mark - NEChatListener

- (void)onReceiveMessages:(NSArray<V2NIMMessage *> *)messages {
    if (!self.conversationId) return;
    NSMutableArray<V2NIMMessage *> *pendingMessages = [NSMutableArray array];
    for (V2NIMMessage *message in messages) {
        if ([message.conversationId isEqualToString:self.conversationId]) {
            [pendingMessages addObject:message];
        }
    }
    NEPinAppendUniqueMessages(self.onReceiveNewMsgs, pendingMessages);
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self stopPlay];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopPlay];
}

#pragma mark - Lazy Properties

- (PinMessageViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[PinMessageViewModel alloc] init];
    }
    return _viewModel;
}

- (NSMutableArray<V2NIMMessage *> *)onReceiveNewMsgs {
    if (!_onReceiveNewMsgs) {
        _onReceiveNewMsgs = [NSMutableArray array];
    }
    return _onReceiveNewMsgs;
}

- (CGFloat)pin_content_maxW {
    if (_pin_content_maxW == 0) {
        _pin_content_maxW = kScreenWidth() - 72;
    }
    return _pin_content_maxW;
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
