//
//  QNDiskCache.m
//  Pods
//
//  Created by 研究院01 on 17/4/13.
//
//

#import "QNDiskCache.h"
#import "NSString+MD5.h"
#import "QNDBHelper.h"
#import "QNDiskCacheIndexModel.h"
#import "NSArray+JSON.h"
#import "YYModel.h"
#import "NSObject+DiskCache.h"
#import "NSData+JSON.h"

#define SEPERATOR_MODELS @"#"

static NSString* const QNDiskCacheIndexKey = @"com.soufun.QNDiskCacheIndexKey";
static NSMapTable* QNCacheMapTableKeyToCache = nil;
static dispatch_queue_t QNDiskCacheIoQueue = nil;

@interface QNDiskCache ()

@property (nonatomic, assign) NSUInteger capacity;
@property (nonatomic, assign) NSUInteger currentUsage;
@property (nonatomic, strong) NSString* dbName;
@property (nonatomic, strong) NSMutableArray* index;
@property (nonatomic, strong) NSMutableDictionary* indexDic;
@property (nonatomic, strong) NSMutableString* indexDes;//index在内存里面的字符串表示，对index的修改反映到这个字符串上，然后需要写DB的时候，只需要把这个字符串序列化就可以了

@property (nonatomic, strong) NSString* resourcePath; //缓存资源的磁盘路径, 为 rootpath/ + md5(dbName)/

/**
 *  remove key 对应的缓存
 *
 *  @param originKey   key
 *  @param isMd5Format 是否是md5格式
 */
- (void)removeObjectForkey:(NSString *)originKey md5ed:(BOOL)isMd5Format;

@end

@implementation QNDiskCache

+ (void)load
{
    QNCacheMapTableKeyToCache = [NSMapTable strongToWeakObjectsMapTable];
    QNDiskCacheIoQueue = dispatch_queue_create("com.soufun.disk.resource.cache", DISPATCH_QUEUE_SERIAL);
}

#pragma mark - public

- (instancetype) initWithCapacity: (NSUInteger)capacity
                             name: (NSString* ) name
{
    if (self = [super init])
    {
        //如果对应的缓存对象已经存在，则直接返回
        @synchronized(QNCacheMapTableKeyToCache)
        {
            if ([QNCacheMapTableKeyToCache objectForKey:name]){
                self = [QNCacheMapTableKeyToCache objectForKey:name];
            }
            else{
               [QNCacheMapTableKeyToCache setObject:self forKey:name];
                self.capacity = capacity;
                self.currentUsage = 0;
                NSString* dbName = name;
                if (!dbName){
                    dbName = @"cache";
                }
                self.dbName = dbName;
                self.resourcePath = [self _qn_diskResourcePath:dbName];
                [self _qn_loadIndex];
            }
            //更新capacity
            self.capacity = capacity;
            if (0 != self.capacity && self.currentUsage >= self.capacity){
                [self _qn_poorData];
            }
        }
    }
    return self;
}

- (instancetype) initWithCapacity: (NSUInteger) capacity
{
    return [self initWithCapacity: capacity
                             name: @"cache.db"];
}


- (NSUInteger) capacity
{
    return _capacity;
}

- (NSUInteger) currentUsage
{
    return _currentUsage;
}

#pragma mark - clean


- (void) removeObjectForkey: (NSString*) key
{
    [self removeObjectForkey:key md5ed:NO];
}

- (void) removeAllData
{
    // TODO: 全部删除可以优化
    @synchronized(self){
        NSArray *arr = [NSArray arrayWithArray:self.index];
        for (QNDiskCacheIndexModel* m in arr) {
            [self removeObjectForkey:m.key md5ed:YES];
        }
    }
}

- (void) removeAllExpiredData
{
    NSMutableArray* expiredCache = [NSMutableArray new];
    NSUInteger now = (NSUInteger) [[NSDate date] timeIntervalSince1970];
    for (QNDiskCacheIndexModel* model in self.index) {
        if (model.age != 0 && model.createdTime + model.age < now) {
            [expiredCache addObject:model];
        }
    }
    
    for (QNDiskCacheIndexModel* model in expiredCache) {
        [self removeObjectForkey:model.key md5ed:YES];
    }
}

#pragma mark - Set


- (void) setData: (NSData*) data
          forKey: (NSString*) key
             age: (NSUInteger) age
            disk: (BOOL) saveInDisk
{
    if (self.capacity != 0 && self.capacity < data.length)
        return;
#if DEBUG
    NSLog(@"DISK_CACHE Save: %@", key);
#endif
    
    key= [key MD5Hash];
    
    @synchronized(self){
        NSAssert(key, @"key is nil");
        QNDiskCacheIndexModel* model = [[QNDiskCacheIndexModel alloc] init];
        model.key = key;
        model.cost = [data length];
        model.age = age;
        model.createdTime = (NSUInteger) [[NSDate date] timeIntervalSince1970];
        model.saveInDisk = saveInDisk;
        
        [self _qn_addModel:model];
        [self _qn_saveIndex];
        
        if (saveInDisk) {
            [self _qn_saveResourceToDisk:data key:key];
        } else {
            [[QNDBHelper sharedInstance] setValue:data forKey:key toDB:self.dbName];
        }
    }
    
    if (self.capacity != 0 && self.currentUsage > self.capacity)
    {
        [self _qn_poorData];
    }
}

- (void) setResource: (NSData*) data
              forKey: (NSString*) key
                 age: (NSUInteger) age
{
    [self setData:data forKey:key age:age disk:YES];
}

- (void) setData: (NSData*) data
          forKey: (NSString*) key
             age: (NSUInteger) age
{
    if (data) {
        [self setData:data forKey:key age:age disk:NO];
    } else {
        [self removeObjectForkey:key];
    }
}

- (void) setString: (NSString*) str
            forKey: (NSString*) key
               age: (NSUInteger) age
{
    if (!str) {
        [self removeObjectForkey:key];
    } else {
        [self setData:[NSData dataWithBytes:[str UTF8String] length:strlen([str UTF8String])]
               forKey:key
                  age:age];
    }
}


- (void) setORMItem: (id)item forKey:(NSString*)key age:(NSUInteger)age {
    NSData* data = nil;
    if ([item isKindOfClass:[NSArray class]]) {
        data = [(NSArray*)item jsonDataWithYYModel];
    } else {
        data = [item yy_modelToJSONData];
    }
    if (data) {
        [self setData:data forKey:key age:age];
    } else {
        [self removeObjectForkey:key];
    }
#ifdef DEBUG
    @try {
        if (item && !data) {
            [NSException exceptionWithName:@"YYModelParseError" reason:@"Error while transform model to json" userInfo:nil];
        }
    } @catch (NSException *exception) {
    } @finally {
    }
#endif
}

- (void) setFoundationItem: (id) item
                    forKey: (NSString*) key
                       age: (NSUInteger) age
{
    if ([item isKindOfClass:[NSArray class]] || [item isKindOfClass:[NSDictionary class]])
    {
        return[self setData:[item JsonData]
                     forKey:key
                        age:age];
    }
    else
    {
        return [self removeObjectForkey:key];
    }
}


#pragma mark - Get

- (id) valueForKey:(NSString *)key
{
#if DEBUG
    NSLog(@"DISK_CACHE Load: %@", key);
#endif
    
    key = [key MD5Hash];
    
    @synchronized(self)
    {
        QNDiskCacheIndexModel* model = self.indexDic[key];
        if (!model) {
            return nil;
        }
        //判断过期
        NSUInteger now = (NSUInteger) [[NSDate date] timeIntervalSince1970];
        if (model.age != 0 && model.createdTime + model.age < now) {
            [self removeObjectForkey:key md5ed:YES];
            return nil;
        }
        
        NSData* data = nil;
        if (model.saveInDisk) {
            data = [self _qn_fetchResourceWithKey:key];
        } else {
            data = [[QNDBHelper sharedInstance] getValueForKey:key fromeDB:self.dbName];
        }
        
        return data;
    }
}

- (NSString*) stringValueForKey: (NSString*) key
{
    @synchronized(self){
        NSString* str = [[NSString alloc] initWithData:[self valueForKey:key] encoding:NSUTF8StringEncoding];
        str.fromCache = YES;
        return str;
    }
}

- (id) foundationItemForKey: (NSString*) key
{
    NSObject* obj = [[self valueForKey:key] JsonObject];
    obj.fromCache = YES;
    return obj;
}


- (id) ormItemForKey:(NSString*)key ofClass:(Class)c {
    id obj = [self foundationItemForKey:key];
    id model = nil;
    if ([obj isKindOfClass:[NSDictionary class]]) {
        model = [c yy_modelWithJSON:obj];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        model = [NSArray yy_modelArrayWithClass:c json:obj];
    }
#ifdef DEBUG
    @try {
        if (obj && !model) {
            [NSException exceptionWithName:@"YYModelParseError"
                                    reason:@"Error while transform json to model from cache.Specially, ['1', '2'] --x--> @[@'1', @'2'], [1, 2] --x--> @[@(1), @(2)]"
                                  userInfo:nil];
        }
    } @catch (NSException *exception) {
    } @finally {
    }
#endif
    return model;
}


#pragma mark - Private


- (void) _qn_poorData
{
    //处理过期数据
    [self removeAllExpiredData];
    if (self.capacity == 0 || self.currentUsage < self.capacity) {
        return;
    }
    // TODO: 可以优化 self.index 本身的排序, 以及可以考虑使用类似 LRU 的缓存策略
    NSArray* arr = [self.index sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        QNDiskCacheIndexModel* m1 = obj1;
        QNDiskCacheIndexModel* m2 = obj2;
        
        return m1.age + m1.createdTime - m2.age - m2.createdTime;
    }];
    
    for (QNDiskCacheIndexModel* m in arr) {
        [self removeObjectForkey:m.key md5ed:YES];
        if (self.currentUsage < self.capacity)
            break;
    }
}

- (void)_qn_removeObjectForkey:(NSString *)key md5ed:(BOOL)isMd5Format
{
#if DEBUG
    NSLog(@"DISK_CACHE Delete: %@", key);
#endif
    
    if (!isMd5Format){
        key = [key MD5Hash];
    }
    @synchronized(self)
    {
        QNDiskCacheIndexModel* model = self.indexDic[key];
        
        if (model){
            [self _qn_deleteModel:model];
            [self _qn_saveIndex];
            if (model.saveInDisk) {
                [self _qn_removeResourceWithKey:key];
            } else {
                [[QNDBHelper sharedInstance] removeValueForKey:key fromDB:self.dbName];
            }
        }
    }
}

- (void)_qn_deleteModel:(QNDiskCacheIndexModel*)model
{
    @synchronized(self)
    {
        NSUInteger index = [self.index indexOfObject:model];
        [self.index removeObject:model];
        self.indexDic[model.key] = nil;
        NSRange range = [self _qn_getModelWithIndex:index];
        if (NSNotFound != range.location){
            [self.indexDes replaceCharactersInRange:range withString:@""];
        }
        
        self.currentUsage -= model.cost;
    }
}

- (NSRange)_qn_getModelWithIndex:(NSInteger)index
{
    NSRange range = NSMakeRange(NSNotFound, 0);
    NSArray* strArr = [self.indexDes componentsSeparatedByString:SEPERATOR_MODELS];
    if (0 <= index && index < strArr.count){
        NSUInteger loc = 0;
        NSUInteger length = 0;
        for (NSInteger i = 0; i < index; i++){
            loc += [strArr[i] length] + 1;
        }
        length = [strArr[index] length] + 1;
        range.location = loc;
        range.length = length;
    }
    return range;
}


- (NSString *)_qn_diskResourcePath:(NSString *)dbName {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString* rootPath = [paths[0] stringByAppendingPathComponent:@"com.soufun.resource.cache.default"];
    return [rootPath stringByAppendingPathComponent:[dbName MD5Hash]];
}

- (void)_qn_addModel:(QNDiskCacheIndexModel*)model
{
    if (model){
        //如果key已经存在，那么不应该继续加model，而应该更新
        QNDiskCacheIndexModel* modelFound = self.indexDic[model.key];
        
        if (modelFound){
            [self _qn_deleteModel:modelFound];
        }
        [self.index addObject:model];
        [self.indexDic setObject:model forKey:model.key];
        [self.indexDes appendFormat:@"%@%@", [model encodedString], SEPERATOR_MODELS];
        self.currentUsage += model.cost;
    }
}

- (void) _qn_saveIndex
{
    NSData* indexData = [self.indexDes dataUsingEncoding:NSUTF8StringEncoding];
    if (indexData){
        [[QNDBHelper sharedInstance] setValue:indexData forKey:QNDiskCacheIndexKey toDB:self.dbName];
    }
}

#pragma mark - Resource


- (void)_qn_saveResourceToDisk:(NSData *)data key:(NSString *)key {
    dispatch_async(QNDiskCacheIoQueue, ^{
        // TODO: fileManager是否需要单独创建一个实例
        NSFileManager* fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:self.resourcePath]) {
            [fileManager createDirectoryAtPath:self.resourcePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        NSString *cachePath = [self.resourcePath stringByAppendingPathComponent:key];
        [fileManager createFileAtPath:cachePath contents:data attributes:nil];
    });
}



- (void)_qn_removeResourceWithKey:(NSString *)key {
    dispatch_async(QNDiskCacheIoQueue, ^{
        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSString *cachePath = [self.resourcePath stringByAppendingPathComponent:key];
        [fileManager removeItemAtPath:cachePath error:nil];
    });
}


- (NSData *)_qn_fetchResourceWithKey:(NSString *)key {
    NSString *cachePath = [self.resourcePath stringByAppendingPathComponent:key];
    NSData* data = [NSData dataWithContentsOfFile:cachePath];
    return data;
}


#pragma mark - IndexDescription


- (void)_qn_loadIndex
{
    NSData* indexData = [[QNDBHelper sharedInstance] getValueForKey:QNDiskCacheIndexKey fromeDB:self.dbName];
    self.currentUsage = 0;
    if (indexData){
        NSMutableArray* arr_models = [NSMutableArray array];
        NSMutableDictionary* dic_models = [NSMutableDictionary dictionary];
        NSString* str_db = [[NSString alloc]initWithData:indexData encoding:NSUTF8StringEncoding];
        //切分成数组
        NSArray* arr_parts = [str_db componentsSeparatedByString:SEPERATOR_MODELS];
        for (NSString* str_part in arr_parts){
            if ([str_part isKindOfClass:[NSString class]] && 0 < str_part.length){
                NSData* data = [str_part dataUsingEncoding:NSUTF8StringEncoding];
                QNDiskCacheIndexModel* model = [QNDiskCacheIndexModel loadFromData:data];
                if (model){
                    [arr_models addObject:model];
                    [dic_models setObject:model forKey:model.key];
                    self.currentUsage += model.cost;
                }
            }
        }
        self.index = arr_models;
        self.indexDic = dic_models;
    }
    else
    {
        self.index = [NSMutableArray array];
        self.indexDic = [NSMutableDictionary dictionary];
        
    }
    [self _qn_initIndexDes];
}

-(void)_qn_initIndexDes
{
    self.indexDes = [NSMutableString string];
    //connect
    if (self.index && 0 < self.index.count){
        NSMutableArray* dataArray = [NSMutableArray array];
        for (NSInteger i = 0; i < self.index.count; i ++){
            NSString* encodedStr = [self.index[i] encodedString];
            [dataArray addObject:encodedStr];
        }
        [self.indexDes appendString:[dataArray componentsJoinedByString:SEPERATOR_MODELS]];
        [self.indexDes appendString:SEPERATOR_MODELS];
    }
}


@end
