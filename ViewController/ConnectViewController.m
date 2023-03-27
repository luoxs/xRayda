//
//  ConnectViewController.m
//  xRayda
//
//  Created by apple on 2021/11/20.
//  Copyright © 2021 apple.gupt.www. All rights reserved.
//

#import "ConnectViewController.h"
#import "FMDatabase.h"
#import "Socket.h"
#import "SDAutoLayout.h"
#import "MBProgressHUD.h"
#import "viewScan.h"

@interface ConnectViewController ()<SocketDelegate>
@property (strong, nonatomic)Socket *header;
@property (retain, nonatomic) IBOutlet UILabel *labelLinked;
@property (retain,nonatomic) MBProgressHUD *HUD;
@property NSInteger strsCount;
@property (strong,nonatomic) NSMutableArray *targets;
@property (retain,nonatomic) NSTimer *timer;
@property  bool isScan;  //是否正在扫描
@property (nonatomic, strong) FMDatabase *db;  //数据库

- (IBAction)connectRayda:(id)sender;
- (IBAction)disconnectRayda:(id)sender;
@end

@implementation ConnectViewController
   UIButton *btDisConnect;
   UIButton *btConnect;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.header = [Socket sharedInstance];
    
    self.strsCount = 0;
    self.targets = [[NSMutableArray alloc] init];
    
    btDisConnect = (UIButton *)[self.view viewWithTag:100];
    btConnect = (UIButton *)[self.view viewWithTag:101];
    [btDisConnect setEnabled:NO];
    [btConnect setEnabled:YES];
    self.isScan = NO;
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setController];
    self.header.orietion = 0;
    self.header.signalout = 0;
}

-(void) setController{
    UIImageView *imgv = [[UIImageView alloc] init];
    [self.view addSubview:imgv];
    [imgv setImage:[UIImage imageNamed:@"IMG_8549"]];
    imgv.sd_layout
    .topSpaceToView(self.view, 20)
    .heightRatioToView(self.view, 0.2)
    .centerXEqualToView(self.view)
    .widthRatioToView(self.view, 0.4);

    //连接状态标签
    [self.labelLinked setBackgroundColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.2]];
    self.labelLinked.sd_layout
    .topSpaceToView(imgv, 5)
    .heightRatioToView(self.view, 0.05)
    .centerXEqualToView(self.view)
    .widthRatioToView(self.view, 0.25);
    [self.labelLinked setText:@"已断开"];
    
    //断开雷达按钮
    btDisConnect = (UIButton *)[self.view viewWithTag:100];
    [btDisConnect setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btDisConnect.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btDisConnect.layer setCornerRadius:8.0];
    btDisConnect.sd_layout
    .centerYEqualToView(self.labelLinked)
    .heightRatioToView(self.view, 0.05)
    .leftSpaceToView(self.view, 20)
    .widthRatioToView(self.view, 0.3);
    [btDisConnect setTitle:@"断开雷达" forState:UIControlStateNormal];
  
    //连接雷达按钮
    btConnect = (UIButton *)[self.view viewWithTag:101];
    [btConnect setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btConnect.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btConnect.layer setCornerRadius:8.0];
    btConnect.sd_layout
    .centerYEqualToView(self.labelLinked)
    .heightRatioToView(self.view, 0.05)
    .rightSpaceToView(self.view, 20)
    .widthRatioToView(self.view, 0.3);
    [btConnect setTitle:@"连接雷达" forState:UIControlStateNormal];
    
#pragma mark 扫瞄界面
    UIView *view2 = [[UIView alloc] init];
    view2.backgroundColor = [UIColor colorWithRed:0.0 green:0.2 blue:0.2 alpha:0.2];
    [self.view addSubview:view2];
    view2.sd_cornerRadiusFromHeightRatio = @(0.03);
    view2.sd_layout
    .topSpaceToView(self.labelLinked, 10)
    .leftSpaceToView(self.view, 5)
    .rightSpaceToView(self.view, 5)
    .heightRatioToView(self.view, 0.618);
    
   
    //扫描目标
    UIButton *btScan = [[UIButton alloc]init];
    [view2 addSubview:btScan];
    [btScan setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btScan.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btScan.layer setCornerRadius:8.0];
    btScan.sd_layout
    .topSpaceToView(view2, 5)
    .leftSpaceToView(view2, 15)
    .heightRatioToView(self.view, 0.05)
    .widthRatioToView(self.view, 0.3);
    [btScan setTitle:@"扫描目标" forState:UIControlStateNormal] ;
    [btScan addTarget:self action:@selector(scanTarget) forControlEvents:UIControlEventTouchUpInside];
    
    //停止扫描按钮
    UIButton *btStopScan = [[UIButton alloc]init];
    [view2 addSubview:btStopScan];
    [btStopScan setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btStopScan.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btStopScan.layer setCornerRadius:8.0];
    btStopScan.sd_layout
    .topSpaceToView(view2, 5)
    .heightRatioToView(self.view, 0.05)
    .widthRatioToView(self.view, 0.3)
    .rightSpaceToView(view2, 15);
    [btStopScan setTitle:@"停止扫描" forState:UIControlStateNormal] ;
    [btStopScan addTarget:self action:@selector(stopScan) forControlEvents:UIControlEventTouchUpInside];
    
    /*
    UILabel *labeltarget = [[UILabel alloc]init];
    [view2 addSubview:labeltarget];
    labeltarget.sd_layout
    .topSpaceToView(view2, 8)
    .heightRatioToView(self.view, 0.05)
    .leftSpaceToView(view2, 10);
    [labeltarget setSingleLineAutoResizeWithMaxWidth:200];
    labeltarget.text = @"当前目标";
     */
    
    viewScan *vScan = [[viewScan alloc] init];
    vScan.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.5];
    [view2 addSubview:vScan];
    vScan.sd_layout
    .topSpaceToView(btScan, 10)
    .bottomSpaceToView(view2, 0)
    .leftSpaceToView(view2, 10)
    .rightSpaceToView(view2, 10);
    [vScan setTag:1007];
}

#pragma mark 扫瞄目标
-(void)scanTarget{
    self.header.dataRead= @"";
    self.strsCount = 0;
    [self.targets removeAllObjects];
    [self.timer invalidate];
    
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
        self.isScan = YES;
        self.header.dataWrite = @"a9 04";
        self.header.tagWrite = 8000;
        [self.header writeBoardWithTag:8000];
        NSLog(@"write board with tag 8000");
    }
    self.header.dataWrite = @"";
}

#pragma mark 停止扫描
-(void)stopScan{
    if([self.header.socket isDisconnected]){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"网络已断开，请重新连接";
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:2];
        return;
    }else{
        NSLog(@"-------停止扫描---------");
        self.isScan = NO;
        self.header.dataWrite = @"a9 00";
        self.header.tagWrite = 8100;
        [self.header writeBoardWithTag:8100];
        NSLog(@"write board with tag 8100");
        viewScan *vScan =(viewScan *) [self.view viewWithTag:1007];
        vScan.dataStr = @"";
        [vScan setNeedsDisplay];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(sendStopCmd) userInfo:nil repeats:NO];
    }
    self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.HUD.mode = MBProgressHUDModeIndeterminate;
    self.HUD.label.textColor = [UIColor blueColor];
    self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
    self.HUD.label.text = @"稍等，正在停止扫描";

    self.HUD.removeFromSuperViewOnHide = YES;
    [self.HUD hideAnimated:YES afterDelay:0.5];
}
-(void) sendStopCmd{
    NSLog(@"-------再次停止扫描---------");
   // [self.header.socket readStream];
    self.header.dataWrite = @"a9 00";
    self.header.tagWrite = 8100;
    [self.header writeBoardWithTag:8100];
    NSLog(@"write board with tag 8100");
    viewScan *vScan =(viewScan *) [self.view viewWithTag:1007];
    vScan.dataStr = @"";
    [vScan setNeedsDisplay];
    
    [self.timer invalidate];
    self.timer = nil;
    
    //500毫秒后再停止扫描一次
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5f repeats:NO block:^(NSTimer * _Nonnull timer) {
        NSLog(@"-------又一次停止扫描---------");
        [self.header.socket readStream];
        self.header.dataWrite = @"a9 00";
        self.header.tagWrite = 8100;
        [self.header writeBoardWithTag:8100];
        NSLog(@"write board with tag 8100");
        //清空扫描区
        viewScan *vScan =(viewScan *) [self.view viewWithTag:1007];
        vScan.dataStr = @"";
        [vScan setNeedsDisplay];
    }];
     
}

- (void) OnDidReadDataWithTag:(long)Tag{
    if(Tag==8000){
        //NSLog(@"%@",self.header.dataRead);
        viewScan *vScan =(viewScan *) [self.view viewWithTag:1007];
        vScan.dataStr = self.header.dataRead;
        [vScan setNeedsDisplay];
        return;
    }

    if(Tag == 1299){
        self.header.strsReset = [self.header.dataRead componentsSeparatedByString:@"\r\n"];
        if([self.header.typeRadar isEqualToString: @"fangza"]){
           //新版本固件
            if([self.header.strsReset count]>=11){
                if([self.header.strsReset[6] isEqualToString:@"DoubleSide"]){
                    self.header.orietion = 0;
                }else if([self.header.strsReset[6] isEqualToString:@"LeftSide"]){
                    self.header.orietion = 1;
                }else{
                    self.header.orietion = 2;
                }
                
                if([self.header.strsReset[7] isEqualToString:@"SignOutDG"]){
                    self.header.signalout = 0;
                }else{
                    self.header.signalout = 1;
                }
                self.header.version = @"new";
            }else{
                self.header.version = @"old";
            }
        }
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.label.text= @"参数刷新成功";
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:1];
    }
    if(Tag==1100){
        self.header.strsVersion  = [[self.header.dataRead componentsSeparatedByString:@":"] objectAtIndex:1];
    }
}

#pragma  mark 连接设备
- (IBAction)connectRayda:(id)sender {
    //连接热点
    [self.header socketConnectHost];
    
    self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.HUD.mode = MBProgressHUDModeIndeterminate;
    self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
    self.HUD.label.text= @"正在连接中";
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(connectTimeOut) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSDefaultRunLoopMode];
}



- (IBAction)disconnectRayda:(id)sender {
    [self.header cutOffSocket];
   // [self onConnectFailed];
   // [self.header.socket disconnect];
    //self.header.socket = nil;
}

-(void)connectTimeOut{
    [self.connectTimer invalidate];
    if(![self.header.socket isConnected]){
        NSLog(@"连接失败！查看是否连接热点");
        
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"连接失败！";
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:2];
    }
}

#pragma mark -连接雷达等代理

-(void)onConnected{
    self.labelLinked.text = @"已连接";
    [self.labelLinked setTextColor:[UIColor blueColor]];
    [btDisConnect setEnabled:YES];
    [btConnect setEnabled:NO];
    
    self.HUD.removeFromSuperViewOnHide = YES;
    [self.HUD hideAnimated:YES afterDelay:0];

    [self refresh];
 
    [self.connectTimer invalidate];
}

-(void)onConnectFailed{
    self.labelLinked.text = @"已断开";
    [self.labelLinked setTextColor:[UIColor redColor]];
    [btDisConnect setEnabled:NO];
    [btConnect setEnabled:YES];
    self.HUD.removeFromSuperViewOnHide = YES;
    [self.HUD hideAnimated:YES afterDelay:0];
    [self.connectTimer invalidate];
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
        self.header.dataWrite = @"c0 01";
        self.header.tagWrite = 1299;
        [self.header writeBoardWithTag:1299];
        NSLog(@"writeBoard with tag ---%d,%@",1299,self.description);
      
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:NO block:^(NSTimer * _Nonnull timer) {
            self.header.dataWrite = @"c0 00";
            self.header.tagWrite = 1100;
            [self.header writeBoardWithTag:1100];
            NSLog(@"writeBoard with tag %d,%@",1100,self.description);
        }];
    }
}

-(void) OnDidReadData{
    NSLog(@"数据读取完毕----");
}

-(void)onScanNotFound{
    self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.HUD.mode = MBProgressHUDModeText;
    self.HUD.label.text= @"未扫描到设备，检查手机是否连接热点";
    self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
    self.HUD.removeFromSuperViewOnHide = YES;
    [self.HUD hideAnimated:YES afterDelay:5];
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

-(void)viewDidAppear:(BOOL)animated{
    self.header.delegate = self;
    if([self.header.socket isConnected]){
      //  [self onConnected];
    }else{
        [self onConnectFailed];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
   
    [self stopScan];
    viewScan *vScan =(viewScan *) [self.view viewWithTag:1007];
    vScan.dataStr = @"";
    [vScan setNeedsDisplay];

   self.header.delegate = nil;
}

-(void) viewDidDisappear:(BOOL)animated{
    [self.timer invalidate];
    self.timer = nil;
    self.header.delegate = nil;
    }

@end
