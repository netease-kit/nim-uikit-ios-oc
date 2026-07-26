#import "FunMultiSelectedViewController.h"
#import "FunSelectedListCell.h"
#import <NEChatKit/NEConstant.h>

@interface FunMultiSelectedViewController ()

@property(nonatomic, strong, nullable) UITapGestureRecognizer *backgroundTapGesture;

@end

@implementation FunMultiSelectedViewController

- (void)dealloc {
  if (self.backgroundTapGesture) {
    [self.view.superview removeGestureRecognizer:self.backgroundTapGesture];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.tableView.rowHeight = 64.0;
  [self.tableView registerClass:[FunSelectedListCell class]
         forCellReuseIdentifier:NSStringFromClass([NEBaseSelectedListCell class])];
  self.tableViewTopAnchor.constant = 50.0;
  [self.emptyView setEmptyImageName:@"fun_user_empty"];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  self.view.layer.cornerRadius = 8.0;
  self.view.layer.borderWidth = 0.5;
  self.view.layer.borderColor = [UIColor lightGrayColor].CGColor;
  self.view.frame = CGRectMake(0.0,
                               [NEConstant screenHeight] - 380.0,
                               [NEConstant screenWidth],
                               380.0);

  if (!self.backgroundTapGesture && self.view.superview) {
    self.backgroundTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.view.superview addGestureRecognizer:self.backgroundTapGesture];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 64.0;
}

- (void)tapAction:(UITapGestureRecognizer *)tap {
  if ([tap locationInView:self.view].y < 0) {
    [self cancelButtonClick];
  }
}

@end
