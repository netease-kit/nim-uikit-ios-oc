// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKit.h>
#import <NIMSDK/NIMSDK.h>
#import "NEChatBaseCell.h"
#import "MessageFileModel.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/FileStateView.h>

NS_ASSUME_NONNULL_BEGIN

@class NEHistorySearchFileCell;

@protocol NEHistorySearchFileCellDelegate <NSObject>

- (void)didClickMoreAction:(NEHistorySearchFileCell *)cell model:(nullable MessageFileModel *)model;

@end

@interface NEHistorySearchFileCell : NEChatBaseCell

@property(nonatomic, strong) NEUserHeaderView *avatarImageView;
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UILabel *timeLabel;
@property(nonatomic, strong) UIView *fileBackView;
@property(nonatomic, strong) UIImageView *fileIconImageView;
@property(nonatomic, strong) UILabel *fileNameLabel;
@property(nonatomic, strong) UILabel *fileSizeLabel;
@property(nonatomic, strong) ExpandButton *moreButton;
@property(nonatomic, strong) UIView *lineBottom;
@property(nonatomic, strong) FileStateView *stateView;

@property(nonatomic, weak, nullable) MessageFileModel *currentModel;
@property(nonatomic, weak, nullable) id<NEHistorySearchFileCellDelegate> delegate;

- (void)setupUI;
- (void)configureWithModel:(MessageFileModel *)model;
- (NSString *)formatMessageTime:(uint64_t)timestamp;
- (NSString *)formatFileSize:(NSUInteger)bytes;
- (nullable UIImage *)getFileIconForAttachment:(V2NIMMessageFileAttachment *)fileObject;

@end

NS_ASSUME_NONNULL_END
