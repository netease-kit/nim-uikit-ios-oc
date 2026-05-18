#import "FusionContactSelectedCell.h"
#import <NEChatKitOC/NECommonLoader.h>

@implementation FusionContactSelectedCell

- (void)setupFusionSelectedCellUI {
  [super setupFusionSelectedCellUI];

  [self.contentView addSubview:self.selectedStateImage];
  self.selectedStateImage.highlightedImage = [coreLoader() loadImage:@"select"];
  [NSLayoutConstraint activateConstraints:@[
    [self.selectedStateImage.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.selectedStateImage.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
  ]];

  [self.contentView addSubview:self.userHeaderView];
  [NSLayoutConstraint activateConstraints:@[
    [self.userHeaderView.widthAnchor constraintEqualToConstant:36.0],
    [self.userHeaderView.heightAnchor constraintEqualToConstant:36.0],
    [self.userHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor constant:0.0],
    [self.userHeaderView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:50.0],
  ]];
  self.userHeaderView.layer.cornerRadius = 18.0;

  [self.contentView addSubview:self.nameLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.nameLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:12.0],
    [self.nameLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-35.0],
    [self.nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.nameLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
  ]];

  [self.contentView addSubview:self.bottomLine];
  [NSLayoutConstraint activateConstraints:@[
    [self.bottomLine.leftAnchor constraintEqualToAnchor:self.userHeaderView.leftAnchor],
    [self.bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.bottomLine.heightAnchor constraintEqualToConstant:1.0],
  ]];
}

@end
