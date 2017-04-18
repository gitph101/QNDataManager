//
//  NSArray+JSON.m
//  Pods
//
//  Created by 研究院01 on 17/4/14.
//
//

#import "NSArray+JSON.h"
#import "YYModel.h"

@implementation NSArray (JSON)

- (NSData*) JsonData
{
    return [NSJSONSerialization dataWithJSONObject:self
                                           options:0
                                             error:nil];
}

- (NSData*) jsonDataWithYYModel {
    NSData* data = [self yy_modelToJSONData];
    @try {
        if (!data) {
            [NSException exceptionWithName:@"YYModelParseError" reason:@"Error while transform arr to jsondata from cache" userInfo:nil];
        }
    } @catch (NSException *exception) {
    } @finally {
    }
    return data;
}

@end
