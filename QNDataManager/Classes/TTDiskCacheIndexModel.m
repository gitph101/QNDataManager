//
//  TTDiskCacheIndexModel.m
//  GiftTalk
//
//  Created by Xiaoxuan Tang on 5/22/15.
//  Copyright (c) 2015 TieTie Inc. All rights reserved.
//

#import "TTDiskCacheIndexModel.h"

@implementation TTDiskCacheIndexModel

//TTDiskCacheIndexModel因为效率问题打一开始就没有使用Mantle，而是自己实现了serialization的两向过程
//+ (NSDictionary *)JSONKeyPathsByPropertyKey
//{
//    static NSDictionary* dict = nil;
//    
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        dict = @{@"key":@"key",
//                 @"age":@"age",
//                 @"cost":@"cost",
//                 @"createdTime":@"createdTime",
//                 @"saveInDisk":@"saveInDisk"
//                 };
//    });
//    
//    return dict;
//}

- (NSString*)encodedString
{
    NSData* data = [self encodedData];
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData*)encodedData
{
    char s[255];
    int n = sprintf(s, "%s %lu %lu %lu %d", [self.key cStringUsingEncoding:NSUTF8StringEncoding], (unsigned long)self.age, (unsigned long)self.cost, (unsigned long)self.createdTime, self.saveInDisk);
    NSData* data = [NSData dataWithBytes:s length:n];
    return data;
}

+ (instancetype)loadFromData:(NSData*)data
{
    if (!data)
    {
        return nil;
    }
    NSString* string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    unsigned int age, cost , createdTime;
    unsigned int saveInDisk = 0;
    char str_key[40];
    sscanf([string cStringUsingEncoding:NSUTF8StringEncoding], "%s %d %d %d %d", str_key, &age, &cost, &createdTime, &saveInDisk);
    TTDiskCacheIndexModel* model = [TTDiskCacheIndexModel new];
    model.key = [NSString stringWithCString:str_key encoding:NSUTF8StringEncoding];
    model.age = age;
    model.cost = cost;
    model.createdTime = createdTime;
    model.saveInDisk = saveInDisk;
    return model;
}
@end
