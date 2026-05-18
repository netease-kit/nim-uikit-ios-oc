// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "BrowserToolsBar.h"
#import "ExpandButton.h"
#import "NECommonUIConstant.h"
#import <NEChatKitOC/NECommonLoader.h>

@interface BrowserToolsBar ()

@property (nonatomic, strong, readwrite) ExpandButton *saveButton;
@property (nonatomic, strong, readwrite) ExpandButton *closeButton;

@end

@implementation BrowserToolsBar

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  self.backgroundColor = UIColor.clearColor;

  [self addSubview:self.closeButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.closeButton.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:20.0],
    [self.closeButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.closeButton.widthAnchor constraintEqualToConstant:28.0],
    [self.closeButton.heightAnchor constraintEqualToConstant:28.0],
  ]];
  [self.closeButton addTarget:self action:@selector(closeClick) forControlEvents:UIControlEventTouchUpInside];

  [self addSubview:self.saveButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.saveButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-20.0],
    [self.saveButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    [self.saveButton.widthAnchor constraintEqualToConstant:28.0],
    [self.saveButton.heightAnchor constraintEqualToConstant:28.0],
  ]];
  [self.saveButton addTarget:self action:@selector(saveClick) forControlEvents:UIControlEventTouchUpInside];
}

- (void)saveClick {
  [self.delegate didSaveClick];
}

- (void)closeClick {
  [self.delegate didCloseClick];
}

- (ExpandButton *)saveButton {
  if (!_saveButton) {
    _saveButton = [[ExpandButton alloc] init];
    _saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_saveButton setImage:[coreLoader() loadImage:@"save_btn"] forState:UIControlStateNormal];
  }
  return _saveButton;
}

- (ExpandButton *)closeButton {
  if (!_closeButton) {
    _closeButton = [[ExpandButton alloc] init];
    _closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_closeButton setImage:[coreLoader() loadImage:@"close_btn"] forState:UIControlStateNormal];
  }
  return _closeButton;
}

@end
