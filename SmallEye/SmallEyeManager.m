//
//  SmallEyeManager.m
//  MMDebugTools
//
//  Created by song.meng on 2021/5/16.
//

#import "SmallEyeManager.h"

@implementation SmallEyeDiskInfo

+ (instancetype)infoWithPath:(NSString *)path attributes:(NSDictionary *)attr isFolder:(BOOL)isFolder {
    SmallEyeDiskInfo *info = [[SmallEyeDiskInfo alloc] initWithPath:path attributes:attr isFolder:isFolder];
    return info;
}

- (instancetype)initWithPath:(NSString *)path attributes:(NSDictionary *)attr isFolder:(BOOL)isFolder {
    if (self = [super init]) {
        _path = path;
        _name = [path lastPathComponent];
        _rawName = _name;
        _isFolder = isFolder;
        _subItems = [NSMutableArray array];
        self.attributes = attr;
    }
    return self;
}

- (void)setSize:(long long)size {
    _size = size;
    _sizeString = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
}

- (void)addSubItem:(SmallEyeDiskInfo *)info {
    if ([info isKindOfClass:[SmallEyeDiskInfo class]]) {
        info.fatherInfo = self;
        [_subItems addObject:info];
        
        if (![_name isEqualToString:HomeDirName]) {
            _name = [NSString stringWithFormat:@"%@ (%lu)",[_path lastPathComponent], _subItems.count];
        }
    }
}

- (void)setAttributes:(NSDictionary * _Nonnull)attributes {
    _attributes = attributes;
    NSDate *date = [attributes fileModificationDate];
    _visitTime = [SmallEyeDiskInfo formatDate:date formaterStrong:@"yyyy-MM-dd HH:mm:ss"];
}

- (void)sortBySizeDescending {
    [(NSMutableArray *)_subItems sortUsingComparator:^NSComparisonResult(SmallEyeDiskInfo  * _Nonnull  obj1, SmallEyeDiskInfo * _Nonnull obj2) {
        if (obj1.size > obj2.size) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];
}

- (BOOL)removeSubItem:(SmallEyeDiskInfo *)item {
    BOOL removeSuccess = NO;
    for (int i = 0; i < _subItems.count; i++) {
        if (_subItems[i] == item) {
            [_subItems removeObjectAtIndex:i];
            removeSuccess = YES;
            [self decreseSize:item.size];
            
            if (![_name isEqualToString:HomeDirName]) {
                _name = [NSString stringWithFormat:@"%@ (%lu)",[_path lastPathComponent], _subItems.count];
            }
            break;
        }
    }
    
    return removeSuccess;
}

- (NSDictionary *)collectInfoWithLimit:(size_t)limit {
    if (_size < limit) {
        return nil;
    }
    
    NSDictionary *result = @{
        @"name" : _name ?: @"--",
        @"size" : _sizeString ?: @"--",
    };
    
    if (_isFolder) {
        NSMutableArray *arr = [NSMutableArray array];
        for (SmallEyeDiskInfo *info in _subItems) {
            NSDictionary *inf = [info collectInfoWithLimit:limit];
            if (inf) {
                [arr addObject:inf];
            }
        }
        
        if (arr.count) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:result];
            dic[@"subs"] = arr;
            result = dic.copy;
        }
    }
    
    return result;
}

- (instancetype)getSubPathInfo:(NSString *)name {
    for (SmallEyeDiskInfo *info in self.subItems) {
        if ([info.rawName isEqualToString:name]) {
            return info;
        }
    }
    return nil;
}

- (void)decreseSize:(long long)size {
    if (size == 0) {
        return;
    }
    
    self.size -= size;
    
    if (_fatherInfo) {
        [_fatherInfo decreseSize:size];
    }
}

+ (NSString *)formatDate:(NSDate *)date formaterStrong:(NSString *)format{
    static NSDateFormatter *formater;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formater =  [[NSDateFormatter alloc] init];
        formater.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    
    [formater setDateFormat:format];
    return [NSString stringWithString:[formater stringFromDate:date]];
}


@end


#pragma mark - SmallEyeManager -

@implementation SmallEyeManager

+ (SmallEyeDiskInfo *)startScan {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSString *home = NSHomeDirectory();
    NSDictionary *homeAttr = [manager attributesOfItemAtPath:home error:NULL];
    SmallEyeDiskInfo *root = [SmallEyeDiskInfo infoWithPath:home attributes:homeAttr isFolder:YES];
    root.name = HomeDirName;
    
    long long size = 0;
    [self fileManager:manager scan:home globalInfo:info fileSize:&size headItem:root];
    root.size = size;
    
    return root;
}

+ (void)fileManager:(NSFileManager *)manager
               scan:(NSString *)path
         globalInfo:(NSMutableDictionary *)info
           fileSize:(long long *)size
            headItem:(SmallEyeDiskInfo *)item {
    NSError *error;
    NSArray *subs = [manager contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        return;
    }
    
    NSError *err;
    NSDictionary *attributes = nil;

    for (NSString * subPath in subs) {
        err = nil;
        NSString *curPath = [NSString stringWithFormat:@"%@/%@", path, subPath];
        attributes = [manager attributesOfItemAtPath:curPath error:&err];
        if (!err) {
            BOOL isFolder = [[attributes fileType] isEqual:NSFileTypeDirectory];
            if (isFolder) {
                long long curSize = 0;
                SmallEyeDiskInfo *inf = [SmallEyeDiskInfo infoWithPath:curPath attributes:attributes isFolder:YES];
                [self fileManager:manager scan:curPath globalInfo:info fileSize:&curSize headItem:inf];
                inf.size = curSize;
                *size += curSize;
                
                [item addSubItem:inf];
            } else {
                long long curSize = [attributes fileSize];
                *size += curSize;
                SmallEyeDiskInfo *inf = [SmallEyeDiskInfo infoWithPath:curPath attributes:attributes isFolder:NO];
                inf.size = curSize;

                [item addSubItem:inf];
            }
        }
    }
}

+ (void)fileManager:(NSFileManager *)manager
               scan:(NSString *)path
         globalInfo:(NSMutableDictionary *)info
           fileSize:(long long *)size
         filterSize:(size_t)limit {
    NSError *error;
    NSArray *subs = [manager contentsOfDirectoryAtPath:path error:&error];
    if (error) {
        return;
    }
    
    NSError *err;
    NSDictionary *attributes = nil;

    for (NSString * subPath in subs) {
        err = nil;
        NSString *curPath = [NSString stringWithFormat:@"%@/%@", path, subPath];
        attributes = [manager attributesOfItemAtPath:curPath error:&err];
        if (!err) {
            BOOL isFolder = [[attributes fileType] isEqual:NSFileTypeDirectory];
            if (isFolder) {
                long long curSize = 0;
                [self fileManager:manager scan:curPath globalInfo:info fileSize:&curSize filterSize:limit];
                *size += curSize;
                
                if (curSize > limit) {
                    [info setValue:[self sizeStringWithSize:curSize] forKey:curPath];
                }
            } else {
                long long curSize = [attributes fileSize];
                *size += curSize;

                if (curSize >= limit) {
                    [info setValue:[self sizeStringWithSize:curSize] forKey:curPath];
                }
            }
        }
    }
}

+ (NSString *)sizeStringWithSize:(long long)size {
    NSString *str = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
    if (!str) {
        return @"";
    }
    return str;
}

@end
