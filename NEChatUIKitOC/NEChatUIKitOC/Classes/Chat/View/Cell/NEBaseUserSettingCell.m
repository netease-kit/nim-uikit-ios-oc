// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseUserSettingCell.h"
#import "UIImage+Chat.h"

#import <NEBaseUIKitOC/NECommonUIConstant.h>

@implementation NEBaseUserSettingCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.showDefaultLine = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.textColor = [NEConstant hexRGB:0x333333];
        _titleLabel.font = [NEConstant defaultTextFont:16.0];
    }
    return _titleLabel;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
        _arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _arrowImageView;
}

- (CornerType)subCornerType {
    return self.cornerType;
}

- (void)setSubCornerType:(CornerType)subCornerType {
    if (self.cornerType != subCornerType) {
        self.cornerType = subCornerType;
        [self setNeedsDisplay];
    }
}

- (void)configure:(id)anyModel {
    if ([anyModel isKindOfClass:[UserSettingCellModel class]]) {
        UserSettingCellModel *m = (UserSettingCellModel *)anyModel;
        self.model = m;
        self.subCornerType = m.cornerType;
        self.titleLabel.text = m.cellName;
    }
}

@end
