//
//  Socket.m
//  demoSocket
//
//  Created by 罗 显松 on 2017/6/24.
//  Copyright © 2017年 neusoft. All rights reserved.
//
#import "Socket.h"
@implementation Socket

#pragma mark  - 单例
+ (Socket *) sharedInstance
{
    static Socket *sharedInstace = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstace = [[self alloc] init];
    });
    return sharedInstace;
}

#pragma mark  - 初使化socket
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
       // self.socket = [[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:nil];
    }
    self.socketPort = 8080;
    return self;
}

#pragma mark  - 连接雷达
-(void)socketConnectHost{
    self.socketHost = @"192.168.4.1";
    //必须确认在断开连接的情况下，进行连接
    if (self.socket.isConnected) {
        [self.socket disconnect];
    }
    [self.socket connectToHost:self.socketHost onPort:self.socketPort withTimeout:1 error:nil];
}

#pragma mark  - 连接成功回调
-(void) socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    [self.connectTimer invalidate];
    NSLog(@"socket连接成功---");
    [self.delegate onConnected];
}

#pragma mark  - 断开之后回调
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"the error is %@",err);
    NSLog(@"sorry the connect is failure %@,socket连接断开---",sock.userData);
    
    if (err.code == 3) {
           NSLog(@"connection refused");
           self.socketPort = 8848;
           [self socketConnectHost];
       }

    //这里可以列举枚举值
    //因用户自动断开 不自动连接
    if (sock.userData == [NSNumber numberWithInt:SocketOfflineByUser])  {
        [self.connectTimer invalidate];
        self.connectTimer = nil;
        //[self.socket setDelegate:nil];
        [self.socket disconnect];
        [self.delegate onConnectFailed];
        NSLog(@"用户自己断开，不重连");
    }
    //因服务器原因断开 自动连接
    else if (sock.userData == [NSNumber numberWithInt:SocketOfflineByServer]) {
        [self.connectTimer invalidate];
        self.connectTimer = nil;
        [self.socket setDelegate:nil];
        [self.socket disconnect];
        [self.socket setDelegate:self];
       // [self.socket connectToHost:self.socketHost onPort:self.socketPort error:nil];
        //[NSThread sleepForTimeInterval:0.06];
        [self socketConnectHost];
        NSLog(@"服务器原因断开，自动重连");
    //因Wifi原因断开 不自动连接
    }
    else{
        [self.connectTimer invalidate];
        self.connectTimer = nil;
        //[self.socket setDelegate:nil];
       // [self.socket disconnect];
        //[self.delegate onConnectFailed];
      //  [NSThread sleepForTimeInterval:0.06];
        //[self socketConnectHost];
        NSLog(@"不明原因断开，不自动重连");
    }
    if(self.socketPort == 8848){
        [self.delegate onConnectFailed];
    }
}

#pragma mark - 切断socket
-(void)cutOffSocket{
    self.socket.userData = [NSNumber numberWithInt:SocketOfflineByUser];
    [self.connectTimer invalidate];
    [self.socket disconnect];
}


#pragma mark - 写数据
-(void) writeBoardWithTag:(long)tag{    

    //写数据
    NSData *data =[self.dataWrite  dataUsingEncoding:NSUTF8StringEncoding];
   
    self.socket.userData  = [NSNumber numberWithInt:SocketOfflineByServer];
    [self.socket writeData:data withTimeout:2 tag:tag];
}


#pragma mark  - 读数据
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    //写数据成功，开始读
    
    if(tag != 8100){
    //    [NSThread sleepForTimeInterval:0.2];
        sock.userData = [NSNumber numberWithInt:SocketOfflineByServer];
        [self.socket readDataWithTimeout:3 tag:tag];
    }
}

#pragma mark - 读数据
-(void) socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //读数据
    sock.userData = [NSNumber numberWithInt:SocketOfflineByServer];
    
    NSString * str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Socket read data on tag %ld %@:",tag,str);
    
   //升级
    if(tag == 998 | tag == 999 | tag==1000 | tag == 1002){
        self.dataRead = str;
        [self.delegate OnDidReadDataWithTag:(long)tag];
        return;
    }
    
    if(((tag == 1308)|(tag == 1309)) & (str.length < 10)){
        return;
    }
    
    NSAssert([str length]>=9, @"socket收到的字符串长度不够");
    
    if([[str substringToIndex:7] isEqualToString:@"UpDataF"]){
        tag = 1001;
    }
    if([[[str componentsSeparatedByString:@":"] objectAtIndex:0] isEqualToString:@"InSightWave"]){
          tag = 1100;
      }
    
    if([[str substringToIndex:3] isEqualToString:@"SN1"]& (self.tagWrite ==1103)){
        tag = 1103;
    }
    
    if([[str substringToIndex:3] isEqualToString:@"SN1"] &(self.tagWrite == 1104)){
        tag = 1104;
    }
    
    if([[str substringToIndex:7] isEqualToString:@"AllMode"]|[[str substringToIndex:7] isEqualToString:@"CarMode"]|[[str substringToIndex:7] isEqualToString:@"WorkMod"]){
        tag = 1210;
        if([[str componentsSeparatedByString:@"\r\n"] count]>=9) tag=1299;
    }
    
    if([[str substringToIndex:8]  isEqualToString:@"VehandPd"]){
        tag = 1215;
    }
    
    if([[str substringToIndex:8]  isEqualToString:@"SetRange"]){
        tag = 1220;
    }
    if([[str substringToIndex:7]  isEqualToString:@"Protect"]){
        tag = 1230;
    }
    
    if([[str substringToIndex:7]  isEqualToString:@"UpRiseT"]){
        tag = 1240;
    }
    
    if([[str substringToIndex:9] isEqualToString:@"FreqTable"]){
        tag = 1250;
    }
    
    if([[str substringToIndex:9] isEqualToString:@"ClearnBar"]){
        tag = 1260;
    }
    
    if([[str substringToIndex:7] isEqualToString:@"BarLeft"]|[[str substringToIndex:7] isEqualToString:@"BarRigh"]|[[str substringToIndex:7] isEqualToString:@"BrakeSh"]){
        tag = 1270;
    }
    //触发雷达刷新
    if([[str substringToIndex:7] isEqualToString:@"WorkMod"]&([[str componentsSeparatedByString:@"\r\n"] count]>=9)){
        tag = 1299;
    }
    
    if([[str substringToIndex:9] isEqualToString:@"CFarAmpNo"]){
        tag = 1308;
    }
    
    if([[str substringToIndex:9] isEqualToString:@"BackPoint"]){
        tag = 1309;
    }
    
    
    if([str isEqualToString:@"DoubleSide\r\n"]|[str isEqualToString:@"LeftSide\r\n"]|[str isEqualToString:@"RightSide\r\n"]){
        tag = 5100;
    }
    
    if([str isEqualToString:@"SignOutDG\r\n"]|[str isEqualToString:@"SignOutSafe\r\n"]){
        tag = 5200;
    }

    switch(tag){
            
        case 1304:
            [self.longData appendString:str];
           // NSLog(@"Socket read data on tag %ld %@:",tag,str);
            if([self.longData length]<2392){
                [self.socket readDataWithTimeout:-1 tag:1304];
            }else{
                [self.delegate OnDidReadDataWithTag:(long)tag];
            }
            break;
            
        case 1308:
            [self.longData appendString:str];
            [self.socket readDataWithTimeout:-1 tag:1308];
            long count1 = [[self.longData componentsSeparatedByString:@","] count];
            if(count1>=10){
                [self.delegate OnDidReadDataWithTag:(long)tag];
            }
            break;
            
        case 1309:
            [self.longData appendString:str];
            [self.socket readDataWithTimeout:-1 tag:1309];
            long count2 = [[self.longData componentsSeparatedByString:@","] count];
            if(count2>=96){
                [self.delegate OnDidReadDataWithTag:(long)tag];
            }
            break;
        case 8000:
            self.dataRead = str;
            [self.delegate OnDidReadDataWithTag:(long)tag];
            //sleep(0.5);
            [self.socket readDataWithTimeout:1 tag:8000];
            break;
        case 8100:
            //[self.delegate OnDidReadDataWithTag:(long)tag];
            break;
        case 1299:
            self.dataRead = str;  //只能读一次，否则错误
            [self.delegate OnDidReadDataWithTag:(long)tag];
          //  [self.socket readDataWithTimeout:-1 tag:1299];
            break;
        default:
            //NSLog(@"Socket read data on tag %ld %@:",tag,str);
            self.dataRead = str;
            [self.delegate OnDidReadDataWithTag:(long)tag];
           // [self.socket readDataWithTimeout:-1 tag:tag];
            break;
    }
}

@end
