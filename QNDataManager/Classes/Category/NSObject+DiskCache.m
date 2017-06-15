//
//  MTLModel+DiskCache.m
//
//
//  Created by Xiaoxuan Tang on 11/5/15.
// 
//

#import "NSObject+DiskCache.h"
#import <objc/runtime.h>

@implementation NSObject (DiskCache)

- (BOOL)fromCache
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void) setfromCache:(BOOL)fromCache
{
    objc_setAssociatedObject(self, @selector(fromCache), @(fromCache), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
