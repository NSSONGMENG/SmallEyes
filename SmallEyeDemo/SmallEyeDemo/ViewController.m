//
//  ViewController.m
//  SmallEyeDemo
//
//  Created by song.meng on 2021/11/25.
//

#import "ViewController.h"
#import <SmallEye/SmallEye.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(100, 200, self.view.frame.size.width - 200, 40);
    [btn setBackgroundColor:[UIColor orangeColor]];
    [btn setTitle:@"查看磁盘" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)buttonAction {
    NSString *path = [NSHomeDirectory() stringByAppendingFormat:@"/Library/demo/aa"];
    
    NSString *subPath = [path stringByReplacingOccurrencesOfString:NSHomeDirectory() withString:HomeDirName];
    
    NSLog(@"%@", [subPath componentsSeparatedByString:@"/"]);
    
    
    // push
    [SmallEyeTableViewController openPathWithNavigationController:self.navigationController
                                                             path:path
                                                         complete:^(CFAbsoluteTime timeCost) {
        NSLog(@"open .");
    }];

    // presenter
//    [SmallEyeTableViewController openPathWithNavigationController:self
//                                                             path:path
//                                                         complete:^(CFAbsoluteTime timeCost) {
//        NSLog(@"open .");
//    }];
}


@end
