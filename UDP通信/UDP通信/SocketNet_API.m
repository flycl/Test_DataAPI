//
//  SocketNet_API.m
//  UDP通信
//
//  Created by shinetech on 2017/6/26.
//  Copyright © 2017年 shinetech. All rights reserved.
//Homebrew


#import "SocketNet_API.h"

@implementation SocketNet_API

-(void)sendDataChangByte{
    NSMutableData *tempData = [NSMutableData data];
    
    Byte *loginTypeByte = (Byte *)[self intToByteArray:0x01  Len:1]; //添加参数---1
    
    [tempData  appendBytes:loginTypeByte length:1];
    if (loginTypeByte){
        free(loginTypeByte);
    }
    
    NSString *username = [NSString stringWithFormat:@"%@ %@",[@"蓝"  stringByReplacingOccurrencesOfString:@"色" withString:@""],@"宁测试"];//入参数---2
    
    [tempData  appendData:[self packageConvertFromNSString:username]];
    
    NSData *converData = [self packageConvertFromData:tempData andProtocal:0x0103];//添加参数 ---3
}

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

/**
 字符串转Byte Data进制包
 @param dataString 字符串
 @return Byte  类型NSData
 */
-(NSData*)packageConvertFromNSString:(NSString*)dataString{
    
    NSString *dataString_ = [dataString mutableCopy];
    // 非空返回
    
    if (!dataString_) {
        return [NSMutableData  data];
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
@end
