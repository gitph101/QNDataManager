//
//  QNDiskCacheIndexModel.h
//  Pods
//
//  Created by 研究院01 on 17/4/18.
//
//

#import <Foundation/Foundation.h>

@interface QNDiskCacheIndexModel : NSObject

@property (nonatomic, strong) NSString* key;
@property (nonatomic, assign) NSUInteger age;
@property (nonatomic, assign) NSUInteger cost;
@property (nonatomic, assign) NSUInteger createdTime;
@property (nonatomic, assign) BOOL saveInDisk;

- (NSString*)encodedString;
- (NSData*)encodedData;

+ (instancetype)loadFromData:(NSData*)data;

@end
