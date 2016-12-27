//
//  AppDelegate.m
//  Bonjour_Demo
//
//  Created by yuedongkui on 2016/12/8.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "AppDelegate.h"
#import "GCDAsyncSocket.h"

#define kDomain @"local."
#define kServiceType @"_ProbeHttpService._tcp."


@interface AppDelegate ()<NSNetServiceDelegate>
{
    NSNetService *netService;
    GCDAsyncSocket *asyncSocket;
    GCDAsyncSocket *receiveSocket;
    NSMutableArray *connectedSockets;
}
@property (weak) IBOutlet NSWindow *window;
@end



@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    connectedSockets = [[NSMutableArray alloc] init];

    //创建socket服务
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    asyncSocket.delegate = self;
    // Now we tell the socket to accept incoming connections.
    // We don't care what port it listens on, so we pass zero for the port number.
    // This allows the operating system to automatically assign us an available port.
    // 如果端口为零，则自动监听可用的端口
    NSError *err = nil;
    if ([asyncSocket acceptOnPort:0 error:&err])
    {
        // So what port did the OS give us?
        
        UInt16 port = [asyncSocket localPort];
        
        // Create and publish the bonjour service.
        // Obviously you will be using your own custom service type.
        
        //1.创建服务类
        netService = [[NSNetService alloc] initWithDomain:kDomain
                                                     type:kServiceType
                                                     name:@""
                                                     port:port];
        [netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [netService setDelegate:self];
        [netService publish];
        
        NSLog(@"创建服务类");
    }
    else
    {
        NSLog(@"Error in acceptOnPort:error: -> %@", err);
    }
}

#pragma mark - 发送消息
//发送Txt消息
- (IBAction)sendTxt:(id)sender
{
    // You can optionally add TXT record stuff
    
    NSMutableDictionary *txtDict = [NSMutableDictionary dictionaryWithCapacity:2];
    NSString *num = [NSString stringWithFormat:@"%d", arc4random()%100];
    [txtDict setObject:num forKey:@"num"];
    [txtDict setObject:@"quack" forKey:@"duck"];
    
    NSData *txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];
    [netService setTXTRecordData:txtData];
    
    _logLabel.stringValue = [NSString stringWithFormat:@"%@\n 发送消息 %@", _logLabel.stringValue, txtDict];
}

//发送socket消息
- (IBAction)sendSocketMsg:(id)sender {
    
}

#pragma mark -

//发布完成
- (void)netServiceDidPublish:(NSNetService *)sender
{
    NSLog(@"发布完成！！！");
    _logLabel.stringValue = [NSString stringWithFormat:@"%@\n发布完成 hostName %@ prot %ld addressed %@", _logLabel.stringValue, sender.hostName, sender.port, sender.addresses];
}

//发布失败
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary<NSString *, NSNumber *> *)errorDict;
{
    NSLog(@"error：发布失败！！！");
    _logLabel.stringValue = [NSString stringWithFormat:@"%@\nerror:发布失败, %@", _logLabel.stringValue, errorDict];
}

#pragma mark - GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSLog(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
    
    // The newSocket automatically inherits its delegate & delegateQueue from its parent.
    
    [connectedSockets addObject:newSocket];
    
    receiveSocket = newSocket;
    [receiveSocket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    [connectedSockets removeObject:sock];
}

//收到消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [receiveSocket readDataWithTimeout:-1 tag:0];

    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                               options:NSJSONReadingMutableContainers
                                                                 error:nil];
    NSLog(@"dictionary ----- %@", dictionary);
}

@end




