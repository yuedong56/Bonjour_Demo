//
//  ViewController.m
//  Bonjour_iOS
//
//  Created by yuedongkui on 2016/12/8.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "ViewController.h"

#define kDomain @"local."
#define kServiceType @"_ProbeHttpService._tcp."

@interface ViewController ()<NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@property (nonatomic, strong) NSMutableArray *netServices;
@property (weak, nonatomic) IBOutlet UITextView *logLabel;
@property (strong) NSNetServiceBrowser *serviceBrowser;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.netServices = [NSMutableArray array];
    //1.创建发现类
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    self.serviceBrowser.delegate = self;
    //2.开始服务发现
    [self.serviceBrowser searchForServicesOfType:kServiceType inDomain:kDomain];
    //
}

#pragma mark -
//发现服务
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    //保存发现的服务
    [self.netServices addObject:service];
//    //开始监控是否有消息发过来（服务端是否执行setTXTRecordData:）
//    [service startMonitoring];
    service.delegate = self;
    
    //开始服务解析
    [service resolveWithTimeout:5];
    NSLog(@"===发现服务 %@", service);
    _logLabel.text = [NSString stringWithFormat:@"%@\n===发现服务： %@", _logLabel.text, service];
}

//未发现服务
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(nonnull NSDictionary<NSString *,NSNumber *> *)errorDict
{
    NSLog(@"===未发现服务 error: %@", errorDict);
    _logLabel.text = [NSString stringWithFormat:@"%@\n===未发现服务 error: %@", _logLabel.text, errorDict];
}

//收到消息
- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
{
    [sender startMonitoring];

    NSString *abc = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    _logLabel.text = [NSString stringWithFormat:@"%@\n===收到新消息： %@", _logLabel.text, abc];
}

#pragma mark -
//完成解析，得到服务器 host 和 port
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    //得到服务器 host 和 port
    NSLog(@"===服务获取到地址 hostName %@ prot %ld addressed %@", sender.hostName, sender.port, sender.addresses);
    
    _logLabel.text = [NSString stringWithFormat:@"%@\n===服务获取到地址 hostName %@ prot %ld addressed %@", _logLabel.text, sender.hostName, sender.port, sender.addresses];
}

@end



