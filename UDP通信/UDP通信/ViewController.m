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
    NSMutableData *tempData = [NSMutableData data];
    //登陆类型 0x01:单台车辆监控用户登陆
    Byte *loginTypeByte = (Byte *)[self intToByteArray:0x01  Len:1];
    //Bytes 添加到 Data
    [tempData  appendBytes:loginTypeByte length:1];
    //添加到NSData 后释放 Byte. 
    if (loginTypeByte){
        // 释放
        // NSLog(@"free - appdelegate - loginTypeByte - 2");
        free(loginTypeByte);
    }
   
    NSString *username = [NSString stringWithFormat:@"%@ %@",[@"蓝"  stringByReplacingOccurrencesOfString:@"色" withString:@""],@"宁测试"];
    //NSString *username = [NSString stringWithFormat:@"%@",@"13620021079"];
    
    NSLog(@"发送内容 %@",username);
    //字符串转
    [tempData  appendData:[self packageConvertFromNSString:username]];
    /*
     *  添加协议字 0x0103 添加协议字，并添加帧头、帧尾
     */
    NSData *converData = [self packageConvertFromData:tempData andProtocal:0x0103];
    
    NSLog(@"发出的Byte包 - %@",converData);
    //发送数据 
    //测试 发送内容
   
    BOOL res = [_recvSocket sendData:converData toHost:@"211.139.198.78" port:10034 withTimeout:-1 tag:20];
    if (res){
        NSLog(@"发送成功");
    }else{
        NSLog(@"发送失败");
    }

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
//    timeoutBo = kno;
//    logoutBo = kno;
//    [self.udpSocket receiveWithTimeout:-1 tag:0];
    return YES;
}

#pragma mark - DataPream
/**
 * 本协议所有字节采用大端字节（big-endian），即高位在前，低位在后
 * 要free
 *
 右移八位
 @param iSource 内容长度
 @param iArrayLen 数组长度
 @return Byte
 */
-(void *)intToByteArray:(int) iSource  Len:(int) iArrayLen{
    //malloc
    Byte  *theByte = (Byte *) malloc(iArrayLen *sizeof(Byte)) ;
    for ( int i = 0;i < iArrayLen; i++){
        theByte[iArrayLen - 1 - i] = (iSource>>8*i & 0xFF );
    }
    return theByte;
}

//转义 字符
-(NSData*)packageConvertFromData:(NSData*)data  andProtocal:(int)thePrototcal{
    ////try 非二进制数据，且  协议字小于0，返回 空包
    if (!data || (!(thePrototcal > 0))){
        return [NSMutableData  data];
    }
    //数据内容长度
    int bytesLength = data.length;
    
    /*
     *  ************************    malloc  convertBytes 为主线     ************************
     */
    //  新建一个包 Byte 包大小为 内容长度+1400
    
    Byte *convertBytes =(Byte *) malloc(bytesLength + 1400 );
    
    int totalConverBytes = 0;
    
    //**0位置  包   添加帧头
    convertBytes[totalConverBytes] = 0x7e ;
    //包位置后移
    totalConverBytes++;
    
    //**myData  数据包长度
    //添加 数据包长度 =（除帧头、帧尾的长度） |Byte 数组| bytesLength +4 --> 4 == 数据包长度(2)+协议编号(2)
    NSMutableData *myData = [NSMutableData data];
    
    Byte * protocalByte = (Byte *)[self intToByteArray:bytesLength +4 Len:2];
    
    //添加到发送Data 数据包长度  将一个长length的byte数组append 进去
    [myData  appendBytes:protocalByte length:2];
    
    //**myData 添加 协议字 协议编号
    protocalByte    = (Byte *)[self intToByteArray:thePrototcal Len:2];
    [myData   appendBytes:protocalByte length:2];
    //malloc 释放
    if (protocalByte){
        free(protocalByte);
    }
    //添加     内容
    [myData  appendData:data];
    //Data  转 Byte.
    Byte *bytes = (Byte *)[myData bytes];
    
    //Data 转Byte Byte 转入包
    for (int i = 0 ; i< bytesLength +4 ; i++)
    {
        /**
         *  发送时，在帧头7EH和帧尾7FH之间的数据出现的7DH、7EH、7FH分别与20H异或， 
         *  变成（5DH、5EH、5FH）再在前加7DH，如一个字节是7DH，经过转义后变为7DH，5DH。
         */
        
        if (bytes[i] == 0x7d ||  bytes[i] == 0x7e || bytes[i] == 0x7f )
        {
            convertBytes[totalConverBytes] = 0x7d;
            totalConverBytes ++;
            
            convertBytes[totalConverBytes] = bytes[i] ^ 0x20;
            totalConverBytes ++;
        }
        /**
         *  Data 转Byte Byte 转入包
         */
        else
        {
            convertBytes[totalConverBytes] = bytes[i];
            totalConverBytes ++;
        }
        
    }
    //**尾位置   添加帧尾
    convertBytes[totalConverBytes] = 0x7F;
    
    //发送包总长度
    totalConverBytes++;
    
    
    NSData *theData = [[NSData alloc] initWithBytes:convertBytes length:totalConverBytes];
    
    if (convertBytes)
    {
        free(convertBytes);
    }
    return theData;
}
/**
 字符串转Byte Data进制包
 @param dataString 字符串
 @return Byte  类型NSData
 */
-(NSData*)packageConvertFromNSString:(NSString*)dataString{
    
    NSString *dataString_ = [dataString mutableCopy];
    // 非空返回
    
    if (!dataString_) {
        return [NSMutableData    data];
    }
    //字符串-> 二进制->Byte -> 二进制长度转  ，二进制长度转New Byte.
    
    //字符转二进制 GBK码
    NSData *aData = [dataString_ dataUsingEncoding: CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
    //数据长度
    NSLog(@"%d",aData.length);
    NSInteger  datalength  = aData.length;
    //二进制 转 Byte(字节数）
    Byte *myBytec = (Byte *)[aData  bytes];
    NSLog(@"%hhu",myBytec[2]);
    // 开辟Byte空间 由dataLength
    Byte *datebuye = (Byte *) malloc(datalength + 1);
    
    //
    datebuye[0] = datalength;
    //二进制 存入Bytes
    for (int i = 0; i < datalength; i ++){
        datebuye[i + 1] = myBytec[i];
    }
    // Byte 转 数据流 返回
    NSData *returnDatac = [NSData dataWithBytes:datebuye length:datalength + 1];
    //释放临时空间
    free(datebuye);
    
    return returnDatac;
}



/**
 去帧头、帧尾－>去转义处理－>校验数据包长度
 
 @param receiveData 接收数据
 @return Dict
 */
-(NSDictionary*)validatePackage:(NSData*)receiveData{
    /**
     *  接收到包长度 小于5 大于 1400 返回重新接收
     */
    int totalLength = receiveData.length;
    //验证 包大小
    if (totalLength <=5  || totalLength >1400) {
        return nil;
    }
    /**
     *  包数据二进制 转 Byte
     */
    Byte *receiveBytes  = (Byte*)[receiveData  bytes];
    
    //验证 帧头帧尾 0x7e 126，0x7f 127
    if (receiveBytes[0] == 126  && receiveBytes[totalLength - 1] == 127)
    {
        if ((Byte *)malloc(sizeof(Byte) * 1400)){}
        
        Byte *covertedBytes = (Byte *)malloc(sizeof(Byte) * 1400);
        //包指针位
        int covertByteLength = 0;
        //下一步指示器
        BOOL convertNext = false;
        
        // check convertBytes
        // 遍历包内容
        for (int i = 1 ; i < totalLength -1 ; i++) {
            /**
             125 <-> 7DH <-> 0x7d 接收时，
             在帧头7EH和帧尾7FH之间的数据出现的7DH，
             表示后一个字符需去转义处理，丢弃7DH，
             后一个字符与20H异或，
             恢复发送时被转义的7DH、7EH、7FH
             */
            if (receiveBytes[i] == 125 && !convertNext) {
                
                // [needConvertBytes   addObject:[NSNumber numberWithInt:i]];
                //有20H异变，改指示器
                convertNext = true;
                
            }else {
                
                //有20异变处理
                if (convertNext) {
                    covertedBytes[covertByteLength] = receiveBytes[i] ^ 32 ;
                    covertByteLength ++;
                    convertNext = false;
                }
                // 正常处理
                else{
                    covertedBytes[covertByteLength] = receiveBytes[i];
                    covertByteLength ++;
                }
                
            }
        }
        
        //
        int   serverTotalLength = covertedBytes[1] + covertedBytes[0] *256;
        
        //长度 验证  （除包头 尾 长度）  看 解包在哪  +86
        if (covertByteLength == serverTotalLength)
        {
            /** eg.
             {
             protocolType = 260;//十进制 260 -> 0x104
             content = <0109c0b6 20c4feb2 e2cad401 20351789 0448d325 50083d7b 79e27300 b87cb55e 06bfe921 b0274ca6 394a7a41 70>;
             }
             */
            //解出<-->协议字
            int protocolType =  covertedBytes[3] + covertedBytes[2] *256;
            
            Byte *contentBytes =(Byte *) malloc(1400);
            
            for (int i = 4 ; i < covertByteLength; i++)
            {
                contentBytes[i-4] = covertedBytes[i];
            }
            //解出<-->内容
            NSData *content = [NSData dataWithBytes:contentBytes length:covertByteLength-4];
            
            if (covertedBytes) free(covertedBytes);
            
            if (contentBytes ) free(contentBytes);
            
            NSDictionary *dic = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects:[NSNumber numberWithInt:protocolType],content, nil] forKeys:[NSArray arrayWithObjects:@"protocolType",@"content", nil]];
            
            NSLog(@"validatePackage -- %@",dic);
            
            return dic;
        }else{
            if (covertedBytes) {
                NSLog(@"free - appdelegate - contentBytes2 - 1");
                free(covertedBytes);
                NSLog(@"free - appdelegate - contentBytes2 - 2");
            }
            return nil;
        }
        
    }
    else
    {
        return nil;
    }
    
    
    
}

#pragma mark - udp返回信息分类

/**
 提取协议内容－>按协议处理。
 
 @param theProtocol 传入字典
 */
-(void)checkProtrol:(NSDictionary *)theProtocol{
    
    if (!theProtocol) {
        return ;
    }
    
    int protocol  = [[theProtocol objectForKey:@"protocolType"] intValue];
    //    十进制转十六进制 按协议字处理 eg.  260 -> 104H
    
    NSLog(@"theProtocol   %x ",protocol);
    
    //    NSLog(@"content   %@ ",[theProtocol objectForKey:@"content"]);
    
#if 1
    switch (protocol) {
            
            //空车列表
            //申请登录反馈
        case 0x0104:
            [self receiveDataForLoginFeedback:[theProtocol objectForKey:@"content"]];
            break;
            
            //            //注册用户登录反馈
            //        case 0x00000106:
            //            [logonFeedbackDelegate receiveDataForLogonFeedback:[theProtocol objectForKey:@"content"]];
            //            break;
            //            //退出登录
            //        case 0x0108:
            //            isLogged = false;
            //            NSLog(@"logout");
            //            [logoutFeedbackDelegate receiveDataForLogoutFeedback:[theProtocol objectForKey:@"content"]];
            //            break;
            //预约结果
            //
            //            //以下为车辆监控
            //            //车辆列表
            //        case 0x0202:
            //
            //            ///
            //
            //            [carListFeedbackDelegate receiveDataForCarListFeedback:[theProtocol objectForKey:@"content"]];
            //            break;
            //            //车辆基本信息
            //        case 0x0204:
            //
            //            [carStatusDelegate receiveDataForCarStatus:[theProtocol objectForKey:@"content"]];
            //            break;
            //            //车辆定位状态 信息
            //        case 0x0206:{
            //            [carLocationStatusDelegate receiveDataForCarLocationStatus:[theProtocol objectForKey:@"content"]];
            //        }
            //            break;
            //            //车辆历史轨迹
            //        case 0x0208:
            //
            //            [historyImpressionDelegate receiveDataForHistoryImpression:[theProtocol objectForKey:@"content"]];
            //            break;
            //            // 终端操作结果
            //        case 0x020a:
            //
            //            canOperate = true;
            //            [carOperateFeedbackDelegate receiveDataForCarOperateFeedback:[theProtocol objectForKey:@"content"]];
            //            break;
            //            // 路况列表
            //        case 0x020d:
            //
            //            [roadStatusDelegate receiveDataForRoadStatus:[theProtocol objectForKey:@"content"]];
            //            break;
            //            //厂商信息
            //        case 0x020e:
            //
            //            NSLog(@"0x020e ");
            //            [messageListDelegate receiveDataForMessageList:[theProtocol objectForKey:@"content"]];
            //
            //            //通信保持
            //        case 0x0107:
            //
            //            NSLog(@"keep alive");
            //            if ([keepAliveDelegate respondsToSelector:@selector(receiveDataForKeepAlive:)]) {
            //                [keepAliveDelegate receiveDataForKeepAlive:[theProtocol objectForKey:@"content"]];
            //            }
            //
            //            break;
            //            //more feedback 	企业车辆定位状态
            //        case 0x0210:
            //        {
            //            NSDictionary *dic = [NSDictionary dictionaryWithObject:[theProtocol objectForKey:@"content"] forKey:@"car0210Data"];
            //            // NSLog(@"carOperateMoreFeedbackDelegate 　-　%@",dic);
            //
            //            [[NSNotificationCenter defaultCenter] postNotificationName:@"mtncar0210" object:self userInfo:dic];
            //
            //        }
            //            break;
            //通信保持
        default:
            NSLog(@"default");
            break;
    }
    
#endif
    
}

//申请登陆反馈
-(void)receiveDataForLoginFeedback:(NSData*)data{
    
    @try {
        
        NSDictionary *dic;
        
        //    NSLog(@"receiveDataForLoginFeedback - %@",dic);
        
        if (data.length < 22){
            //MING 添加
            dic = [NSDictionary dictionaryWithObject:@"连接超时" forKey:@"loginInfo"];
        }
        else{
            /**
             *  解包
             */
            dic=  [self unpackageForLogin:data];
            
            NSLog(@"1== %d %@",data.length,data);
        }
        
        NSLog(@"dic--%@--",dic);
        
        //        NSString *username = [[NSString  alloc] initWithBytes:packageBytes length:userNameLong encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
        //  
        if (!dic){
            return;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"[exception ] %@",exception);
    }
    @finally {
        
    }
}

// 解包。。登录反馈 注册反馈也是一样
-(NSDictionary*)unpackageForLogin:(NSData*)packageData{
    //登陆类型
    Byte *packageBytes = NULL;
    packageBytes = (Byte *)[packageData bytes];
    
    //NSLog(@"%s",packageBytes);
    //NSLog(@"%c",packageBytes[0]);
    
    
    
    //c0b620c4feb2e2cad4
    //包内容，第0个Byte.
    int loginType = packageBytes[0];
    NSLog(@"--1--%d",loginType);//1
    packageBytes++;
    
    NSLog(@"%s",packageBytes);
    
    int userNameLong = packageBytes[0];
    NSLog(@"--2--%d",userNameLong);
    packageBytes++;
    NSLog(@"--3--%d",loginType);
    NSString *username = [[NSString  alloc] initWithBytes:packageBytes length:userNameLong encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
    
//    NSLog(@"<----username--->%@",username);
//    NSLog(@"--4--%d",loginType);
    packageBytes += userNameLong;
//    NSLog(@"---%s---",packageBytes);
    int loginResult =  packageBytes[0];
    
    packageBytes++;
    
    int resultInfoLength = packageBytes[0];
    
    packageBytes++;
    
    NSData *infoData = [NSData dataWithBytes:packageBytes length:resultInfoLength];
    NSLog(@"%d",resultInfoLength);
    
    NSString *infostr = [[NSString  alloc] initWithBytes:packageBytes length:resultInfoLength encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
    NSLog(@"<----infostr--->%@",infostr);
    Byte *packBytes = NULL;
    packBytes = (Byte *)[infoData bytes];
    
    //e164a4b3ccd73ca56eb1abcd7355f3abd274c47b9d40e29706eed40fb372ce86
    
    NSLog(@"--->>%@", [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:loginType],@"loginType", username,@"username",[NSNumber numberWithInt:loginResult],@"loginResult", infoData,@"loginInfo", nil]);
    
    return  [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:loginType],@"loginType", username,@"username",[NSNumber numberWithInt:loginResult],@"loginResult", infoData,@"loginInfo", nil];
}
-(void)dt{
    //
    //
    NSMutableData *data1, *data2;
    
    NSString *firstString = @"ABCD";
    
    NSString *secondString = @"EFGH";
    
    const char *utfFirstString = [firstString UTF8String];
    
    const char *utfSecondString = [secondString UTF8String];
    
    unsigned char *aBuffer;
    
    unsigned len;
    
    data1 = [NSMutableData dataWithBytes:utfFirstString length:strlen(utfFirstString)];
    
    data2 = [NSMutableData dataWithBytes:utfSecondString length:strlen(utfSecondString)];
    
    len = [data2 length];
    
    aBuffer = malloc(len);
    
    [data2 getBytes:aBuffer length:[data2 length]];
    
    [data1 appendBytes:aBuffer length:len];
}



@end
