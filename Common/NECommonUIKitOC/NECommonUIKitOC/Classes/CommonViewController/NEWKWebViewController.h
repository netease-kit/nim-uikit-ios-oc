// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NECommonUIKitOC/NEBaseViewController.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEWKWebViewController : NEBaseViewController <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webview;

- (instancetype)initWithUrl:(NSString *)url title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
