//
//  AppDelegate.m
//  Bonjour_Demo
//
//  Created by yuedongkui on 2016/12/8.
//  Copyright © 2016年 LY. All rights reserved.
//

#import "AppDelegate.h"

#define kDomain @"local."
#define kServiceType @"_ProbeHttpService._tcp."


@interface AppDelegate ()<NSNetServiceDelegate>
@property (weak) IBOutlet NSWindow *window;
@property (strong) NSNetService *netService;
@end



@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //1.创建服务类
    self.netService = [[NSNetService alloc] initWithDomain:kDomain type:kServiceType name:@"texeDemo" port:8888];
    [self.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.netService.delegate = self;
    [self.netService publish];
    NSLog(@"创建服务类");
}

#pragma mark -
- (IBAction)sendTxt:(id)sender {
    NSString *abc = @"1";
    NSData *data = [abc dataUsingEncoding:NSUTF8StringEncoding];
    [self.netService setTXTRecordData:data];
    NSLog(@"data = %@", data);
    _logLabel.stringValue = [NSString stringWithFormat:@"%@\n 发送消息 %@", _logLabel.stringValue, abc];
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

@end
