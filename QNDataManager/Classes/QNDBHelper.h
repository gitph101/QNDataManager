//
//  QNDBHelper.h
//  Pods
//
//  Created by 研究院01 on 17/4/14.
//
//

#import <Foundation/Foundation.h>

@interface QNDBHelper : NSObject

+ (instancetype)sharedInstance;

- (id)getValueForKey:(NSString*)key fromeDB:(NSString*)dbName;

- (void)setValue:(id)value forKey:(NSString *)key toDB:(NSString*)dbName;

- (void)removeValueForKey:(NSString*)key fromDB:(NSString*)dbName;


@end
