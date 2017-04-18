//
//  QNDiskCacheIndexModel.m
//  Pods
//
//  Created by 研究院01 on 17/4/18.
//
//

#import "QNDiskCacheIndexModel.h"

@implementation QNDiskCacheIndexModel

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
    QNDiskCacheIndexModel* model = [QNDiskCacheIndexModel new];
    model.key = [NSString stringWithCString:str_key encoding:NSUTF8StringEncoding];
    model.age = age;
    model.cost = cost;
    model.createdTime = createdTime;
    model.saveInDisk = saveInDisk;
    return model;
}

@end
