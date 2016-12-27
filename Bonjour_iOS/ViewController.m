//
//  ViewController.m
//  Bonjour_iOS
//
//  Created by yuedongkui on 2016/12/8.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

#define kDomain @"local."
#define kServiceType @"_ProbeHttpService._tcp."

@interface ViewController ()<NSNetServiceBrowserDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate>
{
    NSNetServiceBrowser *netServiceBrowser;
    NSNetService *serverService;
    NSMutableArray *serverAddresses;

    GCDAsyncSocket *asyncSocket;
    BOOL connected;
}
@property (weak, nonatomic) IBOutlet UITextView *logLabel;
@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //1.创建发现类
    netServiceBrowser = [[NSNetServiceBrowser alloc] init];
    netServiceBrowser.delegate = self;
    //2.开始服务发现
    [netServiceBrowser searchForServicesOfType:kServiceType inDomain:kDomain];
    
    //停止发现
//    [netServiceBrowser stop];
}

#pragma mark - 发送socket消息
- (IBAction)sendMessage:(id)sender {
    
    NSDictionary *dic = @{@"msg" : [NSString stringWithFormat:@"%d", arc4random()%100]};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    [asyncSocket writeData:data withTimeout:1 tag:0];
}

#pragma mark -
//发现服务
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    if (serverService == nil) {
        serverService = service;
        service.delegate = self;
        
        //开始监控是否有消息发过来（服务端是否执行setTXTRecordData:）
        [service startMonitoring];
        
        //开始服务解析
        [service resolveWithTimeout:5];
        NSLog(@"===发现服务 %@", service);
        _logLabel.text = [NSString stringWithFormat:@"%@\n===发现服务： %@", _logLabel.text, service];
    }
}

//未发现服务
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(nonnull NSDictionary<NSString *,NSNumber *> *)errorDict
{
    NSLog(@"===未发现服务 error: %@", errorDict);
    _logLabel.text = [NSString stringWithFormat:@"%@\n===未发现服务 error: %@", _logLabel.text, errorDict];
}

//收到Txt消息
- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
{
    NSDictionary *infoDict = [NSNetService dictionaryFromTXTRecordData:data];
    _logLabel.text = [NSString stringWithFormat:@"%@\n===收到新消息： %@", _logLabel.text, infoDict];
}

#pragma mark -
//完成解析，得到服务器 host 和 port
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    //得到服务器 host 和 port
    NSLog(@"===服务获取到地址 hostName %@ prot %ld addressed %@", sender.hostName, sender.port, sender.addresses);
    
    _logLabel.text = [NSString stringWithFormat:@"%@\n===服务获取到地址 hostName %@ prot %ld addressed %@", _logLabel.text, sender.hostName, sender.port, sender.addresses];
    
    if (serverAddresses == nil)
    {
        serverAddresses = [[sender addresses] mutableCopy];
    }

    if (asyncSocket == nil)
    {
        asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        [self connectToNextAddress];
    }
}

#pragma mark - socket 部分
- (void)connectToNextAddress
{
    BOOL done = NO;
    
    while (!done && ([serverAddresses count] > 0))
    {
        NSData *addr;
        
        // Note: The serverAddresses array probably contains both IPv4 and IPv6 addresses.
        //
        // If your server is also using GCDAsyncSocket then you don't have to worry about it,
        // as the socket automatically handles both protocols for you transparently.
        
        if (YES) {// Iterate forwards
            addr = [serverAddresses objectAtIndex:0];
            [serverAddresses removeObjectAtIndex:0];
        }
//        else {// Iterate backwards
//            addr = [serverAddresses lastObject];
//            [serverAddresses removeLastObject];
//        }
        
        NSLog(@"Attempting connection to %@", addr);
        
        NSError *err = nil;
        if ([asyncSocket connectToAddress:addr error:&err]) {
            done = YES;
        }
        else {
            NSLog(@"Unable to connect: %@", err);
        }
    }
    
    if (!done) {
        NSLog(@"Unable to connect to any resolved address");
    }
}

#pragma mark -

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Socket:DidConnectToHost: %@ Port: %hu", host, port);
    _logLabel.text = [NSString stringWithFormat:@"%@\n====Socket:DidConnectToHost: %@ Port: %hu", _logLabel.text, host, port];
    connected = YES;
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"SocketDidDisconnect:WithError: %@", err);
    _logLabel.text = [NSString stringWithFormat:@"%@\n====SocketDidDisconnect:WithError: %@", _logLabel.text, err];

    if (!connected) {
        [self connectToNextAddress];
    }
}



@end



