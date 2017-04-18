//
//  MTLModel+DiskCache.m
//  GiftTalk
//
//  Created by Xiaoxuan Tang on 11/5/15.
//  Copyright © 2015 TieTie Inc. All rights reserved.
//

#import "NSObject+DiskCache.h"
#import <objc/runtime.h>

@implementation NSObject (DiskCache)

- (BOOL)fromCache
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void) setfromCache:(BOOL)tt_fromCache
{
    objc_setAssociatedObject(self, @selector(tt_fromCache), @(tt_fromCache), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
