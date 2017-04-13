//
//  QNDataBase.h
//  Pods
//
//  Created by 研究院01 on 17/4/13.
//
//

#import <Foundation/Foundation.h>

@interface QNDataBase : NSObject

+ (instancetype)sharedInstance;

- (id)getValueForKey:(NSString*)key fromeDB:(NSString*)dbName;

- (void)setValue:(id)value forKey:(NSString *)key toDB:(NSString*)dbName;

- (void)removeValueForKey:(NSString*)key fromDB:(NSString*)dbName;

@end
