// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "NEBaseLanguageCell.h"
#import "SelectLanguageViewModel.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@implementation NEBaseLanguageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupLanguageCellUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UILabel *)languageLabel {
    if (!_languageLabel) {
        _languageLabel = [[UILabel alloc] init];
        _languageLabel.font = [UIFont systemFontOfSize:16.0];
        _languageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _languageLabel.backgroundColor = UIColor.clearColor;
        _languageLabel.textColor = UIColor.ne_darkText;
    }
    return _languageLabel;
}

- (UIImageView *)selectedImageView {
    if (!_selectedImageView) {
        _selectedImageView = [[UIImageView alloc] init];
        _selectedImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _selectedImageView.image = chatLoadImage(@"chat_map_select");
        _selectedImageView.hidden = YES;
    }
    return _selectedImageView;
}

- (void)setupLanguageCellUI {
    self.dividerLine.hidden = YES;
}

- (void)configureData:(NElanguageCellModel *)model {
    self.languageLabel.text = model.language;
    self.languageLabel.textColor = model.isSelect ? UIColor.ne_defaultPrimaryColor : UIColor.ne_darkText;
    self.selectedImageView.hidden = !model.isSelect;
    self.cornerType = model.cornerType;
}

@end
