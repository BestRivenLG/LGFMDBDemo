//
//  ViewController.m
//  LGFMDBDemo
//
//  Created by Marvin on 2017/4/1.
//  Copyright © 2017年 Marvin. All rights reserved.
//

#import "ViewController.h"
#import <FMDB.h>
#import "PersonModel.h"
#import <sqlite3.h>
@interface ViewController (){
    sqlite3 *_dbase;
}
@property (nonatomic,strong)FMDatabase *db;
@property (nonatomic,strong)NSString *filePath;
@property (nonatomic,assign)BOOL isSQL;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _isSQL = NO;

    if (_isSQL) {
        [self database];
    }
}

- (NSString *)filePath {
    if (!_filePath) {
        
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        _filePath = [path stringByAppendingPathComponent:@"student.db"];;
    }
    return _filePath;
}



-(sqlite3 *)database{
    
    if (_dbase==nil) {
        //创建数据库
        int result = sqlite3_open([self.filePath UTF8String], &_dbase);
        if (result == SQLITE_OK) {
            NSLog(@"创建成功");
            char *error;
            //    建表格式: create table if not exists 表名 (列名 类型,....)    注: 如需生成默认增加的id: id integer primary key autoincrement
            const char *createSQL = "CREATE TABLE IF NOT EXISTS Person (PerID INTEGER PRIMARY KEY AUTOINCREMENT, Name text NOT NULL, Age INTEGER NOT NULL, Address text NOT NULL, Sorce REAL NOT NULL);";
            int tableResult = sqlite3_exec(_dbase, createSQL, NULL, NULL, &error);
            
            if (tableResult != SQLITE_OK) {
                NSLog(@"创建表失败:%s",error);
            }else{
                NSLog(@"创建表成功呢");
            }
            sqlite3_close(_dbase);
            
        }else{
            NSLog(@"创建失败");
        }
    }
    return _dbase;
}

//fmdb
- (FMDatabase *)db
{
    if (!_db) {
        
        //创建数据库
        _db = [FMDatabase databaseWithPath:self.filePath];
        ;
        if ([_db open]) {
            //创建表
            BOOL res = [_db executeUpdate:@"CREATE TABLE IF NOT EXISTS Person (PerID INTEGER PRIMARY KEY AUTOINCREMENT, Name text NOT NULL, Age INTEGER NOT NULL, Address text NOT NULL, Sorce REAL NOT NULL);"];
            if (res) {
                NSLog(@"创建成功");
            }else{
                NSLog(@"创建失败");
            }
            [_db close];
        }
    }
    return _db;
}




//执行语句
- (void)executePersonSQL:(NSString *) sql{
    NSString *sqlStr = sql;//[NSString stringWithFormat:@"SELECT * FROM Person"];
    FMResultSet *result = [self.db executeQuery:sqlStr];
    NSMutableArray *arr = [NSMutableArray array];
    while ([result next]) {
        NSString *name = [result stringForColumn:@"Name"];
        NSInteger age = [result intForColumn:@"Age"];
        NSString *Address = [result stringForColumn:@"Address"];
        CGFloat sorce = [result doubleForColumn:@"Sorce"];
        PersonModel *person = [PersonModel new];
        person.name = name;
        person.age = age;
        person.address = Address;
        person.sorce = sorce;
        [arr addObject:person];
    }
    [self.db close] ;
    for (PersonModel *person in arr ) {
        NSLog(@"name = %@ age = %ld address = %@ sorce = %.2f",person.name,person.age,person.address,person.sorce);
    }
}

//插入数据
- (IBAction)addAction:(id)sender {
    NSString *insertSql = @"insert into Person (Name, Age, Address, Sorce) values ('peter', 14, '上海', 90)";
    
    //启用sqlite还是fmdb
    [self insertAction:insertSql isSql3:_isSQL];
}

//执行语句
- (void)insertAction:(NSString *)insertSql isSql3:(BOOL)isSql{
    
    //sqlite3
    if (isSql) {
        
        int result = sqlite3_open([self.filePath UTF8String], &_dbase);
        if (result == SQLITE_OK) {
            
            //执行sql语句
            [self executeStudentSqul3:insertSql];
            
            NSString *sqlStr = [NSString stringWithFormat:@"SELECT * FROM Person"];
            //执行查询语句
            [self queryPersonSQL:sqlStr isSql:YES];
            
            sqlite3_close(_dbase);
        }
        
    }else {
        //fmdb
        if ([self.db open]) {
            
            [self executePersonSQL:insertSql];
        }
        [self.db close];
    }
    
}

- (void)executeStudentSqul3:(NSString *)sqlStr {
    
    char *error;
    const char * sql = [sqlStr UTF8String];
    
    int tableResult = sqlite3_exec(_dbase, sql, NULL, NULL, &error);
    
    if (tableResult != SQLITE_OK) {
        NSLog(@"插入数据失败:%s",error);
    }else{
        NSLog(@"插入数据成功");
    }
}

//查询
- (void)queryPersonSQL:(NSString *)sqlStr isSql:(BOOL)isSql{
    
    if (isSql) {
        
        //2.定义一个stmt存放结果集
        sqlite3_stmt *stmt = NULL;
        //3.检测SQL语句的合法性
        int result = sqlite3_prepare_v2(_dbase, [sqlStr UTF8String], -1, &stmt, NULL);
        if (result != SQLITE_OK) {
            NSLog(@"查询语句不合法");
        }else{
            NSLog(@"查询语句合法");
            
            NSMutableArray *array = [NSMutableArray array];
            //执行查询语句
            while (sqlite3_step(stmt) == SQLITE_ROW) {
                
                PersonModel *person = [PersonModel new];
                const unsigned char *name = sqlite3_column_text(stmt, 1);
                person.name = [NSString stringWithUTF8String:(const char *)name];
                
                person.age =  sqlite3_column_int(stmt, 2);
                
                const unsigned char *address = sqlite3_column_text(stmt, 3);
                person.address = [NSString stringWithUTF8String:(const char *)address];
                
                person.sorce = sqlite3_column_double(stmt, 4);
                
                [array addObject:person];
            }
            for (PersonModel *person in array ) {
                NSLog(@"name = %@ age = %ld address = %@ sorce = %.2f",person.name,person.age,person.address,person.sorce);
            }
        }
        
    }else{
        
        if ([self.db open]) {
            
            [self executePersonSQL:sqlStr];//[NSString stringWithFormat:@"SELECT * FROM Person"]];
        }
        
        [self.db close];
        
    }
}

//查询
- (IBAction)queryAction:(id)sender {

    NSString *sqlStr = [NSString stringWithFormat:@"SELECT * FROM Person"];
    [self queryPersonSQL:sqlStr isSql:_isSQL];
}

//删除
- (IBAction)deleteAction:(id)sender {
    
    NSString *insertSql = @"DELETE FROM Person WHERE NAME = 'peter';";
    
    //启用sqlite还是fmdb
    [self insertAction:insertSql isSql3:_isSQL];
    
    
    //    if ([self.db open]) {
    //
    //        [self executePersonSQL:[NSString stringWithFormat:@"DELETE FROM Person WHERE NAME = 'peter';"]];
    //    }
    //
    //    [self.db close];
}

//更新
- (IBAction)updateAction:(id)sender {
    
    NSString *insertSql = @"UPDATE Person SET NAME = 'Coco' WHERE Address = '上海';";
    
    //启用sqlite还是fmdb
    [self insertAction:insertSql isSql3:_isSQL];
    //    if ([self.db open]) {
    //
    //    [self executePersonSQL:[NSString stringWithFormat:@"UPDATE Person SET NAME = 'Coco' WHERE Address = '上海';"]];
    //
    //    }
    //    [self.db close];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

