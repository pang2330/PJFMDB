//
//  DataBaseManager.h
//  拼接SQLite3语句
//
//  Created by mac on 16/4/16.
//  Copyright © 2016年 jun. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, DataPath) {
    DataPathDocuments,
    DataPathCaches
};
typedef NS_ENUM(NSUInteger, AddOrDelete) {
    Delete,
    Add
};
@interface DataBaseManager : NSObject
+(DataBaseManager *)sharedManager;

/* < 从数据库添加/删除数据 模型类的第一个属性必须具有唯一性 > */
+ (void)addOrDeleteData:(id)ModelClass toLibraryPath:(DataPath )dataPath  deleteOrAdd:(AddOrDelete)addOrDelete;

/* < 从数据库获取对应模型类所有存储 > */
+ (NSArray *)getAllDataWithCalss:(Class)modelClass;
@end
