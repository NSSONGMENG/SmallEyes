//
//  SmallEyeTableViewController.m
//  MMDebugTools
//
//  Created by song.meng on 2021/5/16.
//

#import "SmallEyeTableViewController.h"
#import <QuickLook/QuickLook.h>
#import "SmallEyeManager.h"

@interface SmallEyeDiskInfoCell : UITableViewCell
@property (nonatomic, strong)UILabel *titleLabel;
@property (nonatomic, strong)UILabel *timeLabel;
@property (nonatomic, strong)UILabel *detailLabel;
@property (nonatomic, strong)UIImageView *nextImgView;

- (void)showImageView:(BOOL)show;

@end

@implementation SmallEyeDiskInfoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        UILabel * (^createLanel)(CGRect, CGFloat, UIColor *) = ^(CGRect frame, CGFloat size, UIColor *textColor){
            UILabel *lab = [[UILabel alloc] initWithFrame:frame];
            lab.font = [UIFont systemFontOfSize:size];
            lab.textColor = textColor;
            [self.contentView addSubview:lab];
            return lab;
        };
        
        CGFloat windowW = [UIScreen mainScreen].bounds.size.width;
        _titleLabel = createLanel(CGRectMake(15, 6, windowW - 30, 15), 12, [UIColor colorWithRed:50.f/255 green:50.f/255 blue:50.f/255 alpha:1.f]);
        _timeLabel = createLanel(CGRectMake(15, 25, windowW - 120, 15), 10, [UIColor colorWithRed:170.f/255 green:170.f/255 blue:170.f/255 alpha:1.f]);
        _detailLabel = createLanel(CGRectMake(windowW - 100, 25, 90, 15), 10, [UIColor colorWithRed:170.f/255 green:170.f/255 blue:170.f/255 alpha:1.f]);
        _detailLabel.textAlignment = NSTextAlignmentRight;
        
        _nextImgView = [[UIImageView alloc] initWithFrame:CGRectMake(windowW - 20, 16.5, 12, 12)];
        _nextImgView.image = [UIImage imageNamed:@"SmallEyeNext"];
        [self.contentView addSubview:_nextImgView];
    }
    return self;
}

- (void)showImageView:(BOOL)show {
    _nextImgView.hidden = !show;
    CGFloat windowW = [UIScreen mainScreen].bounds.size.width;
    
    if (show) {
        _detailLabel.frame = CGRectMake(windowW - 90 - 22, 25, 90, 15);
    } else {
        _detailLabel.frame = CGRectMake(windowW - 90 - 12, 25, 90, 15);
    }
}

+ (CGFloat)height {
    return 45.f;
}

@end


@interface SmallEyeTableViewController ()<QLPreviewControllerDataSource,QLPreviewControllerDelegate>

@property (nonatomic, strong)SmallEyeDiskInfo *pathInfo;
@property (nonatomic, strong)SmallEyeDiskInfo *qlInfo;   // Quick Look
@property (nonatomic, strong)UILongPressGestureRecognizer *longPressGesture;

@end

@implementation SmallEyeTableViewController


+ (void)openHomeWithNavigationController:(UIViewController *)vc
                                complete:(nullable void(^)(CFAbsoluteTime timeCost))complete {
    CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
    [self _getRootDiskInfoConplete:^(SmallEyeDiskInfo *info) {
        [self _pushWithNavigationController:vc diskInfoArray:@[info] targetPath:nil];
        if (complete) {
            complete(CFAbsoluteTimeGetCurrent() - begin);
        }
    }];
}

+ (void)openPathWithNavigationController:(UIViewController *)vc
                                    path:(NSString *)path
                                complete:(nullable void(^)(CFAbsoluteTime timeCost))complete {
    CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
    [self _getRootDiskInfoConplete:^(SmallEyeDiskInfo *info) {
        if ([path isKindOfClass:[NSString class]] && path.length) {
            // 查找并创建路径vc
            NSString *subPath = [path stringByReplacingOccurrencesOfString:NSHomeDirectory() withString:HomeDirName];
            NSArray <NSString *>*pathArray = [subPath componentsSeparatedByString:@"/"];
            int count = (int)pathArray.count;
            
            if (count) {
                NSMutableArray *itemArray = [NSMutableArray arrayWithCapacity:pathArray.count];
                [itemArray addObject:info];
                
                SmallEyeDiskInfo *tmpInfo = info;
                for (int i = 1; i < count && nil != tmpInfo; i++) {
                    NSString *name = pathArray[i];
                    tmpInfo = [tmpInfo getSubPathInfo:name];
                    if (tmpInfo) {
                        [itemArray addObject:tmpInfo];
                    } else {
                        NSLog(@"【SmallEye notification】未找到名字为%@的路径节点", name);
                    }
                }
                
                [self _pushWithNavigationController:vc diskInfoArray:itemArray targetPath:path];
            } else {
                [self _pushWithNavigationController:vc diskInfoArray:@[info] targetPath:path];
            }
        } else {
            [self _pushWithNavigationController:vc diskInfoArray:@[info] targetPath:path];
        }
        if (complete) {
            complete(CFAbsoluteTimeGetCurrent() - begin);
        }
    }];
}

+ (void)_getRootDiskInfoConplete:(nullable void(^)(SmallEyeDiskInfo *))complete {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        SmallEyeDiskInfo *rootInfo = [SmallEyeManager startScan];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (complete) {
                complete(rootInfo);
            }
        });
    });
}

+ (void)_pushWithNavigationController:(UIViewController *)vc
                        diskInfoArray:(NSArray <SmallEyeDiskInfo *>*)infoArray
                           targetPath:(NSString *)path {
    if (!infoArray.count) {
        return;
    }
    
    BOOL isNavc = [vc isKindOfClass:[UINavigationController class]];
    
    NSArray *vcs;
    if (isNavc) {
        UINavigationController *navc = (UINavigationController *)vc;
        vcs = navc.viewControllers;
    } else {
        vcs = [NSArray array];
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:infoArray.count + vcs.count];
    [array addObjectsFromArray:vcs];
    
    for (int i = 0; i < infoArray.count; i++) {
        SmallEyeDiskInfo *info = infoArray[i];
        UIViewController *vc = nil;
        if (info.isFolder) {
            vc = [[SmallEyeTableViewController alloc] initWithDiskInfo:info];
        } else {
            SmallEyeTableViewController *formerVC = [array lastObject];
            formerVC.qlInfo = info;
            QLPreviewController *qlvc = [[QLPreviewController alloc] init];
            qlvc.delegate = formerVC;
            qlvc.dataSource = formerVC;
            vc = qlvc;
        }
        
        [array addObject:vc];
    }

    if (isNavc) {
        [(UINavigationController *)vc setViewControllers:array animated:YES];
    } else {
        UINavigationController *navc = [[UINavigationController alloc] initWithRootViewController:[array firstObject]];
        [navc setViewControllers:array animated:YES];
        [vc presentViewController:navc animated:YES completion:nil];
    }
}


- (instancetype)initWithDiskInfo:(SmallEyeDiskInfo *)info {
    if (self = [super init]) {
        _pathInfo = info;
        [_pathInfo sortBySizeDescending];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _qlInfo = nil;  // Quick Look节点置位nil
    
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = _pathInfo.name;
    if ([self.navigationController.viewControllers firstObject] == self) {
        [self addRightItem];
    }
    
    _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    [self.tableView addGestureRecognizer:_longPressGesture];
}

- (void)addRightItem {
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(rightItemClicked)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)rightItemClicked {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [SmallEyeDiskInfoCell height];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _pathInfo.subItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SmallEyeDiskInfo *info = _pathInfo.subItems[indexPath.row];
    
    SmallEyeDiskInfoCell *cell = (SmallEyeDiskInfoCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[SmallEyeDiskInfoCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    
    cell.titleLabel.text = info.name;
    cell.timeLabel.text = info.visitTime;
    [cell showImageView:info.isFolder];
    cell.detailLabel.text = info.sizeString;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SmallEyeDiskInfo *info = _pathInfo.subItems[indexPath.row];
    if (info.isFolder) {
        [self pushWithPathInfo:info];
    } else {
        _qlInfo = info;
        QLPreviewController *vc = [[QLPreviewController alloc] init];
        vc.delegate = self;
        vc.dataSource = self;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)pushWithPathInfo:(SmallEyeDiskInfo *)info {
    SmallEyeTableViewController *vc = [[SmallEyeTableViewController alloc] initWithDiskInfo:info];
    [self.navigationController pushViewController:vc animated:YES];
}


//返回文件的个数
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller{
    return 1;
}

//加载需要显示的文件
- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index{
    
    return [NSURL fileURLWithPath:_qlInfo.path];
}

- (void)longPressAction:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [recognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (indexPath && _pathInfo.subItems.count > indexPath.row) {
            SmallEyeDiskInfo *info = _pathInfo.subItems[indexPath.row];
            
            BOOL delable = [[NSFileManager defaultManager] isDeletableFileAtPath:info.path];
            if (!delable) {
                [self showAlert:info.isFolder ? @"该目录不可删除" : @"该文件不可删除"];
                return;
            }
            
            __weak typeof(self) weakself = self;
            
            NSString *msg = [NSString stringWithFormat:@"确认删除/%@?", info.name];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSError *err;
                [[NSFileManager defaultManager] removeItemAtPath:info.path error:&err];
                if (!err) {
                    [weakself.pathInfo removeSubItem:info];
                    [weakself.tableView reloadData];
                    weakself.title = weakself.pathInfo.name;
                    [weakself showAlert:@"删除成功"];
                } else {
                    [weakself showAlert:@"删除失败"];
                }
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)showAlert:(NSString *)string {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:string message:nil preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
