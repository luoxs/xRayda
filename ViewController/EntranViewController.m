//
//  EntranViewController.m
//  xRayda
//
//  Created by apple on 2022/1/17.
//  Copyright © 2022 apple.gupt.www. All rights reserved.
//

#import "EntranViewController.h"
#import "FMDatabase.h"
#import "Socket.h"
#import "SDAutoLayout.h"
#import "MBProgressHUD.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreLocation/CoreLocation.h>

@interface EntranViewController ()<SocketDelegate,UITextFieldDelegate>
@property (nonatomic,retain) NSString *seguID;
@property (strong,nonatomic) Socket *header;
@property (retain,nonatomic) MBProgressHUD *HUD;
@property (nonatomic,retain) NSMutableDictionary *dicUser;
@property (nonatomic,retain) NSMutableDictionary *dicPass;
@property (retain,nonatomic) UIScrollView *scrollView;
@property (retain,nonatomic)  CLLocationManager *manager;
@property (nonatomic, strong) FMDatabase *db;  //数据库
@end

@implementation EntranViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.header = [Socket sharedInstance];
    self.header.delegate = self;
    
    self.HUD = [[MBProgressHUD alloc]init];
    [self.HUD setMode:MBProgressHUDModeText];

    //版本号和用户名
    self.dicUser= [NSMutableDictionary dictionaryWithObjectsAndKeys:@"user0",@"v0",@"user1",@"v1",@"user2",@"v2",@"user3",@"v3",@"user4",@"v4",@"user5",@"v5",@"user6",@"v6",@"user7",@"v7",@"user8",@"v8",@"user9",@"v9",@"user10",@"v10",nil];
    // 新增用户到100名
    [self addUser];
    
    //用户名和密码
    self.dicPass= [NSMutableDictionary dictionaryWithObjectsAndKeys:@"161027",@"InSightWave",@"TY123456",@"user0",@"JS123456",@"user1",@"WL123456",@"user2",@"AJB123456",@"user3",@"HXZX123456",@"user4",@"FSZN123456",@"user5",@"YB123456",@"user6",@"QF123456",@"user7",@"DH123456",@"user8",@"AKZB123456",@"user9",@"RLD123456",@"user10",nil];
    //新增密码到100名
    [self addPassword];
    self.header.typeRadar = [NSString stringWithFormat:@"fangza"];
    self.seguID = [[NSString alloc] initWithFormat:@"fangza"];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setController];
 

    //打开数据库
    [self openDB];
    // Do any additional setup after loading the view.
}
-(void)viewDidAppear:(BOOL)animated{
    //请求定位权限
    self.manager = [[CLLocationManager alloc] init];
    [self.manager requestAlwaysAuthorization];
}


-(void) setController{
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.backgroundColor = [UIColor whiteColor];
    //alwaysBounceVertical，当 UIScrollView 的 contentSize 小于父视图的 frame 时仍然可以具有弹性效果
    // _scrollView.alwaysBounceVertical = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    
    [self.view addSubview:_scrollView];
    //设置 _scrollView 的 frame
    _scrollView.sd_layout
        .spaceToSuperView(UIEdgeInsetsZero);
    //这里设置 BOTTOM_HEIGHT 是底部还有个按钮，定义了一个全局
    _scrollView.sd_layout
        .bottomSpaceToView(self.view, 2);
    
    
    UIImageView *imgv = [[UIImageView alloc] init];
    [_scrollView addSubview:imgv];
    [imgv setImage:[UIImage imageNamed:@"IMG_8549"]];
    imgv.sd_layout
        .topSpaceToView(_scrollView, 30)
        .heightIs(300)
        .centerXEqualToView(_scrollView)
        .widthIs(300);
    
    //用户名
    UILabel *labelUser = [[UILabel alloc]init];
    [_scrollView addSubview:labelUser];
    labelUser.sd_layout
        .topSpaceToView(_scrollView, 340)
        .heightIs(40)
        .widthRatioToView(_scrollView, 0.2)
        .leftSpaceToView(_scrollView, 50);
    labelUser.font = [UIFont systemFontOfSize:16];
    [labelUser setTextColor:[UIColor  blackColor]];
    [labelUser setText:@"用户："] ;
    
    //密码
    UILabel *labelPassword = [[UILabel alloc]init];
    [_scrollView addSubview:labelPassword];
    labelPassword.sd_layout
        .topSpaceToView(labelUser, 16)
        .heightIs(40)
        .widthRatioToView(_scrollView, 0.2)
        .leftSpaceToView(_scrollView, 50);
    labelPassword.font = [UIFont systemFontOfSize:16];
    [labelPassword setTextColor:[UIColor  blackColor]];
    [labelPassword setText:@"密码："] ;
    
    UITextField *txfdUser = [[UITextField alloc]init];
    [_scrollView addSubview:txfdUser];
    txfdUser.sd_layout
        .centerYEqualToView(labelUser)
        .heightIs(40)
        .widthRatioToView(_scrollView, 0.6)
        .leftSpaceToView(labelUser, 0);
    [txfdUser setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1]];
    txfdUser.font = [UIFont systemFontOfSize:16];
    [txfdUser.layer setCornerRadius:4.0];
    txfdUser.text = @"user1";
    [txfdUser setTextColor:[UIColor  blackColor]];
    txfdUser.delegate = self;
    [txfdUser setTag:4101];
    
    
    UITextField *txfdPassword = [[UITextField alloc]init];
    [_scrollView addSubview:txfdPassword];
    txfdPassword.sd_layout
        .centerYEqualToView(labelPassword)
        .heightIs(40)
        .widthRatioToView(_scrollView, 0.6)
        .leftSpaceToView(labelPassword, 0);
    [txfdPassword setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1]];
    txfdPassword.font = [UIFont systemFontOfSize:16];
    [txfdPassword.layer setCornerRadius:.40];
    [txfdPassword setSecureTextEntry:YES];
    // txfdPassword.text = @"JS123456";
    [txfdPassword setTextColor:[UIColor  blackColor]];
    txfdPassword.delegate = self;
    [txfdPassword setTag:4102];
    
    //读取默认用户名和密码
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    txfdUser.text = [userDefaults objectForKey:@"username"];
    txfdPassword.text = [userDefaults objectForKey:@"password"];
    
    NSArray *arrItem =[ [NSArray alloc]initWithObjects:@"防砸雷达",@"触发雷达", nil];
    UISegmentedControl *segmentType = [[UISegmentedControl alloc] initWithItems:arrItem];
    [_scrollView addSubview:segmentType];
    segmentType.sd_layout
        .topSpaceToView(txfdPassword, 40)
        .heightIs(40)
        .centerXEqualToView(_scrollView)
        .leftEqualToView(labelPassword)
        .rightEqualToView(txfdPassword);
    [segmentType setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor]}forState:UIControlStateSelected];
    [segmentType setSelectedSegmentIndex:0];
    [segmentType setTag:4103];
    [segmentType addTarget:self action:@selector(selectType:) forControlEvents:UIControlEventValueChanged];
    
    UIButton *btLogin = [[UIButton alloc]init];
    [_scrollView addSubview:btLogin];
    btLogin.sd_layout
        .topSpaceToView(segmentType, 40)
        .centerXEqualToView(segmentType)
        .heightIs(40)
        .widthRatioToView(_scrollView, 0.4);
    [btLogin setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:64/255.0 green:64/255.0 blue:64/255.0 alpha:1]] forState :UIControlStateHighlighted];
    [btLogin setBackgroundColor:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1]];
    [btLogin.layer setCornerRadius:8.0];
    [btLogin setTitle:@"登录" forState:UIControlStateNormal];
    [btLogin setTag:4104];
    [btLogin addTarget:self action:@selector(login:) forControlEvents:UIControlEventTouchUpInside];
    [_scrollView setupAutoContentSizeWithBottomView:btLogin bottomMargin:500];
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
        NSLog(@"ok");
        //4.创建日志表
        BOOL result1=[db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_daily(id integer PRIMARY KEY AUTOINCREMENT, actionTime datetime NOT NULL, device text NOT NULL, user text NOT NULL, actionDescription text NOT NULL, actionValue text);"];
        if (result1) {
            NSLog(@"创建日志表成功！");
        }else{
            NSLog(@"创建日志表失败！");
        }
        //5.创建车辆表
        BOOL result2=[db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_vehicle(id integer PRIMARY KEY AUTOINCREMENT, passTime datetime NOT NULL, user text NOT NULL, passType bool NOT NULL);"];
        if (result2) {
            NSLog(@"创建车辆表成功！");
        }else{
            NSLog(@"创建车辆表失败！");
        }
    }
    self.db = db;
    
    /*
     //插入数据
     [self insertStu];
     [self deleteStu:6];
     [self updateStu:@"apple7_name" :@"7777"];
     [self insertStu];
     */
    
    //[self dropDaily];
    [self dropVehicle];
   //[self queryDaily];
    //6.关闭数据库
   // [self.db close];
}

//销毁日志表
-(void)dropDaily
{
    [self.db executeUpdate:@"drop table if exists t_Daily;"];
    
    //4.重新创表
    /*
     BOOL result=[self.db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_daily (id integer PRIMARY KEY AUTOINCREMENT, name text NOT NULL, age integer NOT NULL);"];
     if (result) {
     NSLog(@"再次创表成功");
     }else{
     NSLog(@"再次创表失败");
     }
     */
}

//销毁车辆表
-(void)dropVehicle
{
    [self.db executeUpdate:@"drop table if exists t_vehicle;"];
    
    //4.重新创表
    /*
     BOOL result=[self.db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_vehicle (id integer PRIMARY KEY AUTOINCREMENT, name text NOT NULL, age integer NOT NULL);"];
     if (result) {
     NSLog(@"再次创表成功");
     }else{
     NSLog(@"再次创表失败");
     }
     */
}

//查询日志表
-(void)queryDaily
{
    //1.执行查询语句
    //    FMResultSet *resultSet = [self.db executeQuery:@"select * from t_student;"];
    FMResultSet *resultSet = [self.db executeQuery:@"select * from t_daily where id<?;",@(100)];
    
    //2.遍历结果集合
    while ([resultSet next]) {
        int idNum = [resultSet intForColumn:@"id"];
        NSString *device = [resultSet objectForColumn:@"device"];
        NSString *user = [resultSet objectForColumn:@"user"];
        NSString *description = [resultSet objectForColumn:@"actionDescription"];
        NSString *time = [resultSet objectForColumn:@"actionTime"];
        NSLog(@"id=%i ,device=%@,user=%@, description=%@,time=%@",idNum,device,user,description,time);
    }
}

//查询车辆表
-(void)queryVehicle
{
    //1.执行查询语句
    //    FMResultSet *resultSet = [self.db executeQuery:@"select * from t_student;"];
    FMResultSet *resultSet = [self.db executeQuery:@"select * from t_vehicle where id<?;",@(14)];
    
    //2.遍历结果集合
    while ([resultSet next]) {
        int idNum = [resultSet intForColumn:@"id"];
        NSString *name = [resultSet objectForColumn:@"name"];
        int age = [resultSet intForColumn:@"age"];
        NSLog(@"id=%i ,name=%@, age=%i",idNum,name,age);
    }
}

#pragma mark 选择雷达类型
-(void)selectType:(id)sender{
    UISegmentedControl *segmentType = (UISegmentedControl *)[self.view viewWithTag:4103];
    if(segmentType.selectedSegmentIndex == 0){
        self.seguID = @"fangza";
        self.header.typeRadar = @"fangza";
    }else{
        self.seguID = @"chufa";
        self.header.typeRadar = @"chufa";
    }
}

#pragma mark 键盘消失
-(BOOL) textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    [self.view endEditing:YES];
    return YES;
}


-(void) addUser{
    for(int i=11;i<=100;i++){
        NSString *version = [NSString stringWithFormat:@"v%d",i];
        NSString *user = [NSString  stringWithFormat:@"user%d",i];
        [self.dicUser  setValue:user forKey:version];
    }
}

-(void) addPassword{
    for(int i=11;i<=100;i++){
        NSString *user = [NSString  stringWithFormat:@"user%d",i];
        NSString *password = [NSString stringWithFormat:@"123456"];
        [self.dicUser  setValue:password forKey:user];
    }
}

#pragma  mark  登录
-(void) login:(id)sender{
  
    UITextField *txfdUser = (UITextField *)[self.view viewWithTag:4101];
    UITextField *txfdPass = (UITextField *)[self.view viewWithTag:4102];
    
    self.header.user = txfdUser.text;

    //管理员登录
    if([txfdUser.text isEqualToString:@"InSightWave"] && [txfdPass.text isEqualToString:@"161027"]){
        // [self.header cutOffSocket];
        
        //保存用户名和密码
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setValue:txfdUser.text forKey:@"username"];
        [userDefaults setValue:txfdPass.text forKey:@"password"];
        
        if([self.seguID isEqual:@"fangza"]){
            self.header.typeRadar = @"fangza";
            [self performSegueWithIdentifier:@"fangza" sender:self];
        }else{
            self.header.typeRadar = @"chufa";
            [self performSegueWithIdentifier:@"chufa" sender:self];
        }
        return;
    }
    
    //连接热点
    [self.header socketConnectHost];
    self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.HUD.mode = MBProgressHUDModeIndeterminate;
    self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
    self.HUD.label.text= @"连接设备WiFi中";
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(connectTimeOut) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSDefaultRunLoopMode];
}

-(void)connectTimeOut{
    [self.connectTimer invalidate];
    if(![self.header.socket isConnected]){
        NSLog(@"连接雷达失败！查看是否连接热点");
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"连接失败！";
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:2];
    }
}

-(void)onConnected{
    self.HUD.removeFromSuperViewOnHide = YES;
    [self.HUD hideAnimated:YES afterDelay:0];
    [self refresh];
    [self.connectTimer invalidate];

    //获取wifi的uid
    [self getWiFiBSSID];

    /*
    BOOL result1=[db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_daily(id integer PRIMARY KEY AUTOINCREMENT, actionTime datetime NOT NULL, device text NOT NULL, user text NOT NULL, actionDescription text NOT NULL, actionValue text);"];
    */
    /*
     NSInteger identifier = 42;
     NSString *name = @"Liam O'Flaherty (\"the famous Irish author\")";
     NSDate *date = [NSDate date];
     NSString *comment = nil;

     BOOL success = [db executeUpdate:@"INSERT INTO authors (identifier, name, date, comment) VALUES (?, ?, ?, ?)", @(identifier), name, date, comment ?: [NSNull null]];
     if (!success) {
         NSLog(@"error = %@", [db lastErrorMessage]);
     }
     */
    BOOL success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"登录",[NSNull null]];
    if(success){
        NSLog(@"------插入数据成功-------");
    }
}

-(void) getWiFiBSSID{
    //sleep(20);
    NSString *idStr = @"DEVICE BSSID NOT KNOW";
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict != nil) {
            NSDictionary *dict = (NSDictionary*)CFBridgingRelease(myDict);
            idStr = [dict valueForKey:@"BSSID"];
        }
    }
    self.header.BSSID = idStr;
    NSLog(@"设备BSSID为：%@",idStr);
}


-(void) refresh{
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    if([self.header.socket isConnected]){
        self.header.dataWrite = @"c0 00";
        self.header.tagWrite = 1100;
        [self.header writeBoardWithTag:1100];
        NSLog(@"writeBoard with tag ---%d",1100);
    }
}

- (void) OnDidReadDataWithTag:(long)Tag{
    //NSString *user = @"InsightWave";
    NSString *strVersion;
    NSString *strUser;
    NSString *strPass;
    
    UITextField *txfdUser = (UITextField *)[self.view viewWithTag:4101];
    UITextField *txfdPass = (UITextField *)[self.view viewWithTag:4102];
    
    //普通用户登录
    if(Tag==1100){
        NSArray *strs =  [self.header.dataRead componentsSeparatedByString:@"\r\n"];
        //版本号
        strVersion = [strs[0] componentsSeparatedByString:@"_"][1];
        //NSLog(@"%@",strVersion)
        strUser = [self.dicUser objectForKey:strVersion];
        strPass = [self.dicPass objectForKey:strUser];
        NSLog(@"user:%@,pass:%@",strUser,strPass);
    }
    
    if([txfdUser.text isEqualToString:strUser] && [txfdPass.text isEqualToString:strPass]){
        [self.header cutOffSocket];
        
        //保存用户名和密码
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setValue:txfdUser.text forKey:@"username"];
        [userDefaults setValue:txfdPass.text forKey:@"password"];
        
        if([self.seguID isEqual:@"fangza"]){
            self.header.typeRadar = @"fangza";
            [self performSegueWithIdentifier:@"fangza" sender:self];
        }else{
            self.header.typeRadar = @"chufa";
            [self performSegueWithIdentifier:@"chufa" sender:self];
        }
    }else if(![txfdUser.text isEqualToString:strUser]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"用户名和版本不匹配！";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
    }else{
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"登录密码错误！";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
    }
}

-(void)onConnectFailed{
    [self.connectTimer invalidate];
    self.HUD.mode = MBProgressHUDModeText;
    self.HUD.label.text= @"连接失败！";
    self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
    self.HUD.removeFromSuperViewOnHide = YES;
    [self.HUD hideAnimated:YES afterDelay:3];
}

-(void) viewWillDisappear:(BOOL)animated{
    [self.db close];
}


#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    segue.destinationViewController.modalPresentationStyle = UIModalPresentationFullScreen;
}
@end
