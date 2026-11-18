// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEChatBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ForwardItem : NSObject
@property (nonatomic, copy, nullable) NSString *conversationId;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *avatar;
@end

@interface NEBaseForwardSessionCell : UICollectionViewCell
@property (nonatomic, strong) NEUserHeaderView *sessionHeaderView;

- (void)setupUI;
@end

@interface NEBaseForwardAlertViewController : UIViewController
    <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, copy, nullable) void (^cancelBlock)(NSString *_Nullable comment);
@property (nonatomic, copy, nullable) void (^sureBlock)(NSString *_Nullable comment);
@property (nonatomic, copy) NSString *forwardType;
@property (nonatomic, copy) NSString *sessionName;
@property (nonatomic, copy) NSString *senderName;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentViewCenterYAnchor;
@property (nonatomic, strong) UICollectionView *sessionCollectionView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NEUserHeaderView *oneSessionHeadView;
@property (nonatomic, strong) UILabel *oneSessionNameLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UITextField *commentTextFeild;
@property (nonatomic, strong) UIButton *sureButton;
@property (nonatomic, strong) UILabel *tipLabel;

- (void)setupUI;
- (void)attachToSource:(UIViewController *)source;
- (void)setItems:(NSArray<ForwardItem *> *)items;
- (void)keyBoardWillShow:(NSNotification *)notification;
- (void)keyBoardWillHide:(NSNotification *)notification;
- (UICollectionViewCell *)setCellModel:(NEBaseForwardSessionCell *)cell indexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
