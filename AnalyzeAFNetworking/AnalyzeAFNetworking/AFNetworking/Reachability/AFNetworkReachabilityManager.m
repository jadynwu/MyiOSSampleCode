// AFNetworkReachabilityManager.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFNetworkReachabilityManager.h"
#if !TARGET_OS_WATCH

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

NSString * const AFNetworkingReachabilityDidChangeNotification = @"com.alamofire.networking.reachability.change";
NSString * const AFNetworkingReachabilityNotificationStatusItem = @"AFNetworkingReachabilityNotificationStatusItem";
 
//网络状态改变的回调

//对外Block方法内部的接收者
typedef void (^AFNetworkReachabilityStatusBlock)(AFNetworkReachabilityStatus status);
//通过已改变的status配置manager
typedef AFNetworkReachabilityManager * (^AFNetworkReachabilityStatusCallback)(AFNetworkReachabilityStatus status);

//格式化方法
//将status转换成String
NSString * AFStringFromNetworkReachabilityStatus(AFNetworkReachabilityStatus status) {
    switch (status) {
        case AFNetworkReachabilityStatusNotReachable:
            return NSLocalizedStringFromTable(@"Not Reachable", @"AFNetworking", nil);
        case AFNetworkReachabilityStatusReachableViaWWAN:
            return NSLocalizedStringFromTable(@"Reachable via WWAN", @"AFNetworking", nil);
        case AFNetworkReachabilityStatusReachableViaWiFi:
            return NSLocalizedStringFromTable(@"Reachable via WiFi", @"AFNetworking", nil);
        case AFNetworkReachabilityStatusUnknown:
        default:
            return NSLocalizedStringFromTable(@"Unknown", @"AFNetworking", nil);
    }
}

//将SC框架的flags转换成AF框架的status
static AFNetworkReachabilityStatus AFNetworkReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    //使用位运算的方式计算
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));

    AFNetworkReachabilityStatus status = AFNetworkReachabilityStatusUnknown;
    if (isNetworkReachable == NO) {
        status = AFNetworkReachabilityStatusNotReachable;
    }
#if	TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = AFNetworkReachabilityStatusReachableViaWWAN;
    }
#endif
    else {
        status = AFNetworkReachabilityStatusReachableViaWiFi;
    }

    return status;
}

/**
 * Queue a status change notification for the main thread.
 *
 * This is done to ensure that the notifications are received in the same order
 * as they are sent. If notifications are sent directly, it is possible that
 * a queued notification (for an earlier status condition) is processed after
 * the later update, resulting in the listener being left in the wrong state.
 */
//处理SC网络状态改变的结果
//参数1：SC的网络状态flags
//参数2：一个block，传入status返回manager对象，用来当做通知的object
static void AFPostReachabilityStatusChange(SCNetworkReachabilityFlags flags, AFNetworkReachabilityStatusCallback block) {
    //网络状态映射
    AFNetworkReachabilityStatus status = AFNetworkReachabilityStatusForFlags(flags);
    dispatch_async(dispatch_get_main_queue(), ^{
        AFNetworkReachabilityManager *manager = nil;
        if (block) {
            //调用block，获取配置好（networkReachabilityStatus被更新）的manager
            //block中同时调用了setReachabilityStatusChangeBlock：的block回调
            manager = block(status);
        }
        //获取通知中心
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        //将status转换成NSNumber类型，设置为AFNetworkingReachabilityNotificationStatusItem的value放入通知的userInfo中
        NSDictionary *userInfo = @{ AFNetworkingReachabilityNotificationStatusItem: @(status) };
        //发送网络变更通知
        [notificationCenter postNotificationName:AFNetworkingReachabilityDidChangeNotification object:manager userInfo:userInfo];
        //到这里为止，Notification和Block两种状态改变的回调方式都触发了
    });
}

//SC框架中要求格式的方法，将此方法传入到SC方法中，网络状态改变时，SC框架会调用这个方法。
//接收SC网络状态改变的结果
static void AFNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    //调用回调处理方法
    //参数1 ：状态改变后的SC状态flag
    //参数2 ：AFNetworkReachabilityStatusCallback
    AFPostReachabilityStatusChange(flags, (__bridge AFNetworkReachabilityStatusCallback)info);
}

//SC框架中要求格式的方法
//用来将info（一个block）copy到堆上
static const void * AFNetworkReachabilityRetainCallback(const void *info) {
    //Block_copy是一个宏，将传入的参数转换成一个const void *类型的对象传递给_Block_copy()方法
    //1. 传入参数为NULL 返回NULL
    //2. 传入参数为堆Block 引用计数+1 返回
    //3. 传入参数为全局Block 直接返回原值
    //4. 传入参数为栈Block
    //  4.1 调用malloc在堆上开辟内存，失败则返回NULL
    //  4.2 调用memmove将栈上的Block拷贝到堆上
    return Block_copy(info);
}

//SC框架中要求格式的方法
//用来将info（一个block）释放
static void AFNetworkReachabilityReleaseCallback(const void *info) {
    if (info) {
        //Block_release是一个宏，将传入的参数转换成一个const void *类型的对象传递给_Block_release()方法
        //释放堆上的block
        Block_release(info);
    }
}

@interface AFNetworkReachabilityManager ()
//SC获取网络状态的对象
@property (readonly, nonatomic, assign) SCNetworkReachabilityRef networkReachability;
//当前的网络状态
@property (readwrite, nonatomic, assign) AFNetworkReachabilityStatus networkReachabilityStatus;
//网路状态改变的回调
@property (readwrite, nonatomic, copy) AFNetworkReachabilityStatusBlock networkReachabilityStatusBlock;
@end

@implementation AFNetworkReachabilityManager

//单例
+ (instancetype)sharedManager {
    static AFNetworkReachabilityManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [self manager];
    });

    return _sharedManager;
}

+ (instancetype)managerForDomain:(NSString *)domain {
    //创建一个临时的SCNetworkReachabilityRef操作类
    //由于属于CF框架
    //reachability创建并持有SCNetworkReachabilityRef对象A
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [domain UTF8String]);
    //将对象A传入initWithReachability：
    AFNetworkReachabilityManager *manager = [[self alloc] initWithReachability:reachability];
    
    //reachability释放对象
    //调用CFRelease方法将引用计数-1
    //现在对象A的引用计数为2
    CFRelease(reachability);

    return manager;
}

+ (instancetype)managerForAddress:(const void *)address {
    //初始化操作类
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)address);
    AFNetworkReachabilityManager *manager = [[self alloc] initWithReachability:reachability];

    CFRelease(reachability);
    
    return manager;
}

+ (instancetype)manager
{
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len = sizeof(address);
    address.sin6_family = AF_INET6;
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
#endif
    return [self managerForAddress:&address];
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
    self = [super init];
    if (!self) {
        return nil;
    }

    //_networkReachability持有SCNetworkReachabilityRef对象A
    //对象A被两个指针持有，引用计数为2
    //由于是CF框架，需要用CFRetain将引用计数+1
    _networkReachability = CFRetain(reachability);
    //设置当前manager的初始网络状态为unknown
    self.networkReachabilityStatus = AFNetworkReachabilityStatusUnknown;

    return self;
}

//将系统构造方法废弃的方式
//  1. 在.h文件中NS_UNAVAILABLE修饰方法
//  2. 在.m中实现@throw，通过NSException抛出异常
- (instancetype)init
{
    @throw [NSException exceptionWithName:NSGenericException
                                   reason:@"`-init` unavailable. Use `-initWithReachability:` instead"
                                 userInfo:nil];
    return nil;
}

- (void)dealloc {
    //停止监听
    [self stopMonitoring];
    
    //由于_networkReachability是core foundation框架的，并没有ARC，所以需要手动释放内存
    if (_networkReachability != NULL) {
        CFRelease(_networkReachability);
    }
}

#pragma mark -
//是否网络连接
- (BOOL)isReachable {
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
}
//是否是WWAN模式
- (BOOL)isReachableViaWWAN {
    return self.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN;
}
//是否是WiFi模式
- (BOOL)isReachableViaWiFi {
    return self.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi;
}

#pragma mark -

//开始检测
- (void)startMonitoring {
    //先停止之前的检测，保证每次开启都是重新开启
    [self stopMonitoring];

    //如果networkReachability对象 == nil，就返回
    if (!self.networkReachability) {
        return;
    }

    __weak __typeof(self)weakSelf = self;
    //实现 AFNetworkReachabilityStatusCallback 的block
    AFNetworkReachabilityStatusCallback callback = ^(AFNetworkReachabilityStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        //配置状态
        strongSelf.networkReachabilityStatus = status;
        //通过block通知外部网络发生变更
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }
        //返回对象
        return strongSelf;
    };

    //创建SC网络检测类的上下文
    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, AFNetworkReachabilityRetainCallback, AFNetworkReachabilityReleaseCallback, NULL};
    //设置网络改变的回调
    //AFNetworkReachabilityCallback为和SCNetworkReachabilitySetCallback的参数2block格式对应的block
    //当网络状态改变时会调AFNetworkReachabilityCallback
    SCNetworkReachabilitySetCallback(self.networkReachability, AFNetworkReachabilityCallback, &context);
    //将检测器加入runloop
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    
    //手动更新一次网络状态
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        SCNetworkReachabilityFlags flags;
        //异步获取状态
        if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
            //触发回调处理方法
            AFPostReachabilityStatusChange(flags, callback);
        }
    });
}

- (void)stopMonitoring {
    //停止监测
    if (!self.networkReachability) {
        return;
    }
    //将操作类从runloop中移除
    SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

#pragma mark -

- (NSString *)localizedNetworkReachabilityStatusString {
    return AFStringFromNetworkReachabilityStatus(self.networkReachabilityStatus);
}

#pragma mark -

- (void)setReachabilityStatusChangeBlock:(void (^)(AFNetworkReachabilityStatus status))block {
    self.networkReachabilityStatusBlock = block;
}

#pragma mark - NSKeyValueObserving
//属性依赖
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"reachable"] || [key isEqualToString:@"reachableViaWWAN"] || [key isEqualToString:@"reachableViaWiFi"]) {
        return [NSSet setWithObject:@"networkReachabilityStatus"];
    }

    return [super keyPathsForValuesAffectingValueForKey:key];
}

@end
#endif
