//
//  ViewController.m
//  一句代码实现sqlite存储
//
//  Created by mac on 16/4/16.
//  Copyright © 2016年 jun. All rights reserved.
//

#import "ViewController.h"
#import "student.h"
#import "DataBaseManager.h"


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *ageTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
- (IBAction)addData:(id)sender {
    student *stu = [student new];
    if (self.nameTextField.text.length>0) {
        stu.name = self.nameTextField.text;
        stu.age  = [self.ageTextField.text integerValue];
        [DataBaseManager addOrDeleteData:stu toLibraryPath:DataPathCaches deleteOrAdd:Add];
    }
    
}
- (IBAction)deleteData:(id)sender {
    student *stu = [student new];
    [stu setValuesForKeysWithDictionary:@{@"name":@"张三",@"age":@"25"}];
    [DataBaseManager addOrDeleteData:stu toLibraryPath:DataPathCaches deleteOrAdd:Delete];
}
- (IBAction)queryData:(id)sender {
    NSArray *array = [DataBaseManager getAllDataWithCalss:[student class]];
    NSLog(@"%@",array);
}
@end
