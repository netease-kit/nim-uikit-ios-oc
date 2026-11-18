// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import "TopicChatViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NETopicChatViewModelOutput <TopicChatViewModelOutput>
@end

@interface NETopicChatViewModel : TopicChatViewModel
- (instancetype)initWithConversationId:(NSString *)conversationId
                                  topic:(nullable V2NIMTopic *)topic
                            sessionName:(NSString *)sessionName;
- (void)updateTopicName:(NSString *)name completion:(void (^)(NSError *_Nullable error))completion;
@end

NS_ASSUME_NONNULL_END
