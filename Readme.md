`SmallEye`是为方便快捷的查看磁盘目录开发的一个小工具，功能如下：

- 按目录原有的树状结构枚举所有的目录和文件
- 计算目录及子目录所占用的空间大小，并按占用空间的大小进行排序
- 快捷分享和查看文件（系统分享和Quick Look）
- 长按删除目录或文件
- 打开根目录/指定目录

不足：

- 目录和文件较多的情况下，递归遍历花费的时间较长
- 因目录和文件是树状结构，若节点和叶子节点过多， 会导致`info`对象过多从而占用大量内存



`pod`集成：

```shell
pod 'SmallEye'
```

使用：

```OC
#import <SmallEye/SmallEyeTableViewController.h>

// presenter
[SmallEyeTableViewController openPathWithNavigationController:self  // self为UIViewController
                                                         path:path
                                                     complete:^(CFAbsoluteTime timeCost) {
		NSLog(@"open .");
}];
    
// push
[SmallEyeTableViewController openPathWithNavigationController:self.navigationController
                                                         path:path
                                                     complete:^(CFAbsoluteTime timeCost) {
		NSLog(@"open .");
}];
```

