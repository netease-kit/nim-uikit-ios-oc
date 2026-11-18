// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageCallRecordModel.h"
#import "ChatCellConstantValue.h"
#import "NEChatUIConstant.h"
#import "ChatUIConfig.h"
#import "ChatMessageHelper.h"
#import <NEChatKit/NSDate+NECommon.h>
#import <NEChatKit/NSString+NECommon.h>
#import <NIMSDK/NIMSDK.h>

@implementation MessageCallRecordModel

- (instancetype)initWithMessage:(V2NIMMessage *)message {
  self = [super initWithMessage:message];
  if (self) {
    self.type = MessageTypeRtcCallRecord;
    BOOL isAudioRecord = NO;

    if ([message.attachment isKindOfClass:[V2NIMMessageCallAttachment class]]) {
      V2NIMMessageCallAttachment *attach = (V2NIMMessageCallAttachment *)message.attachment;
      _callRecordAttributeStr = [[NSMutableAttributedString alloc] init];

      NSInteger callType = attach.type;
      NSInteger callStatus = attach.status;
      UIImage *image = nil;
      CGRect bound = CGRectZero;
      CGFloat offset = -1.0f;

      if (callType == 1) {
        isAudioRecord = YES;
        image = chatLoadImage(@"audio_record");
        bound = CGRectMake(0, offset - 5, 24, 24);
      } else {
        image = chatLoadImage(@"video_record");
        bound = CGRectMake(0, offset, 24, 14);
      }

      switch (callStatus) {
        case 1: {
          NSTimeInterval duration = 0;
          for (V2NIMMessageCallDuration *durationModel in attach.durations) {
            if ([durationModel.accountId isEqualToString:message.senderId]) {
              duration = (NSTimeInterval)durationModel.duration;
              break;
            }
          }
          NSString *timeString = [NSDate ne_getFormatPlayTime:duration];
          NSString *text = [NSString stringWithFormat:@"%@ %@", chatLocalizable(@"call_complete"), timeString];
          [_callRecordAttributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:text]];
          break;
        }
        case 2:
          [_callRecordAttributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:chatLocalizable(@"call_canceled")]];
          break;
        case 3:
          [_callRecordAttributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:chatLocalizable(@"call_rejected")]];
          break;
        case 4:
          [_callRecordAttributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:chatLocalizable(@"call_timeout")]];
          break;
        case 5:
          [_callRecordAttributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:chatLocalizable(@"call_busy")]];
          break;
        default:
          break;
      }

      NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
      attachment.image = image;
      attachment.bounds = bound;

      UIColor *messageTextColor = nil;
      if ([ChatMessageHelper isSelf:message]) {
        [_callRecordAttributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        [_callRecordAttributeStr appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
        messageTextColor = [ChatUIConfig shared].messageProperties.selfMessageTextColor;
      } else {
        [_callRecordAttributeStr insertAttributedString:[[NSAttributedString alloc] initWithString:@" "] atIndex:0];
        [_callRecordAttributeStr insertAttributedString:[NSAttributedString attributedStringWithAttachment:attachment] atIndex:0];
        messageTextColor = [ChatUIConfig shared].messageProperties.receiveMessageTextColor;
      }

      NSRange fullRange = NSMakeRange(0, _callRecordAttributeStr.length);
      [_callRecordAttributeStr addAttribute:NSFontAttributeName value:self.messageTextFont range:fullRange];
      [_callRecordAttributeStr addAttribute:NSForegroundColorAttributeName value:messageTextColor range:fullRange];
    }

    CGSize textSize = [NSAttributedString getRealTextViewSize:_callRecordAttributeStr
                                                         font:self.messageTextFont
                                                      maxSize:self.messageMaxSize];
    CGFloat contentSizeWidth = textSize.width + chat_cell_margin * 2;
    CGFloat contentSizeHeight = textSize.height + (isAudioRecord ? 20 : 24);
    self.contentSize = CGSizeMake(contentSizeWidth, contentSizeHeight);
    self.height = contentSizeHeight + chat_content_margin * 2 + self.fullNameHeight + chat_pin_height;
  }
  return self;
}

@end
