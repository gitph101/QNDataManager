//
//  NSData+JSON.m
//  GiftTalk
//
//  Created by Xiaoxuan Tang on 5/22/15.
//  Copyright (c) 2015 TieTie Inc. All rights reserved.
//

#import "NSData+JSON.h"

@implementation NSData (JSON)

- (id) tt_JsonObject
{
    return [NSJSONSerialization JSONObjectWithData:self
                                           options:0
                                             error:nil];
}

@end
