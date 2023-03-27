//
//  MoreViewController.m
//  xRayda
//
//  Created by apple on 2022/2/22.
//  Copyright © 2022 apple.gupt.www. All rights reserved.
//

#import "MoreViewController.h"
#import "FMDatabase.h"
#import "SDAutoLayout.h"
#import "MBProgressHUD.h"
#import "Socket.h"
#import "AdvanceViewController.h"
#import "LogViewController.h"
#import "UpgradeViewController.h"
#import "CopyRightViewController.h"

@interface MoreViewController ()<UITableViewDelegate,UITableViewDataSource,SocketDelegate>
@property (strong,nonatomic) Socket *header;
@property (nonatomic,strong) NSArray *titles;
@property (nonatomic,strong) UITableView *tableView;
@property (weak,nonatomic) NSTimer* timer;
@property  NSInteger stopScanTimes;
@property (nonatomic, strong) FMDatabase *db;  //数据库
@end

@implementation MoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.header = [Socket sharedInstance];
    self.tableView = [[UITableView alloc] init];
    if([self.header.typeRadar isEqualToString:@"fangza"]&[self.header.version isEqualToString:@"new"]){
        self.titles = [NSArray arrayWithObjects: @"高级设置",@"操作日志",@"软件升级",@"版本信息",nil];
    }else{
        self.titles = [NSArray arrayWithObjects: @"操作日志",@"软件升级",@"版本信息",nil];
    }
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.stopScanTimes = 0;
    [self setAutoLayOut];
}

#pragma  mark 布局
-(void) setAutoLayOut{

    UILabel *labelTitle = [[UILabel alloc]init];
    [self.view addSubview:labelTitle];
    labelTitle.sd_layout
    .topSpaceToView(self.view, 100)
    .heightIs(50)
    .centerXEqualToView(self.view);
    [labelTitle setSingleLineAutoResizeWithMaxWidth:200];
    labelTitle.font = [UIFont systemFontOfSize:24];
    [labelTitle setTextColor:[UIColor  blackColor]];

    labelTitle.text = @"更多设置";
    

    [self.view addSubview: self.tableView];
    [self.tableView.layer setCornerRadius:8.0];
    self.tableView.sd_layout
    .centerXEqualToView(self.view)
    .heightRatioToView(self.view, 0.25)
    .widthRatioToView(self.view, 0.8)
    .centerYEqualToView(self.view);
    self.tableView.backgroundColor = [UIColor whiteColor];
    
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    cell.textLabel.text = [self.titles objectAtIndex:indexPath.row];
    return cell;
}
*/

#pragma mark - tableView代理

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return  [self.titles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:ID];
    }
    //显示标题
    NSString *strTile = [self.titles objectAtIndex:indexPath.row];
    cell.textLabel.text = strTile;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.backgroundColor = [UIColor whiteColor];
    //显示图标
    UIImage *image = [UIImage imageNamed:@"house-7"];
    cell.imageView.image = image;
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.timer invalidate];
    self.timer = nil;

    AdvanceViewController *advanceViewController = [[AdvanceViewController alloc]init];
    [advanceViewController.view setBackgroundColor:[UIColor whiteColor]];
    LogViewController *logViewController = [[LogViewController alloc] init];
    [logViewController.view setBackgroundColor:[UIColor whiteColor]];
    UpgradeViewController *upgrageViewController = [[UpgradeViewController alloc] init];
    [upgrageViewController.view setBackgroundColor:[UIColor whiteColor]];
    CopyRightViewController *copyrightViewController = [[CopyRightViewController alloc] init];
    [copyrightViewController.view setBackgroundColor:[UIColor whiteColor]];
    
    if([self.titles[indexPath.row] isEqualToString:@"高级设置"]){
        [self showViewController:advanceViewController sender:self];
    }else if([self.titles[indexPath.row] isEqualToString:@"操作日志"]){
        [self showViewController:logViewController sender:self];
    }else if([self.titles[indexPath.row] isEqualToString:@"软件升级"]){
        [self showViewController:upgrageViewController sender:self];
    }else{
        [self showViewController:copyrightViewController sender:self];
    }
}

- (void) OnDidReadDataWithTag:(long)Tag{
    //仅为占位
}

-(void) onConnectFailed{
    NSLog(@"重连网络失败！");
}
-(void) onConnected{
    NSLog(@"重新连接网络成功！");
}


-(void) viewWillAppear:(BOOL)animated{
    /*
        if([self.header.socket isConnected]){
            self.header.dataWrite = @"a9 00";
            self.header.tagWrite = 8100;
            [self.header writeBoardWithTag:8100];
        }
    */
}


-(void)viewWillDisappear:(BOOL)animated{
    [self.timer invalidate];
    self.timer = nil;
    [self refresh];
}

-(void) refresh{
    [self.timer invalidate];
    self.timer = nil;
    
    if([self.header.socket isConnected]){
        self.header.dataWrite = @"c0 01";
        self.header.tagWrite = 1299;
        [self.header writeBoardWithTag:1299];
        NSLog(@"writeBoard with tag ---%d",1299);
    }
}


-(void)viewDidAppear:(BOOL)animated{
    self.header.delegate = self;
    
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
        if(self.stopScanTimes > 10){
            [self.timer invalidate];
            self.timer = nil;
            self.stopScanTimes = 0;
        }
    }];
    //[self refresh];
}


-(void)dealloc{
    [self.timer invalidate];
    self.timer = nil;
}
@end
