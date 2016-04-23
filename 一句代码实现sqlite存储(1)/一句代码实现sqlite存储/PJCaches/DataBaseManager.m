//
//  DataBaseManager.m
//  拼接SQLite3语句
//
//  Created by mac on 16/4/16.
//  Copyright © 2016年 jun. All rights reserved.
//

#import "DataBaseManager.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "FMDatabaseAdditions.h"
#import <objc/runtime.h>
#import "NSObject+getProprety.h"

#define WK(weakSelf) \
__block __weak __typeof(&*self)weakSelf = self;\

@interface DataBaseManager()
/** < 数据库队列 > **/
@property (nonatomic)FMDatabaseQueue *dbQueue;

@end

@implementation DataBaseManager
+(DataBaseManager *)sharedManager {
    static dispatch_once_t pred = 0;
    __strong static DataBaseManager *_sharedManager = nil;
    dispatch_once(&pred, ^{
        _sharedManager = [[DataBaseManager alloc] init];
    });
    return _sharedManager;
}


/** < 返回创建sqlite表语句 > **/
-(NSString *)createTableForClass:(Class)modelClass
{
    unsigned int propertyCount;
    objc_property_t *propertes = class_copyPropertyList([modelClass class], &propertyCount);
    NSMutableString *str = [NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (",[self tableNameForClass:modelClass]];
    for (int i=0; i<propertyCount; i++) {
        objc_property_t property=propertes[i];
        [str appendString:@(property_getName(property))];
        NSString *pro1 = [[@(property_getAttributes(property)) componentsSeparatedByString:@","] firstObject];
        
        [str appendString:[self type:pro1]];
        if (i!=propertyCount-1) {
            [str appendString:@","];
        }
    }
    [str appendString:@")"];
    NSLog(@"%@",str);
    return [str copy];
}
/** < 类名做表名存储 > **/
- (NSString *)tableNameForClass:(Class)modelClass
{
    return [NSString stringWithUTF8String:object_getClassName(modelClass)];
}
/** < 返回属性对应类型存储到数据库的类型 > **/
- (NSString *)type:(NSString *)type
{
    if ([type isEqualToString:@"T@\"NSString\""]){
        return @" text";
    }else if ([type isEqualToString:@"Tq"]||[type isEqualToString:@"TB"]){
        return @" integer";
    }else if ([type isEqualToString:@"Td"]||[type isEqualToString:@"Tf"]){
        return @" REAL";
    }else if ([type isEqualToString:@"T@\"NSData\""]){
        return @" BLOB";
    }else{
        return @" NULL";
    }
}
/** < 添加数据到数据库 > **/
+ (void)addOrDeleteData:(id)ModelClass toLibraryPath:(DataPath )dataPath  deleteOrAdd:(AddOrDelete)addOrDelete
{
    [[self alloc] addOrDeleteData:ModelClass toLibraryPath:dataPath deleteOrAdd:addOrDelete];
}
- (void)addOrDeleteData:(id)ModelClass toLibraryPath:(DataPath )dataPath  deleteOrAdd:(AddOrDelete)addOrDelete
{
    if (!ModelClass) {
        return;
    }
    NSString *path = nil;
    switch (dataPath) {
        case DataPathDocuments:{
            path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject];
        }break;
        case DataPathCaches:{
            path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)firstObject];
        }break;
    }
    NSString *fielPath = [path stringByAppendingPathComponent:@"myData.db"];
    //创建/"打开"数据库文件
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:fielPath];
    // 创建数据库表
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        //先判断表是否存在
        if (![db  tableExists:[self tableNameForClass:[ModelClass class]]]) {
            [db executeUpdate:[self createTableForClass:[ModelClass class]]];
        }
        //查询
        FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"select * from %@",[self tableNameForClass:[ModelClass class]]]];
        NSDictionary *dic=[ModelClass properties_aps];
        unsigned int propertyCount;
        objc_property_t *propertes = class_copyPropertyList([ModelClass class], &propertyCount);
        objc_property_t property=propertes[0];
        //addOrDelete
        switch (addOrDelete) {
            case Add:{
                //循环获取记录中的字段
                while ([resultSet next]) {
                    NSDictionary *dicc =[resultSet resultDictionary];
                    if ([[dicc valueForKey:@(property_getName(property))] isEqualToString:[dic valueForKey: @(property_getName(property))]]){
                        NSString *delete = [NSString stringWithFormat:@"delete from %@ where %@='%@'",[self tableNameForClass:[ModelClass class]],@(property_getName(property)),[dic valueForKey:@(property_getName(property))]];
                        BOOL isSuccess = [db executeUpdate:delete];
                        if (isSuccess) {
                            BOOL isSuccess = [db executeUpdate:[self addDataToTableForClass:ModelClass withResultSet:resultSet]];
                            if (isSuccess) {
                                NSLog(@"修改成功");
                            }
                        }
                        return;
                    }
                }
                
                BOOL isSuccess = [db executeUpdate:[self addDataToTableForClass:ModelClass withResultSet:resultSet]];
                if (isSuccess) {
                    NSLog(@"插入成功");
                }
            }break;
            case Delete:{
                //删除操作
                while ([resultSet next]) {
                    NSDictionary *dicc =[resultSet resultDictionary];
                    if ([[dicc valueForKey:@(property_getName(property))] isEqualToString:[dic valueForKey: @(property_getName(property))]]){
                        NSString *delete = [NSString stringWithFormat:@"delete from %@ where %@='%@'",[self tableNameForClass:[ModelClass class]],@(property_getName(property)),[dic valueForKey:@(property_getName(property))]];
                        BOOL isSuccess = [db executeUpdate:delete];
                        if (isSuccess) {
                            NSLog(@"删除成功");
                        }
                        return;
                    }
                }
            }break;
        }
    }];

}
/* < 从数据库获取对应模型类所有存储 > */
+ (NSArray *)getAllDataWithCalss:(Class)modelClass
{
    return [[self alloc]getAllDataWithCalss:modelClass];
}
- (NSArray *)getAllDataWithCalss:(Class)modelClass
{
    NSFileManager *manager = [[NSFileManager alloc]init];
    NSString *fielPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)firstObject] stringByAppendingPathComponent:@"myData.db"];
    if (![manager fileExistsAtPath:fielPath]) {
        fielPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)firstObject] stringByAppendingPathComponent:@"myData.db"];
    }
    
    NSMutableArray *mutaleArray = [NSMutableArray array];
    self.dbQueue = [FMDatabaseQueue databaseQueueWithPath:fielPath];
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        //查询
        if ([db tableExists:[self tableNameForClass:modelClass]]) {
            FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"select * from %@",[self tableNameForClass:modelClass]]];
            //循环获取记录中的字段
            while ([resultSet next]) {
                NSMutableDictionary *dic =[NSMutableDictionary dictionary];
                [dic addEntriesFromDictionary:[resultSet resultDictionary]];
                [dic removeObjectForKey:@"id"];
                
                [mutaleArray addObject:dic];
            }
        }
    }];
    return [mutaleArray copy];
}
/** < 返回插入表数据语句 > **/
- (NSString *)addDataToTableForClass:(id)ModelClass withResultSet:(FMResultSet*)resultSet
{
    unsigned int propertyCount;
    objc_property_t *propertes = class_copyPropertyList([ModelClass class], &propertyCount);
    NSMutableString *str = [NSMutableString stringWithFormat:@"insert into  %@ (",[self tableNameForClass:ModelClass]];
    for (int i=0; i<propertyCount; i++) {
        objc_property_t property=propertes[i];
        [str appendString:@(property_getName(property))];
        if (i!=propertyCount-1) {
            [str appendString:@","];
        }
    }
    [str appendString:@") values ("];
    
    NSDictionary *dic1 = [ModelClass properties_aps];
    NSLog(@"%@",dic1);
    for (int i=0; i<propertyCount; i++) {
        
        objc_property_t property1=propertes[i];
        NSLog(@"%@",@(property_getName(property1)));
        id value = [dic1 valueForKey:@(property_getName(property1))];
        
        NSString *addStr = [NSString stringWithFormat:@" '%@'",value];
        [str appendString:addStr];
        
        
        if (i!=propertyCount-1) {
            [str appendFormat:@","];
        }
    }
    [str appendString:@")"];
    
    
    NSLog(@"%@",[str copy]);
    return [str copy];
}
@end
