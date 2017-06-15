//
//  QNDiskCache.h
//  Pods
//
//  Created by 研究院01 on 17/4/13.
//
//

#import <Foundation/Foundation.h>

@interface QNDiskCache : NSObject

- (instancetype) initWithCapacity: (NSUInteger)capacity
                             name: (NSString* ) name;

- (instancetype) initWithCapacity: (NSUInteger) capacity;

- (NSUInteger) capacity;
- (NSUInteger) currentUsage;

- (void) setString: (NSString*) str
            forKey: (NSString*) key
               age: (NSUInteger) age;

- (void) setData: (NSData*) data
          forKey: (NSString*) key
             age: (NSUInteger) age;

/**
 *  调用这个接口存储的数据会存在磁盘,不会存入数据库
 */
- (void) setResource: (NSData*) data
              forKey: (NSString*) key
                 age: (NSUInteger) age;


- (void) setORMItem: (id)item forKey:(NSString*)key age:(NSUInteger)age;

/**
 *  和 Plist 序列化一个标准的
 *
 *  @param items items 全都是由 NS 系列组成的
 *  @param key   key
 *  @param age   过期时间
 */
- (void) setFoundationItem: (id) item
                    forKey: (NSString*) key
                       age: (NSUInteger) age;


- (NSData*) valueForKey:(NSString *)key;
- (NSString*) stringValueForKey: (NSString*) key;
- (id) foundationItemForKey: (NSString*) key;

- (id) ormItemForKey:(NSString*)key ofClass:(Class)c;

- (void) removeObjectForkey: (NSString*) key;
- (void) removeAllData;
- (void) removeAllExpiredData;

@end
