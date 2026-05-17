#import "ContactUnCheckCell.h"
#import "ContactInfo.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>

@implementation ContactUnCheckCell

- (void)setupUI {
  [super setupUI];
  self.avatarImageView.layer.cornerRadius = 18.0;
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.avatarImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.avatarImageView.widthAnchor constraintEqualToConstant:36.0],
    [self.avatarImageView.heightAnchor constraintEqualToConstant:36.0],
  ]];
}

- (void)setAvatarWH:(CGFloat)height {
  self.avatarImageView.layer.cornerRadius = height / 2.0;
  [self.avatarImageView updateLayoutConstraintFirstItem:self.avatarImageView
                                             secondItem:nil
                                              attribute:NSLayoutAttributeWidth
                                               constant:height];
  [self.avatarImageView updateLayoutConstraintFirstItem:self.avatarImageView
                                             secondItem:nil
                                              attribute:NSLayoutAttributeHeight
                                               constant:height];
}

- (void)configure:(id)model {
  if (![model isKindOfClass:[ContactInfo class]]) {
    return;
  }

  ContactInfo *contact = (ContactInfo *)model;
  NSString *url = contact.user.user.avatar;
  NSString *name = [contact.user shortName:YES count:2] ?: @"";
  NSString *accountId = contact.user.user.accountId ?: @"";
  [self.avatarImageView configHeadData:url name:name uid:accountId];
}

@end
