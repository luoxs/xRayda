//
//  ViewController.m
//  xRayda
//
//  Created by apple on 2021/11/19.
//  Copyright © 2021 apple.gupt.www. All rights reserved.
//

#import "ViewController.h"
#import "Socket.h"
#import "SVProgressHUD.h"

@interface ViewController ()
@property (strong, nonatomic)Socket *header;
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.header = [Socket sharedInstance];
    self.header.delegate = self;
    //连接热点
    [self.header socketConnectHost];
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Connect",nil)];
}

//连接成功
-(void)onConnected{
   // [SVProgressHUD dismiss];
    NSLog(@"连接成功！------");
}
@end
