//
//  LogViewController.m
//  xRayda
//
//  Created by apple on 2021/12/16.
//  Copyright © 2021 apple.gupt.www. All rights reserved.
//

#import "LogViewController.h"
#import "FMDatabase.h"
#import "Socket.h"
#import "UIView+SDAutoLayout.h"
#import "UITableView+SDAutoTableViewCellHeight.h"
#import "SDAutoLayout.h"
#import "MBProgressHUD.h"

@interface LogViewController ()<UITableViewDataSource,UITableViewDelegate,SocketDelegate>
@property (strong,nonatomic) Socket *header;
@property (retain,nonatomic) MBProgressHUD *HUD;
@property (retain,nonatomic) UITableView *tableView1;
@property (retain,nonatomic) UITableView *tableView2;
@property (strong,nonatomic) UIView *view1;
@property (strong,nonatomic) UIView *view2;
@property (strong,nonatomic) NSMutableArray *actionLog;  //操作记录
@property (strong,nonatomic) NSMutableArray *actionLogDetail;  //操作记录
@property (strong,nonatomic) NSMutableArray *vehicleLog;  //车辆记录
@property NSInteger logCount;
@property (nonatomic, strong) FMDatabase *db;  //数据库
@end

@implementation LogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    self.header = [Socket sharedInstance];
    self.header.delegate = self;
    
    self.actionLog = [[NSMutableArray alloc] init];
   // self.view.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    self.actionLogDetail = [[NSMutableArray alloc] init];
    
    self.vehicleLog = [[NSMutableArray alloc] init];
    self.logCount = 0;
    //self.view.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    
    self.tableView1 = [[UITableView alloc]init];
    self.tableView1.dataSource = self;
    
    self.tableView2 = [[UITableView alloc]init];
    self.tableView2.dataSource = self;
   // [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setAutoLayOut];
}

//#pragma mark - 连接成功
-(void)onConnected{
    NSLog(@"已连接----");
    
}
//#pragma mark - 连接失败
-(void)onConnectFailed{
    self.header.socket.userData = [NSNumber numberWithInt:SocketOfflineByServer];
    //[self.header socketConnectHost];
    NSLog(@"网络断开了----");
    self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.HUD.mode = MBProgressHUDModeText;
    self.HUD.label.text= @"网络已断开,请重新连接";
    self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
    [self.HUD removeFromSuperview];
    [self.HUD hideAnimated:YES afterDelay:3];
}

#pragma  mark 布局
-(void) setAutoLayOut{
    
    _view1 = [[UIView alloc] init];
    _view1.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
    [self.view addSubview:_view1];
    _view1.sd_cornerRadiusFromHeightRatio = @(0.03);
    _view1.sd_layout
        .topSpaceToView(self.view, 10)
        .leftSpaceToView(self.view, 10)
        .rightSpaceToView(self.view, 10)
        .heightRatioToView(self.view, 0.45);

    UILabel *labelAction = [[UILabel alloc]init];
    [_view1 addSubview:labelAction];
    labelAction.sd_layout
        .topSpaceToView(_view1, 8)
        .heightIs(40)
        .leftSpaceToView(_view1, 10);
    [labelAction setSingleLineAutoResizeWithMaxWidth:200];
    labelAction.font = [UIFont systemFontOfSize:20];
    labelAction.text = @"操作记录：";
    
    //读取操作按钮
    UIButton *btReadAction = [[UIButton alloc]init];
    [_view1 addSubview:btReadAction];
    [btReadAction setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btReadAction.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btReadAction.layer setCornerRadius:8.0];
    btReadAction.sd_layout
        .centerYEqualToView(labelAction)
        .heightIs(32)
        .widthRatioToView(_view1, 0.3)
        .centerXEqualToView(_view1);
    [btReadAction setTitle:@"读取记录" forState:UIControlStateNormal] ;
    [btReadAction addTarget:self action:@selector(readAction) forControlEvents:UIControlEventTouchUpInside];
    
    //清空操作按钮
    UIButton *btClearAction = [[UIButton alloc]init];
    [_view1 addSubview:btClearAction];
    [btClearAction setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btClearAction.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btClearAction.layer setCornerRadius:8.0];
    btClearAction.sd_layout
        .centerYEqualToView(labelAction)
        .heightIs(32)
        .widthRatioToView(_view1, 0.3)
        .rightSpaceToView(_view1, 10);
    [btClearAction setTitle:@"清除记录" forState:UIControlStateNormal] ;
    [btClearAction addTarget:self action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];
    
    //tableview 操作信息
    [_view1 addSubview:self.tableView1];
    [self.tableView1.layer setCornerRadius:8.0];
    self.tableView1.sd_layout
        .topSpaceToView(labelAction, 8)
        .bottomSpaceToView(_view1, 0)
        .leftSpaceToView(_view1, 10)
        .rightSpaceToView(_view1, 10);
    
    //车辆出入信息
    _view2 = [[UIView alloc] init];
    _view2.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
    [self.view addSubview:_view2];
    _view2.sd_cornerRadiusFromHeightRatio = @(0.03);
    _view2.sd_layout
        .topSpaceToView(self.view1, 0)
        .leftSpaceToView(self.view, 10)
        .rightSpaceToView(self.view, 10)
        .heightRatioToView(self.view, 0.45);
    
    UILabel *labelVehicle = [[UILabel alloc]init];
    [_view2 addSubview:labelVehicle];
    labelVehicle.sd_layout
        .topSpaceToView(_view2, 8)
        .heightIs(40)
        .leftSpaceToView(_view2, 10);
    [labelVehicle setSingleLineAutoResizeWithMaxWidth:200];
    labelVehicle.font = [UIFont systemFontOfSize:20];
    labelVehicle.text = @"车辆出入：";
    
    //读取日志按钮
    UIButton *btReadVehicle = [[UIButton alloc]init];
    [_view2 addSubview:btReadVehicle];
    [btReadVehicle setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btReadVehicle.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btReadVehicle.layer setCornerRadius:8.0];
    btReadVehicle.sd_layout
        .centerYEqualToView(labelVehicle)
        .heightIs(32)
        .widthRatioToView(_view2, 0.3)
        .centerXEqualToView(_view2);
    [btReadVehicle setTitle:@"读取记录" forState:UIControlStateNormal] ;
    [btReadVehicle addTarget:self action:@selector(readVehicle) forControlEvents:UIControlEventTouchUpInside];
    
    //清空日志按钮
    UIButton *btClearVehicle = [[UIButton alloc]init];
    [_view2 addSubview:btClearVehicle];
    [btClearVehicle setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btClearVehicle.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btClearVehicle.layer setCornerRadius:8.0];
    btClearVehicle.sd_layout
        .centerYEqualToView(labelVehicle)
        .heightIs(32)
        .widthRatioToView(_view2, 0.3)
        .rightSpaceToView(_view2, 10);
    [btClearVehicle setTitle:@"清除记录" forState:UIControlStateNormal] ;
    [btClearVehicle addTarget:self action:@selector(clearVehicle) forControlEvents:UIControlEventTouchUpInside];
    
    //添加tableView,车辆信息
    [_view2 addSubview:self.tableView2];
    [self.tableView2.layer setCornerRadius:8.0];
    self.tableView2.sd_layout
        .topSpaceToView(labelVehicle, 8)
        .bottomSpaceToView(_view2, 0)
        .leftSpaceToView(_view2, 10)
        .rightSpaceToView(_view2, 10);
    
    UIButton *goBack = [[UIButton alloc]init];
    [self.view addSubview:goBack];
    [goBack.layer setCornerRadius:8.0];
    goBack.sd_layout
        .bottomSpaceToView(self.view, 8)
        .heightRatioToView(self.view, 0.1)
        .widthRatioToView(self.view, 0.4)
        .centerXEqualToView(self.view);
    [goBack setTitle:@"返回" forState:UIControlStateNormal];
    [goBack setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [goBack addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
}

//退出页面
-(void)goBack{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark 颜色生成按钮背景图片
-(UIImage *) imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


#pragma mark 读取记录
//读取操作记录
-(void)readAction{
    [self openDB];
    [self queryDaily];
}

//读取日志
-(void)readVehicle{
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    if([self.header.socket isConnected]){
        self.header.dataWrite = @"c3 00";
        [self.header writeBoardWithTag:3120];
        self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:100 target:self selector:@selector(readTimeOut) userInfo:nil repeats:NO];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeIndeterminate;
        self.HUD.label.text= @"正在读取数据！";
    }
    self.header.dataWrite = @"";
}

-(void)readTimeOut{
    [self.connectTimer invalidate];
    self.HUD.mode = MBProgressHUDModeText;
    self.HUD.label.text = @"读取日志完成";
    self.HUD.removeFromSuperViewOnHide = YES;
    [self.HUD hideAnimated:YES afterDelay:5];
}

-(void) clearAction{
    [self dropAction];
}


-(void)clearVehicle{
    self.header.dataWrite = @"c3 ff";
    [self.header writeBoardWithTag:3121];
    //[self.tableView2 reloadData];
}

- (void) OnDidReadDataWithTag:(long)Tag{
    if(Tag==3120){
        self.logCount++;
        NSArray *strs = [self.header.dataRead componentsSeparatedByString:@","];
        long  numTotal = 0;
        if([strs count]>0){
            NSString *strTotal = [strs[0] substringFromIndex:6];    //日志数量
            numTotal = [strTotal intValue];
        }
        if(self.logCount < numTotal-1){
            [self.vehicleLog addObject:self.header.dataRead];
            [self.tableView2 reloadData];
            [self.header.socket readDataWithTimeout:-1 tag:3120];
        }else{
            [self.tableView1 reloadData];
            self.HUD.mode = MBProgressHUDModeText;
            self.HUD.label.text = @"道匝数据读取完毕";
            
            self.HUD.removeFromSuperViewOnHide = YES;
            [self.HUD hideAnimated:YES afterDelay:3];
        }
    }
}

#pragma mark 数据库操作
-(void)openDB{
    //1.获得数据库文件的路径
    NSString *doc=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fileDB = [doc stringByAppendingPathComponent:@"db.sqlite"];
    NSLog(@"fileDB = %@",fileDB);
    
    //2.获得数据库
    FMDatabase *db = [FMDatabase databaseWithPath:fileDB];
    
    //3.打开数据库
    if ([db open]) {
        NSLog(@"数据库已打开");
    }
    self.db = db;
    
   //6.关闭数据库
   // [self.db close];
}

//查询操作记录
-(void)queryDaily
{
    //1.执行查询语句
    FMResultSet *resultSet = [self.db executeQuery:@"select * from t_daily where id<?;",@(100)];
    
    //2.遍历结果集合
    while ([resultSet next]) {
        int idNum = [resultSet intForColumn:@"id"];
        NSString *device = [resultSet objectForColumn:@"device"];
        NSString *user = [resultSet objectForColumn:@"user"];
        NSString *actionDescription = [resultSet objectForColumn:@"actionDescription"];
        NSString *actionTime = [resultSet objectForColumn:@"actionTime"];
        NSString *actionValue = [resultSet objectForColumn:@"actionValue"];
        
        NSString *strAction = [NSString stringWithFormat:@"id=%i ,device=%@,user=%@, description=%@,time=%@",idNum,device,user,actionDescription,actionTime];
        NSLog( @"%@",strAction);
        NSString *strLog = [NSString stringWithFormat:@"%@  %@  %@",actionTime,actionDescription,actionValue];
        if([actionValue isEqual:[NSNull null]]){
            strLog = [NSString stringWithFormat:@"%@  %@",actionTime,actionDescription];
        }
        [self.actionLog addObject:strLog];
        
        NSString *strLogDetail = [NSString stringWithFormat:@"设备ID:%@   用户:%@",device,user];
        [self.actionLogDetail addObject:strLogDetail];
    }
    [self.tableView1 reloadData];
}

//删除操作记录
-(void)dropAction
{
    [self.db executeUpdate:@"drop table if exists t_daily;"];
    //4.创建操作表
    BOOL result1=[self.db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_daily(id integer PRIMARY KEY AUTOINCREMENT, actionTime datetime NOT NULL, device text NOT NULL, user text NOT NULL, actionDescription text NOT NULL, actionValue text);"];
    if (result1) {
        NSLog(@"创建日志表成功！");
    }else{
        NSLog(@"创建日志表失败！");
    }
    [self.actionLog removeAllObjects];
    [self.actionLogDetail removeAllObjects];
    [self.tableView1 reloadData];
}


#pragma mark - tableView代理
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 8.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if([tableView isEqual:self.tableView2]){
        return  [self.vehicleLog count];
    }else{
        return  [self.actionLog count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    //操作日志
    if([tableView isEqual:self.tableView1]){
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleSubtitle) reuseIdentifier:ID];
        }
        NSString *strShow = [NSString stringWithFormat:@"%@",self.actionLog[indexPath.row]];
        NSString *strShowDetail = [NSString stringWithFormat:@"%@",self.actionLogDetail[indexPath.row]];
        cell.textLabel.text = strShow;
        cell.detailTextLabel.text = strShowDetail;
    }else{    //车辆出入
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:ID];
        }
       //系统返回字符串
        NSString *strReturn = [NSString stringWithFormat:@"%@",self.vehicleLog[indexPath.row]];
        //转换为显示字符串
        NSString *strShow = [self strConvert:strReturn];
        cell.textLabel.text = strShow;
    }
    return cell;
}

//将返回字符串转会为符合显示要求字符串
-(NSString *)strConvert:(NSString *)strReturn{
    NSArray *strs = [strReturn componentsSeparatedByString:@","];
    //strs[0]:Total=512  strs[1]:Index=1 strs[2]:Tick=3836389279  strs[3]:State=1
    NSString  *strSeq = [strs[1] substringFromIndex:6];  //序号
    long long secondPass = [[strs[2] substringFromIndex:5] longLongValue]; //经历秒数
    NSString *status = [strs[3] substringFromIndex:6];
    
    //将秒数转换为时间格式
    NSString *dateStr1900=@"1900-01-01 00:00:00";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:8]];//解决8小时时间差问题
    NSDate *Date1900 = [dateFormatter dateFromString:dateStr1900];
    NSDate *date = [NSDate dateWithTimeInterval:secondPass  sinceDate:Date1900];
    NSString *strTime = [date descriptionWithLocale:nil];
    
    //栏杆活动状态
    NSString *strStatus = [[NSString alloc] init];
    if([status isEqualToString:@"0\r\n"]){
        strStatus = @"离开雷达区域";
    }else if([status isEqualToString:@"1\r\n"]){
        strStatus = @"进入雷达区域";
    }else if([status isEqualToString:@"7\r\n"]){
        strStatus = @"雷达重启";
    }else{
        strStatus = @"雷达状态未知";
    }
    NSString *strShow = [[NSString alloc] initWithFormat:@"%@: %@ %@",strSeq,strTime,strStatus];
    return strShow;
}

-(void)viewDidAppear:(BOOL)animated{
    self.header.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated{
    // self.header.delegate = nil;
    [self.db close];
}

@end
