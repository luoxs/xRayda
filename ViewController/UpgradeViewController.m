//
//  UpgradeViewController.m
//  xRayda
//
//  Created by apple on 2021/12/4.
//  Copyright © 2021 apple.gupt.www. All rights reserved.
//

#import "UpgradeViewController.h"
#import "FMDatabase.h"
#import "Socket.h"
#import "UIView+SDAutoLayout.h"
#import "SDAutoLayout.h"
#import "MBProgressHUD.h"
#import "crcLib.h"

#define NAK  0x15
#define ACK  0x06
#define STH  0x02
#define EOT  0x04
#define CAN  0x18


@interface UpgradeViewController ()<SocketDelegate,UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic)Socket *header;
@property (retain,nonatomic) MBProgressHUD *HUD;

@property (nonatomic, strong) NSMutableArray *btnArray;
@property (nonatomic, strong) UIButton *selectedBtn;
@property (nonatomic, retain) NSString *filenameOfFirm;
@property  NSInteger len;  //文件总包数
@property  NSInteger k; //发送包序号
@property  NSInteger datatimes;  //读取数据次数
@property (nonatomic,retain) NSMutableArray *listPack; //升级包
@property (retain,nonatomic) UITableView *tableView;
@property (nonatomic, retain) NSTimer  *upgradeTimer; // 升级计时器
@property (nonatomic, strong) FMDatabase *db;  //数据库
@end

@implementation UpgradeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.header = [Socket sharedInstance];
    self.header.delegate = self;
    self.btnArray = [[NSMutableArray alloc]init];
    self.listPack = [[NSMutableArray alloc] init];
    
    self.tableView = [[UITableView alloc]init];
    self.header.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.HUD = [[MBProgressHUD alloc]init];
    [self.HUD setMode:MBProgressHUDModeText];
    [self.view addSubview:self.HUD];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setAutoLayout];
    [self listGujian];
    
    self.k = 1;
    self.len = 0;
    self.datatimes = 0;
    
    //屏幕常亮
    [UIApplication sharedApplication].idleTimerDisabled = YES;
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

-(void)setAutoLayout{
    //标签：固件升级
    UILabel *labelGujianShenji = [[UILabel alloc]init];
    [self.view addSubview:labelGujianShenji];
    labelGujianShenji.sd_layout
    .topSpaceToView(self.view, 100)
    .autoHeightRatio(0)
    .centerXEqualToView(self.view);
    [labelGujianShenji setSingleLineAutoResizeWithMaxWidth:200];
    labelGujianShenji.font = [UIFont systemFontOfSize:30];
    [labelGujianShenji setTextColor:[UIColor  blackColor]];
    labelGujianShenji.text = @"固件升级";
    
    //标签：选择固件
    UILabel *labelXuanze = [[UILabel alloc]init];
    [self.view addSubview:labelXuanze];
    [labelXuanze setTag:101];
    labelXuanze.sd_layout
    .topSpaceToView(labelGujianShenji, 30)
    .autoHeightRatio(0)
    .leftSpaceToView(self.view, 20);
    [labelXuanze setSingleLineAutoResizeWithMaxWidth:500];
    labelXuanze.font = [UIFont systemFontOfSize:20];
    labelXuanze.text = @"选择固件:";
    
    [self.view addSubview:self.tableView];
    //tbView2.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [self.tableView.layer setCornerRadius:8.0];
    self.tableView.sd_layout
    .topSpaceToView(labelXuanze, 10)
    .heightIs(240)
    .leftSpaceToView(self.view, 10)
    .rightSpaceToView(self.view, 10);
    
    //标签：确定升级
    UIButton *btGuJianShengji = [[UIButton alloc]init];
    [self.view addSubview:btGuJianShengji];
    
    [btGuJianShengji setBackgroundImage:[self imageWithColor: [UIColor colorWithRed:54/255.0 green:65/255.0 blue:87/255.0 alpha:1]] forState :UIControlStateHighlighted];
    btGuJianShengji.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [btGuJianShengji.layer setCornerRadius:8.0];
    btGuJianShengji.sd_layout
    .topSpaceToView(self.tableView, 20)
    .heightIs(50)
    .widthRatioToView(self.view, 0.4)
    .centerXEqualToView(self.view);
    [btGuJianShengji setTitle:@"确定升级" forState:UIControlStateNormal];
    [btGuJianShengji addTarget:self action:@selector(confirmUPgrade) forControlEvents:UIControlEventTouchUpInside];
    
    //返回
    UIButton *goBack = [[UIButton alloc]init];
    [self.view addSubview:goBack];
    
    [goBack.layer setCornerRadius:8.0];
    goBack.sd_layout
    .topSpaceToView(btGuJianShengji, 20)
    .heightIs(50)
    .widthRatioToView(self.view, 0.4)
    .centerXEqualToView(self.view);
    [goBack setTitle:@"返回" forState:UIControlStateNormal];
    [goBack setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [goBack addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
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

#pragma mark - tableView代理

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    //return [self.vehicleLog count];
    return  [self.listPack count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:ID];
    }
    
    NSString *strPack = [NSString stringWithFormat:@"%@",self.listPack[indexPath.row]];
    //转换为显示字符串
    cell.textLabel.text = strPack;
    return cell;
}
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSIndexPath *oldIndex = [tableView indexPathForSelectedRow];
    [[tableView cellForRowAtIndexPath:oldIndex] setAccessoryType:UITableViewCellAccessoryNone];
    [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    return  indexPath;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.filenameOfFirm = [self.listPack objectAtIndex:indexPath.row];
    NSLog(@"firmToUpgrade:%@",self.filenameOfFirm);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"删除该固件";
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"删除");
        
        // 更新数据至文件
        //BOOL isSuccess = [NSKeyedArchiver archiveRootObject:self.contactList toFile:self.docPath];
        //NSLog(@"%@",isSuccess?@"保存成功":@"保存失败");
        //}
        NSFileManager *fileManger = [NSFileManager defaultManager];
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        NSString *documentPath = [documentPaths objectAtIndex:0];
        //NSError *error= nil;
        //NSArray *fileList= [[NSArray alloc] init];
        
        //更改到待操作的目录下
        [fileManger changeCurrentDirectoryPath:[documentPath stringByExpandingTildeInPath]];
      
        BOOL isSuccess = [fileManger removeItemAtPath:[self.listPack objectAtIndex:indexPath.row] error:nil];
        if(isSuccess){
            NSLog(@"删除成功");
        }else{
            NSLog(@"删除失败");
        }
        
        [self.listPack  removeObjectAtIndex:[indexPath section]];  //删除数组里的数据
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
}

#pragma mark 列出可选固件
-(void)listGujian{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"test.txt"];
    //NSLog(@"%@",filePath);
    
    NSString *text1 = @"leida";
    NSData *data = [text1 dataUsingEncoding: NSUTF8StringEncoding];
    if ([fileManager createFileAtPath:filePath contents:data attributes:nil]) {
        NSLog(@"Documents创建占位文件成功--");
    }
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *documentDir= [documentPaths objectAtIndex:0];
    NSError *error= nil;
    NSArray *fileList= [[NSArray alloc] init];
    
    fileList= [fileManager contentsOfDirectoryAtPath:documentDir error:&error];
    
    unsigned long  filenum = [fileList count];
    for(int i=0;i<filenum;i++){
        NSString *filename = [NSString stringWithFormat:@"%@",[fileList objectAtIndex:i]];
        if([filename containsString:@".Trash"]) continue;
        if([filename containsString:@"test"]) continue;
        if([filename containsString:@"sqlite"]) continue;
        NSLog(@"%@",[fileList objectAtIndex:i]);
        [self.listPack addObject:filename];
    }
}

#pragma  mark -固件选择
-(void)firmwareSelected:(UIButton *)sender{
    
    self.selectedBtn = sender;
    sender.selected = !sender.selected;
    
    for (NSInteger j = 0; j < [self.btnArray count]; j++) {
        UIButton *btn = self.btnArray[j] ;
        if (sender.tag == j+200) {
            btn.selected = sender.selected;
        }else {
            btn.selected = NO;
        }
    }
    NSLog(@"%@ selected!----",self.selectedBtn.currentTitle);
}

#pragma  mark -确定升级
-(void) confirmUPgrade{

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
    
    if(self.filenameOfFirm == nil){
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.HUD.mode = MBProgressHUDModeText;
        self.HUD.label.text= @"请先选择要升级的固件";
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:3];
        return;
    }else{
        //设计升级定时
        self.upgradeTimer = [NSTimer timerWithTimeInterval:240 repeats:NO block:^(NSTimer * _Nonnull timer) {
            //升级失败
            UIAlertController   *alert = [UIAlertController alertControllerWithTitle:@"升级失败" message:@"升级失败，请重启雷达，重新进行升级" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [self.HUD removeFromSuperview];
            }];
            [alert addAction:action];
            [self presentViewController:alert animated:YES completion:^{
                ;
            }];
        }];
        
        [[NSRunLoop currentRunLoop] addTimer:self.upgradeTimer forMode:NSRunLoopCommonModes];
        
    
        NSString *docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSString *filePath = [docPath stringByAppendingPathComponent:self.filenameOfFirm];
        NSData *dataOfFirm = [NSData dataWithContentsOfFile:filePath];
        self.len = [dataOfFirm length]/1024;
        if([dataOfFirm length]%1024 >0){
            self.len ++;
        }
        self.header.dataWrite = @"c1 00";
        self.header.tagWrite = 998;
        [self.header writeBoardWithTag:998];
        //self.datatimes = 0;
        
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

        self.HUD.mode = MBProgressHUDModeAnnularDeterminate;
        self.HUD.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.label.numberOfLines = 2;
        self.HUD.label.text= @"正在固件升级中……\n请不要离开本页面";
    }
}

#pragma mark 根据tag读取数据
- (void) OnDidReadDataWithTag:(long)Tag{
  //  if(Tag != self.header.tagWrite) return;
    if(Tag == 998){
        if([self.header.dataRead isEqual:@"C"]){
            NSLog(@"可以发送数据了！");
            [self senderData:1];
        }else{
            [self.header.socket readDataWithTimeout:-1 tag:998];
        }
    }
    
    const char *charRead = [self.header.dataRead UTF8String];
    if([self.header.dataRead length]==0) return;
    
    if(charRead[0] == ACK && self.k<self.len){
        NSLog(@"收到NAK--%ld",self.k);
        self.k++;
        [self senderData:self.k];
        self.HUD.progress = 1.0*self.k/self.len;
    }else if(charRead[0] == NAK && self.k<self.len){
        NSLog(@"发送失败，重新发送");
        [self senderData:self.k];
    }
    
    if(charRead[0] == ACK && self.k==self.len){  //结束
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:0];
        
        NSLog(@"数据发送完成！");
        Byte package[1] = {0};
        package[0] = EOT;
        NSData *endData = [NSData dataWithBytes:package length:1];
        self.header.socket.userData  = [NSNumber numberWithInt:SocketOfflineByServer];
        self.header.tagWrite = 1000;
        [self.header.socket writeData:endData withTimeout:-1 tag:1000];
        //[self.header.socket readDataWithTimeout:-1 tag:1000];
    }
    
    if( charRead[0] == ACK && Tag==1000){
        self.header.dataWrite = @"be 00";
        self.header.tagWrite = 1002;
        self.header.socket.userData  = [NSNumber numberWithInt:SocketOfflineByServer];
        [self.header writeBoardWithTag:1002];
        NSLog(@"升级完成！");
        
        //取消定时器
        [self.upgradeTimer invalidate];
        
        /*
        self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        //self.HUD.mode = MBProgressHUDModeText;
        self.HUD.mode = MBProgressHUDModeDeterminate;
        self.HUD.label.numberOfLines = 4;
        self.HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        self.HUD.bezelView.backgroundColor = [UIColor yellowColor];
        self.HUD.label.text= @"升级完成，等待雷达重启\n重启后请重新连接雷达\n点击重置按钮令雷达恢复出厂设置\n断电重启雷达后重新调试雷达";
        self.HUD.removeFromSuperViewOnHide = YES;
        [self.HUD hideAnimated:YES afterDelay:5];
         */
        //HUD改为alert
        UIAlertController   *alert = [UIAlertController alertControllerWithTitle:@"升级完成" message:@"升级完成，等待雷达重启\n重启后请重新连接雷达\n点击重置按钮令雷达恢复出厂设置\n断电重启雷达后重新调试雷达" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self dismissViewControllerAnimated:YES completion:^{
                            ;
            }];
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:^{
            ;
        }];
    }
}

#pragma mark 发送数据包
-(void) senderData:(long)k{
    
    NSString *docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *filePath = [docPath stringByAppendingPathComponent:self.filenameOfFirm];
    NSData *dataOfFirm = [NSData dataWithContentsOfFile:filePath];
    NSInteger lenOfFile = [dataOfFirm length];
    
    Byte *byteData = (Byte *)malloc(lenOfFile);
    memcpy(byteData,[dataOfFirm bytes],lenOfFile);
    
    Byte package[1029] = {0x1A};   //数据包
    package[0] = STH;
    package[1] = (Byte)k;
    package[2] = ~package[1];
    
    memcpy(&package[3],&byteData[1024*(k-1)],1024);
    uint16_t ccrc = crc16_xmodem(&package[3], 1024);
    
    package[1027] = (ccrc>>8) & 0xFF;
    package[1028] = ccrc &0xFF;
    
    NSData *dataSender = [NSData dataWithBytes:&package length:1029];
    self.header.tagWrite = 999;
    self.header.socket.userData  = [NSNumber numberWithInt:SocketOfflineByServer];
    [self.header.socket writeData:dataSender withTimeout:-1 tag:999];
    NSLog(@"发送第%ld个包",k);
    //}
}

-(void)goBack{
    
    [self dismissViewControllerAnimated:YES completion:^{

    }];
    
}

#pragma  mark -界面刷新
-(void)viewDidAppear:(BOOL)animated{
    self.header.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated{
    self.header.delegate = nil;
    self.HUD.removeFromSuperViewOnHide = YES;
    [self.HUD hideAnimated:YES afterDelay:0];
    [self.upgradeTimer invalidate];
    self.upgradeTimer = nil;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

@end
