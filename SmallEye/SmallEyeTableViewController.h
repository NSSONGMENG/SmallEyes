//
//  SmallEyeTableViewController.h
//  MMDebugTools
//
//  Created by song.meng on 2021/5/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class SmallEyeDiskInfo;

@interface SmallEyeTableViewController : UITableViewController

- (instancetype)initWithDiskInfo:(SmallEyeDiskInfo *)info;

// 打开根目录
+ (void)openHomeWithNavigationController:(UIViewController *)navc
                                complete:(nullable void(^)(CFAbsoluteTime timeCost))complete;

// 打开指定目录
+ (void)openPathWithNavigationController:(UIViewController *)navc
                                    path:(NSString *)path
                                complete:(nullable void(^)(CFAbsoluteTime timeCost))complete;

@end

NS_ASSUME_NONNULL_END
