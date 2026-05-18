// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseForwardAlertViewController.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import "NEChatUIConstant.h"
#import "ChatViewController.h"
#import <NEChatKitOC/SettingRepo.h>

@implementation ForwardItem
@end

@implementation NEBaseForwardSessionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)setupUI {
    [self.contentView addSubview:self.sessionHeaderView];
    [NSLayoutConstraint activateConstraints:@[
        [self.sessionHeaderView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
        [self.sessionHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.sessionHeaderView.widthAnchor constraintEqualToConstant:32.0],
        [self.sessionHeaderView.heightAnchor constraintEqualToConstant:32.0],
    ]];
}

- (NEUserHeaderView *)sessionHeaderView {
    if (!_sessionHeaderView) {
        _sessionHeaderView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
        _sessionHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
        _sessionHeaderView.titleLabel.font = [NEConstant defaultTextFont:11.0];
        _sessionHeaderView.clipsToBounds = YES;
        _sessionHeaderView.accessibilityIdentifier = @"id.forwardHeaderView";
    }
    return _sessionHeaderView;
}

@end

@interface NEBaseForwardAlertViewController ()
@property (nonatomic, strong) NSMutableArray<ForwardItem *> *forwardSessions;
@end

@implementation NEBaseForwardAlertViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _forwardSessions = [NSMutableArray array];
        _forwardType = chatLocalizable(@"operation_forward");
        _sessionName = @"";
        _senderName = @"";
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([self.parentViewController isKindOfClass:[ChatViewController class]]) {
        ((ChatViewController *)self.parentViewController).isCurrentPage = NO;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyBoardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyBoardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.viewControllers.lastObject.view endEditing:NO];
}

- (void)setupUI {
    self.view.backgroundColor = [[UIColor colorWithRed:0 green:0 blue:0 alpha:1.0] colorWithAlphaComponent:0.4];

    [self.view addSubview:self.contentView];
    self.contentViewCenterYAnchor = [self.contentView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor];
    self.contentViewCenterYAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.contentView.widthAnchor constraintEqualToConstant:276],
        [self.contentView.heightAnchor constraintEqualToConstant:250],
    ]];

    [self.contentView addSubview:self.tipLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.tipLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16.0],
        [self.tipLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16],
        [self.tipLabel.heightAnchor constraintEqualToConstant:18.0],
    ]];

    [self.contentView addSubview:self.oneSessionHeadView];
    [NSLayoutConstraint activateConstraints:@[
        [self.oneSessionHeadView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16],
        [self.oneSessionHeadView.topAnchor constraintEqualToAnchor:self.tipLabel.bottomAnchor constant:16],
        [self.oneSessionHeadView.widthAnchor constraintEqualToConstant:32.0],
        [self.oneSessionHeadView.heightAnchor constraintEqualToConstant:32.0],
    ]];

    [self.contentView addSubview:self.oneSessionNameLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.oneSessionNameLabel.leftAnchor constraintEqualToAnchor:self.oneSessionHeadView.rightAnchor constant:8.0],
        [self.oneSessionNameLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16.0],
        [self.oneSessionNameLabel.centerYAnchor constraintEqualToAnchor:self.oneSessionHeadView.centerYAnchor],
    ]];

    [self.contentView addSubview:self.sessionCollectionView];
    [NSLayoutConstraint activateConstraints:@[
        [self.sessionCollectionView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16.0],
        [self.sessionCollectionView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16.0],
        [self.sessionCollectionView.heightAnchor constraintEqualToConstant:32.0],
        [self.sessionCollectionView.topAnchor constraintEqualToAnchor:self.oneSessionHeadView.topAnchor],
    ]];

    UIView *textBackView = [[UIView alloc] init];
    textBackView.translatesAutoresizingMaskIntoConstraints = NO;
    textBackView.backgroundColor = [NEConstant hexRGB:0xF2F4F5];
    textBackView.clipsToBounds = YES;
    textBackView.layer.cornerRadius = 4.0;
    [self.contentView addSubview:textBackView];
    [NSLayoutConstraint activateConstraints:@[
        [textBackView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16.0],
        [textBackView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-16.0],
        [textBackView.topAnchor constraintEqualToAnchor:self.oneSessionHeadView.bottomAnchor constant:12.0],
    ]];

    [textBackView addSubview:self.contentLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.contentLabel.leftAnchor constraintEqualToAnchor:textBackView.leftAnchor constant:12],
        [self.contentLabel.rightAnchor constraintEqualToAnchor:textBackView.rightAnchor constant:-12],
        [self.contentLabel.topAnchor constraintEqualToAnchor:textBackView.topAnchor constant:7],
        [self.contentLabel.bottomAnchor constraintEqualToAnchor:textBackView.bottomAnchor constant:-7],
    ]];

    if (self.sessionName.length > 0) {
        self.contentLabel.text = [NSString stringWithFormat:@"[%@]%@%@", self.forwardType, self.sessionName, chatLocalizable(@"session_record")];
    } else if (self.senderName.length > 0) {
        self.contentLabel.text = [NSString stringWithFormat:@"[%@]%@%@", self.forwardType, self.senderName, chatLocalizable(@"collection_message")];
    }

    [self.contentView addSubview:self.commentTextFeild];
    [NSLayoutConstraint activateConstraints:@[
        [self.commentTextFeild.leftAnchor constraintEqualToAnchor:textBackView.leftAnchor],
        [self.commentTextFeild.rightAnchor constraintEqualToAnchor:textBackView.rightAnchor],
        [self.commentTextFeild.topAnchor constraintEqualToAnchor:textBackView.bottomAnchor constant:16],
        [self.commentTextFeild.heightAnchor constraintEqualToConstant:32],
    ]];

    UIView *verticalLine = [[UIView alloc] init];
    verticalLine.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:verticalLine];
    verticalLine.backgroundColor = forwardLineColor();
    [NSLayoutConstraint activateConstraints:@[
        [verticalLine.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [verticalLine.widthAnchor constraintEqualToConstant:1.0],
        [verticalLine.heightAnchor constraintEqualToConstant:51],
        [verticalLine.topAnchor constraintEqualToAnchor:self.commentTextFeild.bottomAnchor constant:24.0],
    ]];

    UIView *horizontalLine = [[UIView alloc] init];
    horizontalLine.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:horizontalLine];
    horizontalLine.backgroundColor = forwardLineColor();
    [NSLayoutConstraint activateConstraints:@[
        [horizontalLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
        [horizontalLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
        [horizontalLine.heightAnchor constraintEqualToConstant:1],
        [horizontalLine.bottomAnchor constraintEqualToAnchor:verticalLine.topAnchor],
    ]];

    UIButton *cancelButton = [[UIButton alloc] init];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(cancelClick) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:commonLocalizable(@"cancel") forState:UIControlStateNormal];
    [cancelButton setTitleColor:UIColor.ne_greyText forState:UIControlStateNormal];
    cancelButton.accessibilityIdentifier = @"id.forwardCancelBtn";
    [self.contentView addSubview:cancelButton];
    [NSLayoutConstraint activateConstraints:@[
        [cancelButton.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
        [cancelButton.bottomAnchor constraintEqualToAnchor:verticalLine.bottomAnchor],
        [cancelButton.topAnchor constraintEqualToAnchor:horizontalLine.bottomAnchor],
        [cancelButton.rightAnchor constraintEqualToAnchor:verticalLine.leftAnchor],
    ]];

    [self.contentView addSubview:self.sureButton];
    [NSLayoutConstraint activateConstraints:@[
        [self.sureButton.bottomAnchor constraintEqualToAnchor:verticalLine.bottomAnchor],
        [self.sureButton.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
        [self.sureButton.topAnchor constraintEqualToAnchor:horizontalLine.bottomAnchor],
        [self.sureButton.leftAnchor constraintEqualToAnchor:verticalLine.rightAnchor],
    ]];
}

- (void)keyBoardWillShow:(NSNotification *)notification {
    self.contentViewCenterYAnchor.constant = -60;
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyBoardWillHide:(NSNotification *)notification {
    self.contentViewCenterYAnchor.constant = 0;
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)setItems:(NSArray<ForwardItem *> *)items {
    [self.forwardSessions addObjectsFromArray:items];
    if (self.forwardSessions.count == 1) {
        ForwardItem *item = self.forwardSessions[0];
        [self.oneSessionHeadView configHeadData:item.avatar
                                                      name:item.name ?: @""
                                                       uid:item.conversationId ?: @""];
        self.oneSessionNameLabel.text = item.name ?: item.conversationId;
        self.sessionCollectionView.hidden = YES;
    } else {
        self.oneSessionHeadView.hidden = YES;
        self.oneSessionNameLabel.hidden = YES;
    }
}

- (void)sureClick {
    NSMutableArray<NSString *> *recentForwardIdList = [NSMutableArray array];
    for (ForwardItem *item in self.forwardSessions) {
        if (item.conversationId) {
            [recentForwardIdList addObject:item.conversationId];
        }
    }
    [[SettingRepo shared] updateRecentForward:recentForwardIdList];
    if (self.sureBlock) {
        self.sureBlock(self.commentTextFeild.text);
    }
    [self removeSelf];
}

- (void)cancelClick {
    if (self.cancelBlock) {
        self.cancelBlock(self.commentTextFeild.text);
    }
    [self removeSelf];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)removeSelf {
    if ([self.parentViewController isKindOfClass:[ChatViewController class]]) {
        ((ChatViewController *)self.parentViewController).isCurrentPage = YES;
    }
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.forwardSessions.count;
}

- (UICollectionViewCell *)setCellModel:(NEBaseForwardSessionCell *)cell indexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.forwardSessions.count) {
        return cell;
    }
    ForwardItem *item = self.forwardSessions[indexPath.row];
    [cell.sessionHeaderView configHeadData:item.avatar
                                                 name:item.name ?: @""
                                                  uid:item.conversationId ?: @""];
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[UICollectionViewCell alloc] init];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(32.0, 32.0);
}

#pragma mark - Lazy Properties

- (UIButton *)sureButton {
    if (!_sureButton) {
        _sureButton = [[UIButton alloc] init];
        _sureButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_sureButton addTarget:self action:@selector(sureClick) forControlEvents:UIControlEventTouchUpInside];
        [_sureButton setTitle:chatLocalizable(@"send") forState:UIControlStateNormal];
        [_sureButton setTitleColor:UIColor.ne_normalTheme forState:UIControlStateNormal];
        _sureButton.accessibilityIdentifier = @"id.forwardSendBtn";
    }
    return _sureButton;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _tipLabel.font = [NEConstant defaultTextFont:16.0];
        _tipLabel.textColor = UIColor.ne_darkText;
        _tipLabel.text = chatLocalizable(@"send_to");
        _tipLabel.accessibilityIdentifier = @"id.forwardTitle";
    }
    return _tipLabel;
}

- (UICollectionView *)sessionCollectionView {
    if (!_sessionCollectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.minimumLineSpacing = 9.5;
        flowLayout.minimumInteritemSpacing = 9.5;
        _sessionCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _sessionCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
        _sessionCollectionView.delegate = self;
        _sessionCollectionView.dataSource = self;
        _sessionCollectionView.backgroundColor = UIColor.clearColor;
        _sessionCollectionView.showsHorizontalScrollIndicator = NO;
    }
    return _sessionCollectionView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = UIColor.whiteColor;
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        _contentView.clipsToBounds = YES;
        _contentView.layer.cornerRadius = 8.0;
    }
    return _contentView;
}

- (NEUserHeaderView *)oneSessionHeadView {
    if (!_oneSessionHeadView) {
        _oneSessionHeadView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
        _oneSessionHeadView.clipsToBounds = YES;
        _oneSessionHeadView.translatesAutoresizingMaskIntoConstraints = NO;
        _oneSessionHeadView.accessibilityIdentifier = @"id.forwardHeaderView";
    }
    return _oneSessionHeadView;
}

- (UILabel *)oneSessionNameLabel {
    if (!_oneSessionNameLabel) {
        _oneSessionNameLabel = [[UILabel alloc] init];
        _oneSessionNameLabel.textColor = UIColor.ne_darkText;
        _oneSessionNameLabel.font = [NEConstant defaultTextFont:14.0];
        _oneSessionNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _oneSessionNameLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _contentLabel.font = [NEConstant defaultTextFont:14.0];
        _contentLabel.textColor = UIColor.ne_darkText;
        _contentLabel.numberOfLines = 1;
        _contentLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _contentLabel.accessibilityIdentifier = @"id.forwardContentText";
    }
    return _contentLabel;
}

- (UITextField *)commentTextFeild {
    if (!_commentTextFeild) {
        _commentTextFeild = [[UITextField alloc] init];
        _commentTextFeild.translatesAutoresizingMaskIntoConstraints = NO;
        _commentTextFeild.placeholder = chatLocalizable(@"leave_message");
        _commentTextFeild.layer.cornerRadius = 4;
        _commentTextFeild.layer.borderWidth = 1;
        _commentTextFeild.layer.borderColor = forwardLineColor().CGColor;
        _commentTextFeild.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 0)];
        _commentTextFeild.leftViewMode = UITextFieldViewModeAlways;
        _commentTextFeild.font = [UIFont systemFontOfSize:14];
        _commentTextFeild.accessibilityIdentifier = @"id.messageInput";
    }
    return _commentTextFeild;
}

@end
