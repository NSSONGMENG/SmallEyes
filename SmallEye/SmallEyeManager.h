//
//  SmallEyeManager.h
//  SmallEye
//
//  Created by song.meng on 2021/5/16.
//

#import <Foundation/Foundation.h>

#define HomeDirName @"HOME"

NS_ASSUME_NONNULL_BEGIN

@interface SmallEyeDiskInfo : NSObject

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *rawName;
@property (nonatomic, copy) NSString *sizeString;
@property (nonatomic, copy) NSString *visitTime;

@property (nonatomic, assign) BOOL isFolder;
@property (nonatomic, assign) long long size;

@property (nonatomic, readonly) NSDictionary *attributes;
@property (nonatomic, strong) NSMutableArray <SmallEyeDiskInfo *>* subItems;
@property (nonatomic, weak) SmallEyeDiskInfo  *fatherInfo;   //父文件夹

// 按空间降序排序
- (void)sortBySizeDescending;

// 删除指定文件 / 指定目录
- (BOOL)removeSubItem:(SmallEyeDiskInfo *)item;

// 收集size > limit的路径信息
- (NSDictionary *)collectInfoWithLimit:(size_t)limit;

- (instancetype)getSubPathInfo:(NSString *)name;


@end



@interface SmallEyeManager : NSObject

@property(nonatomic, readonly) NSArray <SmallEyeDiskInfo *>*rootItems;

+ (SmallEyeDiskInfo *)startScan;

@end

NS_ASSUME_NONNULL_END
