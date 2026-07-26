// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseScanQRViewController.h"
#import "NEConversationLoader.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <NEChatKit/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@interface NEScanBeamView : UIView

@property (nonatomic, strong) UIColor *beamColor;
@property (nonatomic, strong) UIColor *glowColor;

@end

@implementation NEScanBeamView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    _beamColor = [UIColor colorWithRed:0.275 green:0.525 blue:1.0 alpha:1.0];
    _glowColor = [UIColor colorWithRed:0.337 green:0.659 blue:1.0 alpha:1.0];
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
  }
  return self;
}

- (void)setBeamColor:(UIColor *)beamColor {
  _beamColor = beamColor ?: [UIColor clearColor];
  [self setNeedsDisplay];
}

- (void)setGlowColor:(UIColor *)glowColor {
  _glowColor = glowColor ?: [UIColor clearColor];
  [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  if (ctx == NULL) {
    return;
  }

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));

  [self drawEllipticalGradientInContext:ctx
                             colorSpace:colorSpace
                                 colors:@[
                                   self.glowColor,
                                   [self.glowColor colorWithAlphaComponent:0.28],
                                   [UIColor clearColor]
                                 ]
                              locations:@[@0.0, @0.50, @1.0]
                                 center:center
                                hRadius:CGRectGetWidth(rect) * 0.53
                                vRadius:CGRectGetHeight(rect) * 0.96];

  [self drawEllipticalGradientInContext:ctx
                             colorSpace:colorSpace
                                 colors:@[
                                   self.beamColor,
                                   [self.beamColor colorWithAlphaComponent:0.22],
                                   [UIColor clearColor]
                                 ]
                              locations:@[@0.0, @0.42, @1.0]
                                 center:center
                                hRadius:CGRectGetWidth(rect) * 0.36
                                vRadius:CGRectGetHeight(rect) * 0.53];

  CGColorSpaceRelease(colorSpace);
}

- (void)drawEllipticalGradientInContext:(CGContextRef)ctx
                             colorSpace:(CGColorSpaceRef)colorSpace
                                 colors:(NSArray<UIColor *> *)colors
                              locations:(NSArray<NSNumber *> *)locations
                                 center:(CGPoint)center
                                hRadius:(CGFloat)hRadius
                                vRadius:(CGFloat)vRadius {
  if (vRadius <= 0 || colors.count == 0 || colors.count != locations.count) {
    return;
  }

  NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:colors.count];
  NSUInteger count = locations.count;
  CGFloat *locationValues = count > 0 ? malloc(sizeof(CGFloat) * count) : NULL;
  for (NSUInteger idx = 0; idx < count; idx++) {
    locationValues[idx] = locations[idx].doubleValue;
  }
  for (UIColor *color in colors) {
    [cgColors addObject:(id)color.CGColor];
  }

  CGGradientRef gradient =
      CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)cgColors, locationValues);
  if (locationValues != NULL) {
    free(locationValues);
  }
  if (gradient == NULL) {
    return;
  }

  CGContextSaveGState(ctx);
  CGContextTranslateCTM(ctx, center.x, center.y);
  CGContextScaleCTM(ctx, hRadius / vRadius, 1.0);
  CGContextDrawRadialGradient(ctx,
                              gradient,
                              CGPointZero,
                              0,
                              CGPointZero,
                              vRadius,
                              kCGGradientDrawsBeforeStartLocation);
  CGContextRestoreGState(ctx);
  CGGradientRelease(gradient);
}

@end

static NECommonLoader *NEConversationScanLoader(void) {
  static NECommonLoader *loader = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:[NEConversationLoader class]];
  });
  return loader;
}

static NSString *NEConversationScanLocalizable(NSString *key) {
  return [NEConversationScanLoader() localizable:key];
}

@interface NEBaseScanQRViewController () <AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) UIView *previewContainer;
@property (nonatomic, strong) NEScanBeamView *scanBeamView;
@property (nonatomic, strong, nullable) AVCaptureSession *captureSession;
@property (nonatomic, strong, nullable) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong, nullable) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong, nullable) NSLayoutConstraint *scanBeamTopConstraint;
@property (nonatomic, strong) CIDetector *qrDetector;
@property (nonatomic, strong) dispatch_queue_t scanQueue;
@property (nonatomic, assign) BOOL isAnimationStarted;
@property (atomic, assign) BOOL isHandlingScanResult;

@end

@implementation NEBaseScanQRViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = NEConversationScanLocalizable(@"scan_qr");
  self.view.backgroundColor = [UIColor blackColor];
  [self setupScanUI];
  [self checkCameraPermission];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  self.previewLayer.frame = self.previewContainer.bounds;
  if (!self.isAnimationStarted && CGRectGetHeight(self.view.bounds) > 0) {
    self.isAnimationStarted = YES;
    [self startScanAnimation];
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self startRunning];
  if (self.isAnimationStarted) {
    [self startScanAnimation];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self stopRunning];
  [self stopScanAnimation];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

- (void)dealloc {
  [self.videoDataOutput setSampleBufferDelegate:nil queue:NULL];
}

- (void)setupScanUI {
  self.previewContainer = [[UIView alloc] init];
  self.previewContainer.translatesAutoresizingMaskIntoConstraints = NO;
  if (self.navigationView.superview == self.view) {
    [self.view insertSubview:self.previewContainer belowSubview:self.navigationView];
  } else {
    [self.view addSubview:self.previewContainer];
  }
  [NSLayoutConstraint activateConstraints:@[
    [self.previewContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.previewContainer.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.previewContainer.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.previewContainer.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.navigationView setNavigationBackgroundColor:[UIColor clearColor]];
  self.navigationView.navTitle.textColor = [UIColor whiteColor];
  self.navigationView.titleBarBottomLine.hidden = YES;

  UIImage *backImage = [[self.navigationView.backButton imageForState:UIControlStateNormal]
      imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  [self.navigationView.backButton setImage:backImage forState:UIControlStateNormal];
  self.navigationView.backButton.tintColor = [UIColor whiteColor];

  self.scanBeamView = [[NEScanBeamView alloc] init];
  self.scanBeamView.translatesAutoresizingMaskIntoConstraints = NO;
  if (self.navigationView.superview == self.view) {
    [self.view insertSubview:self.scanBeamView belowSubview:self.navigationView];
  } else {
    [self.view addSubview:self.scanBeamView];
  }
  self.scanBeamTopConstraint = [self.scanBeamView.topAnchor constraintEqualToAnchor:self.view.topAnchor];
  self.scanBeamTopConstraint.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.scanBeamView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.scanBeamView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.scanBeamView.heightAnchor constraintEqualToConstant:64.0],
  ]];
}

- (void)startScanAnimation {
  [self.scanBeamView.layer removeAllAnimations];

  CGFloat navBottom = CGRectGetMaxY(self.navigationView.frame);
  CGFloat viewHeight = CGRectGetHeight(self.view.bounds);

  [UIView performWithoutAnimation:^{
    self.scanBeamTopConstraint.constant = navBottom;
    [self.view layoutIfNeeded];
  }];

  [self animateBeamFromY:navBottom toY:viewHeight];
}

- (void)animateBeamFromY:(CGFloat)startY toY:(CGFloat)endY {
  [UIView animateWithDuration:2.5
                        delay:0
                      options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                   animations:^{
    self.scanBeamTopConstraint.constant = endY;
    [self.view layoutIfNeeded];
  } completion:^(BOOL finished) {
    if (!finished) {
      return;
    }
    [UIView performWithoutAnimation:^{
      self.scanBeamTopConstraint.constant = startY;
      [self.view layoutIfNeeded];
    }];
    [self animateBeamFromY:startY toY:endY];
  }];
}

- (void)stopScanAnimation {
  [self.scanBeamView.layer removeAllAnimations];
}

- (void)checkCameraPermission {
  AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  switch (status) {
    case AVAuthorizationStatusAuthorized:
      [self setupCaptureSession];
      break;
    case AVAuthorizationStatusNotDetermined: {
      __weak typeof(self) weakSelf = self;
      [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
          if (granted) {
            [weakSelf setupCaptureSession];
          } else {
            [weakSelf.view ne_makeToast:NEConversationScanLocalizable(@"scan_qr_no_camera_permission")];
          }
        });
      }];
      break;
    }
    default:
      [self.view ne_makeToast:NEConversationScanLocalizable(@"scan_qr_no_camera_permission")];
      break;
  }
}

- (void)setupCaptureSession {
  AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  NSError *error = nil;
  AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
  if (device == nil || input == nil || error != nil) {
    return;
  }

  AVCaptureSession *session = [[AVCaptureSession alloc] init];
  session.sessionPreset = AVCaptureSessionPresetHigh;
  if (![session canAddInput:input]) {
    return;
  }
  [session addInput:input];

  AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
  if (![session canAddOutput:output]) {
    return;
  }
  [session addOutput:output];
  [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

  NSArray<AVMetadataObjectType> *supportedTypes = @[
    AVMetadataObjectTypeQRCode,
    AVMetadataObjectTypeEAN13Code,
    AVMetadataObjectTypeEAN8Code,
    AVMetadataObjectTypeCode128Code,
    AVMetadataObjectTypeCode39Code,
    AVMetadataObjectTypeCode93Code,
    AVMetadataObjectTypeAztecCode,
    AVMetadataObjectTypePDF417Code,
    AVMetadataObjectTypeDataMatrixCode,
  ];
  NSMutableArray<AVMetadataObjectType> *availableTypes = [NSMutableArray array];
  for (AVMetadataObjectType type in supportedTypes) {
    if ([output.availableMetadataObjectTypes containsObject:type]) {
      [availableTypes addObject:type];
    }
  }
  if (availableTypes.count > 0) {
    output.metadataObjectTypes = availableTypes;
  }
  output.rectOfInterest = CGRectMake(0, 0, 1, 1);

  AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
  videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
  videoDataOutput.videoSettings = @{
    (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
  };
  if ([session canAddOutput:videoDataOutput]) {
    [session addOutput:videoDataOutput];
    [videoDataOutput setSampleBufferDelegate:self queue:self.scanQueue];
    self.videoDataOutput = videoDataOutput;
  }

  self.captureSession = session;

  AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
  previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  previewLayer.frame = self.previewContainer.bounds;
  [self.previewContainer.layer insertSublayer:previewLayer atIndex:0];
  self.previewLayer = previewLayer;

  [self startRunning];
}

- (void)startRunning {
  if (self.captureSession == nil || self.captureSession.isRunning) {
    return;
  }
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    [self.captureSession startRunning];
  });
}

- (void)stopRunning {
  if (self.captureSession == nil || !self.captureSession.isRunning) {
    return;
  }
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    [self.captureSession stopRunning];
  });
}

- (void)metadataOutput:(AVCaptureMetadataOutput *)output
 didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
        fromConnection:(AVCaptureConnection *)connection {
  for (AVMetadataObject *metadataObject in metadataObjects) {
    AVMetadataMachineReadableCodeObject *obj =
        [metadataObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]] ?
        (AVMetadataMachineReadableCodeObject *)metadataObject : nil;
    NSString *value = obj.stringValue;
    if (value.length > 0) {
      [self handleDetectedQRCode:value];
      return;
    }
  }
}

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
  if (self.isHandlingScanResult || sampleBuffer == NULL) {
    return;
  }

  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (imageBuffer == NULL) {
    return;
  }

  CIImage *image = [CIImage imageWithCVPixelBuffer:imageBuffer];
  NSArray<CIFeature *> *features = [self.qrDetector featuresInImage:image];
  for (CIFeature *feature in features) {
    if (![feature isKindOfClass:[CIQRCodeFeature class]]) {
      continue;
    }

    NSString *value = ((CIQRCodeFeature *)feature).messageString;
    if (value.length == 0) {
      continue;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
      [self handleDetectedQRCode:value];
    });
    return;
  }
}

- (void)handleDetectedQRCode:(NSString *)value {
  if (value.length == 0 || self.isHandlingScanResult) {
    return;
  }

  self.isHandlingScanResult = YES;
  [self stopRunning];
  if (@available(iOS 10.0, *)) {
    [[[UINotificationFeedbackGenerator alloc] init] notificationOccurred:UINotificationFeedbackTypeSuccess];
  }
  [self handleScanResult:value];
}

- (void)handleScanResult:(NSString *)result {
  if (self.onScanResult) {
    BOOL handled = self.onScanResult(result);
    if (!handled) {
      self.isHandlingScanResult = NO;
      [self startRunning];
    }
    return;
  }

  [self.view ne_makeToast:[NSString stringWithFormat:NEConversationScanLocalizable(@"scan_qr_result"), result]];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    [self.navigationController popViewControllerAnimated:YES];
  });
}

- (dispatch_queue_t)scanQueue {
  if (!_scanQueue) {
    _scanQueue = dispatch_queue_create("com.netease.nim.conversation.scan.qr", DISPATCH_QUEUE_SERIAL);
  }
  return _scanQueue;
}

- (CIDetector *)qrDetector {
  if (!_qrDetector) {
    _qrDetector = [CIDetector detectorOfType:CIDetectorTypeQRCode
                                     context:nil
                                     options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
  }
  return _qrDetector;
}

@end
