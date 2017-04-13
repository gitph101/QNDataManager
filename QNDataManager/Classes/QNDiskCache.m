//
//  QNDiskCache.m
//  Pods
//
//  Created by 研究院01 on 17/4/13.
//
//

#import "QNDiskCache.h"
#import "NSString+MD5.h"

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

- (instancetype) initWithCapacity: (NSUInteger)capacity
                             name: (NSString* ) name
{
    if (self = [super init])
    {
        //如果对应的缓存对象已经存在，则直接返回
        @synchronized(QNCacheMapTableKeyToCache)
        {
            if ([QNCacheMapTableKeyToCache objectForKey:name])
            {
                self = [QNCacheMapTableKeyToCache objectForKey:name];
            }
            else
            {
                [QNCacheMapTableKeyToCache setObject:self forKey:name];
                self.capacity = capacity;
                self.currentUsage = 0;
                NSString* dbName = name;
                if (!dbName)
                {
                    dbName = @"cache";
                }
                self.dbName = dbName;
                self.resourcePath = [self _qn_diskResourcePath:dbName];
                [self loadIndex];
            }
            //更新capacity
            self.capacity = capacity;
            if (0 != self.capacity && self.currentUsage >= self.capacity)
            {
                [self poorData];
            }
        }
    }
    
    return self;
}

-(void)loadIndex
{

}

-(void)poorData
{

}

#pragma mark - privi
- (NSString *)_qn_diskResourcePath:(NSString *)dbName {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString* rootPath = [paths[0] stringByAppendingPathComponent:@"com.soufun.resource.cache.default"];
    return [rootPath stringByAppendingPathComponent:[dbName MD5Hash]];
}


#pragma mark - IndexDescription


- (void)_qn_loadIndex
{
    NSData* indexData = [[TTDBHelper sharedInstance] getValueForKey:TTDiskCacheIndexKey fromeDB:self.dbName];
    
    self.currentUsage = 0;
    
    if (indexData)
    {
        NSMutableArray* arr_models = [NSMutableArray array];
        NSMutableDictionary* dic_models = [NSMutableDictionary dictionary];
        
        NSString* str_db = [[NSString alloc]initWithData:indexData encoding:NSUTF8StringEncoding];
        //切分成数组
        NSArray* arr_parts = [str_db componentsSeparatedByString:SEPERATOR_MODELS];
        for (NSString* str_part in arr_parts)
        {
            if ([str_part isKindOfClass:[NSString class]] && 0 < str_part.length)
            {
                NSData* data = [str_part dataUsingEncoding:NSUTF8StringEncoding];
                TTDiskCacheIndexModel* model = [TTDiskCacheIndexModel loadFromData:data];
                if (model)
                {
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
    [self initIndexDes];
}

@end
