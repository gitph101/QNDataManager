//
//  QNDataBase.m
//  Pods
//
//  Created by 研究院01 on 17/4/13.
//
//

#import "QNDataBase.h"

static QNDataBase* dataBase = nil;
static dispatch_queue_t TTCacheDBQueue = nil;

@interface QNDataBase()
@property (nonatomic, strong) NSString* currentDBName;
@property (nonatomic, strong) LevelDB* levelDB;

- (void)switchToDB:(NSString*)dbName;
@end

@implementation QNDataBase

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!dataBase)
        {
            TTCacheDBQueue = dispatch_queue_create("com.tt.cache.db", NULL);
            dataBase = [QNDataBase new];
        }
    });
    return dataBase;
}

- (instancetype)init
{
    if (self = [super init])
    {
    }
    return self;
}

- (id)getValueForKey:(NSString*)key fromeDB:(NSString*)dbName
{
    NSAssert(key && [key isKindOfClass:[NSString class]], @"key is invalid");
    NSAssert(dbName && [dbName isKindOfClass:[NSString class]], @"dbName is invalid");
    __block id value = nil;
    dispatch_sync(TTCacheDBQueue, ^{
        [self switchToDB:dbName];
        value = self.levelDB[key];
    });
    return value;
}

- (void)setValue:(id)value forKey:(NSString *)key toDB:(NSString*)dbName
{
    NSAssert(key && [key isKindOfClass:[NSString class]], @"key is invalid");
    NSAssert(dbName && [dbName isKindOfClass:[NSString class]], @"dbName is invalid");
    NSAssert(value, @"value is not invalid");
    dispatch_async(TTCacheDBQueue, ^{
        [self switchToDB:dbName];
        [self.levelDB setValue:value forKey:key];
    });
}

- (void)removeValueForKey:(NSString*)key fromDB:(NSString*)dbName
{
    NSAssert(key && [key isKindOfClass:[NSString class]], @"key is invalid");
    NSAssert(dbName && [dbName isKindOfClass:[NSString class]], @"dbName is invalid");
    
    dispatch_async(TTCacheDBQueue, ^{
        [self switchToDB:dbName];
        [self.levelDB removeObjectForKey:key];
    });
}

- (void)switchToDB:(NSString*)dbName
{
    NSAssert(dbName && [dbName isKindOfClass:[NSString class]], @"dbName is invalid");
    //if db is not same as current db
    if (![dbName isEqualToString:self.currentDBName])
    {
#ifdef DEBUG
        //        NSLog(@"old count:%lu", (unsigned long)self.levelDB.allKeys.count);
#endif
        
        //close and connect
        [self.levelDB close];
        _currentDBName = dbName;
        self.levelDB = [[LevelDB alloc]initWithPath:[[TTLocalPathHelper libraryPath] stringByAppendingString:_currentDBName] andName:_currentDBName];
        
#ifdef DEBUG
        //        NSLog(@"new count:%lu", (unsigned long)self.levelDB.allKeys.count);
#endif
    }
}

@end
