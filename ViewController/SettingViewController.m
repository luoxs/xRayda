//
//  SettingViewController.m
//  xRayda
//
//  Created by apple on 2021/11/20.
//  Copyright © 2021 apple.gupt.www. All rights reserved.
//

#import "SettingViewController.h"
#import "FMDatabase.h"
#import "Socket.h"
#import "UIView+SDAutoLayout.h"
#import "SDAutoLayout.h"
#import "MBProgressHUD.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "viewNoise.h"

@interface SettingViewController ()<SocketDelegate>
@property (strong,nonatomic) Socket *header;
@property (retain,nonatomic) MBProgressHUD *HUD;
@property (retain,nonatomic) UIScrollView *scrollView;
@property (strong,nonatomic) UIView *view1;
@property (strong,nonatomic) UIView *view2;
@property (strong,nonatomic) UIView *view3;
@property (weak,nonatomic) NSTimer* timer;
@property (strong,nonatomic) AVAudioPlayer *player;
@property  BOOL hasShiftValue;
@property  NSInteger stopScanTimes;
@property (nonatomic, strong) FMDatabase *db;  //数据库
@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.header = [Socket sharedInstance];
    self.HUD = [[MBProgressHUD alloc]init];
    [self.HUD setMode:MBProgressHUDModeText];
    
    self.header.delegate = self;
    //设置布局
    
    [self setAutoLayout];
    self.header.longData = [[NSMutableString alloc]init];
    self.stopScanTimes = 0;
    [self resetContolls];
    // NSLog(@"%ld",[self.header.strsReset count]);
    [self openDB];
}

-(void) resetContolls{
    
    UILabel *labelGuJian = (UILabel *)[self.view viewWithTag:1100];  //固件查询
    UILabel *labelZhenji = (UILabel *)[self.view viewWithTag:1101];  //整机查询
    UILabel *labelDanji = (UILabel *)[self.view viewWithTag:1102];   //单机查询
    UISwitch *switchRenche = (UISwitch *)[self.view viewWithTag:1202]; //人车模式开关
    UILabel  *labelDiff = (UILabel *)[self.view viewWithTag:1203];  //人车区分
    UILabel  *labelWidth = (UILabel *)[self.view viewWithTag:1213];    //横向宽度
    UILabel  *labelDistance = (UILabel *)[self.view viewWithTag:1223];  //纵向距离
    UILabel  *labelDownTime = (UILabel *)[self.view viewWithTag:1233]; //落杆时间
    UILabel  *labelUpTime = (UILabel *)[self.view viewWithTag:1243];   //升杆时间
    UILabel  *labelShoot = (UILabel *)[self.view viewWithTag:1253];    //对射频表
    UISwitch *switchType = (UISwitch *)[self.view viewWithTag:1262];
    UILabel  *labelPoleType = (UILabel *)[self.view viewWithTag:1263];  //栏杆类型
    UISwitch *switchDirection = (UISwitch *)[self.view viewWithTag:1272];
    UILabel  *labelDirection = (UILabel *)[self.view viewWithTag:1273];  //偏移方向
    UILabel  *labelShift = (UILabel *)[self.view viewWithTag:1282];//偏移量
    
    UILabel  *labelDiviation = (UILabel *)[self.view viewWithTag:1271];  //"中心偏移"
    UILabel  *labelPianyi = (UILabel *)[self.view viewWithTag:1285];     //"偏移量"
    UIButton *btConfirmShift =(UIButton *)[self.view viewWithTag:1274];
    
    labelGuJian.text = self.header.strsVersion;
    
    if ([self.header.strsReset count]<9) {
        return;
    }else if([self.header.strsReset count]==9){
        NSLog(@"这是少参数版本");
        if([[self.header.strsReset[0] substringToIndex:7] isEqualToString:@"AllMode"]){
            labelDiff.text = @"不区分";
            [switchRenche setOn:NO];
        }else if([[self.header.strsReset[0] substringToIndex:7] isEqualToString:@"CarMode"]){
            labelDiff.text = @"区分";
            [switchRenche setOn:YES];
        }
        
        [labelDiff setTextColor:[UIColor blackColor]];
        NSString *width = [self.header.strsReset[0] substringFromIndex:7];
        if([width isEqualToString:@"1m"]){
            labelWidth.text = @"1.0";
        }else  if([width isEqualToString:@"0.8m"]){
            labelWidth.text = @"0.8";
        }else  if([width isEqualToString:@"0.6m"]){
            labelWidth.text = @"0.6";
        }else  if([width isEqualToString:@"0.4m"]){
            labelWidth.text = @"0.4";
        }
        [labelWidth setTextColor:[UIColor blackColor]];
        
        labelShoot.text = [self.header.strsReset[1] substringFromIndex:9];
        [labelShoot setTextColor:[UIColor blackColor]];
        
        if([self.header.strsReset[2] isEqualToString:@"StraightBar"]){
            labelPoleType.text = @"直杆";
            [switchType setOn:NO];
            [labelPoleType setTextColor:[UIColor blackColor]];
        }else if([self.header.strsReset[2] isEqualToString:@"BrakeBar"]){
            labelPoleType.text = @"栅栏杆";
            [switchType setOn:YES];
            [labelPoleType setTextColor:[UIColor blackColor]];
        }
        
        if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"0"]){
            labelDownTime.text = @"0.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"1"]){
            labelDownTime.text = @"1.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"2"]){
            labelDownTime.text = @"2.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"3"]){
            labelDownTime.text = @"3.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"4"]){
            labelDownTime.text = @"4.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"5"]){
            labelDownTime.text = @"5.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"6"]){
            labelDownTime.text = @"6.0";
        }
        [labelDownTime setTextColor:[UIColor blackColor]];
        
        if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"0"]){
            labelUpTime.text = @"0.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"1"]){
            labelUpTime.text = @"1.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"2"]){
            labelUpTime.text = @"2.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"3"]){
            labelUpTime.text = @"3.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"4"]){
            labelUpTime.text = @"4.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"5"]){
            labelUpTime.text = @"5.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"6"]){
            labelUpTime.text = @"6.0";
        }
        [labelUpTime setTextColor:[UIColor blackColor]];
        
        labelDistance.text = [self.header.strsReset[4] substringWithRange:NSMakeRange(6, 3)];
        [labelDistance setTextColor:[UIColor blackColor]];
        
    
        self.hasShiftValue = NO;
        UIButton *btSubShift = (UIButton *)[self.view viewWithTag:1281];
        UIButton *btAddShift = (UIButton *)[self.view viewWithTag:1283];
        
        [btSubShift setEnabled:NO];
        [btAddShift setEnabled:NO];
        //变灰
        
        
        labelShift.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
        labelDirection.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
        labelDiviation.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
        labelPianyi.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
        
        [btSubShift setBackgroundColor: [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2]];
        [btAddShift setBackgroundColor: [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2]];
        [btConfirmShift setBackgroundColor: [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2]];
        
        
        UISwitch *swithShift = (UISwitch *)[self.view  viewWithTag:1272];
        UIButton *btConfirmShift = (UIButton *)[self.view viewWithTag:1274];
        [swithShift setEnabled:NO];
        [btConfirmShift setEnabled:NO];
        //[labelDirection setTextColor:[UIColor blackColor]];
        // [labelShift setTextColor:[UIColor blackColor]];
        
        labelZhenji.text = [self.header.strsReset[6] substringFromIndex:4];
        labelDanji.text = [self.header.strsReset[7] substringFromIndex:4];
        
        UIButton *btRefresh = (UIButton *)[self.view viewWithTag:1292];
        [btRefresh setEnabled: YES];
    }
    //  NSAssert([strsReset count]>=10, @"刷新收到的字段数量不够");
    if([self.header.strsReset count]>=11){
        NSLog(@"这是多参数版本");
        if([[self.header.strsReset[0] substringToIndex:7] isEqualToString:@"AllMode"]){
            labelDiff.text = @"不区分";
            [switchRenche setOn:NO];
        }else if([[self.header.strsReset[0] substringToIndex:7] isEqualToString:@"CarMode"]){
            labelDiff.text = @"区分";
            [switchRenche setOn:YES];
        }
        
        [labelDiff setTextColor:[UIColor blackColor]];
        NSString *width = [self.header.strsReset[0] substringFromIndex:7];
        if([width isEqualToString:@"1m"]){
            labelWidth.text = @"1.0";
        }else  if([width isEqualToString:@"0.8m"]){
            labelWidth.text = @"0.8";
        }else  if([width isEqualToString:@"0.6m"]){
            labelWidth.text = @"0.6";
        }else  if([width isEqualToString:@"0.4m"]){
            labelWidth.text = @"0.4";
        }
        [labelWidth setTextColor:[UIColor blackColor]];
        
        labelShoot.text = [self.header.strsReset[1] substringFromIndex:9];
        [labelShoot setTextColor:[UIColor blackColor]];
        
        if([self.header.strsReset[2] isEqualToString:@"StraightBar"]){
            labelPoleType.text = @"直杆";
            [switchType setOn:NO];
            [labelPoleType setTextColor:[UIColor blackColor]];
        }else if([self.header.strsReset[2] isEqualToString:@"BrakeBar"]){
            labelPoleType.text = @"栅栏杆";
            [switchType setOn:YES];
            [labelPoleType setTextColor:[UIColor blackColor]];
        }
        
        if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"0"]){
            labelDownTime.text = @"0.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"1"]){
            labelDownTime.text = @"1.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"2"]){
            labelDownTime.text = @"2.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"3"]){
            labelDownTime.text = @"3.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"4"]){
            labelDownTime.text = @"4.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"5"]){
            labelDownTime.text = @"5.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"6"]){
            labelDownTime.text = @"6.0";
        }
        [labelDownTime setTextColor:[UIColor blackColor]];
        
        if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"0"]){
            labelUpTime.text = @"0.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"1"]){
            labelUpTime.text = @"1.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"2"]){
            labelUpTime.text = @"2.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"3"]){
            labelUpTime.text = @"3.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"4"]){
            labelUpTime.text = @"4.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"5"]){
            labelUpTime.text = @"5.0";
        }else if([[self.header.strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"6"]){
            labelUpTime.text = @"6.0";
        }
        [labelUpTime setTextColor:[UIColor blackColor]];
        
        labelDistance.text = [self.header.strsReset[4] substringWithRange:NSMakeRange(6, 3)];
        [labelDistance setTextColor:[UIColor blackColor]];
        
        if([[self.header.strsReset[5] substringWithRange:NSMakeRange(3, 4)] isEqualToString:@"Left"]){
            labelDirection.text = @"左偏";
            [switchDirection setOn:NO];
            NSString *strShift = [self.header.strsReset[5] substringWithRange:NSMakeRange(8,3)];
            labelShift.text = strShift;
        }else{
            labelDirection.text = @"右偏";
            [switchDirection setOn:YES];
            NSString *strShift = [self.header.strsReset[5] substringWithRange:NSMakeRange(9,3)];
            labelShift.text = strShift;
        }
        [labelDirection setTextColor:[UIColor blackColor]];
        [labelShift setTextColor:[UIColor blackColor]];
        
        labelZhenji.text = [self.header.strsReset[8] substringFromIndex:4];
        labelDanji.text = [self.header.strsReset[9] substringFromIndex:4];
    }
    
    UIButton *btRefresh = (UIButton *)[self.view viewWithTag:1292];
    [btRefresh setEnabled: YES];
    
    [self.view setNeedsDisplay];
    
    //这是缺参数版本，请重置雷达参数
    if([self.header.strsReset count]==10){
        /*
         self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
         self.HUD.label.text = @"雷达参数异常\n请点击下方重置按钮恢复出厂设置\n然后断开重新连接雷达";
         self.HUD.label.numberOfLines = 3;
         self.HUD.mode = MBProgressHUDModeText;
         self.HUD.label.textColor = [UIColor blueColor];
         self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
         self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
         self.HUD.removeFromSuperViewOnHide = YES;
         [self.HUD hideAnimated:YES afterDelay:5];*/
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"雷达参数异常" message:@"请点击下方重置按钮恢复出厂设置\n然后断开重新连接雷达" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ;
        }];
        
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:^{
            ;
        }];
        UIButton *btRefresh = (UIButton *)[self.view viewWithTag:1292];
        [btRefresh setEnabled: NO];
    }
}


//#pragma mark - 连接成功
-(void)onConnected{
    //[SVProgressHUD dismiss];
    NSLog(@"已连接----");
}
//#pragma mark - 连接失败
-(void)onConnectFailed{
    self.header.socket.userData = [NSNumber numberWithInt:SocketOfflineByServer];
    //[self.header socketConnectHost];
    NSLog(@"网络断开了----");
    if(self.header.tagWrite ==1304){
        self.HUD.label.text = @"获取背景噪声失败";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:2];
    }
}

//#pragma mark - 读取数据
-(void) OnDidReadData{
    NSLog(@"数据读取完毕----");
}

//#pragma mark - 页面布局
-(void)setAutoLayout{
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
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
    
#pragma mark - 雷达数据view1
    _view1 = [[UIView alloc] init];
    _view1.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
    [_scrollView addSubview:_view1];
    _view1.sd_cornerRadiusFromHeightRatio = @(0.03);
    _view1.sd_layout
        .topSpaceToView(_scrollView, 10)
        .leftSpaceToView(_scrollView, 12)
        .rightSpaceToView(_scrollView, 12)
        .heightIs(240);
    
    
    UILabel *labelLeidaData = [[UILabel alloc]init];
    [_view1 addSubview:labelLeidaData];
    labelLeidaData.sd_layout
        .topSpaceToView(_view1, 8)
        .heightIs(50)
        .centerXEqualToView(_view1);
    [labelLeidaData setSingleLineAutoResizeWithMaxWidth:200];
    [labelLeidaData setTextColor:[UIColor  blackColor]];
    labelLeidaData.font = [UIFont systemFontOfSize:24];
    labelLeidaData.text = @"雷达数据";
    
    //固件版本按钮
    UIButton *btGuJianbanben = [[UIButton alloc]init];
    [_view1 addSubview:btGuJianbanben];
    [btGuJianbanben setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btGuJianbanben.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btGuJianbanben.layer setCornerRadius:8.0];
    btGuJianbanben.sd_layout
        .topSpaceToView(labelLeidaData, 8)
        .heightIs(40)
        .widthRatioToView(_view1, 0.4)
        .leftSpaceToView(_view1, 10);
    [btGuJianbanben setTitle:@"固件版本" forState:UIControlStateNormal] ;
    [btGuJianbanben addTarget:self action:@selector(Gujianbanben) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *labelGuJian = [[UILabel alloc]init];
    [_view1 addSubview:labelGuJian];
    labelGuJian.sd_layout
        .topSpaceToView(_view1, 8)
        .topSpaceToView(labelLeidaData, 8)
        .heightIs(40)
        .widthRatioToView(_view1, 0.5)
        .rightSpaceToView(_view1, 10);
    labelGuJian.textAlignment = NSTextAlignmentCenter;
    //[labelGuJian setSingleLineAutoResizeWithMaxWidth:200];
    [labelGuJian setTextColor:[UIColor  blackColor]];
    labelGuJian.text = @"_____________";
    labelGuJian.font = [UIFont fontWithName:@"Helvetica Neue" size:16];
    [labelGuJian setTag:1100];
    
    //整机SN按钮
    UIButton *btZhengJiSN = [[UIButton alloc]init];
    [_view1 addSubview:btZhengJiSN];
    [btZhengJiSN setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btZhengJiSN.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btZhengJiSN.layer setCornerRadius:8.0];
    btZhengJiSN.sd_layout
        .topSpaceToView(btGuJianbanben, 8)
        .heightIs(40)
        .widthRatioToView(_view1, 0.4)
        .leftSpaceToView(_view1, 10);
    [btZhengJiSN setTitle:@"整机SN" forState:UIControlStateNormal];
    [btZhengJiSN addTarget:self action:@selector(SNchaxun:) forControlEvents:UIControlEventTouchUpInside];
    [btZhengJiSN setTag:1103];
    
    UILabel *labelZhengJi = [[UILabel alloc]init];
    [_view1 addSubview:labelZhengJi];
    labelZhengJi.sd_layout
        .topSpaceToView(labelGuJian, 8)
        .heightIs(40)
        .widthRatioToView(_view1, 0.5)
        .rightSpaceToView(_view1, 10);
    labelZhengJi.textAlignment = NSTextAlignmentCenter;
    // [labelZhengJi setSingleLineAutoResizeWithMaxWidth:200];
    [labelZhengJi setTextColor:[UIColor  blackColor]];
    labelZhengJi.text = @"_____________";
    labelZhengJi.font = [UIFont fontWithName:@"Helvetica Neue" size:16];
    [labelZhengJi setTag:1101];
    
    //单机SN按钮
    UIButton *btDanbanSN = [[UIButton alloc]init];
    [_view1 addSubview:btDanbanSN];
    [btDanbanSN setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btDanbanSN.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btDanbanSN.layer setCornerRadius:8.0];
    btDanbanSN.sd_layout
        .topSpaceToView(btZhengJiSN, 8)
        .heightIs(40)
        .widthRatioToView(_view1, 0.4)
        .leftSpaceToView(_view1, 10);
    [btDanbanSN setTitle:@"单机SN" forState:UIControlStateNormal];
    [btDanbanSN addTarget:self action:@selector(SNchaxun:) forControlEvents:UIControlEventTouchUpInside];
    [btZhengJiSN setTag:1104];
    
    UILabel *labelDanji = [[UILabel alloc]init];
    [_view1 addSubview:labelDanji];
    labelDanji.sd_layout
        .topSpaceToView(labelZhengJi, 8)
        .heightIs(40)
        .widthRatioToView(_view1, 0.5)
        .rightSpaceToView(_view1, 10);
    labelDanji.textAlignment = NSTextAlignmentCenter;
    // [labelDanji setSingleLineAutoResizeWithMaxWidth:200];
    [labelDanji setTextColor:[UIColor  blackColor]];
    labelDanji.text = @"_____________";
    labelDanji.font = [UIFont fontWithName:@"Helvetica Neue" size:16];
    [labelDanji setTag:1102];
    
    
#pragma mark - 参数设置view2
    _view2 = [[UIView alloc] init];
    _view2.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
    [_scrollView addSubview:_view2];
    _view2.sd_cornerRadiusFromHeightRatio = @(0.01);
    _view2.sd_layout
        .topSpaceToView(_view1, 0)
        .leftSpaceToView(_scrollView, 12)
        .rightSpaceToView(_scrollView, 12)
        .topSpaceToView(_view1, 20)
        .heightIs(660);
    
    UILabel *labelCanshu = [[UILabel alloc]init];
    [_view2 addSubview:labelCanshu];
    labelCanshu.sd_layout
        .topSpaceToView(_view2, 8)
        .heightIs(50)
        .centerXEqualToView(_view2);
    [labelCanshu setSingleLineAutoResizeWithMaxWidth:200];
    labelCanshu.font = [UIFont systemFontOfSize:24];
    [labelCanshu setTextColor:[UIColor  blackColor]];
    labelCanshu.text = @"参数设置";
    
#pragma mark - 区分人车
    UILabel *labelQufenrenche = [[UILabel alloc]init];
    [_view2 addSubview:labelQufenrenche];
    labelQufenrenche.sd_layout
        .topSpaceToView(labelCanshu, 8)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(_view2, 10);
    [labelQufenrenche setSingleLineAutoResizeWithMaxWidth:100];
    labelQufenrenche.font = [UIFont systemFontOfSize:20];
    [labelQufenrenche setTextColor:[UIColor  blackColor]];
    labelQufenrenche.text = @"区分人车";
    
    UISwitch *switchRenche = [[UISwitch alloc] init];
    [_view2 addSubview:switchRenche];
    switchRenche.sd_layout
        .centerYEqualToView(labelQufenrenche)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(labelQufenrenche, 8);
    [switchRenche setTag:1202];
    [switchRenche addTarget:self action:@selector(distinguish) forControlEvents:UIControlEventTouchUpInside];
    
    //区分人车
    UILabel *labelDiff = [[UILabel alloc] init];
    [_view2 addSubview:labelDiff];
    labelDiff.sd_layout
        .centerYEqualToView(labelQufenrenche)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(switchRenche, 12);
    [labelDiff setSingleLineAutoResizeWithMaxWidth:100];
    labelDiff.text = @"不区分";
    labelDiff.font = [UIFont systemFontOfSize:20];
    [labelDiff setTextColor:[UIColor redColor]];
    [labelDiff setTag:1203];
    
#pragma mark - 横向宽度
    UILabel *labelHengxiang = [[UILabel alloc]init];
    [_view2 addSubview:labelHengxiang];
    labelHengxiang.sd_layout
        .topSpaceToView(labelQufenrenche, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(_view2, 10);
    [labelHengxiang setSingleLineAutoResizeWithMaxWidth:100];
    labelHengxiang.font = [UIFont systemFontOfSize:20];
    [labelHengxiang setTextColor:[UIColor  blackColor]];
    labelHengxiang.text = @"横向宽度";
    
    UIButton *btSubwidth = [[UIButton alloc]init];
    [_view2 addSubview:btSubwidth];
    [btSubwidth.layer setCornerRadius:5];
    [btSubwidth setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btSubwidth.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btSubwidth.sd_layout
        .centerYEqualToView(labelHengxiang)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .leftSpaceToView(labelHengxiang, 8);
    [btSubwidth setTitle:@"-" forState:UIControlStateNormal];
    [btSubwidth addTarget:self action:@selector(subWidth) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *labelWidth = [[UILabel alloc]init];
    [_view2 addSubview:labelWidth];
    labelWidth.sd_layout
        .centerYEqualToView(labelHengxiang)
        .heightIs(40)
        .widthRatioToView(_view2, 0.1)
        .centerXEqualToView(_view2);
    //[labelWidth setSingleLineAutoResizeWithMaxWidth:50];
    labelWidth.text = @"1.0";
    labelWidth.font = [UIFont systemFontOfSize:20];
    [labelWidth setTextColor:[UIColor redColor]];
    [labelWidth setTag:1213];
    
    UIButton *btConfirmWidth = [[UIButton alloc]init];
    [_view2 addSubview:btConfirmWidth];
    [btConfirmWidth.layer setCornerRadius:8.0];
    [btConfirmWidth setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btConfirmWidth.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btConfirmWidth.sd_layout
        .topSpaceToView(labelCanshu, 16)
        .heightIs(80)
        .widthRatioToView(_view2, 0.25)
        .rightSpaceToView(_view2, 10);
    [btConfirmWidth setTitle:@"确定" forState:UIControlStateNormal];
    [btConfirmWidth addTarget:self action:@selector(confirmWidth) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btAddwidth = [[UIButton alloc]init];
    [_view2 addSubview:btAddwidth];
    [btAddwidth.layer setCornerRadius:5];
    [btAddwidth setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btAddwidth.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btAddwidth.sd_layout
        .centerYEqualToView(labelHengxiang)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .rightSpaceToView(btConfirmWidth, 10);
    [btAddwidth setTitle:@"+" forState:UIControlStateNormal];
    [btAddwidth addTarget:self action:@selector(addWidth) forControlEvents:UIControlEventTouchUpInside];
    
    
    
#pragma mark - 纵向距离
    UILabel *labelZongxiang = [[UILabel alloc]init];
    [_view2 addSubview:labelZongxiang];
    labelZongxiang.sd_layout
        .topSpaceToView(labelHengxiang, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(_view2, 10);
    [labelZongxiang setSingleLineAutoResizeWithMaxWidth:100];
    labelZongxiang.font = [UIFont systemFontOfSize:20];
    [labelZongxiang setTextColor:[UIColor  blackColor]];
    labelZongxiang.text = @"纵向距离";
    
    UIButton *btSubDistance = [[UIButton alloc]init];
    [_view2 addSubview:btSubDistance];
    [btSubDistance.layer setCornerRadius:5];
    [btSubDistance setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btSubDistance.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btSubDistance.sd_layout
        .centerYEqualToView(labelZongxiang)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .leftSpaceToView(labelZongxiang, 10);
    [btSubDistance setTitle:@"-" forState:UIControlStateNormal];
    [btSubDistance addTarget:self action:@selector(subDistance) forControlEvents:UIControlEventTouchUpInside];
    
    //长按手势
    UILongPressGestureRecognizer *longPressSub = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(subDistance)];
    [btSubDistance addGestureRecognizer:longPressSub];
    
    UILabel *labelDistance = [[UILabel alloc]init];
    [_view2 addSubview:labelDistance];
    labelDistance.sd_layout
        .centerYEqualToView(labelZongxiang)
        .heightIs(40)
        .widthRatioToView(_view2, 0.1)
        .centerXEqualToView(_view2);
    [labelDistance setSingleLineAutoResizeWithMaxWidth:50];
    labelDistance.text = @"3.0";
    labelDistance.font = [UIFont systemFontOfSize:20];
    [labelDistance setTextColor:[UIColor redColor]];
    [labelDistance setTag:1223];
    
    UIButton *btConfirmDistance = [[UIButton alloc]init];
    [_view2 addSubview:btConfirmDistance];
    [btConfirmDistance.layer setCornerRadius:8.0];
    [btConfirmDistance setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btConfirmDistance.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btConfirmDistance.sd_layout
        .centerYEqualToView(labelZongxiang)
        .heightIs(40)
        .widthRatioToView(_view2, 0.25)
        .rightSpaceToView(_view2, 10);
    [btConfirmDistance setTitle:@"确定" forState:UIControlStateNormal];
    [btConfirmDistance addTarget:self action:@selector(confirmDistance) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btAddDistance = [[UIButton alloc]init];
    [_view2 addSubview:btAddDistance];
    [btAddDistance.layer setCornerRadius:5];
    [btAddDistance setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btAddDistance.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btAddDistance.sd_layout
        .centerYEqualToView(labelZongxiang)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .rightSpaceToView(btConfirmDistance, 10);
    [btAddDistance setTitle:@"+" forState:UIControlStateNormal];
    [btAddDistance addTarget:self action:@selector(addDistance) forControlEvents:UIControlEventTouchUpInside];
    //长按手势
    UILongPressGestureRecognizer *longPressAdd = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(addDistance)];
    [btAddDistance addGestureRecognizer:longPressAdd];
    
#pragma mark - 落杆时间
    UILabel *labelLuogan = [[UILabel alloc]init];
    [_view2 addSubview:labelLuogan];
    labelLuogan.sd_layout
        .topSpaceToView(labelZongxiang, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(_view2, 10);
    [labelLuogan setSingleLineAutoResizeWithMaxWidth:100];
    labelLuogan.font = [UIFont systemFontOfSize:20];
    [labelLuogan setTextColor:[UIColor  blackColor]];
    labelLuogan.text = @"落杆时间";
    
    UIButton *btSubDownpole = [[UIButton alloc]init];
    [_view2 addSubview:btSubDownpole];
    [btSubDownpole.layer setCornerRadius:5];
    [btSubDownpole setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btSubDownpole.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btSubDownpole.sd_layout
        .centerYEqualToView(labelLuogan)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .leftSpaceToView(labelLuogan, 10);
    [btSubDownpole setTitle:@"-" forState:UIControlStateNormal];
    [btSubDownpole addTarget:self action:@selector(subDownTime) forControlEvents:UIControlEventTouchUpInside];
    
    //落杆时间
    UILabel *labelDownTime = [[UILabel alloc]init];
    [_view2 addSubview:labelDownTime];
    labelDownTime.sd_layout
        .centerYEqualToView(labelLuogan)
        .heightIs(40)
        .widthRatioToView(_view2, 0.1)
        .centerXEqualToView(_view2);
    [labelDownTime setSingleLineAutoResizeWithMaxWidth:50];
    labelDownTime.text = @"3.0";
    labelDownTime.font = [UIFont systemFontOfSize:20];
    [labelDownTime setTextColor:[UIColor redColor]];
    [labelDownTime setTag:1233];
    
    UIButton *btConfirmDownTime = [[UIButton alloc]init];
    [_view2 addSubview:btConfirmDownTime];
    [btConfirmDownTime.layer setCornerRadius:8.0];
    [btConfirmDownTime setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btConfirmDownTime.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btConfirmDownTime.sd_layout
        .topSpaceToView(labelZongxiang, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.25)
        .rightSpaceToView(_view2, 10);
    [btConfirmDownTime setTitle:@"确定" forState:UIControlStateNormal];
    [btConfirmDownTime addTarget:self action:@selector(confirmDownTime) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btAddDownTime = [[UIButton alloc]init];
    [_view2 addSubview:btAddDownTime];
    [btAddDownTime.layer setCornerRadius:5];
    [btAddDownTime setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btAddDownTime.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btAddDownTime.sd_layout
        .centerYEqualToView(btSubDownpole)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .rightSpaceToView(btConfirmDownTime, 10);
    [btAddDownTime setTitle:@"+" forState:UIControlStateNormal];
    [btAddDownTime addTarget:self action:@selector(addDownTime) forControlEvents:UIControlEventTouchUpInside];
    
#pragma mark - 升杆时间
    UILabel *labelShenggan = [[UILabel alloc]init];
    [_view2 addSubview:labelShenggan];
    labelShenggan.sd_layout
        .topSpaceToView(labelLuogan, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(_view2, 10);
    [labelShenggan setSingleLineAutoResizeWithMaxWidth:100];
    labelShenggan.font = [UIFont systemFontOfSize:20];
    [labelShenggan setTextColor:[UIColor  blackColor]];
    labelShenggan.text = @"升杆时间";
    
    UIButton *btSubUpPole = [[UIButton alloc]init];
    [_view2 addSubview:btSubUpPole];
    [btSubUpPole.layer setCornerRadius:5];
    [btSubUpPole setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btSubUpPole.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btSubUpPole.sd_layout
        .centerYEqualToView(labelShenggan)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .leftSpaceToView(labelShenggan, 10);
    [btSubUpPole setTitle:@"-" forState:UIControlStateNormal];
    [btSubUpPole addTarget:self action:@selector(subUpTime) forControlEvents:UIControlEventTouchUpInside];
    
    //升杆时间
    UILabel *labelUpTime = [[UILabel alloc]init];
    [_view2 addSubview:labelUpTime];
    labelUpTime.sd_layout
        .centerYEqualToView(labelShenggan)
        .heightIs(40)
        .widthRatioToView(_view2, 0.1)
        .centerXEqualToView(_view2);
    [labelUpTime setSingleLineAutoResizeWithMaxWidth:50];
    labelUpTime.text = @"3.0";
    labelUpTime.font = [UIFont systemFontOfSize:20];
    [labelUpTime setTextColor:[UIColor redColor]];
    [labelUpTime setTag:1243];
    
    UIButton *btConfirmUpTime = [[UIButton alloc]init];
    [_view2 addSubview:btConfirmUpTime];
    [btConfirmUpTime.layer setCornerRadius:8.0];
    [btConfirmUpTime setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btConfirmUpTime.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btConfirmUpTime.sd_layout
        .topSpaceToView(labelLuogan, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.25)
        .rightSpaceToView(_view2, 10);
    [btConfirmUpTime setTitle:@"确定" forState:UIControlStateNormal];
    [btConfirmUpTime addTarget:self action:@selector(confirmUpTime) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btAddUpTime = [[UIButton alloc]init];
    [_view2 addSubview:btAddUpTime];
    [btAddUpTime.layer setCornerRadius:5];
    [btAddUpTime setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btAddUpTime.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btAddUpTime.sd_layout
        .centerYEqualToView(labelUpTime)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .rightSpaceToView(btConfirmUpTime, 10);
    [btAddUpTime setTitle:@"+" forState:UIControlStateNormal];
    [btAddUpTime addTarget:self action:@selector(addUpTime) forControlEvents:UIControlEventTouchUpInside];
    
    
#pragma mark - 对射设置
    UILabel *labelDuishe = [[UILabel alloc]init];
    [_view2 addSubview:labelDuishe];
    labelDuishe.sd_layout
        .topSpaceToView(labelShenggan, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(_view2, 10);
    [labelDuishe setSingleLineAutoResizeWithMaxWidth:100];
    labelDuishe.font = [UIFont systemFontOfSize:20];
    [labelDuishe setTextColor:[UIColor  blackColor]];
    labelDuishe.text = @"对射设置";
    
    UIButton *btSubShoot = [[UIButton alloc]init];
    [_view2 addSubview:btSubShoot];
    [btSubShoot.layer setCornerRadius:5];
    [btSubShoot setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btSubShoot.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btSubShoot.sd_layout
        .centerYEqualToView(labelDuishe)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .leftSpaceToView(labelDuishe, 10);
    [btSubShoot setTitle:@"-" forState:UIControlStateNormal];
    [btSubShoot addTarget:self action:@selector(subShoot) forControlEvents:UIControlEventTouchUpInside];
    
    //对射设置
    UILabel *labelShoot = [[UILabel alloc]init];
    [_view2 addSubview:labelShoot];
    labelShoot.sd_layout
        .centerYEqualToView(labelDuishe)
        .heightIs(40)
        .widthRatioToView(_view2, 0.1)
        .leftSpaceToView(btSubShoot, 12);
    //.centerXEqualToView(_view2);
    [labelShoot setSingleLineAutoResizeWithMaxWidth:100];
    labelShoot.text = @"A";
    labelShoot.font = [UIFont systemFontOfSize:20];
    [labelShoot setTextColor:[UIColor redColor]];
    [labelShoot setTag:1253];
    
    UIButton *btConfirmShoot = [[UIButton alloc]init];
    [_view2 addSubview:btConfirmShoot];
    [btConfirmShoot.layer setCornerRadius:8.0];
    [btConfirmShoot setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btConfirmShoot.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btConfirmShoot.sd_layout
        .topSpaceToView(labelShenggan, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.25)
        .rightSpaceToView(_view2, 10);
    [btConfirmShoot setTitle:@"确定" forState:UIControlStateNormal];
    [btConfirmShoot addTarget:self action:@selector(confirmShoot) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *btAddShoot = [[UIButton alloc]init];
    [_view2 addSubview:btAddShoot];
    [btAddShoot.layer setCornerRadius:5];
    [btAddShoot setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btAddShoot.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btAddShoot.sd_layout
        .centerYEqualToView(labelDuishe)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .rightSpaceToView(btConfirmShoot, 10);
    [btAddShoot setTitle:@"+" forState:UIControlStateNormal];
    [btAddShoot addTarget:self action:@selector(addShoot) forControlEvents:UIControlEventTouchUpInside];
    
    
#pragma mark - 栏杆类型
    UILabel *labelLeixing = [[UILabel alloc]init];
    [_view2 addSubview:labelLeixing];
    labelLeixing.sd_layout
        .topSpaceToView(labelDuishe, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(_view2, 10);
    [labelLeixing setSingleLineAutoResizeWithMaxWidth:100];
    labelLeixing.font = [UIFont systemFontOfSize:20];
    [labelLeixing setTextColor:[UIColor  blackColor]];
    labelLeixing.text = @"栏杆类型";
    
    UISwitch *switchType = [[UISwitch alloc] init];
    [_view2 addSubview:switchType];
    switchType.sd_layout
        .centerYEqualToView(labelLeixing)
        .heightIs(30)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(labelLeixing, 10);
    [switchType setTag:1262];
    [switchType addTarget:self action:@selector(poleType) forControlEvents:UIControlEventTouchUpInside];
    
    //显示栏杆类型
    UILabel *labelType = [[UILabel alloc]init];
    [_view2 addSubview:labelType];
    labelType.sd_layout
        .topSpaceToView(labelDuishe, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(switchType, 20);
    [labelType setSingleLineAutoResizeWithMaxWidth:100];
    [labelType setTextColor:[UIColor redColor]];
    labelType.text = @"直杆";
    labelType.font = [UIFont systemFontOfSize:20];
    [labelType setTag:1263];
    
    UIButton *btConfirmType = [[UIButton alloc]init];
    [_view2 addSubview:btConfirmType];
    [btConfirmType.layer setCornerRadius:8.0];
    [btConfirmType setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btConfirmType.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btConfirmType.sd_layout
        .topSpaceToView(labelDuishe, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.25)
        .rightSpaceToView(_view2, 10);
    [btConfirmType setTitle:@"确定" forState:UIControlStateNormal];
    [btConfirmType addTarget:self action:@selector(confirmType) forControlEvents:UIControlEventTouchUpInside];
    
    
#pragma mark - 栏杆中心偏移
    UILabel *labelDiviation = [[UILabel alloc]init];
    [_view2 addSubview:labelDiviation];
    labelDiviation.sd_layout
        .topSpaceToView(labelLeixing, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(_view2, 10);
    [labelDiviation setSingleLineAutoResizeWithMaxWidth:100];
    labelDiviation.font = [UIFont systemFontOfSize:20];
    [labelDiviation setTextColor:[UIColor  blackColor]];
    labelDiviation.text = @"中心偏移";
    [labelDiviation setTag:1271];
    
    UISwitch *switchDirection = [[UISwitch alloc] init];
    [_view2 addSubview:switchDirection];
    switchDirection.sd_layout
        .centerYEqualToView(labelDiviation)
        .heightIs(30)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(labelDiviation, 10);
    [switchDirection setTag:1272];
    [switchDirection addTarget:self action:@selector(direction) forControlEvents:UIControlEventTouchUpInside];
    
    //显示雷达中心偏移
    UILabel *labelDirection = [[UILabel alloc]init];
    [_view2 addSubview:labelDirection];
    labelDirection.sd_layout
        .centerYEqualToView(labelDiviation)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(switchDirection, 20);
    [labelDirection setSingleLineAutoResizeWithMaxWidth:100];
    [labelDirection setTextColor:[UIColor redColor]];
    labelDirection.text = @"左偏";
    labelDirection.font = [UIFont systemFontOfSize:20];
    [labelDirection setTag:1273];
    
    
    UIButton *btConfirmShift = [[UIButton alloc]init];
    [_view2 addSubview:btConfirmShift];
    [btConfirmShift.layer setCornerRadius:8.0];
    [btConfirmShift setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btConfirmShift.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btConfirmShift.sd_layout
        .topSpaceToView(labelLeixing, 20)
        .heightIs(80)
        .widthRatioToView(_view2, 0.25)
        .rightSpaceToView(_view2, 10);
    [btConfirmShift setTitle:@"确定" forState:UIControlStateNormal];
    [btConfirmShift setTag:1274];
    [btConfirmShift addTarget:self action:@selector(confirmShift) forControlEvents:UIControlEventTouchUpInside];
    
    
    UILabel *labelPianyi = [[UILabel alloc]init];
    [_view2 addSubview:labelPianyi];
    labelPianyi.sd_layout
        .topSpaceToView(labelDiviation, 12)
        .heightIs(40)
        .widthRatioToView(_view2, 0.2)
        .leftSpaceToView(_view2, 10);
    [labelPianyi setSingleLineAutoResizeWithMaxWidth:100];
    labelPianyi.font = [UIFont systemFontOfSize:20];
    [labelPianyi setTextColor:[UIColor  blackColor]];
    labelPianyi.text = @"偏移量";
    [labelPianyi setTag:1285];
    
    UIButton *btSubShift = [[UIButton alloc]init];
    [_view2 addSubview:btSubShift];
    [btSubShift.layer setCornerRadius:5];
    [btSubShift setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btSubShift.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btSubShift.sd_layout
        .centerYEqualToView(labelPianyi)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .centerXEqualToView(btSubShoot);
    [btSubShift setTitle:@"-" forState:UIControlStateNormal];
    [btSubShift addTarget:self action:@selector(subShift) forControlEvents:UIControlEventTouchUpInside];
    [btSubShift setTag:1281];
    
    UILabel *labelShift = [[UILabel alloc]init];
    [_view2 addSubview:labelShift];
    labelShift.sd_layout
        .centerYEqualToView(btSubShift)
        .heightIs(40)
        .widthRatioToView(_view2, 0.1)
        .centerXEqualToView(_view2);
    
    labelShift.text = @"0.0";
    labelShift.font = [UIFont systemFontOfSize:20];
    [labelShift setTextColor:[UIColor redColor]];
    [labelShift setTag:1282];
    
    UIButton *btAddShift = [[UIButton alloc]init];
    [_view2 addSubview:btAddShift];
    [btAddShift.layer setCornerRadius:5];
    [btAddShift setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btAddShift.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btAddShift.sd_layout
        .centerYEqualToView(labelPianyi)
        .heightIs(30)
        .widthRatioToView(_view2, 0.15)
        .rightSpaceToView(btConfirmShift, 10);
    [btAddShift setTitle:@"+" forState:UIControlStateNormal];
    [btAddShift addTarget:self action:@selector(addShift) forControlEvents:UIControlEventTouchUpInside];
    [btAddShift setTag:1283];
    
#pragma mark - 重置和刷新
    //重置按钮
    UIButton *btReset = [[UIButton alloc]init];
    [_view2 addSubview:btReset];
    [btReset setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btReset.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.5 alpha:1.0];
    [btReset.layer setCornerRadius:8.0];
    btReset.sd_layout
        .topSpaceToView(labelPianyi, 18)
        .heightIs(40)
        .widthRatioToView(_view2, 0.38)
        .leftSpaceToView(_view2, 10);
    [btReset setTitle:@"重置" forState:UIControlStateNormal] ;
    [btReset addTarget:self action:@selector(reset:) forControlEvents:UIControlEventTouchUpInside];
    
    
    //刷新按钮
    UIButton *btRefresh = [[UIButton alloc]init];
    [_view2 addSubview:btRefresh];
    [btRefresh setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btRefresh.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.5 alpha:1.0];
    [btRefresh.layer setCornerRadius:8.0];
    btRefresh.sd_layout
        .centerYEqualToView(btReset)
        .heightIs(40)
        .widthRatioToView(_view2, 0.42)
        .rightSpaceToView(_view2, 10);
    [btRefresh setTitle:@"刷新" forState:UIControlStateNormal] ;
    [btRefresh setTag:1292];
    [btRefresh addTarget:self action:@selector(refresh) forControlEvents:UIControlEventTouchUpInside];
    
    
    UILabel *labelCaution = [[UILabel alloc]init];
    [_view2 addSubview:labelCaution];
    labelCaution.sd_layout
        .bottomSpaceToView(_view2, 20)
        .heightIs(40)
    //.widthRatioToView(_view2, 0.8)
        .centerXEqualToView(_view2);
    [labelCaution setSingleLineAutoResizeWithMaxWidth:300];
    //labelFangwei.font = [UIFont systemFontOfSize:20];
    [labelCaution setTextColor:[UIColor  blackColor]];
    labelCaution.text = @"注意：当数字为红色时，设置未生效";
    
    
#pragma mark - 背景学习view3
    _view3 = [[UIView alloc] init];
    _view3.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
    [_scrollView addSubview:_view3];
    _view3.sd_cornerRadiusFromHeightRatio = @(0.01);
    _view3.sd_layout
        .topSpaceToView(_view2, 0)
        .leftSpaceToView(_scrollView, 12)
        .rightSpaceToView(_scrollView, 12)
        .topSpaceToView(_view2, 20)
        .heightIs(1388) ;
    
    [_scrollView setupAutoContentSizeWithBottomView:_view3 bottomMargin:10];
    
    UILabel *labelBackStudy = [[UILabel alloc]init];
    [_view3 addSubview:labelBackStudy];
    labelBackStudy.sd_layout
        .topSpaceToView(_view3, 8)
        .heightIs(50)
        .centerXEqualToView(_view3);
    [labelBackStudy setSingleLineAutoResizeWithMaxWidth:200];
    labelBackStudy.font = [UIFont systemFontOfSize:24];
    [labelBackStudy setTextColor:[UIColor  blackColor]];
    labelBackStudy.text = @"背景学习";
    
    //环境背景学习按钮
    UIButton *btEnvirStudy = [[UIButton alloc]init];
    [_view3 addSubview:btEnvirStudy];
    [btEnvirStudy setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btEnvirStudy.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btEnvirStudy.layer setCornerRadius:8.0];
    btEnvirStudy.sd_layout
        .topSpaceToView(labelBackStudy, 8)
        .heightIs(40)
        .widthRatioToView(_view3, 0.4)
        .leftSpaceToView(_view3, 10);
    [btEnvirStudy setTitle:@"环境背景学习" forState:UIControlStateNormal] ;
    [btEnvirStudy addTarget:self action:@selector(environStudy:) forControlEvents:UIControlEventTouchUpInside];
    
    
    //栅栏杆学习按钮
    UIButton *btBrakeStudy = [[UIButton alloc]init];
    [_view3 addSubview:btBrakeStudy];
    [btBrakeStudy setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btBrakeStudy.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btBrakeStudy.layer setCornerRadius:8.0];
    btBrakeStudy.sd_layout
        .topSpaceToView(labelBackStudy, 8)
        .heightIs(40)
        .widthRatioToView(_view3, 0.4)
        .rightSpaceToView(_view3, 10);
    [btBrakeStudy setTitle:@"栅栏杆学习" forState:UIControlStateNormal] ;
    [btBrakeStudy addTarget:self action:@selector(brakeStudy:) forControlEvents:UIControlEventTouchUpInside];
    
    //直杆学习按钮
    UIButton *btStraightStudy = [[UIButton alloc]init];
    [_view3 addSubview:btStraightStudy];
    [btStraightStudy setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btStraightStudy.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btStraightStudy.layer setCornerRadius:8.0];
    btStraightStudy.sd_layout
        .topSpaceToView(btEnvirStudy, 20)
        .heightIs(40)
        .widthRatioToView(_view3, 0.4)
        .leftSpaceToView(_view3, 10);
    [btStraightStudy setTitle:@"直杆学习" forState:UIControlStateNormal] ;
    [btStraightStudy addTarget:self action:@selector(straightStudy:) forControlEvents:UIControlEventTouchUpInside];
    
    
    //背景参数查询按钮
    UIButton *btStudyQuery = [[UIButton alloc]init];
    [_view3 addSubview:btStudyQuery];
    [btStudyQuery setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btStudyQuery.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btStudyQuery.layer setCornerRadius:8.0];
    btStudyQuery.sd_layout
        .topSpaceToView(btBrakeStudy, 20)
        .heightIs(40)
        .widthRatioToView(_view3, 0.4)
        .rightSpaceToView(_view3, 10);
    [btStudyQuery setTitle:@"背景参数查询" forState:UIControlStateNormal] ;
    [btStudyQuery addTarget:self action:@selector(studyQuery:) forControlEvents:UIControlEventTouchUpInside];
    
    //环境噪声
    UILabel *labelEnviron = [[UILabel alloc]init];
    [_view3 addSubview:labelEnviron];
    labelEnviron.sd_layout
        .topSpaceToView(btStraightStudy, 20)
        .heightIs(40)
        .leftSpaceToView(_view3, 10)
        .rightSpaceToView(_view3,10);
    
    labelEnviron.textAlignment = NSTextAlignmentCenter;
    [labelEnviron setBackgroundColor:[UIColor colorWithRed:0 green:0.2 blue:0.2 alpha:0.2]];
    labelEnviron.font = [UIFont systemFontOfSize:18];
    [labelEnviron setTextColor:[UIColor  blackColor]];
    labelEnviron.text = @"环境背景";
    
    viewNoise *tvEnviron = [[viewNoise alloc] init];
    tvEnviron.backgroundColor = [UIColor whiteColor];
    [_view3 addSubview:tvEnviron ];
    tvEnviron.sd_layout
        .topSpaceToView(labelEnviron, 8)
        .heightIs(328)
        .leftSpaceToView(_view3, 10)
        .rightSpaceToView(_view3,10);
    [tvEnviron setTag:1332];
    NSMutableArray *arrEnviron = [[NSMutableArray alloc] init];
    for(int i=0;i<128; i++){
        [arrEnviron addObject:@"0"];
    }
    tvEnviron.dataStr = arrEnviron;
    tvEnviron.colorNumber = 0;
    
    //直杆噪声
    UILabel *labelStraight = [[UILabel alloc]init];
    [_view3 addSubview:labelStraight];
    labelStraight.sd_layout
        .topSpaceToView(tvEnviron, 8)
        .heightIs(40)
        .leftSpaceToView(_view3, 10)
        .rightSpaceToView(_view3,10);
    
    labelStraight.textAlignment = NSTextAlignmentCenter;
    [labelStraight setBackgroundColor:[UIColor colorWithRed:0 green:0.2 blue:0.2 alpha:0.2]];
    labelStraight.font = [UIFont systemFontOfSize:18];
    [labelStraight setTextColor:[UIColor  blackColor]];
    labelStraight.text = @"直杆背景";
    
    viewNoise *tvStraight = [[viewNoise alloc] init];
    tvStraight.backgroundColor = [UIColor whiteColor];
    [_view3 addSubview:tvStraight ];
    tvStraight.sd_layout
        .topSpaceToView(labelStraight, 8)
        .heightIs(328)
        .leftSpaceToView(_view3, 10)
        .rightSpaceToView(_view3,10);
    [tvStraight setTag:1334];
    NSMutableArray *arrStraight = [[NSMutableArray alloc] init];
    for(int i=0;i<128; i++){
        [arrStraight addObject:@"0"];
    }
    tvStraight.dataStr = arrStraight;
    tvStraight.colorNumber = 0;
    
    
    //栅栏杆噪声
    UILabel *labelBrake = [[UILabel alloc]init];
    [_view3 addSubview:labelBrake];
    labelBrake.sd_layout
        .topSpaceToView(tvStraight, 8)
        .heightIs(40)
        .leftSpaceToView(_view3, 10)
        .rightSpaceToView(_view3,10);
    
    labelBrake.textAlignment = NSTextAlignmentCenter;
    [labelBrake setBackgroundColor:[UIColor colorWithRed:0 green:0.2 blue:0.2 alpha:0.2]];
    labelBrake.font = [UIFont systemFontOfSize:18];
    [labelBrake setTextColor:[UIColor  blackColor]];
    
    labelBrake.text = @"栅栏杆背景";
    
    viewNoise *tvBrake = [[viewNoise alloc] init];
    tvBrake.backgroundColor = [UIColor whiteColor];
    [_view3 addSubview:tvBrake ];
    tvBrake.sd_layout
        .topSpaceToView(labelBrake, 8)
        .heightIs(328)
        .leftSpaceToView(_view3, 10)
        .rightSpaceToView(_view3,10);
    [tvBrake setTag:1336];
    NSMutableArray *arrBrake = [[NSMutableArray alloc] init];
    for(int i=0;i<128; i++){
        [arrBrake addObject:@"0"];
    }
    tvBrake.dataStr = arrBrake;
    tvBrake.colorNumber = 0;
    
    UILabel *labelCautionNoise = [[UILabel alloc]init];
    [_view3 addSubview:labelCautionNoise];
    labelCautionNoise.sd_layout
        .bottomSpaceToView(_view3, 20)
        .heightIs(40)
        .centerXEqualToView(_view3);
    [labelCautionNoise setSingleLineAutoResizeWithMaxWidth:300];
    [labelCautionNoise setTextColor:[UIColor  blackColor]];
    labelCautionNoise.text = @"注意：当数字为红色时，未更新背景";
}

#pragma mark 环境噪声显示
-(void) addNoiseLayout{
    
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

#pragma mark 获取固件版本
-(void)Gujianbanben{
    [self.timer invalidate];
    self.timer = nil;
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
    //self.header.dataWrite = @"";
}
-(void)SNchaxun:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    UIButton *button = (UIButton *)sender;
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
        self.header.dataWrite = @"c0 08";
        if([button.currentTitle  isEqual:@"整机SN"]){
            self.header.tagWrite = 1103;
            [self.header writeBoardWithTag:1103];
            NSLog(@"writeBoard with tag ---%d",1103);
        }else{
            self.header.tagWrite = 1104;
            [self.header writeBoardWithTag:1104];
            NSLog(@"writeBoard with tag ---%d",1104);
        }
    }
    //self.header.dataWrite = @"";
}

#pragma mark 区分人车切换,横向宽度
-(void) distinguish{
    [self.timer invalidate];
    self.timer = nil;
    UISwitch *switchDiff = (UISwitch *)[self.view viewWithTag:1202];
    UILabel  *labelRenche = (UILabel *)[self.view viewWithTag:1203];
    if(![switchDiff isOn]){
        [labelRenche setText:@"不区分"];
    }else{
        [labelRenche setText:@"区分"];
    }
    [labelRenche setTextColor:[UIColor redColor]];
}

-(void) subWidth{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelWidth = (UILabel *)[self.view viewWithTag:1213];
    if([labelWidth.text isEqualToString:@"1.0"]){
        [labelWidth setText:@"0.8"];
    }else if([labelWidth.text isEqualToString:@"0.8"]){
        [labelWidth setText:@"0.6"];
    }else if([labelWidth.text isEqualToString:@"0.6"]){
        [labelWidth setText:@"0.4"];
    }else{
        return;
    }
    [labelWidth setTextColor:[UIColor redColor]];
}

-(void) addWidth{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelWidth = (UILabel *)[self.view viewWithTag:1213];
    if([labelWidth.text isEqualToString:@"0.4"]){
        [labelWidth setText:@"0.6"];
    }else if([labelWidth.text isEqualToString:@"0.6"]){
        [labelWidth setText:@"0.8"];
    }else if([labelWidth.text isEqualToString:@"0.8"]){
        [labelWidth setText:@"1.0"];
    }else{
        return;
    }
    [labelWidth setTextColor:[UIColor redColor]];
}

-(void) confirmWidth{
    [self.timer invalidate];
    self.timer = nil;
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    UILabel  *labelRenche = (UILabel *)[self.view viewWithTag:1203];
    UILabel  *labelWidth = (UILabel *)[self.view viewWithTag:1213];
    if([labelRenche.text isEqualToString:@"不区分"] && [self.header.socket isConnected]){
        if([labelWidth.text isEqualToString:@"1.0"]){
            self.header.dataWrite = @"a7 00";
        }else if([labelWidth.text isEqualToString:@"0.8"]){
            self.header.dataWrite = @"a7 01";
        }else if([labelWidth.text isEqualToString:@"0.6"]){
            self.header.dataWrite = @"a7 02";
        }else{
            self.header.dataWrite = @"a7 03";
        }
        
    }else if([labelRenche.text isEqualToString:@"区分"] && [self.header.socket isConnected]){
        if([labelWidth.text isEqualToString:@"1.0"]){
            self.header.dataWrite = @"a7 04";
        }else if([labelWidth.text isEqualToString:@"0.8"]){
            self.header.dataWrite = @"a7 05";
        }else if([labelWidth.text isEqualToString:@"0.6"]){
            self.header.dataWrite = @"a7 06";
        }else{
            self.header.dataWrite = @"a7 07";
        }
    }
    self.header.tagWrite = 1210;
    [self.header writeBoardWithTag:1210];
    NSLog(@"writeBoard with tag ---%d",1210);
}

#pragma mark 调整纵向距离
-(void) subDistance{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelDistance = (UILabel *)[self.view viewWithTag:1223];
    float floatDistance  = [labelDistance.text floatValue];
    if(floatDistance>0.5){
        floatDistance -=0.1;
    }else{
        return;
    }
    labelDistance.text = [NSString stringWithFormat:@"%.1f",floatDistance];
    [labelDistance setTextColor:[UIColor redColor]];
}

-(void) addDistance{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelDistance = (UILabel *)[self.view viewWithTag:1223];
    float floatDistance  = [labelDistance.text floatValue];
    if(floatDistance<6.0){
        floatDistance +=0.1;
    }else{
        return;
    }
    labelDistance.text = [NSString stringWithFormat:@"%.1f",floatDistance];
    [labelDistance setTextColor:[UIColor redColor]];
}

-(void) confirmDistance{
    [self.timer invalidate];
    self.timer = nil;
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    UILabel  *labelDistance = (UILabel *)[self.view viewWithTag:1223];
    float floatDistance  = [labelDistance.text floatValue];
    if(floatDistance<0.5){
        return;
    }
    int intDistance = (int) (floatDistance * 10);
    NSString *strDistance;
    if(intDistance>=10){
        strDistance = [NSString stringWithFormat:@"a8 %2d",intDistance];
    }else{
        strDistance = [NSString stringWithFormat:@"a8 0%d1",intDistance];
    }
    self.header.dataWrite = strDistance;
    self.header.tagWrite = 1220;
    [self.header writeBoardWithTag:1220];
    NSLog(@"writeBoard with tag ---%d",1220);
}

#pragma mark 调整落杆时间
-(void) subDownTime{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelDownTime = (UILabel *)[self.view viewWithTag:1233];
    
    if([labelDownTime.text isEqualToString:@"6.0"]){
        [labelDownTime setText:@"5.0"];
    }else if([labelDownTime.text isEqualToString:@"5.0"]){
        [labelDownTime setText:@"4.0"];
    }else if([labelDownTime.text isEqualToString:@"4.0"]){
        [labelDownTime setText:@"3.0"];
    }else if([labelDownTime.text isEqualToString:@"3.0"]){
        [labelDownTime setText:@"2.0"];
    }else{
        return;
    }
    [labelDownTime setTextColor:[UIColor redColor]];
    //最低只可以设置成2.0
}

-(void) addDownTime{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelDownTime = (UILabel *)[self.view viewWithTag:1233];
    //小于2.0，直接设置为2.0
    if([labelDownTime.text isEqualToString:@"0.0"]){
        [labelDownTime setText:@"2.0"];
    }else if([labelDownTime.text isEqualToString:@"1.0"]){
        [labelDownTime setText:@"2.0"];
    }else if([labelDownTime.text isEqualToString:@"2.0"]){
        [labelDownTime setText:@"3.0"];
    }else if([labelDownTime.text isEqualToString:@"3.0"]){
        [labelDownTime setText:@"4.0"];
    }else if([labelDownTime.text isEqualToString:@"4.0"]){
        [labelDownTime setText:@"5.0"];
    }else if([labelDownTime.text isEqualToString:@"5.0"]){
        [labelDownTime setText:@"6.0"];
    }else{
        return;
    }
    [labelDownTime setTextColor:[UIColor redColor]];
}

-(void) confirmDownTime{
    [self.timer invalidate];
    self.timer = nil;
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    UILabel  *labelDownTime = (UILabel *)[self.view viewWithTag:1233];
    if([labelDownTime.text isEqualToString:@"0.0"]){
        return;
    }
    if([labelDownTime.text isEqualToString:@"1.0"]){
        return;
    }
    
    if([labelDownTime.text isEqualToString:@"2.0"]){
        self.header.dataWrite = @"ac 14";
    }else if([labelDownTime.text isEqualToString:@"3.0"]){
        self.header.dataWrite = @"ac 1e";
    }else if([labelDownTime.text isEqualToString:@"4.0"]){
        self.header.dataWrite = @"ac 28";
    }else if([labelDownTime.text isEqualToString:@"5.0"]){
        self.header.dataWrite = @"ac 32";
    }else if([labelDownTime.text isEqualToString:@"6.0"]){
        self.header.dataWrite = @"ac 3c";
    }
    self.header.tagWrite = 1230;
    [self.header writeBoardWithTag:1230];
    NSLog(@"writeBoard with tag ---%d",1230);
}

#pragma mark 调整升杆时间
-(void) subUpTime{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelUpTime = (UILabel *)[self.view viewWithTag:1243];
    if([labelUpTime.text isEqualToString:@"6.0"]){
        [labelUpTime setText:@"5.0"];
    }else if([labelUpTime.text isEqualToString:@"5.0"]){
        [labelUpTime setText:@"4.0"];
    }else if([labelUpTime.text isEqualToString:@"4.0"]){
        [labelUpTime setText:@"3.0"];
    }else if([labelUpTime.text isEqualToString:@"3.0"]){
        [labelUpTime setText:@"2.0"];
    }else if([labelUpTime.text isEqualToString:@"2.0"]){
        [labelUpTime setText:@"1.0"];
    }else if([labelUpTime.text isEqualToString:@"1.0"]){
        [labelUpTime setText:@"0.0"];
    }else{
        return;
    }
    [labelUpTime setTextColor:[UIColor redColor]];
}

-(void) addUpTime{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelUpTime = (UILabel *)[self.view viewWithTag:1243];
    if([labelUpTime.text isEqualToString:@"0.0"]){
        [labelUpTime setText:@"1.0"];
    }else if([labelUpTime.text isEqualToString:@"1.0"]){
        [labelUpTime setText:@"2.0"];
    }else if([labelUpTime.text isEqualToString:@"2.0"]){
        [labelUpTime setText:@"3.0"];
    }else if([labelUpTime.text isEqualToString:@"3.0"]){
        [labelUpTime setText:@"4.0"];
    }else if([labelUpTime.text isEqualToString:@"4.0"]){
        [labelUpTime setText:@"5.0"];
    }else if([labelUpTime.text isEqualToString:@"5.0"]){
        [labelUpTime setText:@"6.0"];
    }else{
        return;
    }
    [labelUpTime setTextColor:[UIColor redColor]];
}

-(void) confirmUpTime{
    [self.timer invalidate];
    self.timer = nil;
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    UILabel  *labelUpTime = (UILabel *)[self.view viewWithTag:1243];
    if([labelUpTime.text isEqualToString:@"0.0"]){
        self.header.dataWrite = @"af 00";
    }else if([labelUpTime.text isEqualToString:@"1.0"]){
        self.header.dataWrite = @"af 0a";
    }else if([labelUpTime.text isEqualToString:@"2.0"]){
        self.header.dataWrite = @"af 14";
    }else if([labelUpTime.text isEqualToString:@"3.0"]){
        self.header.dataWrite = @"af 1e";
    }else if([labelUpTime.text isEqualToString:@"4.0"]){
        self.header.dataWrite = @"af 28";
    }else if([labelUpTime.text isEqualToString:@"5.0"]){
        self.header.dataWrite = @"af 32";
    }else{
        self.header.dataWrite = @"af 3c";
    }
    self.header.tagWrite = 1240;
    [self.header writeBoardWithTag:1240];
    NSLog(@"writeBoard with tag ---%d",1240);
}

#pragma mark 调整对射频表
-(void) subShoot{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelShoot = (UILabel *)[self.view viewWithTag:1253];
    if([labelShoot.text isEqualToString:@"D"]){
        [labelShoot setText:@"C"];
    }else if([labelShoot.text isEqualToString:@"C"]){
        [labelShoot setText:@"B"];
    }else if([labelShoot.text isEqualToString:@"B"]){
        [labelShoot setText:@"A"];
    }else{
        return;
    }
    [labelShoot setTextColor:[UIColor redColor]];
}

-(void) addShoot{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelShoot = (UILabel *)[self.view viewWithTag:1253];
    if([labelShoot.text isEqualToString:@"A"]){
        [labelShoot setText:@"B"];
    }else if([labelShoot.text isEqualToString:@"B"]){
        [labelShoot setText:@"C"];
    }else if([labelShoot.text isEqualToString:@"C"]){
        [labelShoot setText:@"D"];
    }else{
        return;
    }
    [labelShoot setTextColor:[UIColor redColor]];
}

-(void) confirmShoot{
    [self.timer invalidate];
    self.timer = nil;
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    UILabel  *labelShoot = (UILabel *)[self.view viewWithTag:1253];
    if([labelShoot.text isEqualToString:@"A"]){
        self.header.dataWrite = @"ab 00";
    }else if([labelShoot.text isEqualToString:@"B"]){
        self.header.dataWrite = @"ab 01";
    }else if([labelShoot.text isEqualToString:@"C"]){
        self.header.dataWrite = @"ab 02";
    }else{
        self.header.dataWrite = @"ab 03";
    }
    self.header.tagWrite = 1250;
    [self.header writeBoardWithTag:1250];
    NSLog(@"writeBoard with tag ---%d",1250);
}

#pragma mark 栏杆类型切换
-(void) poleType{
    [self.timer invalidate];
    self.timer = nil;
    UISwitch *switchType = (UISwitch *)[self.view viewWithTag:1262];
    UILabel  *labelPoleType = (UILabel *)[self.view viewWithTag:1263];
    if([switchType isOn]){
        [labelPoleType setText:@"栅栏杆"];
    }else{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认切换" message:@"若栅栏杆切换为直杆，将清除背景参数" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"切换" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [labelPoleType setText:@"直杆"];
            viewNoise  *tvEnviron = (viewNoise *)[self.view viewWithTag:1332];//
            viewNoise  *tvBrake = (viewNoise *)[self.view viewWithTag:1336];//
            viewNoise  *tvStraight = (viewNoise *)[self.view viewWithTag:1334];//
            
            tvEnviron.colorNumber = 0;
            tvStraight.colorNumber = 0;
            tvBrake.colorNumber = 0;
            [tvEnviron setNeedsDisplay];
            [tvStraight setNeedsDisplay];
            [tvBrake setNeedsDisplay];
        }];
        UIAlertAction *action2= [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
            [switchType setOn:YES];
            [labelPoleType setText:@"栅栏杆"];
        }];
        [alert addAction:action1];
        [alert addAction:action2];
        [self presentViewController:alert animated:YES completion:^{
        }];
        //[labelPoleType setText:@"直杆"];
        
    }
    [labelPoleType setTextColor:[UIColor redColor]];
}

-(void) confirmType{
    [self.timer invalidate];
    self.timer = nil;
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    UISwitch *switchType = (UISwitch *)[self.view viewWithTag:1262];
    UILabel  *labelPoleType = (UILabel *)[self.view viewWithTag:1263];
    self.header.dataWrite = @"bf 01";
    
    [labelPoleType setTextColor:[UIColor blackColor]];
    self.header.tagWrite = 1260;
    [self.header writeBoardWithTag:1260];
    NSLog(@"writeBoard with tag ---%d",1260);
    
    if([switchType isOn]){
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"进行环境背景和栅栏杆学习" message:@"是否进行环境背景学习\r\n学习完成后再进行栅栏杆学习？" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            if([self.header.socket isDisconnected]){
                self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.HUD.mode = MBProgressHUDModeText;
                self.HUD.label.text= @"网络已断开，请重新连接";
                self.HUD.label.textColor = [UIColor blueColor];
                self.HUD.removeFromSuperViewOnHide = YES;
                [self.HUD hideAnimated:YES afterDelay:3];
                return;
            }
            [self sound1];
            UIAlertController *alertBegin = [UIAlertController alertControllerWithTitle:@"环境背景学习" message:@"确保雷达十米内无行人或车辆\n请先将道闸杆升起！学习过程中道闸杆务必保持不动!\n确定后开始学习" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"开始" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self.player stop];
                
                [self sound2];
                if([self.header.socket isConnected]){
                    self.header.dataWrite = @"aa 01";
                    self.header.tagWrite = 1301;
                    [self.header writeBoardWithTag:1301];
                    NSLog(@"writeBoard with tag ---%d",1301);
                    
                    //viewNoise  *tvEnviron = (viewNoise *)[self.view viewWithTag:1332];
                    // [tvEnviron setTextColor:[UIColor redColor]];
                }
                //-----------
                UIAlertController *alertStudy = [UIAlertController alertControllerWithTitle:@"环境背景学习" message:@"正在学习，确保无行人或车辆通过\n学习过程中道闸杆务必保持升起状态不动！\n开始学习5秒后即可停止学习" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action11 = [UIAlertAction actionWithTitle:@"停止" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                    if([self.header.socket isConnected]){
                        self.header.dataWrite = @"aa 00";
                        self.header.tagWrite = 1307;
                        [self.header writeBoardWithTag:1307];
                        NSLog(@"writeBoard with tag ---%d",1307);
                    }
                    [self sound3];
                    UIAlertController *alertEnd = [UIAlertController alertControllerWithTitle:@"环境背景学习" message:@"学习结果保存完毕" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *action111 = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                        //保存背景
                        self.header.dataWrite = @"bf 00";
                        self.header.tagWrite = 1001;
                        [self.header writeBoardWithTag:1001];
                        NSLog(@"writeBoard with tag ---%d",1001);
                        //self.header.dataWrite = @"";
                        
                        if([self.header.socket isDisconnected]){
                            self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                            self.HUD.mode = MBProgressHUDModeText;
                            self.HUD.label.text= @"网络已断开，请重新连接";
                            self.HUD.label.textColor = [UIColor blueColor];
                            self.HUD.removeFromSuperViewOnHide = YES;
                            [self.HUD hideAnimated:YES afterDelay:3];
                            return;
                        }
                        [self sound4];
                        UIAlertController *alertBegin = [UIAlertController alertControllerWithTitle:@"栅栏杆学习" message:@"确保雷达十米内无行人或车辆！\n确定后开始学习！" preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"开始" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            [self.player stop];
                            
                            [self sound2];
                            if([self.header.socket isConnected]){
                                self.header.dataWrite = @"aa 03";
                                self.header.tagWrite = 1303;
                                [self.header writeBoardWithTag:1303];
                                NSLog(@"writeBoard with tag ---%d",1303);
                            }
                            //-----------
                            UIAlertController *alertStudy = [UIAlertController alertControllerWithTitle:@"栅栏杆学习" message:@"正在学习，确保无行人或车辆通过\n 请遥控升降道闸杆三次，完成后即可停止学习" preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction *action11 = [UIAlertAction actionWithTitle:@"停止" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                                if([self.header.socket isConnected]){
                                    self.header.dataWrite = @"aa 00";
                                    self.header.tagWrite = 1307;
                                    [self.header writeBoardWithTag:1307];
                                    NSLog(@"writeBoard with tag ---%d",1307);
                                }
                                [self sound3];
                                UIAlertController *alertEnd = [UIAlertController alertControllerWithTitle:@"栅栏杆学习" message:@"学习结束\n参数保存完成" preferredStyle:UIAlertControllerStyleAlert];
                                UIAlertAction *action111 = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                                    //保存背景
                                    self.header.dataWrite = @"bf 00";
                                    self.header.tagWrite = 1001;
                                    [self.header writeBoardWithTag:1001];
                                    NSLog(@"writeBoard with tag ---%d",1001);
                                    //self.header.dataWrite = @"";
                                }];
                                [alertEnd addAction:action111];
                                [self presentViewController:alertEnd animated:YES completion:^{
                                }];
                            }];
                            [alertStudy addAction:action11];
                            [self presentViewController:alertStudy animated:YES completion:^{
                            }];
                        }];
                        UIAlertAction *action2= [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                            [self.player stop];
                        }];
                        [alertBegin addAction:action1];
                        [alertBegin addAction:action2];
                        [self presentViewController:alertBegin animated:YES completion:^{
                        }];
                    }];
                    [alertEnd addAction:action111];
                    [self presentViewController:alertEnd animated:YES completion:^{
                    }];
                }];
                [alertStudy addAction:action11];
                [self presentViewController:alertStudy animated:YES completion:^{
                }];
            }];
            UIAlertAction *action2= [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self.player stop];
            }];
            [alertBegin addAction:action1];
            [alertBegin addAction:action2];
            [self presentViewController:alertBegin animated:YES completion:^{
            }];
        }];
        UIAlertAction *action2= [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
            [switchType setOn:NO];
            [labelPoleType setText:@"直杆"];
        }];
        [alert addAction:action1];
        [alert addAction:action2];
        [self presentViewController:alert animated:YES completion:^{
        }];
        
    }
}

#pragma mark 雷达中心偏移
-(void) direction{
    [self.timer invalidate];
    self.timer = nil;
    UISwitch *switchDirection = (UISwitch *)[self.view viewWithTag:1272];
    UILabel  *labelDirection = (UILabel *)[self.view viewWithTag:1273];
    if(![switchDirection isOn]){
        [labelDirection setText:@"左偏"];
        [switchDirection setOn:NO];
    }else{
        [labelDirection setText:@"右偏"];
        [switchDirection setOn:YES];
    }
    [labelDirection setTextColor:[UIColor redColor]];
}

-(void) subShift{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelShift = (UILabel *)[self.view viewWithTag:1282];
    if([labelShift.text isEqualToString:@"0.3"]){
        [labelShift setText:@"0.2"];
    }else if([labelShift.text isEqualToString:@"0.2"]){
        [labelShift setText:@"0.1"];
    }else if([labelShift.text isEqualToString:@"0.1"]){
        [labelShift setText:@"0.0"];
    }else{
        return;
    }
    [labelShift setTextColor:[UIColor redColor]];
}

-(void) addShift{
    [self.timer invalidate];
    self.timer = nil;
    UILabel  *labelShift = (UILabel *)[self.view viewWithTag:1282];
    if([labelShift.text isEqualToString:@"0.0"]){
        [labelShift setText:@"0.1"];
    }else if([labelShift.text isEqualToString:@"0.1"]){
        [labelShift setText:@"0.2"];
    }else if([labelShift.text isEqualToString:@"0.2"]){
        [labelShift setText:@"0.3"];
    }else{
        return;
    }
    [labelShift setTextColor:[UIColor redColor]];
}

-(void) confirmShift{
    [self.timer invalidate];
    self.timer = nil;
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    UISwitch *switchShift = (UISwitch *)[self.view viewWithTag:1272];
    //UILabel  *labelDirection = (UILabel *)[self.view viewWithTag:1273];
    UILabel *labelShift = (UILabel *)[self.view viewWithTag:1282];
    NSString *strCmd = [[NSString alloc] init];
    if([labelShift.text isEqualToString:@"0.0"]){
        strCmd = @"00";
    }else if([labelShift.text isEqualToString:@"0.1"]){
        strCmd = @"10";
    }else if([labelShift.text isEqualToString:@"0.2"]){
        strCmd = @"20";
    }else if([labelShift.text isEqualToString:@"0.3"]){
        strCmd = @"30";
    }
    if([switchShift isOn]){
        self.header.dataWrite = [NSString stringWithFormat:@"b1 01 %@",strCmd];
    }else{
        self.header.dataWrite = [NSString stringWithFormat:@"b1 00 %@",strCmd];;
    }
    //[labelDirection setTextColor:[UIColor blackColor]];
    self.header.tagWrite = 1270;
    [self.header writeBoardWithTag:1270];
    NSLog(@"writeBoard with tag ---%d",1270);
}

#pragma mark 确认重置和刷新
-(void) reset:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
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
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确认重置" message:@"是否重置设备Flash数据" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            if([self.header.socket isConnected]){
                self.header.dataWrite = @"bf ff";
                self.header.tagWrite = 1298;
                [self.header writeBoardWithTag:1298];
                NSLog(@"writeBoard with tag ---%d",1298);
            }
        }];
        UIAlertAction *action2= [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }];
        [alert addAction:action1];
        [alert addAction:action2];
        [self presentViewController:alert animated:YES completion:^{
            sleep(1);
        }];
    }
    // self.header.dataWrite = @"";
}

-(void) refresh{
    [self.timer invalidate];
    self.timer = nil;
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
        self.header.dataWrite = @"c0 01";
        self.header.tagWrite = 1299;
        [self.header writeBoardWithTag:1299];
        NSLog(@"writeBoard with tag ---%d",1299);
    }
    //self.header.dataWrite = @"";
    [self.timer invalidate];
}


#pragma mark 确认背景学习
//环境背景学习
-(void) environStudy:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    [self sound1];
    UIAlertController *alertBegin = [UIAlertController alertControllerWithTitle:@"环境背景学习" message:@"确保雷达十米内无行人或车辆\n请先将道闸杆升起！学习过程中道闸杆务必保持不动!\n确定后开始学习！" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"开始" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.player stop];
        
        [self sound2];
        if([self.header.socket isConnected]){
            self.header.dataWrite = @"aa 01";
            self.header.tagWrite = 1301;
            [self.header writeBoardWithTag:1301];
            NSLog(@"writeBoard with tag ---%d",1301);
            
            // viewNoise  *tvEnviron = (viewNoise *)[self.view viewWithTag:1332];
            // [tvEnviron setTextColor:[UIColor redColor]];
        }
        //-----------
        UIAlertController *alertStudy = [UIAlertController alertControllerWithTitle:@"环境背景学习" message:@"正在学习，确保无行人或车辆通过！\n 学习过程中道闸杆务必保持升起状态不动！\n开始学习5秒后即可停止学习" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action11 = [UIAlertAction actionWithTitle:@"停止" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            if([self.header.socket isConnected]){
                self.header.dataWrite = @"aa 00";
                self.header.tagWrite = 1307;
                [self.header writeBoardWithTag:1307];
                NSLog(@"writeBoard with tag ---%d",1307);
            }
            [self sound3];
            UIAlertController *alertEnd = [UIAlertController alertControllerWithTitle:@"环境背景学习" message:@"学习结束，参数保存完成" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action111 = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                //保存背景
                self.header.dataWrite = @"bf 00";
                self.header.tagWrite = 1001;
                [self.header writeBoardWithTag:1001];
                NSLog(@"writeBoard with tag ---%d",1001);
                //self.header.dataWrite = @"";
            }];
            [alertEnd addAction:action111];
            [self presentViewController:alertEnd animated:YES completion:^{
            }];
        }];
        [alertStudy addAction:action11];
        [self presentViewController:alertStudy animated:YES completion:^{
        }];
    }];
    UIAlertAction *action2= [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.player stop];
    }];
    [alertBegin addAction:action1];
    [alertBegin addAction:action2];
    [self presentViewController:alertBegin animated:YES completion:^{
    }];
}

//栅栏杆学习
-(void) brakeStudy:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    [self sound4];
    UIAlertController *alertBegin = [UIAlertController alertControllerWithTitle:@"栅栏杆学习" message:@"确保雷达十米内无行人或车辆\n确定后开始学习！" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"开始" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.player stop];
        
        [self sound2];
        if([self.header.socket isConnected]){
            self.header.dataWrite = @"aa 03";
            self.header.tagWrite = 1303;
            [self.header writeBoardWithTag:1303];
            NSLog(@"writeBoard with tag ---%d",1303);
            
            // viewNoise  *tvBrake = (viewNoise *)[self.view viewWithTag:1336];
            // [tvBrake setTextColor:[UIColor redColor]];
        }
        //-----------
        UIAlertController *alertStudy = [UIAlertController alertControllerWithTitle:@"栅栏杆学习" message:@"正在学习,确保无行人或车辆通过\n请遥控升降道闸杆三次，完成后即可停止学习！" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action11 = [UIAlertAction actionWithTitle:@"停止" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            if([self.header.socket isConnected]){
                self.header.dataWrite = @"aa 00";
                self.header.tagWrite = 1307;
                [self.header writeBoardWithTag:1307];
                NSLog(@"writeBoard with tag ---%d",1307);
            }
            [self sound3];
            UIAlertController *alertEnd = [UIAlertController alertControllerWithTitle:@"栅栏杆学习" message:@"学习结果保存完毕" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action111 = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                //保存背景
                self.header.dataWrite = @"bf 00";
                self.header.tagWrite = 1001;
                [self.header writeBoardWithTag:1001];
                NSLog(@"writeBoard with tag ---%d",1001);
                //self.header.dataWrite = @"";
            }];
            [alertEnd addAction:action111];
            [self presentViewController:alertEnd animated:YES completion:^{
            }];
        }];
        [alertStudy addAction:action11];
        [self presentViewController:alertStudy animated:YES completion:^{
        }];
    }];
    UIAlertAction *action2= [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.player stop];
    }];
    [alertBegin addAction:action1];
    [alertBegin addAction:action2];
    [self presentViewController:alertBegin animated:YES completion:^{
    }];
}

//直杆学习学习
-(void) straightStudy:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    [self sound4];
    UIAlertController *alertBegin = [UIAlertController alertControllerWithTitle:@"直杆学习" message:@"确保雷达十米内无行人或车辆\n确定后开始学习！" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"开始" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.player stop];
        
        [self sound2];
        if([self.header.socket isConnected]){
            self.header.dataWrite = @"aa 02";
            self.header.tagWrite = 1302;
            [self.header writeBoardWithTag:1302];
            NSLog(@"writeBoard with tag ---%d",1302);
            
            //viewNoise  *tvStraight = (viewNoise *)[self.view viewWithTag:1334];
            // [tvStraight setTextColor:[UIColor redColor]];
        }
        //-----------
        UIAlertController *alertStudy = [UIAlertController alertControllerWithTitle:@"直杆学习" message:@"正在学习，确保无行人或车辆通过!\n请遥控升降道闸杆3次，完成后即可停止学习" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action11 = [UIAlertAction actionWithTitle:@"停止" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            if([self.header.socket isConnected]){
                self.header.dataWrite = @"aa 00";
                self.header.tagWrite = 1307;
                [self.header writeBoardWithTag:1307];
                NSLog(@"writeBoard with tag ---%d",1307);
            }
            [self sound3];
            UIAlertController *alertEnd = [UIAlertController alertControllerWithTitle:@"直杆学习" message:@"学习结束，参数保存完成" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action111 = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                //保存背景
                self.header.dataWrite = @"bf 00";
                self.header.tagWrite = 1001;
                [self.header writeBoardWithTag:1001];
                NSLog(@"writeBoard with tag ---%d",1001);
                //self.header.dataWrite = @"";
            }];
            [alertEnd addAction:action111];
            [self presentViewController:alertEnd animated:YES completion:^{
            }];
        }];
        [alertStudy addAction:action11];
        [self presentViewController:alertStudy animated:YES completion:^{
        }];
    }];
    UIAlertAction *action2= [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self.player stop];
    }];
    [alertBegin addAction:action1];
    [alertBegin addAction:action2];
    [self presentViewController:alertBegin animated:YES completion:^{
    }];
}

-(void)sound1{
    NSURL *url =  [[NSBundle mainBundle] URLForResource:@"daozha" withExtension:@"wav"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    //self.player.delegate = self;
    [self.player prepareToPlay];
    [self.player play];
    
}

-(void)sound2{
    NSURL *url =  [[NSBundle mainBundle] URLForResource:@"zhengzai" withExtension:@"wav"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    //self.player.delegate = self;
    [self.player prepareToPlay];
    [self.player play];
    
}

-(void)sound3{
    NSURL *url =  [[NSBundle mainBundle] URLForResource:@"wanbi" withExtension:@"wav"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    //self.player.delegate = self;
    [self.player prepareToPlay];
    [self.player play];
}

-(void)sound4{
    NSURL *url =  [[NSBundle mainBundle] URLForResource:@"shengjiang" withExtension:@"wav"];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    //self.player.delegate = self;
    [self.player prepareToPlay];
    [self.player play];
}


//学习查询
-(void)studyQuery:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }
    // [self addNoiseLayout];
    if([self.header.socket isConnected]){
        [self.header.longData  setString:@""];
        self.header.dataWrite = @"c0 02";
        self.header.tagWrite = 1304;
        [self.header writeBoardWithTag:1304];
        NSLog(@"writeBoard with tag ---%d",1304);
        
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeIndeterminate;
        self.HUD.label.text= @"正在获取背景噪声";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        
    }
    //self.header.dataWrite = @"";
}
#pragma mark 根据tag读取数据
- (void) OnDidReadDataWithTag:(long)Tag{
    if(Tag != self.header.tagWrite) {
        [self.header.socket readDataWithTimeout:-1 tag:self.header.tagWrite];
    }
    
    self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.HUD.mode = MBProgressHUDModeText;
    self.HUD.label.textColor = [UIColor blueColor];
    self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
    
    
    NSArray *strs = [self.header.dataRead componentsSeparatedByString:@":"];
    NSArray *strsReset = [self.header.dataRead componentsSeparatedByString:@"\r\n"];
    
    UILabel *labelGuJian = (UILabel *)[self.view viewWithTag:1100];  //固件查询
    UILabel *labelZhenji = (UILabel *)[self.view viewWithTag:1101];  //整机查询
    UILabel *labelDanji = (UILabel *)[self.view viewWithTag:1102];   //单机查询
    UISwitch *switchRenche = (UISwitch *)[self.view viewWithTag:1202]; //人车模式开关
    UILabel  *labelDiff = (UILabel *)[self.view viewWithTag:1203];  //人车区分
    UILabel  *labelWidth = (UILabel *)[self.view viewWithTag:1213];    //横向宽度
    UILabel  *labelDistance = (UILabel *)[self.view viewWithTag:1223];  //纵向距离
    UILabel  *labelDownTime = (UILabel *)[self.view viewWithTag:1233]; //落杆时间
    UILabel  *labelUpTime = (UILabel *)[self.view viewWithTag:1243];   //升杆时间
    UILabel  *labelShoot = (UILabel *)[self.view viewWithTag:1253];    //对射频表
    UISwitch *switchType = (UISwitch *)[self.view viewWithTag:1262];
    UILabel  *labelPoleType = (UILabel *)[self.view viewWithTag:1263];  //栏杆类型
    UISwitch *switchDirection = (UISwitch *)[self.view viewWithTag:1272];
    UILabel  *labelDirection = (UILabel *)[self.view viewWithTag:1273];  //偏移方向
    UILabel  *labelShift = (UILabel *)[self.view viewWithTag:1282];//偏移量
    
    UILabel  *labelDiviation = (UILabel *)[self.view viewWithTag:1271];  //"中心偏移"
    UILabel  *labelPianyi = (UILabel *)[self.view viewWithTag:1285];     //"偏移量"
    UIButton *btConfirmShift =(UIButton *)[self.view viewWithTag:1274];
    
    
    viewNoise  *tvEnviron = (viewNoise *)[self.view viewWithTag:1332];//
    viewNoise  *tvBrake = (viewNoise *)[self.view viewWithTag:1336];//
    viewNoise  *tvStraight = (viewNoise *)[self.view viewWithTag:1334];//
    
    NSString *strHUD = [[NSString alloc]init];
    
    switch (Tag) {
        case 1001:
            NSLog(@"%@",self.header.dataRead);
            strHUD = @"更新用户数据成功";
            BOOL success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"更新用户数据",[NSNull null]];
            if(success){
                NSLog(@"------插入数据成功-------");
            }
            break;
        case 1100:
            if([strs count]>0){
                labelGuJian.text = strs[1];
            }
            strHUD = @"固件版本获取成功！";
            success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"更新固件版本",[NSNull null]];
            if(success){
                NSLog(@"------插入数据成功-------");
            }
            break;
        case 1103:
            if([strs count]>3){
                labelZhenji.text = [strs[1] substringToIndex:13];
            }
            strHUD = @"整机SN获取成功！";
            success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"获取整机sn",[NSNull null]];
            if(success){
                NSLog(@"------插入数据成功-------");
            }
            break;
        case 1104:
            if([strs count]>3){
                labelDanji.text = strs[1];
            }
            strHUD = @"单机SN获取成功！";
            success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"获取单机sn",[NSNull null]];
            if(success){
                NSLog(@"------插入数据成功-------");
            }
            break;
        case 1210:
            [labelDiff setTextColor:[UIColor blackColor]];
            [labelWidth setTextColor:[UIColor blackColor]];
            strHUD = [NSString stringWithFormat:@"人车%@,横向宽度%@米设置成功！",labelDiff.text,labelWidth.text];
            success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"设置横向宽度",labelWidth.text];
            if(success){
                NSLog(@"------插入数据成功-------");
            }
            break;
        case 1220:
            [labelDistance setTextColor:[UIColor blackColor]];
            strHUD = [NSString stringWithFormat:@"纵向距离%@米设置成功！",labelDistance.text];
            success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"设置纵向距离",labelDistance.text];
            if(success){
                NSLog(@"------插入数据成功-------");
            }
            break;
        case 1230:
            [labelDownTime setTextColor:[UIColor blackColor]];
            strHUD = [NSString stringWithFormat:@"落杆保护时间%@秒设置成功！",labelDownTime.text];
            success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"设置落杆保护时间",labelDownTime.text];
            if(success){
                NSLog(@"------插入数据成功-------");
            }
            break;
        case 1240:
            [labelUpTime setTextColor:[UIColor blackColor]];
            strHUD = [NSString stringWithFormat:@"升杆时间%@秒设置成功！",labelUpTime.text];
            success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"设置升杆时间间",labelUpTime.text];
            if(success){
                NSLog(@"------插入数据成功-------");
            }
            break;
        case 1250:
            [labelShoot setTextColor:[UIColor blackColor]];
            strHUD = [NSString stringWithFormat:@"对射模式%@设置成功",labelShoot.text];
            success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"设置对射模式",labelShoot.text];
            if(success){
                NSLog(@"------插入数据成功-------");
            }
            break;
        case 1260:
            [labelPoleType setTextColor:[UIColor blackColor]];
            strHUD = @"栏杆类型设置成功！";
            success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"设置栏杆类型",[NSNull null]];
            if(success){
                NSLog(@"------插入数据成功-------");
            }
            break;
        case 1270:
            [labelDirection setTextColor:[UIColor blackColor]];
            [labelShift setTextColor:[UIColor blackColor]];
            if(self.hasShiftValue){
                strHUD = [NSString stringWithFormat:@"雷达中心%@设置成功",labelDirection.text];
            }else{
                strHUD = [NSString stringWithFormat:@"雷达中心%@设置成功",labelDirection.text];
            }
            success = [self.db executeUpdate:@"INSERT INTO t_daily (device,user,actionTime,actionDescription,actionValue) VALUES(?,?,datetime(),?,?)",self.header.BSSID,self.header.user,@"设置雷达中心",labelDirection.text];
            if(success){
                NSLog(@"------插入数据成功-------");
            }
            break;
        case 1298:
            strHUD = @"设备重置成功！";
            [labelDiff setTextColor:[UIColor redColor]];
            [labelWidth setTextColor:[UIColor redColor]];
            [labelDistance setTextColor:[UIColor redColor]];
            [labelDownTime setTextColor:[UIColor redColor]];
            [labelUpTime setTextColor:[UIColor redColor]];
            [labelShoot setTextColor:[UIColor redColor]];
            [labelPoleType setTextColor:[UIColor redColor]];
            [labelDirection setTextColor:[UIColor redColor]];
            [labelShift setTextColor:[UIColor redColor]];
            break;
        case 1299:
            strHUD = @"参数刷新成功";
            if ([strsReset count]<9) {
                break;
            }else if([strsReset count]==9){
                NSLog(@"这是少参数版本");
                if([[strsReset[0] substringToIndex:7] isEqualToString:@"AllMode"]){
                    labelDiff.text = @"不区分";
                    [switchRenche setOn:NO];
                }else if([[strsReset[0] substringToIndex:7] isEqualToString:@"CarMode"]){
                    labelDiff.text = @"区分";
                    [switchRenche setOn:YES];
                }
                
                [labelDiff setTextColor:[UIColor blackColor]];
                NSString *width = [strsReset[0] substringFromIndex:7];
                if([width isEqualToString:@"1m"]){
                    labelWidth.text = @"1.0";
                }else  if([width isEqualToString:@"0.8m"]){
                    labelWidth.text = @"0.8";
                }else  if([width isEqualToString:@"0.6m"]){
                    labelWidth.text = @"0.6";
                }else  if([width isEqualToString:@"0.4m"]){
                    labelWidth.text = @"0.4";
                }
                [labelWidth setTextColor:[UIColor blackColor]];
                
                labelShoot.text = [strsReset[1] substringFromIndex:9];
                [labelShoot setTextColor:[UIColor blackColor]];
                
                if([strsReset[2] isEqualToString:@"StraightBar"]){
                    labelPoleType.text = @"直杆";
                    [switchType setOn:NO];
                    [labelPoleType setTextColor:[UIColor blackColor]];
                }else if([strsReset[2] isEqualToString:@"BrakeBar"]){
                    labelPoleType.text = @"栅栏杆";
                    [switchType setOn:YES];
                    [labelPoleType setTextColor:[UIColor blackColor]];
                }
                
                if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"0"]){
                    labelDownTime.text = @"0.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"1"]){
                    labelDownTime.text = @"1.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"2"]){
                    labelDownTime.text = @"2.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"3"]){
                    labelDownTime.text = @"3.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"4"]){
                    labelDownTime.text = @"4.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"5"]){
                    labelDownTime.text = @"5.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"6"]){
                    labelDownTime.text = @"6.0";
                }
                [labelDownTime setTextColor:[UIColor blackColor]];
                
                if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"0"]){
                    labelUpTime.text = @"0.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"1"]){
                    labelUpTime.text = @"1.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"2"]){
                    labelUpTime.text = @"2.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"3"]){
                    labelUpTime.text = @"3.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"4"]){
                    labelUpTime.text = @"4.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"5"]){
                    labelUpTime.text = @"5.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"6"]){
                    labelUpTime.text = @"6.0";
                }
                [labelUpTime setTextColor:[UIColor blackColor]];
                
                labelDistance.text = [strsReset[4] substringWithRange:NSMakeRange(6, 3)];
                [labelDistance setTextColor:[UIColor blackColor]];
                
                if([strsReset[5]  isEqualToString:@"BarLeft"]){
                    labelDirection.text = @"左偏";
                    [switchDirection setOn:NO];
                    if([strsReset[5] length] == 13){     //有偏移量
                        self.hasShiftValue = YES;
                        NSString *strShift = [strsReset[5] substringWithRange:NSMakeRange(8,3)];
                        labelShift.text = strShift;
                    }else{
                        self.hasShiftValue = NO;
                        UIButton *btSubShift = (UIButton *)[self.view viewWithTag:1281];
                        UIButton *btAddShift = (UIButton *)[self.view viewWithTag:1283];
                        [btSubShift setEnabled:NO];
                        [btAddShift setEnabled:NO];
                        [labelDirection setTextColor:[UIColor grayColor]];
                        
                        labelShift.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
                        labelDirection.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
                        labelDiviation.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
                        labelPianyi.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
                        
                        [btSubShift setBackgroundColor: [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2]];
                        [btAddShift setBackgroundColor: [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2]];
                        [btConfirmShift setBackgroundColor: [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2]];
                    }
                }else{
                    labelDirection.text = @"右偏";
                    [switchDirection setOn:YES];
                    if([strsReset[5] length] == 14){
                        self.hasShiftValue = YES;
                        NSString *strShift = [strsReset[5] substringWithRange:NSMakeRange(9,3)];
                        labelShift.text = strShift;
                    }else{
                        self.hasShiftValue = NO;
                        UIButton *btSubShift = (UIButton *)[self.view viewWithTag:1281];
                        UIButton *btAddShift = (UIButton *)[self.view viewWithTag:1283];
                        [btSubShift setEnabled:NO];
                        [btAddShift setEnabled:NO];
                        [labelDirection setTextColor:[UIColor grayColor]];
                        
                        labelShift.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
                        labelDirection.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
                        labelDiviation.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
                        labelPianyi.textColor = [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2];
                        
                        [btSubShift setBackgroundColor: [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2]];
                        [btAddShift setBackgroundColor: [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2]];
                        [btConfirmShift setBackgroundColor: [UIColor colorWithRed:192/255 green:192/255 blue:192/255 alpha:0.2]];
                    }
                }
                // [labelDirection setTextColor:[UIColor blackColor]];
                //[labelShift setTextColor:[UIColor blackColor]];
                
                UISwitch *swithShift = (UISwitch *)[self.view  viewWithTag:1272];
                UIButton *btConfirmShift = (UIButton *)[self.view viewWithTag:1274];
                [swithShift setEnabled:NO];
                [btConfirmShift setEnabled:NO];
                
                labelZhenji.text = [strsReset[6] substringFromIndex:4];
                labelDanji.text = [strsReset[7] substringFromIndex:4];
            }
            //  NSAssert([strsReset count]>=10, @"刷新收到的字段数量不够");
            if([strsReset count]>9){
                NSLog(@"这是多参数版本");
                if([[strsReset[0] substringToIndex:7] isEqualToString:@"AllMode"]){
                    labelDiff.text = @"不区分";
                    [switchRenche setOn:NO];
                }else if([[strsReset[0] substringToIndex:7] isEqualToString:@"CarMode"]){
                    labelDiff.text = @"区分";
                    [switchRenche setOn:YES];
                }
                
                [labelDiff setTextColor:[UIColor blackColor]];
                NSString *width = [strsReset[0] substringFromIndex:7];
                if([width isEqualToString:@"1m"]){
                    labelWidth.text = @"1.0";
                }else  if([width isEqualToString:@"0.8m"]){
                    labelWidth.text = @"0.8";
                }else  if([width isEqualToString:@"0.6m"]){
                    labelWidth.text = @"0.6";
                }else  if([width isEqualToString:@"0.4m"]){
                    labelWidth.text = @"0.4";
                }
                [labelWidth setTextColor:[UIColor blackColor]];
                
                labelShoot.text = [strsReset[1] substringFromIndex:9];
                [labelShoot setTextColor:[UIColor blackColor]];
                
                if([strsReset[2] isEqualToString:@"StraightBar"]){
                    labelPoleType.text = @"直杆";
                    [switchType setOn:NO];
                    [labelPoleType setTextColor:[UIColor blackColor]];
                }else if([strsReset[2] isEqualToString:@"BrakeBar"]){
                    labelPoleType.text = @"栅栏杆";
                    [switchType setOn:YES];
                    [labelPoleType setTextColor:[UIColor blackColor]];
                }
                
                if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"0"]){
                    labelDownTime.text = @"0.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"1"]){
                    labelDownTime.text = @"1.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"2"]){
                    labelDownTime.text = @"2.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"3"]){
                    labelDownTime.text = @"3.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"4"]){
                    labelDownTime.text = @"4.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"5"]){
                    labelDownTime.text = @"5.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(12, 1)] isEqualToString:@"6"]){
                    labelDownTime.text = @"6.0";
                }
                [labelDownTime setTextColor:[UIColor blackColor]];
                
                if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"0"]){
                    labelUpTime.text = @"0.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"1"]){
                    labelUpTime.text = @"1.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"2"]){
                    labelUpTime.text = @"2.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"3"]){
                    labelUpTime.text = @"3.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"4"]){
                    labelUpTime.text = @"4.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"5"]){
                    labelUpTime.text = @"5.0";
                }else if([[strsReset[3] substringWithRange:NSMakeRange(26, 1)] isEqualToString:@"6"]){
                    labelUpTime.text = @"6.0";
                }
                [labelUpTime setTextColor:[UIColor blackColor]];
                
                labelDistance.text = [strsReset[4] substringWithRange:NSMakeRange(6, 3)];
                [labelDistance setTextColor:[UIColor blackColor]];
                
                if([[strsReset[5] substringWithRange:NSMakeRange(3, 4)] isEqualToString:@"Left"]){
                    labelDirection.text = @"左偏";
                    [switchDirection setOn:NO];
                    NSString *strShift = [strsReset[5] substringWithRange:NSMakeRange(8,3)];
                    labelShift.text = strShift;
                }else{
                    labelDirection.text = @"右偏";
                    [switchDirection setOn:YES];
                    NSString *strShift = [strsReset[5] substringWithRange:NSMakeRange(9,3)];
                    labelShift.text = strShift;
                }
                [labelDirection setTextColor:[UIColor blackColor]];
                [labelShift setTextColor:[UIColor blackColor]];
                
                labelZhenji.text = [strsReset[8] substringFromIndex:4];
                labelDanji.text = [strsReset[9] substringFromIndex:4];
            }
            break;
        case 1301:
            tvEnviron.colorNumber = 0;
            [tvEnviron setNeedsDisplay];
            break;
        case 1302:
            tvStraight.colorNumber = 0;
            [tvStraight setNeedsDisplay];
            break;
        case 1303:
            tvBrake.colorNumber = 0;
            [tvBrake setNeedsDisplay];
            break;
        case 1304:
            strHUD = @"获取背景噪声成功";
            self.HUD.mode = MBProgressHUDModeText;
            self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
            self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
            NSArray  *strs = [self.header.longData componentsSeparatedByString:@","];
            if([strs count]  >= 3*128){
                
                NSArray *arrayNoise = [self.header.longData componentsSeparatedByString:@":"];
                if([arrayNoise count]>=4){
                    NSString *strInter = arrayNoise[1];
                    NSString *strExter = arrayNoise[2];
                    NSString *strUpDown= arrayNoise[3];
                    //环境噪声
                    NSArray *arrInter = [strInter componentsSeparatedByString:@","];
                    NSMutableArray *arrEnviron = [[NSMutableArray alloc] init];
                    for(int i=0;i<128; i++){
                        if(i%16==0){
                            [arrEnviron addObject:[arrInter[i] substringFromIndex:2]];
                        }else{
                            [arrEnviron addObject:arrInter[i]];
                        }
                    }
                    tvEnviron.dataStr = arrEnviron;
                    tvEnviron.colorNumber = 1;
                    [tvEnviron setNeedsDisplay];
                    //直杆噪声
                    NSArray *arrExter = [strExter componentsSeparatedByString:@","];
                    NSMutableArray *arrStraight = [[NSMutableArray alloc] init];
                    for(int i=0;i<128; i++){
                        if(i%16==0){
                            [arrStraight addObject:[arrExter[i] substringFromIndex:2]];
                        }else{
                            [arrStraight addObject:arrExter[i]];
                        }
                    }
                    tvStraight.dataStr = arrStraight;
                    tvStraight.colorNumber = 1;
                    [tvStraight setNeedsDisplay];
                    //栅栏杆噪声
                    NSArray *arrUpDown = [strUpDown componentsSeparatedByString:@","];
                    NSMutableArray *arrUpdown = [[NSMutableArray alloc] init];
                    for(int i=0;i<128; i++){
                        if(i%16==0){
                            [arrUpdown addObject:[arrUpDown[i] substringFromIndex:2]];
                        }else{
                            [arrUpdown addObject:arrUpDown[i]];
                        }
                    }
                    tvBrake.dataStr = arrUpdown;
                    tvBrake.colorNumber = 1;
                    [tvBrake setNeedsDisplay];
                    
                    //tvBrake.text = updown;
                    // tvBrake.textColor = [UIColor blackColor];
                    
                    [self.view updateLayout];
                }
            }
            break;
    }
    if(Tag != 1001){
        self.header.dataWrite = @"bf 00";
        self.header.tagWrite = 1001;
        [self.header writeBoardWithTag:1001];
        NSLog(@"writeBoard with tag ---%d",1001);
    }
    
    if((Tag==1301|Tag==1302|Tag==1303)){
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:0];
    }else{
        self.HUD.label.text= strHUD;
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
    }
    self.header.dataWrite = @"";
}



/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
-(void) viewWillAppear:(BOOL)animated{
    /*
     if([self.header.socket isConnected]){
     
     self.header.dataWrite = @"a9 00";
     self.header.tagWrite = 8100;
     [self.header writeBoardWithTag:8100];
     }*/
    // self.header.dataWrite = @"";
    [self openDB];
}

-(void)viewDidAppear:(BOOL)animated{
    self.header.delegate = self;
    //刷新控件
    //[self resetContolls];
    
    self.header.dataWrite = @"a9 00";
    self.header.tagWrite = 8100;
    [self.header writeBoardWithTag:8100];
    NSLog(@"write board with tag 8100");
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer * _Nonnull timer) {
        self.header.dataWrite = @"a9 00";
        self.header.tagWrite = 8100;
        [self.header writeBoardWithTag:8100];
        NSLog(@"write board with tag 8100");
        self.stopScanTimes++;
        if(self.stopScanTimes >10){
            [self.timer invalidate];
            self.timer = nil;
            self.stopScanTimes = 0;
        }
    }];
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [self.timer invalidate];
    self.timer = nil;
    
    //self.header.delegate = nil;
    //更新用户数据
    self.header.dataWrite = @"bf 00";
    self.header.tagWrite = 1001;
    [self.header writeBoardWithTag:1001];
    NSLog(@"writeBoard with tag ---%d",1001);
    // self.header.dataWrite = @"";
    self.header.delegate = nil;
    //关闭数据
    [self.db  close];
}
-(void)dealloc{
    [self.timer invalidate];
    self.timer = nil;
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

@end
