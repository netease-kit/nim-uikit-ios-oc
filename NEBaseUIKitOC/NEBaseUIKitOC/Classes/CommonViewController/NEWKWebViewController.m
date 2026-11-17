// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEWKWebViewController.h"
#import "NENavigationView.h"

@interface NEWKWebViewController ()
@property (nonatomic, copy) NSString *loadUrl;
@end

@implementation NEWKWebViewController

- (instancetype)initWithUrl:(NSString *)url title:(NSString *)title {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _loadUrl = url;
    self.title = title;
  }
  return self;
}

- (WKWebView *)webview {
  if (!_webview) {
    _webview = [[WKWebView alloc] init];
    _webview.translatesAutoresizingMaskIntoConstraints = NO;
    _webview.navigationDelegate = self;
  }
  return _webview;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setUpSubViews];
}

- (void)setUpSubViews {
  self.navigationView.backgroundColor = UIColor.whiteColor;
  self.navigationView.moreButton.hidden = YES;
  self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;

  NSURL *requestUrl = [NSURL URLWithString:_loadUrl];
  if (!requestUrl) return;

  NSURLRequest *request = [NSURLRequest requestWithURL:requestUrl];
  [self.webview loadRequest:request];
  [self.view addSubview:self.webview];

  [NSLayoutConstraint activateConstraints:@[
    [self.webview.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.webview.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.webview.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
    [self.webview.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
  [self handleWebViewError:error];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
  [self handleWebViewError:error];
}

- (void)handleWebViewError:(NSError *)error {
  NSString *message;
  switch (error.code) {
    case NSURLErrorNotConnectedToInternet:
      message = @"网络错误";
      break;
    case NSURLErrorTimedOut:
      message = @"请求超时";
      break;
    case NSURLErrorCannotFindHost:
    case NSURLErrorBadURL:
      message = @"无效的 URL";
      break;
    default:
      message = [NSString stringWithFormat:@"加载失败: %ld", (long)error.code];
      break;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    [self showSingleAlertWithMessage:message completion:^{
      [self.navigationController popViewControllerAnimated:YES];
    }];
  });
  NSString *html = @"<html><body style='font-family:-apple-system;padding:20px'>"
                   @"<h2 style='color:#FF3B30'>Page Failed to Load</h2>"
                   @"<p>Please check your internet connection or verify the URL.</p>"
                   @"</body></html>";
  [self.webview loadHTMLString:html baseURL:nil];
}

@end
