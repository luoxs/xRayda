//
//  Socket.h
//  demoSocket
//
//  Created by 罗 显松 on 2017/6/24.
//  Copyright © 2017年 neusoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t onceToken = 0; \
__strong static id sharedInstance = nil; \
dispatch_once(&onceToken, ^{ \
sharedInstance = block(); \
}); \
return sharedInstance; \

@protocol SocketDelegate <NSObject>
@optional
- (void) onScanStart; //开始扫描
- (void) onScanStop; //停止扫描
- (void) onScanNotFound; //未找到设备
- (void) onConnectFailed; //连接失败
- (void) onConnected; //连接成功
- (void) onConnectBreak; //连接断开
- (void) OnDidReadDataWithTag:(long)Tag; //更新数据
- (void) OnDataError; //写数据错或者读数据错
@end

@interface Socket : NSObject<GCDAsyncSocketDelegate>
@property (nonatomic,strong) GCDAsyncSocket *socket;  // socket
@property (nonatomic,copy) NSString *socketHost;   // socket的Host
@property (nonatomic,assign) UInt16 socketPort;    // socket的prot

@property (nonatomic,strong) id<SocketDelegate>delegate;
@property (nonatomic,strong) NSString  *dataWrite;
@property (nonatomic,strong) NSString *dataRead;
@property (nonatomic,strong) NSArray *strsReset; //刷新参数
@property (nonatomic,strong) NSString  *strsVersion; //版本
@property (nonatomic,strong) NSMutableString *longData;

@property  long tagWrite;
@property  (nonatomic,strong) NSString *typeRadar;
@property  int orietion;   //来车方向有效
@property  int signalout;  //信号输出方式
@property  (nonatomic,strong) NSString *version; //旧版或新版
@property  (nonatomic,strong) NSString *user; //用户
@property  (nonatomic,strong) NSString *BSSID; //设备MAC地址

-(void)socketConnectHost;// socket连接
-(void)cutOffSocket; // 断开socket连接
-(void) writeBoardWithTag:(long)Tag;

+ (Socket *)sharedInstance;
@property (nonatomic, retain) NSTimer  *connectTimer; // 计时器
enum{
    SocketOfflineByServer,// 服务器掉线，默认为0
    SocketOfflineByUser,  // 用户主动cut,为1
};
@end





