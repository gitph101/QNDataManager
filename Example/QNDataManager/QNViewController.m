//
//  QNViewController.m
//  QNDataManager
//
//  Created by gitph101 on 04/13/2017.
//  Copyright (c) 2017 gitph101. All rights reserved.
//

#import "QNViewController.h"
#import "QNDiskCache.h"
#import "DemoModel.h"

@interface QNViewController ()

@end

@implementation QNViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    QNDiskCache *disk = [[QNDiskCache alloc]initWithCapacity:1024*1024];
    [disk setString:@"value" forKey:@"key" age:0];
    NSLog(@"%@",[disk stringValueForKey:@"key"]);
    
    DemoModel *model = [[DemoModel alloc]init];
    model.name = @"hello";
    model.age = @"25";
    
    [disk setORMItem:[NSArray arrayWithObject:model] forKey:@"keyArray" age:0];
    NSLog(@"Array : %@",[disk stringValueForKey:@"keyArray"]);

    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
