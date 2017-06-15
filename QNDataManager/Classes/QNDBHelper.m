//
//  QNDBHelper.m
//  Pods
//
//  Created by 研究院01 on 17/4/14.
//
//

#import "QNDBHelper.h"
#import "LevelDB.h"
#import "YTKKeyValueStore.h"


//是否使用SQLite作为数据库引擎
static BOOL kQNShouldSQLite = NO;
static QNDBHelper* helper = nil;
static dispatch_queue_t QNCacheDBQueue = nil;
static NSString* const QNSQLiteNameKey = @"com.qn.QNSQLiteNameKey";

///
/// 两套数据引擎 对于SQLite 而言 dbName 指的是表的名字。数据名字为QNSQLiteNameKey
///

@interface QNDBHelper()
@property (nonatomic, strong) NSString* currentDBName;
@property (nonatomic, strong) LevelDB* levelDB;
@property (nonatomic, strong) YTKKeyValueStore *sqliteDB;
@property (nonatomic, strong) NSString *tableName;

- (void)switchToDB:(NSString*)dbName;
@end

@implementation QNDBHelper

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!helper){
            QNCacheDBQueue = dispatch_queue_create("com.qn.queue", NULL);
            helper = [QNDBHelper new];
        }
    });
    return helper;
}

#pragma mark - Public


- (id)getValueForKey:(NSString*)key fromeDB:(NSString*)dbName
{
    NSAssert(key && [key isKindOfClass:[NSString class]], @"key is invalid");
    NSAssert(dbName && [dbName isKindOfClass:[NSString class]], @"dbName is invalid");
    __block id value = nil;
    dispatch_sync(QNCacheDBQueue, ^{
        if (kQNShouldSQLite == YES) {
            [self _qn_getValueForKey:key fromeSQLiteDB:dbName];
        }else {
            [self _qn_getValueForKey:key fromeLevelDB:dbName];
        }
    });
    return value;
}

- (void)setValue:(id)value forKey:(NSString *)key toDB:(NSString*)dbName
{
    NSAssert(key && [key isKindOfClass:[NSString class]], @"key is invalid");
    NSAssert(dbName && [dbName isKindOfClass:[NSString class]], @"dbName is invalid");
    NSAssert(value, @"value is not invalid");
    dispatch_async(QNCacheDBQueue, ^{
        if (kQNShouldSQLite == YES) {
            [self _qn_setValue:value forKey:key SQLiteDB:dbName];
        }else {
            [self _qn_setValue:value forKey:key LevelDB:dbName];
        }
    });
}

- (void)removeValueForKey:(NSString*)key fromDB:(NSString*)dbName
{
    NSAssert(key && [key isKindOfClass:[NSString class]], @"key is invalid");
    NSAssert(dbName && [dbName isKindOfClass:[NSString class]], @"dbName is invalid");
    
    dispatch_async(QNCacheDBQueue, ^{
        if (kQNShouldSQLite == YES) {
            [self _qn_removeValueForKey:key fromeSQLiteDB:dbName];
        }else {
            [self _qn_removeValueForKey:key fromeLevelDB:dbName];
        }
    });
}

- (void)switchToDB:(NSString*)dbName
{
    NSAssert(dbName && [dbName isKindOfClass:[NSString class]], @"dbName is invalid");
    //if db is not same as current db
    if (![dbName isEqualToString:self.currentDBName])
    {
        if (kQNShouldSQLite == YES) {
            [self _qn_switchToSQLiteDB:dbName];
        }else {
            [self _qn_switchToLevelDB:dbName];
        }
    }
}

#pragma mark - Private


- (void)_qn_switchToLevelDB:(NSString*)dbName
{
    [self.levelDB close];
    self.currentDBName = dbName;
    self.levelDB = [[LevelDB alloc]initWithPath:[[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/"] stringByAppendingString:_currentDBName] andName:_currentDBName];
}

/// get
- (void)_qn_switchToSQLiteDB:(NSString*)dbName
{
    self.tableName = dbName;
    self.sqliteDB = [[YTKKeyValueStore alloc] initDBWithName:QNSQLiteNameKey];
    [self.sqliteDB createTableWithName:self.tableName];
}

- (id)_qn_getValueForKey:(NSString*)key fromeSQLiteDB:(NSString*)dbName
{
    [self switchToDB:dbName];
    __block id value = nil;
    value = self.levelDB[key];
    return value;
}

- (id)_qn_getValueForKey:(NSString*)key fromeLevelDB:(NSString*)dbName
{
    __block id value = nil;
     value = [self.sqliteDB getObjectById:key fromTable:self.tableName];
    return value;
}
///set
- (void)_qn_setValue:(id)value forKey:(NSString *)key SQLiteDB:(NSString*)dbName
{
    [self.sqliteDB putObject:value withId:key intoTable:dbName];
}

- (void)_qn_setValue:(id)value forKey:(NSString *)key LevelDB:(NSString*)dbName
{
    [self _qn_switchToLevelDB:dbName];
    [self.levelDB setValue:value forKey:key];
}
///remove
- (void)_qn_removeValueForKey:(NSString*)key fromeSQLiteDB:(NSString*)dbName
{
    [self.sqliteDB deleteObjectById:key fromTable:dbName];
}

- (void)_qn_removeValueForKey:(NSString*)key fromeLevelDB:(NSString*)dbName
{
    [self _qn_switchToLevelDB:dbName];
    [self.levelDB removeObjectForKey:key];
}

@end
