//
//  ViewController.m
//  UDP通信
//
//  Created by shinetech on 2016/12/28.
//  Copyright © 2016年 shinetech. All rights reserved.
//  https://github.com/flycl/Test_DataAPI.git

#import "ViewController.h"
#import "SocketNet_API.h"
#import "AsyncUdpSocket.h"//UDP库



//UDP库代理
@interface ViewController ()<AsyncUdpSocketDelegate>{
    bool    timeOut;
    int     logintimes;
}

//@property (nonatomic, strong) AsyncUdpSocket *sendSocket;//发送 Socket

@property (nonatomic, strong) AsyncUdpSocket *recvSocket;//接收 Socket

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //UIButton
    //
    [self createBtn];
    
    [self createSocket];
}

-(void)createBtn{
    UIButton *sendBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 250, self.view.bounds.size.width, 40)];
    sendBtn.backgroundColor = [UIColor grayColor];
    [sendBtn setTitle:@"发送初始化" forState:UIControlStateNormal];
    [sendBtn addTarget:self action:@selector(sendDataBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendBtn];
}

-(void)createSocket{
    //接收端 Socket
    //发送端 Socket
    _recvSocket = [[AsyncUdpSocket alloc]initWithDelegate:self];
    //绑定端口
    [_recvSocket bindToPort:10034 error:nil];
    //监听接收数据
    [_recvSocket receiveWithTimeout:-1 tag:100];
}


-(void)sendDataBtn{
    //创建一个包 NSData


    NSData *converData = [NSData new];
    // 入参，返回Data发送
    
    [_recvSocket sendData:converData toHost:@"211.139.198.78" port:10034 withTimeout:-1 tag:20];
}

#pragma mark - Delegate

//didSendData
- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    NSLog(@"发送-数据完成");
}

//didReceiveData
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port{
    //NSLog(@"接收-数据完成");
    //去帧头、帧尾－》去转义处理－》校验数据包长度  validatePackage
    //NSLog(@"[self validatePackage:data]%@",[self validatePackage:data]);
    //提取协议内容－》按协议处理  checkProtrol:
    
    
    [self checkProtrol:[self validatePackage:data]];
    
    //改方法，只入Data参数 返回Dict 功 Array
    
    return YES;
}



#pragma mark - udp返回信息分类



@end
