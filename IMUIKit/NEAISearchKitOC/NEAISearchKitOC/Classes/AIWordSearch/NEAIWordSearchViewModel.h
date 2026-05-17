// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class NEAIWordSearchModel;

@protocol NEAIWordSearchViewModelDelegate <NSObject>

- (void)tableViewReload:(BOOL)isLoading;

@end

@interface NEAIWordSearchViewModel : NSObject <V2NIMAIListener>

@property (nonatomic, weak, nullable) id<NEAIWordSearchViewModelDelegate> delegate;
@property (nonatomic, strong) NSMutableArray<NEAIWordSearchModel *> *data;

- (void)loadData:(nullable NSString *)searchText
      completion:(void (^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
