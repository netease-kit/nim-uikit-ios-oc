// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageDefaultCell.h"
#import "NEChatUIConstant.h"
#import <NECommonUIKitOC/NELinkableLabel.h>

@implementation NEBasePinMessageDefaultCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)setupUI {
    [super setupUI];
}

- (void)configure:(NEPinMessageModel *)item {
    [super configure:item];
    self.contentLabel.text = chatLocalizable(@"unkonw_pin_message");
}

@end
