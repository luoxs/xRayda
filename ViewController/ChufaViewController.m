//
//  ChufaViewController.m
//  xRayda
//
//  Created by apple on 2022/1/17.
//  Copyright © 2022 apple.gupt.www. All rights reserved.
//


#import "ChufaViewController.h"
#import "FMDatabase.h"
#import "Socket.h"
#import "UIView+SDAutoLayout.h"
#import "SDAutoLayout.h"
#import "MBProgressHUD.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "viewNoise.h"
#import "viewNoiseGate.h"
#import "viewNoiseDot.h"

@interface ChufaViewController()<SocketDelegate>
@property (strong,nonatomic) Socket *header;
@property (retain,nonatomic) MBProgressHUD *HUD;
@property (retain,nonatomic) UIScrollView *scrollView;
@property (strong,nonatomic) UIView *view1;
@property (strong,nonatomic) UIView *view2;
@property (strong,nonatomic) UIView *view3;
@property (weak,nonatomic) NSTimer* timer;
@property NSInteger stopScanTimes;
@property (strong,nonatomic) AVAudioPlayer *player;
@property (nonatomic, strong) FMDatabase *db;  //数据库
@end

@implementation ChufaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.header = [Socket sharedInstance];
    //self.HUD = [[MBProgressHUD alloc]init];
    //[self.HUD setMode:MBProgressHUDModeText];
    
    self.header.delegate = self;
    //设置布局
    [self setAutoLayout];
    //启动查询
    self.header.longData = [[NSMutableString alloc]init];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.stopScanTimes = 0;
    [self resetContolls];
}

-(void) resetContolls{
    
    UILabel *labelGuJian = (UILabel *)[self.view viewWithTag:1100];  //固件查询
    UILabel *labelZhenji = (UILabel *)[self.view viewWithTag:1101];  //整机查询
    UILabel *labelDanji = (UILabel *)[self.view viewWithTag:1102];   //单机查询
    UISwitch *switchMode = (UISwitch *)[self.view viewWithTag:1205]; //工作模式开关
    UILabel  *labelMode = (UILabel *)[self.view viewWithTag:1206];  //工作模式指示
    UISwitch *switchRenche = (UISwitch *)[self.view viewWithTag:1202]; //人车区分开关
    UILabel  *labelDiff = (UILabel *)[self.view viewWithTag:1203];  //人车区分
    UIButton *btConfirmDiff = (UIButton *)[self.view viewWithTag:1204];//确认区分人车
    UILabel  *labelDistance = (UILabel *)[self.view viewWithTag:1223];  //纵向距离
    UILabel  *labelShoot = (UILabel *)[self.view viewWithTag:1253];    //对射频表
    UISwitch *switchDirection = (UISwitch *)[self.view viewWithTag:1272];
    UILabel  *labelDirection = (UILabel *)[self.view viewWithTag:1273];  //偏移方向
    
    //strHUD = @"参数刷新成功";
   // NSAssert([strsReset count]>=12, @"刷新收到的字段数量不够");
    if(self.header.strsVersion){
        labelGuJian.text = self.header.strsVersion;
    }
    
    if([self.header.strsReset count]>=12){
        if([[self.header.strsReset[0] substringFromIndex:8] isEqualToString:@"veh pd"]){
            labelMode.text = @"人、车";
            [switchMode setOn:NO];
            [switchRenche setEnabled:YES];
            [labelDiff setEnabled:YES];
            [btConfirmDiff setEnabled:YES];
        }else if([[self.header.strsReset[0] substringFromIndex:8] isEqualToString:@"veh motor pd"]){
            labelMode.text = @"人、车、\n非机动车";
            [switchMode setOn:YES];
            [switchRenche setEnabled:NO];
            [labelDiff setEnabled:NO];
            [btConfirmDiff setEnabled:NO];
        }
        [labelMode setTextColor:[UIColor blackColor]];
        
        if([self.header.strsReset[1] isEqual:@"VehandPd Distinguished"]){
            labelDiff.text = @"区分";
            [switchRenche setOn:YES];
        }else{
            labelDiff.text = @"不区分";
            [switchRenche setOn:NO];
        }
        [labelDiff setTextColor:[UIColor blackColor]];
        
        labelShoot.text = [self.header.strsReset[2] substringFromIndex:9];
        [labelShoot setTextColor:[UIColor blackColor]];
        
        labelDistance.text = [self.header.strsReset[5] substringWithRange:NSMakeRange(9, 3)];
        [labelDistance setTextColor:[UIColor blackColor]];
        
        if([self.header.strsReset[7] isEqual:@"BarLeft"]){
            labelDirection.text = @"雷达左侧";
            [switchDirection setOn:NO];
        }else{
            labelDirection.text = @"雷达右侧";
            [switchDirection setOn:YES];
        }
        [labelDirection setTextColor:[UIColor blackColor]];
        
        labelZhenji.text = [self.header.strsReset[8] substringFromIndex:4];
        labelDanji.text = [self.header.strsReset[9] substringFromIndex:4];
    }
    [self.view setNeedsDisplay];
}


//#pragma mark - 连接成功
-(void)onConnected{
    //[SVProgressHUD dismiss];
    NSLog(@"已连接----");
    [self.view setNeedsDisplay];
}
//#pragma mark - 连接失败
-(void)onConnectFailed{
    //self.header.socket.userData = [NSNumber numberWithInt:SocketOfflineByServer];
    //[self.header socketConnectHost];
    
    NSLog(@"网络断开了----");
    
    if(self.header.tagWrite == 1309){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text = @"共读取到0个值";
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];

        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
        self.header.socket.userData = [NSNumber numberWithInt:2];
    }
    /*
    if(self.header.tagWrite == 1299){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text = @"没有返回值，请重新刷新";
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
    }*/
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
    labelLeidaData.font = [UIFont systemFontOfSize:24];
    [labelLeidaData setTextColor:[UIColor  blackColor]];
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
    .heightIs(480);
    
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
    
#pragma mark - 工作模式
    UILabel *labelMoshi = [[UILabel alloc]init];
    [_view2 addSubview:labelMoshi];
    labelMoshi.sd_layout
    .topSpaceToView(labelCanshu, 8)
    .heightIs(40)
    .widthRatioToView(_view2, 0.2)
    .leftSpaceToView(_view2, 10);
    [labelMoshi setSingleLineAutoResizeWithMaxWidth:100];
    labelMoshi.font = [UIFont systemFontOfSize:20];
    [labelMoshi setTextColor:[UIColor  blackColor]];

    labelMoshi.text = @"工作模式";
    
    UISwitch *switchMode = [[UISwitch alloc] init];
    [_view2 addSubview:switchMode];
    switchMode.sd_layout
    .centerYEqualToView(labelMoshi)
    .heightIs(40)
    .widthRatioToView(_view2, 0.2)
    .leftSpaceToView(labelMoshi, 8);
    [switchMode setTag:1205];
    [switchMode addTarget:self action:@selector(setWorkMode:) forControlEvents:UIControlEventTouchUpInside];
    
    //模式
    UILabel *labelMode = [[UILabel alloc] init];
    [_view2 addSubview:labelMode];
    labelMode.sd_layout
    .centerYEqualToView(labelMoshi)
    .heightIs(60)
    .widthRatioToView(_view2, 0.3)
    .leftSpaceToView(switchMode, 12);
   // [labelMode setSingleLineAutoResizeWithMaxWidth:90];
    [labelMode setNumberOfLines:2];
    //[labelMode setLineBreakMode:NSLineBreakByTruncatingTail];
    //[labelMode setLineBreakMode:NSLineBreakByWordWrapping];
    labelMode.text = @"人、车";
    labelMode.font = [UIFont systemFontOfSize:18];
    //[labelMode sizeToFit];
    [labelMode setTextColor:[UIColor redColor]];
    [labelMode setTag:1206];
    
    UIButton *btConfirmMode = [[UIButton alloc]init];
    [_view2 addSubview:btConfirmMode];
    [btConfirmMode.layer setCornerRadius:8.0];
    [btConfirmMode setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btConfirmMode.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btConfirmMode.sd_layout
    .centerYEqualToView(labelMoshi)
    .heightIs(40)
    .widthRatioToView(_view2, 0.25)
    .rightSpaceToView(_view2, 10);
    [btConfirmMode setTitle:@"确定" forState:UIControlStateNormal];
    [btConfirmMode addTarget:self action:@selector(confirmMode:) forControlEvents:UIControlEventTouchUpInside];
    
#pragma mark - 区分人车
    UILabel *labelQufenrenche = [[UILabel alloc]init];
    [_view2 addSubview:labelQufenrenche];
    labelQufenrenche.sd_layout
    .topSpaceToView(labelMode, 8)
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
    [switchRenche addTarget:self action:@selector(distinguish:) forControlEvents:UIControlEventTouchUpInside];
    
    //区分人车
    UILabel *labelDiff = [[UILabel alloc] init];
    [_view2 addSubview:labelDiff];
    labelDiff.sd_layout
    .centerYEqualToView(labelQufenrenche)
    .heightIs(40)
    .widthRatioToView(_view2, 0.2)
    .leftSpaceToView(switchRenche, 13);
    [labelDiff setSingleLineAutoResizeWithMaxWidth:100];
    labelDiff.text = @"区分";
    labelDiff.font = [UIFont systemFontOfSize:18];
    [labelDiff setTextColor:[UIColor redColor]];
    [labelDiff setTag:1203];
    
    UIButton *btConfirmDiff = [[UIButton alloc]init];
    [_view2 addSubview:btConfirmDiff];
    [btConfirmDiff.layer setCornerRadius:8.0];
    [btConfirmDiff setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btConfirmDiff.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btConfirmDiff.sd_layout
    .centerYEqualToView(labelDiff)
    .heightIs(40)
    .widthRatioToView(_view2, 0.25)
    .rightSpaceToView(_view2, 10);
    [btConfirmDiff setTitle:@"确定" forState:UIControlStateNormal];
    [btConfirmDiff setTag:1204];
    [btConfirmDiff addTarget:self action:@selector(confirmDiff:) forControlEvents:UIControlEventTouchUpInside];
    
#pragma mark - 纵向距离
    UILabel *labelZongxiang = [[UILabel alloc]init];
    [_view2 addSubview:labelZongxiang];
    labelZongxiang.sd_layout
    .topSpaceToView(labelQufenrenche, 12)
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
    //.centerXEqualToView(_view2);
    .leftSpaceToView(btSubDistance, 6);
    [labelDistance setSingleLineAutoResizeWithMaxWidth:50];
    labelDistance.text = @"3.0";
    labelDistance.font = [UIFont systemFontOfSize:18];
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
    [btConfirmDistance addTarget:self action:@selector(confirmDistance:) forControlEvents:UIControlEventTouchUpInside];
    
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
    
#pragma mark - 对射设置
    UILabel *labelDuishe = [[UILabel alloc]init];
    [_view2 addSubview:labelDuishe];
    labelDuishe.sd_layout
    .topSpaceToView(labelZongxiang, 12)
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
    . centerYEqualToView(labelDuishe)
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
    
#pragma mark - 栏杆方位
    UILabel *labelDiviation = [[UILabel alloc]init];
    [_view2 addSubview:labelDiviation];
    labelDiviation.sd_layout
    .topSpaceToView(labelDuishe, 12)
    .heightIs(40)
    .widthRatioToView(_view2, 0.2)
    .leftSpaceToView(_view2, 10);
    [labelDiviation setSingleLineAutoResizeWithMaxWidth:100];
    labelDiviation.font = [UIFont systemFontOfSize:20];
    [labelDiviation setTextColor:[UIColor  blackColor]];

    labelDiviation.text = @"栏杆方位";
    
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
    .leftSpaceToView(switchDirection, 12);
    [labelDirection setSingleLineAutoResizeWithMaxWidth:100];
    [labelDirection setTextColor:[UIColor redColor]];
    labelDirection.text = @"雷达左侧";
    labelDirection.font = [UIFont systemFontOfSize:18];
    [labelDirection setTag:1273];
    
    
    UIButton *btComfirmShift = [[UIButton alloc]init];
    [_view2 addSubview:btComfirmShift];
    [btComfirmShift.layer setCornerRadius:8.0];
    [btComfirmShift setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btComfirmShift.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    btComfirmShift.sd_layout
    .centerYEqualToView(labelDiviation)
    .heightIs(40)
    .widthRatioToView(_view2, 0.25)
    .rightSpaceToView(_view2, 10);
    [btComfirmShift setTitle:@"确定" forState:UIControlStateNormal];
    [btComfirmShift addTarget:self action:@selector(confirmShift) forControlEvents:UIControlEventTouchUpInside];
    
    
#pragma mark - 重置和刷新
    //重置按钮
    UIButton *btReset = [[UIButton alloc]init];
    [_view2 addSubview:btReset];
    [btReset setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btReset.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.5 alpha:1.0];
    [btReset.layer setCornerRadius:8.0];
    btReset.sd_layout
    .topSpaceToView(labelDiviation, 18)
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
    
    
#pragma mark - 学习功能view3
    _view3 = [[UIView alloc] init];
    _view3.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
    [_scrollView addSubview:_view3];
    _view3.sd_cornerRadiusFromHeightRatio = @(0.01);
    _view3.sd_layout
    .topSpaceToView(_view2, 0)
    .leftSpaceToView(_scrollView, 12)
    .rightSpaceToView(_scrollView, 12)
    .topSpaceToView(_view2, 20)
    .heightIs(2000) ;
    
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

    labelBackStudy.text = @"学习功能";
    
    //外部环境学习(门限方式)按钮
    UIButton *btGateStudy = [[UIButton alloc]init];
    [_view3 addSubview:btGateStudy];
    [btGateStudy setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btGateStudy.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btGateStudy.layer setCornerRadius:4.0];
    btGateStudy.sd_layout
    .topSpaceToView(labelBackStudy, 8)
    .heightIs(40)
    .widthRatioToView(_view3, 0.45)
    .leftSpaceToView(_view3, 10);
    [btGateStudy setTitle:@"外部环境学习(门限方式)" forState:UIControlStateNormal];
    
    //btEnvirStudy.font = [UIFont systemFontOfSize:12];
    btGateStudy.titleLabel.adjustsFontSizeToFitWidth = YES;
    [btGateStudy addTarget:self action:@selector(gateStudy:) forControlEvents:UIControlEventTouchUpInside];
    
    
    //外部环境学习(点方式)按钮
    UIButton *btDotStudy = [[UIButton alloc]init];
    [_view3 addSubview:btDotStudy];
    [btDotStudy setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btDotStudy.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btDotStudy.layer setCornerRadius:4.0];
    btDotStudy.sd_layout
    .topSpaceToView(labelBackStudy, 8)
    .heightIs(40)
    .widthRatioToView(_view3, 0.45)
    .rightSpaceToView(_view3, 10);
    [btDotStudy setTitle:@"外部环境学习(点方式)" forState:UIControlStateNormal];
    btDotStudy.titleLabel.adjustsFontSizeToFitWidth = YES;
    [btDotStudy addTarget:self action:@selector(dotStudy:) forControlEvents:UIControlEventTouchUpInside];
    
    //查询学习噪声(门限)按钮
    UIButton *btGateQuery = [[UIButton alloc]init];
    [_view3 addSubview:btGateQuery];
    [btGateQuery setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btGateQuery.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btGateQuery.layer setCornerRadius:4.0];
    btGateQuery.sd_layout
    .topSpaceToView(btDotStudy, 20)
    .heightIs(40)
    .widthRatioToView(_view3, 0.45)
    .leftSpaceToView(_view3, 10);
    [btGateQuery setTitle:@"查询学习噪声(门限)" forState:UIControlStateNormal] ;
    btGateQuery.titleLabel.adjustsFontSizeToFitWidth = YES;
    [btGateQuery addTarget:self action:@selector(gateQuery:) forControlEvents:UIControlEventTouchUpInside];
    
    //查询学习噪声(点)按钮
    UIButton *btDotQuery = [[UIButton alloc]init];
    [_view3 addSubview:btDotQuery];
    [btDotQuery setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btDotQuery.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btDotQuery.layer setCornerRadius:4.0];
    btDotQuery.sd_layout
    .centerYEqualToView(btGateQuery)
    .heightIs(40)
    .widthRatioToView(_view3, 0.45)
    .rightSpaceToView(_view3, 10);
    [btDotQuery setTitle:@"查询学习噪声(点)" forState:UIControlStateNormal] ;
    btDotQuery.titleLabel.adjustsFontSizeToFitWidth = YES;
    [btDotQuery addTarget:self action:@selector(dotQuery:) forControlEvents:UIControlEventTouchUpInside];
    
    //噪声点(门限方式)
    UILabel *labelEnviron = [[UILabel alloc]init];
    [_view3 addSubview:labelEnviron];
    labelEnviron.sd_layout
    .topSpaceToView(btDotQuery, 20)
    .heightIs(40)
    .leftSpaceToView(_view3, 10)
    .rightSpaceToView(_view3,10);
    //[labelEnviron setSingleLineAutoResizeWithMaxWidth:1000];
    labelEnviron.textAlignment = NSTextAlignmentCenter;
    [labelEnviron setBackgroundColor:[UIColor colorWithRed:0 green:0.2 blue:0.2 alpha:0.2]];
    labelEnviron.font = [UIFont systemFontOfSize:18];
    [labelEnviron setTextColor:[UIColor  blackColor]];

    labelEnviron.text = @"噪声点(门限方式)";
    
    viewNoise *viewGate = [[viewNoise alloc] init];
    viewGate.backgroundColor = [UIColor whiteColor];
    [_view3 addSubview:viewGate];
    viewGate.sd_layout
    .topSpaceToView(labelEnviron, 8)
    .heightIs(328)
    .leftSpaceToView(_view3, 10)
    .rightSpaceToView(_view3,10);
    [viewGate setTag:1332];
    NSMutableArray *arrGate = [[NSMutableArray alloc] init];
    for(int i=0;i<128; i++){
        [arrGate addObject:@"0"];
    }
    viewGate.dataStr = arrGate;
    viewGate.colorNumber = 0;
    
    //噪声点(点方式)
    UILabel *labelDot = [[UILabel alloc]init];
    [_view3 addSubview:labelDot];
    labelDot.sd_layout
    .topSpaceToView(viewGate, 8)
    .heightIs(40)
    .leftSpaceToView(_view3, 10)
    .rightSpaceToView(_view3,10);
    //[labelBrake setSingleLineAutoResizeWithMaxWidth:1000];
    labelDot.textAlignment = NSTextAlignmentCenter;
    [labelDot setBackgroundColor:[UIColor colorWithRed:0 green:0.2 blue:0.2 alpha:0.2]];
    labelDot.font = [UIFont systemFontOfSize:18];
    [labelDot setTextColor:[UIColor  blackColor]];

    labelDot.text = @"噪声点(点方式)";
    
    UILabel *labelRange = [[UILabel alloc]init];
    [_view3 addSubview:labelRange];
    labelRange.sd_layout
    .topSpaceToView(labelDot, 8)
    .heightIs(40)
    .leftSpaceToView(_view3, 10)
    .widthRatioToView(_view3, 0.3);
    labelRange.textAlignment = NSTextAlignmentCenter;
    [labelRange setBackgroundColor:[UIColor colorWithRed:0 green:0.2 blue:0.2 alpha:0.2]];
    labelRange.font = [UIFont systemFontOfSize:18];
    labelRange.text = @"Range";
    
    UILabel *labelAngle = [[UILabel alloc]init];
    [_view3 addSubview:labelAngle];
    labelAngle.sd_layout
    .topSpaceToView(labelDot, 8)
    .heightIs(40)
    .centerXEqualToView(_view3)
    .widthRatioToView(_view3, 0.3);
    labelAngle.textAlignment = NSTextAlignmentCenter;
    [labelAngle setBackgroundColor:[UIColor colorWithRed:0 green:0.2 blue:0.2 alpha:0.2]];
    labelAngle.font = [UIFont systemFontOfSize:18];
    labelAngle.text = @"Angle";
    
    UILabel *lableElavation = [[UILabel alloc]init];
    [_view3 addSubview:lableElavation];
    lableElavation.sd_layout
    .topSpaceToView(labelDot, 8)
    .heightIs(40)
    .rightSpaceToView(_view3, 10)
    .widthRatioToView(_view3, 0.3);
    lableElavation.textAlignment = NSTextAlignmentCenter;
    [lableElavation setBackgroundColor:[UIColor colorWithRed:0 green:0.2 blue:0.2 alpha:0.2]];
    lableElavation.font = [UIFont systemFontOfSize:18];
    lableElavation.text = @"Elevation";
    
    viewNoiseDot *viewDot = [[viewNoiseDot alloc] init];
    viewDot.backgroundColor = [UIColor whiteColor];
    [_view3 addSubview:viewDot ];
    viewDot.sd_layout
    .topSpaceToView(lableElavation, 8)
    .heightIs(1312)
    .leftSpaceToView(_view3, 10)
    .rightSpaceToView(_view3,10);
    [viewDot setTag:1336];
    NSMutableArray *arrStraight = [[NSMutableArray alloc] init];
    for(int i=0;i<63*3; i++){
        [arrStraight addObject:@"0"];
    }
    viewDot.dataStr = arrStraight;
    viewDot.colorNumber = 0;
    
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
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
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
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
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

#pragma mark 工作模式切换
-(void)setWorkMode:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    
    UISwitch *switchMode = (UISwitch *)sender;
    UISwitch *switchDiff = (UISwitch *)[self.view viewWithTag:1202];
    UILabel *labelDiff = (UILabel *)[self.view viewWithTag:1203];
    UIButton *btConfirmDiff = (UIButton *)[self.view viewWithTag:1204];
    UILabel  *labelMode = (UILabel *)[self.view viewWithTag:1206];
    if(![switchMode isOn]){
        [labelMode setText:@"人、车"];
        [switchDiff setEnabled:YES];
        [labelDiff setEnabled:YES];
        [btConfirmDiff setEnabled:YES];
    }else{
        [labelMode setText:@"人、车、\n非机动车"];
        [switchDiff setEnabled:NO];
        [labelDiff setEnabled:NO];
        [btConfirmDiff setEnabled:NO];
    }
    [labelMode setTextColor:[UIColor redColor]];
}

-(void) confirmMode:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
        return;
    }
    UISwitch  *switchMode = (UISwitch *)[self.view viewWithTag:1205];
    // UILabel  *labelMode = (UILabel *)[self.view viewWithTag:1206];
    if([switchMode isOn]){
        self.header.dataWrite = @"a5 01";   //三类
    }else{
        self.header.dataWrite = @"a5 00";   //两类
    }
    self.header.tagWrite = 1210;
    [self.header writeBoardWithTag:1210];
    NSLog(@"writeBoard with tag ---%d",1210);
}

#pragma mark 区分人车
-(void) distinguish:(id) sender{
    [self.timer invalidate];
    self.timer = nil;
    
    UISwitch *switchDiff = (UISwitch *)sender;
    //UISwitch *swithcMode = (UISwitch *)[self.view viewWithTag:1205];
    UILabel  *labelRenche = (UILabel *)[self.view viewWithTag:1203];
    if(![switchDiff isOn]){
        [labelRenche setText:@"不区分"];
    }else{
        [labelRenche setText:@"区分"];
    }
    [labelRenche setTextColor:[UIColor redColor]];
}

-(void) confirmDiff:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
        return;
    }
    UILabel  *labelRenche = (UILabel *)[self.view viewWithTag:1203];
    if([labelRenche.text isEqualToString:@"不区分"]){
        self.header.dataWrite = @"ad 00";
    }else if([labelRenche.text isEqualToString:@"区分"]){
        self.header.dataWrite = @"ad 01";
    }
    self.header.tagWrite = 1215;
    [self.header writeBoardWithTag:1215];
    NSLog(@"writeBoard with tag ---%d",1215);
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

-(void) confirmDistance:(id) sender{
    [self.timer invalidate];
    self.timer = nil;
    
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
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
        [self.HUD hideAnimated:YES afterDelay:1.5];
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


#pragma mark 调整栏杆方位
-(void) direction{
    [self.timer invalidate];
    self.timer = nil;
    
    UISwitch *switchDirection = (UISwitch *)[self.view viewWithTag:1272];
    UILabel  *labelDirection = (UILabel *)[self.view viewWithTag:1273];
    if(![switchDirection isOn]){
        [labelDirection setText:@"雷达左侧"];
        [switchDirection setOn:NO];
    }else{
        [labelDirection setText:@"雷达右侧"];
        [switchDirection setOn:YES];
    }
    [labelDirection setTextColor:[UIColor redColor]];
}

-(void) confirmShift{
    [self.timer invalidate];
    self.timer = nil;
    
    
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
        return;
    }
    UISwitch *switchShift = (UISwitch *)[self.view viewWithTag:1272];
    if(![switchShift isOn]){
        self.header.dataWrite = @"b8 01";  //雷达左侧
    }else{
        self.header.dataWrite = @"b8 00";  //雷达右侧
    }
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
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
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
    //self.header.dataWrite = @"";
}

-(void) refresh{
    [self.timer invalidate];
    self.timer = nil;
    
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
        return;
    }
    
    if([self.header.socket isConnected]){
        self.header.dataWrite = @"c0 01";
        self.header.tagWrite = 1299;
        [self.header writeBoardWithTag:1299];
        NSLog(@"writeBoard with tag ---%d %@",1299,self.description);
        
       // [self.header.socket disconnect];
       // sleep(0.1);
       // [self.header socketConnectHost];
    }
    //self.header.dataWrite = @"";
}


#pragma mark 确认背景学习
//门限方式学习
-(void) gateStudy:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
        return;
    }
    //[self sound1];
    UIAlertController *alertBegin = [UIAlertController alertControllerWithTitle:@"门限方式学习" message:@"确保雷达十米内无行人车辆\n确定后开始学习\n学习时间6秒" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"开始" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.player stop];
        
        [self sound2];
        if([self.header.socket isConnected]){
            self.header.dataWrite = @"aa 02";
            self.header.tagWrite = 1305;
            [self.header writeBoardWithTag:1305];
            NSLog(@"writeBoard with tag ---%d",1305);
            
            // viewNoise  *tvEnviron = (viewNoise *)[self.view viewWithTag:1332];
            // [tvEnviron setTextColor:[UIColor redColor]];
        }
        //-----------
        UIAlertController *alertStudy = [UIAlertController alertControllerWithTitle:@"门限方式学习" message:@"正在学习\n" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action11 = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            if([self.header.socket isConnected]){
                self.header.dataWrite = @"aa 00";
                self.header.tagWrite = 1307;
                [self.header writeBoardWithTag:1307];
                NSLog(@"writeBoard with tag ---%d",1307);
            }
            [self sound3];
            UIAlertController *alertEnd = [UIAlertController alertControllerWithTitle:@"门限方式学习" message:@"学习结果保存完毕" preferredStyle:UIAlertControllerStyleAlert];
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

//点学习
-(void) dotStudy:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
        return;
    }
    // [self sound4];
    UIAlertController *alertBegin = [UIAlertController alertControllerWithTitle:@"点方式学习" message:@"确保雷达十米内无行人车辆\n确定后开始学习" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"开始" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.player stop];
        
        // [self sound2];
        if([self.header.socket isConnected]){
            self.header.dataWrite = @"aa 01";
            self.header.tagWrite = 1306;
            [self.header writeBoardWithTag:1306];
            NSLog(@"writeBoard with tag ---%d",1306);
            
            //viewNoise  *tvBrake = (viewNoise *)[self.view viewWithTag:1336];
            // [tvBrake setTextColor:[UIColor redColor]];
        }
        //-----------
        UIAlertController *alertStudy = [UIAlertController alertControllerWithTitle:@"点方式学习" message:@"正在学习" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action11 = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            if([self.header.socket isConnected]){
                self.header.dataWrite = @"aa 00";
                self.header.tagWrite = 1307;
                [self.header writeBoardWithTag:1307];
                NSLog(@"writeBoard with tag ---%d",1307);
            }
            [self sound3];
            UIAlertController *alertEnd = [UIAlertController alertControllerWithTitle:@"点方式学习" message:@"学习结果保存完毕" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action111 = [UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                //保存背景
                self.header.dataWrite = @"bf 00";
                [self.header writeBoardWithTag:1001];
                self.header.tagWrite = 1001;
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


//门限学习查询
-(void)gateQuery:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
        return;
    }
    // [self addNoiseLayout];
    if([self.header.socket isConnected]){
      //  [self.header.longData  setString:@""];
        self.header.dataWrite = @"c0 05";
        self.header.tagWrite = 1308;
        [self.header writeBoardWithTag:1308];
        NSLog(@"writeBoard with tag ---%d",1308);
        
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeIndeterminate;
        self.HUD.label.text= @"正在查询门限值";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:2];
    }
    //self.header.dataWrite = @"";
}

//点学习查询
-(void)dotQuery:(id)sender{
    [self.timer invalidate];
    self.timer = nil;
    
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1.5];
        return;
    }
    // [self addNoiseLayout];
    if([self.header.socket isConnected]){
        [self.header.longData  setString:@""];
        self.header.dataWrite = @"c0 04";
        self.header.tagWrite = 1309;
        [self.header writeBoardWithTag:1309];
        NSLog(@"writeBoard with tag ---%d",1309);
        
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeIndeterminate;
        self.HUD.label.text= @"正在查询点值";
        self.HUD.label.textColor = [UIColor blueColor];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:2];
    }
    //self.header.dataWrite = @"";
}

#pragma mark 根据tag读取数据
- (void) OnDidReadDataWithTag:(long)Tag{
    
    self.HUD.removeFromSuperViewOnHide = YES;
    [self.HUD hideAnimated:YES afterDelay:0];

   // if(Tag != self.header.tagWrite) return;
    
    self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.HUD.mode = MBProgressHUDModeText;
    self.HUD.label.textColor = [UIColor blueColor];
    self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.HUD.bezelView.backgroundColor = [UIColor yellowColor];

    NSArray *strs = [self.header.dataRead componentsSeparatedByString:@":"];
    NSArray *strsReset = [self.header.dataRead componentsSeparatedByString:@"\r\n"];
    //NSArray *strsGate = [NSString new];
    NSArray *strsGate = [[NSArray alloc] init];  //门限字符串分离数组
    NSArray *strsTemp = [NSArray new];
    NSMutableArray *arrGate = [NSMutableArray new]; //门限值
    
    NSArray *strsDot = [NSArray new];  //点字符分离值
    long dotNumber = 0;
    
    NSString *strHUD = [[NSString alloc]init];
    NSMutableArray *arrDot = [[NSMutableArray alloc]init];
    
    UILabel *labelGuJian = (UILabel *)[self.view viewWithTag:1100];  //固件查询
    UILabel *labelZhenji = (UILabel *)[self.view viewWithTag:1101];  //整机查询
    UILabel *labelDanji = (UILabel *)[self.view viewWithTag:1102];   //单机查询
    UISwitch *switchMode = (UISwitch *)[self.view viewWithTag:1205]; //工作模式开关
    UILabel  *labelMode = (UILabel *)[self.view viewWithTag:1206];  //工作模式指示
    UISwitch *switchRenche = (UISwitch *)[self.view viewWithTag:1202]; //人车区分开关
    UILabel  *labelDiff = (UILabel *)[self.view viewWithTag:1203];  //人车区分
    UIButton *btConfirmDiff = (UIButton *)[self.view viewWithTag:1204];//确认区分人车
    UILabel  *labelDistance = (UILabel *)[self.view viewWithTag:1223];  //纵向距离
    UILabel  *labelShoot = (UILabel *)[self.view viewWithTag:1253];    //对射频表
    UISwitch *switchDirection = (UISwitch *)[self.view viewWithTag:1272];
    UILabel  *labelDirection = (UILabel *)[self.view viewWithTag:1273];  //偏移方向
    
    viewNoise  *viewGate = (viewNoise *)[self.view viewWithTag:1332];//
    viewNoiseDot  *viewDot = (viewNoiseDot *)[self.view viewWithTag:1336];//
    
    switch (Tag) {
        case 1001:
            NSLog(@"%@",self.header.dataRead);
            strHUD = @"更新用户数据成功";
            break;
        case 1100:
            if([strs count]>0){
                labelGuJian.text = strs[1];
            }
            strHUD = @"固件版本获取成功！";
            break;
        case 1103:
            if([strs count]>1){
                labelZhenji.text = [strs[1] substringToIndex:13];
            }
            strHUD = @"整机SN获取成功！";
            break;
        case 1104:
            if([strs count]>1){
                labelDanji.text = strs[2];
            }
            strHUD = @"单机SN获取成功！";
            break;
        case 1210:
            [labelMode setTextColor:[UIColor blackColor]];
            strHUD = [NSString stringWithFormat:@"工作模式:%@设置成功！",labelMode.text];
            self.HUD.label.numberOfLines = 2;
            break;
        case 1215:
            [labelDiff setTextColor:[UIColor blackColor]];
            strHUD = [NSString stringWithFormat:@"人车%@设置成功！",labelDiff.text];
            break;
        case 1220:
            [labelDistance setTextColor:[UIColor blackColor]];
            strHUD = [NSString stringWithFormat:@"纵向距离%@米设置成功！",labelDistance.text];
            break;
        case 1250:
            [labelShoot setTextColor:[UIColor blackColor]];
            strHUD = [NSString stringWithFormat:@"对射模式%@设置成功",labelShoot.text];
            break;
        case 1270:
            [labelDirection setTextColor:[UIColor blackColor]];
            strHUD = [NSString stringWithFormat:@"杆在%@设置成功",labelDirection.text];
            break;
        case 1298:
            strHUD = @"设备重置成功！";
            [labelMode setTextColor:[UIColor redColor]];
            [labelDiff setTextColor:[UIColor redColor]];
            [labelDistance setTextColor:[UIColor redColor]];
            [labelShoot setTextColor:[UIColor redColor]];
            [labelDirection setTextColor:[UIColor redColor]];
            break;
        case 1299:
            strHUD = @"参数刷新成功";
           // NSAssert([strsReset count]>=12, @"刷新收到的字段数量不够");
            if([strsReset count]>=12){
                if([[strsReset[0] substringFromIndex:8] isEqualToString:@"veh pd"]){
                    labelMode.text = @"人、车";
                    [switchMode setOn:NO];
                    [switchRenche setEnabled:YES];
                    [labelDiff setEnabled:YES];
                    [btConfirmDiff setEnabled:YES];
                }else if([[strsReset[0] substringFromIndex:8] isEqualToString:@"veh motor pd"]){
                    labelMode.text = @"人、车、\n非机动车";
                    [switchMode setOn:YES];
                    [switchRenche setEnabled:NO];
                    [labelDiff setEnabled:NO];
                    [btConfirmDiff setEnabled:NO];
                }
                [labelMode setTextColor:[UIColor blackColor]];
                
                if([strsReset[1] isEqual:@"VehandPd Distinguished"]){
                    labelDiff.text = @"区分";
                    [switchRenche setOn:YES];
                }else{
                    labelDiff.text = @"不区分";
                    [switchRenche setOn:NO];
                }
                [labelDiff setTextColor:[UIColor blackColor]];
                
                labelShoot.text = [strsReset[2] substringFromIndex:9];
                [labelShoot setTextColor:[UIColor blackColor]];
                
                labelDistance.text = [strsReset[5] substringWithRange:NSMakeRange(9, 3)];
                [labelDistance setTextColor:[UIColor blackColor]];
                
                if([strsReset[7] isEqual:@"BarLeft"]){
                    labelDirection.text = @"雷达左侧";
                    [switchDirection setOn:NO];
                }else{
                    labelDirection.text = @"雷达右侧";
                    [switchDirection setOn:YES];
                }
                [labelDirection setTextColor:[UIColor blackColor]];
                
                labelZhenji.text = [strsReset[8] substringFromIndex:4];
                labelDanji.text = [strsReset[9] substringFromIndex:4];
            }
            [self.view setNeedsDisplay];
            break;
        case 1305:
            viewGate.colorNumber = 0;
            [viewGate setNeedsDisplay];
            break;
        case 1306:
            viewDot.colorNumber = 0;
            [viewDot setNeedsDisplay];
            break;
        case 1308:  //门限点值
            //strHUD = @"正在获取门限值！";
            strsGate = [self.header.longData componentsSeparatedByString:@"\r\n"];
            //strsTemp = [strsGate[1]  componentsSeparatedByString:@","];
            //门限噪声
            if(strsGate.count >1){
                strsTemp = [strsGate[1]  componentsSeparatedByString:@","];
                strHUD = [NSString stringWithFormat:@"噪声门限值读取成功\n共读取到%ld个门限值",[strsTemp count]-1];
                self.HUD.label.numberOfLines = 2;
            }
            for(long i=0;i<strsTemp.count-1;i++){
                [arrGate addObject:strsTemp[i]];
            }
            for( long j=strsTemp.count-1; j<128;j++){
                [arrGate addObject:@"0"];
            }
            viewGate.dataStr = arrGate;
            viewGate.colorNumber = 1;
            [viewGate setNeedsDisplay];
            [self.view updateLayout];
            break;
        case 8000:
            strHUD = @"即将停止扫描";
            break;
        case 1309:   //读取噪声点值
            strHUD = @"正在获取点值！";
            strsDot = [self.header.longData  componentsSeparatedByString:@"\r\n"];
         //   if(strsDot.count >33){
                NSString *strNumber = [strsDot[0] substringWithRange:NSMakeRange(10, 2)];
                //点值个数
                dotNumber = [strNumber intValue];
                strHUD = [NSString stringWithFormat:@"噪声点读取成功\n共读取到%ld个点值",dotNumber];
                self.HUD.label.numberOfLines = 2;
                for(int i=1;i<= dotNumber;i++){
                    NSArray *dotValues = [strsDot[i] componentsSeparatedByString:@","];
                    [arrDot addObject:[dotValues[0] substringFromIndex:7]];
                    [arrDot addObject:[dotValues[1] substringFromIndex:7]];
                    [arrDot addObject:[dotValues[2] substringFromIndex:11]];
                }
          //  }
            for(long j=dotNumber*3;j<63*3;j++){
                [arrDot addObject:@"0"];
            }
            [self.header.longData setString:@""];
            viewDot.dataStr = arrDot;
            viewDot.colorNumber = 1;
            [viewDot setNeedsDisplay];
            [self.view updateLayout];
            break;
        //default:break;
    }
    if(Tag==1305|Tag==1306){
        [self.HUD hideAnimated:YES afterDelay:0];
        self.HUD.removeFromSuperViewOnHide = YES;
    }else{
        self.HUD.label.text= strHUD;
        [self.HUD hideAnimated:YES afterDelay:1.5];
        self.HUD.removeFromSuperViewOnHide = YES;
    }
    
    if(Tag != 1001){
        self.header.dataWrite = @"bf 00";
        self.header.tagWrite = 1001;
        [self.header writeBoardWithTag:1001];
        NSLog(@"writeBoard with tag ---%d",1001);
    }
    
    self.header.dataWrite = @"";
    [self.header.longData setString:@""];
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
        NSLog(@"write board with tag 8100");
    }
     */
    //self.header.dataWrite = @"";
}

-(void)viewDidAppear:(BOOL)animated{
    self.header.delegate = self;
    //[self resetContolls];
    self.header.dataWrite = @"a9 00";
    self.header.tagWrite = 8100;
    [self.header writeBoardWithTag:8100];
    NSLog(@"write board with tag 8100");
    
    
    //self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(refresh) userInfo:nil repeats:NO];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer * _Nonnull timer) {
        self.header.dataWrite = @"a9 00";
        self.header.tagWrite = 8100;
        [self.header writeBoardWithTag:8100];
        NSLog(@"write board with tag 8100");
        self.stopScanTimes++;
        if(self.stopScanTimes > 10){
            [self.timer invalidate];
            self.timer = nil;
            self.stopScanTimes = 0;
        }
    }];
    //[self refresh];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    //self.header.delegate = nil;
    //更新用户数据
    [self.timer invalidate];
    self.timer = nil;
    
    self.header.dataWrite = @"bf 00";
    self.header.tagWrite = 1001;
    [self.header writeBoardWithTag:1001];
    NSLog(@"writeBoard with tag ---%d",1001);
    self.header.delegate = nil;
}
-(void)dealloc{
    [self.timer invalidate];
    self.timer = nil;
}

@end
