// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UIImage+Chat.h"
#import "NEChatUIConstant.h"

@implementation UIImage (Chat)

+ (UIImage *)ne_imageNamed:(NSString *)name {
  if (!name) {
    return nil;
  }
  return chatLoadImage(name);
}

+ (UIImage *)ne_bundleImage:(NSString *)name {
  NSString *bundleName = [NSString stringWithFormat:@"NIMKitEmoticon.bundle/Emoji/%@", name];
  UIImage *image = chatLoadImage(bundleName);
  if (image) {
    return image;
  }
  return [[UIImage alloc] init];
}

- (UIImage *)fixOrientation {
  // Default orientation needs no fix
  if (self.imageOrientation == UIImageOrientationUp) {
    return self;
  }

  CGAffineTransform transform = CGAffineTransformIdentity;

  switch (self.imageOrientation) {
    case UIImageOrientationDown:
    case UIImageOrientationDownMirrored:
      transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
      transform = CGAffineTransformRotate(transform, M_PI);
      break;

    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
      transform = CGAffineTransformTranslate(transform, self.size.width, 0);
      transform = CGAffineTransformRotate(transform, M_PI_2);
      break;

    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
      transform = CGAffineTransformTranslate(transform, 0, self.size.height);
      transform = CGAffineTransformRotate(transform, -M_PI_2);
      break;

    default:
      break;
  }

  switch (self.imageOrientation) {
    case UIImageOrientationUpMirrored:
    case UIImageOrientationDownMirrored:
      transform = CGAffineTransformTranslate(transform, self.size.width, 0);
      transform = CGAffineTransformScale(transform, -1, 1);
      break;

    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRightMirrored:
      transform = CGAffineTransformTranslate(transform, self.size.height, 0);
      transform = CGAffineTransformScale(transform, -1, 1);
      break;

    default:
      break;
  }

  CGImageRef cgImage = self.CGImage;
  if (!cgImage) {
    return self;
  }

  CGContextRef ctx = CGBitmapContextCreate(NULL,
                                           (size_t)self.size.width,
                                           (size_t)self.size.height,
                                           CGImageGetBitsPerComponent(cgImage),
                                           0,
                                           CGImageGetColorSpace(cgImage),
                                           CGImageGetBitmapInfo(cgImage));
  if (!ctx) {
    return self;
  }

  CGContextConcatCTM(ctx, transform);

  // Redraw
  switch (self.imageOrientation) {
    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
      CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.height, self.size.width), cgImage);
      break;

    default:
      CGContextDrawImage(ctx, CGRectMake(0, 0, self.size.width, self.size.height), cgImage);
      break;
  }

  CGImageRef newCGImage = CGBitmapContextCreateImage(ctx);
  CGContextRelease(ctx);

  if (!newCGImage) {
    return self;
  }

  UIImage *result = [UIImage imageWithCGImage:newCGImage];
  CGImageRelease(newCGImage);
  return result;
}

@end
