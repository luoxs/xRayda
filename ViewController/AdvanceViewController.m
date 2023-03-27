//
//  AdvanceViewController.m
//  xRayda
//
//  Created by apple on 2022/2/24.
//  Copyright © 2022 apple.gupt.www. All rights reserved.
//

#import "AdvanceViewController.h"
#import "FMDatabase.h"
#import "Socket.h"
#import "SDAutoLayout.h"
#import "MBProgressHUD.h"

@interface AdvanceViewController ()<SocketDelegate>
@property (strong,nonatomic) Socket *header;
@property (retain,nonatomic) MBProgressHUD *HUD;
@property (strong,nonatomic) NSString *orientation;
@property (strong,nonatomic) NSString *signalout;
@property (nonatomic, strong) FMDatabase *db;  //数据库
@end

@implementation AdvanceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.header = [Socket sharedInstance];
    self.header.delegate = self;
    
    self.orientation = [[NSString alloc] init];
    self.signalout = [[NSString alloc] init];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setAutoLayOut];
    
    [self refresh];
    
}


-(void) setAutoLayOut{
    //来车方向
    UILabel *labelOrientation = [[UILabel alloc]init];
    [self.view addSubview:labelOrientation];
    labelOrientation.sd_layout
    .topSpaceToView(self.view, 100)
    .heightIs(40)
    .centerXEqualToView(self.view);
    [labelOrientation setSingleLineAutoResizeWithMaxWidth:100];
    labelOrientation.font = [UIFont systemFontOfSize:20];
    [labelOrientation setTextColor:[UIColor  blackColor]];
    labelOrientation.text = @"来车方向";
    
    UIButton *btQuestion1 = [[UIButton alloc]init];
    [self.view addSubview:btQuestion1];
    UIImage *imageQuestion = [UIImage imageNamed:@"question"];
    [btQuestion1 setImage:imageQuestion forState:UIControlStateNormal];
    btQuestion1.sd_layout
    .centerYEqualToView(labelOrientation)
    .leftSpaceToView(labelOrientation, 2)
    .widthIs(30)
    .heightIs(30);
    [btQuestion1 addTarget:self action:@selector(showquestion1:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray *arrOrientation =[ [NSArray alloc]initWithObjects:@"双向有效",@"左向有效",@"右向有效", nil];
    UISegmentedControl *segmentOrientation = [[UISegmentedControl alloc] initWithItems:arrOrientation];
    [self.view addSubview:segmentOrientation];
    segmentOrientation.sd_layout
    .topSpaceToView(labelOrientation, 30)
    .heightIs(40)
    .centerXEqualToView(self.view)
    .leftSpaceToView(self.view, 10)
    .rightSpaceToView(self.view, 10);
    [segmentOrientation setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor]}forState:UIControlStateSelected];
    [segmentOrientation setSelectedSegmentIndex:0];
    [segmentOrientation setTag:101];
    [segmentOrientation addTarget:self action:@selector(selectOrientation:) forControlEvents:UIControlEventValueChanged];
    
    UIButton *btOrientation = [[UIButton alloc]init];
    [self.view addSubview:btOrientation];
    btOrientation.sd_layout
    .topSpaceToView(segmentOrientation, 30)
    .centerXEqualToView(self.view)
    .heightIs(40)
    .widthRatioToView(self.view, 0.4);
    [btOrientation setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:64/255.0 green:64/255.0 blue:64/255.0 alpha:1]] forState :UIControlStateHighlighted];
    [btOrientation setBackgroundColor:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1]];
    [btOrientation.layer setCornerRadius:8.0];
    [btOrientation setTitle:@"确定" forState:UIControlStateNormal];
    [btOrientation setTag:102];
    [btOrientation addTarget:self action:@selector(comfirmOrientation:) forControlEvents:UIControlEventTouchUpInside];
    
    //信号输出
    UILabel *labelSignalOut = [[UILabel alloc]init];
    [self.view addSubview:labelSignalOut];
    labelSignalOut.sd_layout
    .topSpaceToView(btOrientation, 100)
    .heightIs(40)
    .centerXEqualToView(self.view);
    [labelSignalOut setSingleLineAutoResizeWithMaxWidth:100];
    labelSignalOut.font = [UIFont systemFontOfSize:20];
    [labelSignalOut setTextColor:[UIColor  blackColor]];
    
    labelSignalOut.text = @"信号输出";
    
    UIButton *btQuestion2 = [[UIButton alloc]init];
    [self.view addSubview:btQuestion2];
    [btQuestion2 setImage:imageQuestion forState:UIControlStateNormal];
    btQuestion2.sd_layout
    .centerYEqualToView(labelSignalOut)
    .leftSpaceToView(labelSignalOut, 2)
    .widthIs(30)
    .heightIs(30);
    [btQuestion2 addTarget:self action:@selector(showquestion2:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray *arrSignalOut =[ [NSArray alloc]initWithObjects:@"输出接地感",@"输出接保护", nil];
    UISegmentedControl *segmentSignalOut = [[UISegmentedControl alloc] initWithItems:arrSignalOut];
    [self.view addSubview:segmentSignalOut];
    segmentSignalOut.sd_layout
    .topSpaceToView(labelSignalOut, 30)
    .heightIs(40)
    .centerXEqualToView(self.view)
    .leftSpaceToView(self.view, 10)
    .rightSpaceToView(self.view, 10);
    [segmentSignalOut setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor]}forState:UIControlStateSelected];
    [segmentSignalOut setSelectedSegmentIndex:0];
    [segmentSignalOut setTag:103];
    [segmentSignalOut addTarget:self action:@selector(selectSignalOut:) forControlEvents:UIControlEventValueChanged];
    
    UIButton *btSignalOut = [[UIButton alloc]init];
    [self.view addSubview:btSignalOut];
    btSignalOut.sd_layout
    .topSpaceToView(segmentSignalOut, 30)
    .centerXEqualToView(self.view)
    .heightIs(40)
    .widthRatioToView(self.view, 0.4);
    [btSignalOut setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:64/255.0 green:64/255.0 blue:64/255.0 alpha:1]] forState :UIControlStateHighlighted];
    [btSignalOut setBackgroundColor:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1]];
    [btSignalOut.layer setCornerRadius:8.0];
    [btSignalOut setTitle:@"确定" forState:UIControlStateNormal];
    [btSignalOut setTag:104];
    [btSignalOut addTarget:self action:@selector(comfirmSignalOut:) forControlEvents:UIControlEventTouchUpInside];
    
    //返回
    UIButton *goBack = [[UIButton alloc]init];
    [self.view addSubview:goBack];
    
    [goBack.layer setCornerRadius:8.0];
    goBack.sd_layout
    .topSpaceToView(btSignalOut, 20)
    .heightIs(40)
    .widthRatioToView(self.view, 0.4)
    .centerXEqualToView(self.view);
    [goBack setTitle:@"返回" forState:UIControlStateNormal];
    [goBack setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [goBack addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
}

-(void) selectOrientation:(id)sender{
    
}

//#pragma mark - 连接失败
-(void)onConnectFailed{
    self.header.socket.userData = [NSNumber numberWithInt:SocketOfflineByServer];
}

-(void)onConnected{
    //[SVProgressHUD dismiss];
    NSLog(@"已连接----");
}

//#pragma mark - 读取数据
-(void) OnDidReadData{
    NSLog(@"数据读取完毕----");
}

-(void)showquestion1:(id)sender{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"人面向雷达正面方向，左手边为“左向来车”，右手边为“右向来车”；设置为单向（左或右）有效时，反方向来车无效，即雷达不输出信号。" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {}];
    [alertVC addAction:action1];
    [self presentViewController:alertVC animated:YES completion:nil];
}

-(void)showquestion2:(id)sender{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"雷达默认输出接地感模式，仅当雷达作为防砸保护（雷达信号输出接入系统保护端、不负责落闸）使用时方可选择“输出接保护”选项，否则不可设置。" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {}];
    [alertVC addAction:action1];
    [self presentViewController:alertVC animated:YES completion:nil];
}

-(void) comfirmOrientation:()sender{
    UISegmentedControl *segmentOrientation = (UISegmentedControl *)[self.view viewWithTag:101];
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
        if(segmentOrientation.selectedSegmentIndex == 0){
            self.header.dataWrite = @"ba 00";
            self.header.orietion = 0;
        }else if(segmentOrientation.selectedSegmentIndex == 1){
            self.header.dataWrite = @"ba 02";
            self.header.orietion = 1;
        }else{
            self.header.dataWrite = @"ba 01";
            self.header.orietion = 2;
        }
        [self.header writeBoardWithTag:5100];
        self.header.tagWrite = 5100;
        NSLog(@"writeBoard with tag ---%d",5100);
    }
    self.header.dataWrite = @"";
}

-(void)selectSignalOut:(id)sender{
    
}




-(void) comfirmSignalOut:()sender{
    UISegmentedControl *segmentSignalOut = (UISegmentedControl *)[self.view viewWithTag:103];
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
        if(segmentSignalOut.selectedSegmentIndex == 0){
            self.header.dataWrite = @"bb 00";
            self.header.signalout = 0;
        }else{
            self.header.dataWrite = @"bb 01";
            self.header.signalout = 1;
        }
        [self.header writeBoardWithTag:5200];
        self.header.tagWrite = 5200;
        NSLog(@"writeBoard with tag ---%d",5200);
    }
    self.header.dataWrite = @"";
}

-(void)goBack{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

#pragma mark 根据tag读取数据
- (void) OnDidReadDataWithTag:(long)Tag{
    /*
     self.HUD.removeFromSuperViewOnHide = YES;
     [self.HUD hideAnimated:YES afterDelay:0];
     */
    if(Tag != self.header.tagWrite) return;
    
    self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.HUD.mode = MBProgressHUDModeText;
    self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
    self.HUD.label.textColor = [UIColor blueColor];
    
 
    NSString *strvalue = [NSString new];
    if([self.header.dataRead isEqualToString:@"DoubleSide\r\n"]){
        strvalue = @"双向有效";
    }else if([self.header.dataRead isEqualToString:@"LeftSide\r\n"]){
        strvalue = @"左向有效";
    }else if([self.header.dataRead isEqualToString:@"RightSide\r\n"]){
        strvalue = @"右向有效";
    }else if([self.header.dataRead isEqualToString:@"SignOutDG\r\n"]){
        strvalue = @"输出接地感";
    }else if([self.header.dataRead isEqualToString:@"SignOutSafe\r\n"]){
        strvalue = @"输出接保护";
    }
    
    NSString *strHUD = [[NSString alloc]init];
    switch (Tag) {
        case 5100:
            //NSLog(@"%@",self.header.dataRead);
            strHUD = [NSString stringWithFormat:@"来车方向%@设置成功",strvalue];
            break;
        case 5200:
            strHUD = [NSString stringWithFormat:@"信号%@设置成功",strvalue];
            break;
        default:break;
    }
    
    self.HUD.label.text= strHUD;
    [self.HUD hideAnimated:YES afterDelay:2];
    self.HUD.removeFromSuperViewOnHide = YES;
    
    self.header.dataWrite = @"";
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
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

-(void) refresh{
    UISegmentedControl *segmentOrientation = (UISegmentedControl *)[self.view viewWithTag:101];
    UISegmentedControl *segmentSignalOut =(UISegmentedControl *)[self.view viewWithTag:103];
    
    if(self.header.orietion == 0){
        segmentOrientation.selectedSegmentIndex = 0;
    }else if(self.header.orietion == 1){
        segmentOrientation.selectedSegmentIndex = 1;
    }else{
        segmentOrientation.selectedSegmentIndex = 2;
    }
    
    if(self.header.signalout==0){
        segmentSignalOut.selectedSegmentIndex = 0;
    }else{
        segmentSignalOut.selectedSegmentIndex = 1;
    }
}

-(void) viewWillAppear:(BOOL)animated{
    self.header.dataWrite = @"";
}

-(void)viewDidAppear:(BOOL)animated{
    self.header.delegate = self;
    //启动查询
}

-(void)viewWillDisappear:(BOOL)animated{
    self.header.delegate = nil;
    //更新用户数据
    self.header.dataWrite = @"bf 00";
    [self.header writeBoardWithTag:1001];
    self.header.tagWrite = 1001;
    NSLog(@"writeBoard with tag ---%d",1001);
    self.header.dataWrite = @"";
}

@end
