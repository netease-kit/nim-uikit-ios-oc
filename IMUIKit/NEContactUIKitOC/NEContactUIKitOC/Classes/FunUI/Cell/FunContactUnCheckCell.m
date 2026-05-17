#import "FunContactUnCheckCell.h"
#import "ContactInfo.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>

@implementation FunContactUnCheckCell

- (void)setupUI {
  [super setupUI];
  self.avatarImageView.layer.cornerRadius = 4.0;
  [NSLayoutConstraint activateConstraints:@[
    [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.avatarImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    [self.avatarImageView.widthAnchor constraintEqualToConstant:40.0],
    [self.avatarImageView.heightAnchor constraintEqualToConstant:40.0],
  ]];
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
