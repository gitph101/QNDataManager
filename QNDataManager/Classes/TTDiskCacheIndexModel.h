//
//  TTDiskCacheIndexModel.h
//  GiftTalk
//
//  Created by Xiaoxuan Tang on 5/22/15.
//  Copyright (c) 2015 TieTie Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTDiskCacheIndexModel : NSObject

@property (nonatomic, strong) NSString* key;
@property (nonatomic, assign) NSUInteger age;
@property (nonatomic, assign) NSUInteger cost;
@property (nonatomic, assign) NSUInteger createdTime;
@property (nonatomic, assign) BOOL saveInDisk;

- (NSString*)encodedString;
- (NSData*)encodedData;

+ (instancetype)loadFromData:(NSData*)data;
@end
