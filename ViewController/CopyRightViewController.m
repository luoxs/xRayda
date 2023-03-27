//
//  CopyrightViewController.m
//  xRayda
//
//  Created by apple on 2022/3/4.
//  Copyright © 2022 apple.gupt.www. All rights reserved.
//

#import "CopyRightViewController.h"
#import "FMDatabase.h"
#import "SDAutoLayout.h"
#import "AFNetworking.h"
#import "MBProgressHUD.h"

@interface CopyRightViewController ()
@property (nonatomic, strong) FMDatabase *db;  //数据库
@end

@implementation CopyRightViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setAutoLayout];
    
   // [self checkVersion];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)setAutoLayout{
    
    UILabel *labelCopyright = [[UILabel alloc]init];
    [self.view addSubview:labelCopyright];
    labelCopyright.sd_layout
    .topSpaceToView(self.view, 100)
    .heightIs(50)
    .centerXEqualToView(self.view);
    [labelCopyright setSingleLineAutoResizeWithMaxWidth:200];
    labelCopyright.font = [UIFont systemFontOfSize:24];
    [labelCopyright setTextColor:[UIColor  blackColor]];
    NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    labelCopyright.text = [NSString stringWithFormat:@"当前版本：%@",currentVersion];
    
    UIButton *btCheck = [[UIButton alloc]init];
    [self.view addSubview:btCheck];
    [btCheck.layer setCornerRadius:8.0];
    btCheck.sd_layout
    .topSpaceToView(labelCopyright, 20)
    .heightIs(50)
    .widthRatioToView(self.view, 0.3)
    .leftSpaceToView(self.view,10);
    //.centerXEqualToView(self.view);
    [btCheck setTitle:@"检查更新" forState:UIControlStateNormal];
    [btCheck setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btCheck addTarget:self action:@selector(checkVersion:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *labelCheck = [[UILabel alloc]init];
    [self.view addSubview:labelCheck];
    labelCheck.sd_layout
    .topSpaceToView(labelCopyright, 20)
    .heightIs(100)
    .widthRatioToView(self.view, 0.5)
    .leftSpaceToView(btCheck, 5);
    //.centerXEqualToView(self.view);
    //[labelCheck setSingleLineAutoResizeWithMaxWidth:200];
    labelCheck.font = [UIFont systemFontOfSize:18];
    [labelCheck setTextColor:[UIColor  blackColor]];
    [labelCheck setTag:101];
    labelCheck.numberOfLines = 0;
    labelCheck.textAlignment = NSTextAlignmentCenter;
    labelCheck.lineBreakMode = NSLineBreakByWordWrapping;
    labelCheck.text = @"请先切换为可用互联网后检查更新或进入AppStore检查更新";
    
  
    UIButton *goBack = [[UIButton alloc]init];
    [self.view addSubview:goBack];
    [goBack.layer setCornerRadius:8.0];
    goBack.sd_layout
    .topSpaceToView(labelCheck, 20)
    .heightIs(50)
    .widthRatioToView(self.view, 0.4)
    .centerXEqualToView(self.view);
    [goBack setTitle:@"返回" forState:UIControlStateNormal];
    [goBack setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [goBack addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    
}

-(void) checkVersion: (id) sender{
    //NSString *kAppID = @"1618737665";
    UILabel *labelNotice = (UILabel *)[self.view viewWithTag:101];
    
    MBProgressHUD  *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [HUD setMode:MBProgressHUDModeIndeterminate];
    HUD.label.textColor = [UIColor blueColor];
    HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    HUD.bezelView.backgroundColor = [UIColor yellowColor];
    HUD.label.text= @"正在连接服务器";
    
    NSString *url = @"http://itunes.apple.com/cn/lookup?id=1618737665";
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/javascript", nil];
    
    //设置超时时间
    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
     manager.requestSerializer.timeoutInterval = 10.0f;
    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    
    [manager POST:url parameters:nil headers:nil progress:^(NSProgress * _Nonnull uploadProgress) {
       HUD.mode = MBProgressHUDModeText;
       HUD.label.text= @"正在连接";
       NSLog(@"-------%@",uploadProgress);
    
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *newVersion = responseObject[@"results"][0][@"version"];//获取版本号
       // NSLog(@"%@",responseObject);
        NSLog(@"%@",newVersion);
        
        HUD.mode = MBProgressHUDModeText;
        HUD.label.text= @"连接成功";
        HUD.label.textColor = [UIColor blueColor];
        HUD.removeFromSuperViewOnHide = YES;
        [HUD hideAnimated:YES afterDelay:0];
        
        NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];  //获取本地版本号
        
        if (![currentVersion isEqualToString:newVersion]) { //比较是否相等
            NSLog(@"有新版本，请更新到最新版本！！！");
            labelNotice.text = @"有新版本";
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"发现新版本" message:@"有新版本，是否更新？" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action1= [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
            }];
            
          
             UIAlertAction *action2= [UIAlertAction actionWithTitle:@"去更新" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                [ [UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://apps.apple.com/us/app/%E9%9B%B7%E8%BE%BE%E5%8A%A9%E6%89%8B/id1618737665"]];

             }];
            
            [alert addAction:action1];
            [alert addAction:action2];
            [self presentViewController:alert animated:YES completion:^{
            }];
            
        } else {
            NSLog(@"已是最新版本！！！");
            labelNotice.text = @"已是最新版";
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"错误");
        HUD.mode = MBProgressHUDModeText;
        HUD.label.text= @"连接服务器失败,请检查网络连接";
        HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
        HUD.bezelView.backgroundColor = [UIColor yellowColor];
        HUD.label.textColor = [UIColor blueColor];
        HUD.removeFromSuperViewOnHide = YES;
        [HUD hideAnimated:YES afterDelay:5];
    }];
}


-(void)goBack{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

@end
