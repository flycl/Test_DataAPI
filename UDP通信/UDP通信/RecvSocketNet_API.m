//
//  RecvSocketNet_API.m
//  UDP通信
//
//  Created by shinetech on 2017/6/29.
//  Copyright © 2017年 shinetech. All rights reserved.
//

#import "RecvSocketNet_API.h"

@implementation RecvSocketNet_API

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
}


#pragma mark - DataPream
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
        
        //长度 验证  （除包头 尾 长度）  看 解包在哪
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

//申请登陆反馈
-(void)receiveDataForLoginFeedback:(NSData*)data{
    
    @try {
        
        NSDictionary *dic;
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

@end
