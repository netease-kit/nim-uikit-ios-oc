#import "FusionContactUnCheckCell.h"
#import "NEFusionContactCellModel.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>

@implementation FusionContactUnCheckCell

- (void)configure:(id)model {
  if (![model isKindOfClass:[NEFusionContactCellModel class]]) {
    return;
  }

  NEFusionContactCellModel *cellModel = (NEFusionContactCellModel *)model;
  if (cellModel.user != nil) {
    NSString *url = cellModel.user.user.avatar;
    NSString *name = [cellModel getShortName:2];
    NSString *accountId = [cellModel getAccountId];
    [self.avatarImageView configHeadData:url name:name uid:accountId];
  } else if (cellModel.aiUser != nil) {
    NSString *url = cellModel.aiUser.avatar;
    NSString *name = [cellModel getShortName:2];
    NSString *accountId = [cellModel getAccountId];
    [self.avatarImageView configHeadData:url name:name uid:accountId];
  }
}

@end
