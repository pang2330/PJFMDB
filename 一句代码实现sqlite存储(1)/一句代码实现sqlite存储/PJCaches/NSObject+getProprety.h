//
//  NSObject+getProprety.h
//  拼接SQLite3语句
//
//  Created by mac on 16/4/16.
//  Copyright © 2016年 jun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (getProprety)
/** < 获取对象的所有属性 > **/
- (NSArray *)getAllProperties;
/** < 获取对象的所有属性 以及属性值 > **/
- (NSDictionary *)properties_aps;
/** < 获取对象的所有方法 > **/
-(void)printMothList;
@end
