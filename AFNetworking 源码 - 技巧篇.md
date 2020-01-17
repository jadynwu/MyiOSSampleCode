## AFNetworking 源码 - 技巧篇

### 简介

本文主要分析AFNetworking框架中`AFNetworkingReachabilityManager`类的源码中，与我在项目日常开发中不同的代码技巧和设计思路。

`AFNetworkingReachabilityManager`主要是基于`CoreFoundation`下的`#import <SystemConfiguration/SystemConfiguration.h>`框架进行网络状态监测。



### 命名

##### 静态变量的命名

- 通知名：

  示例：`NSString * const AFNetworkingReachabilityDidChangeNotification = @"com.alamofire.networking.reachability.change";`

  - 变量使用类名作为前缀，使用**Notification**结尾
  - 值使用**bundleId**作为前缀
  - 值使用**.语法**可以巧妙的将通知分类

- 通知userInfo中的key

  - 变量和值一致
  - 使用类名作为前缀，使用**NotificationXXXX**结尾



### 静态函数

AFNetworking中使用**静态函数**代替了所有的**私有方法**。

##### *静态函数* vs *方法*

- 静态函数：
  1. 占用的空间更小，运行更快，编译器可以内联。
- 方法：
  1. 在多态场景下，使用方法来解决重写等问题。
  2. .h中声明的接口用方法。

综上，根据不同的场景选择使用***静态函数***和***方法***。



### 只读属性

```objective-c
//方式1
//.h
@property (readonly, nonatomic, assign, getter = isReachable) BOOL reachable;
//.m
- (BOOL)isReachable {
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
}


//方式2
//.h
@property (readonly, nonatomic, assign) BOOL reachable;
//.m
- (BOOL)reachable {
    return [self isReachableViaWWAN] || [self isReachableViaWiFi];
}

```



### 宏

##### __unused

一般情况下，声明一个方法，方法的入参应该做到**充要**。

```objective-c
//方法中的参数2需要传入SCNetworkReachabilityCallBack方法
//在网络状态发生改变的时候将结果值传入到SCNetworkReachabilityCallBack方法的参数1和参数2
SCNetworkReachabilitySetCallback		(
						SCNetworkReachabilityRef			target,
						SCNetworkReachabilityCallBack	__nullable	callout,
						SCNetworkReachabilityContext	* __nullable	context
						)				API_AVAILABLE(macos(10.3), ios(2.0));

//这是一个SCNetworkReachability声明的方法
typedef void (*SCNetworkReachabilityCallBack)	(
						SCNetworkReachabilityRef			target,
						SCNetworkReachabilityFlags			flags,
						void			     *	__nullable	info
						);

//AF中按照SCNetworkReachabilityCallBack格式声明方法
//作为SCNetworkReachabilitySetCallback的参数
//target没有被用到，
static void AFNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    AFPostReachabilityStatusChange(flags, (__bridge AFNetworkReachabilityStatusCallback)info);
}

```

而由于SCNetworkReachability中方法的特殊性，需要创建方法变量格式一样方法。此时方法中的`target`没有在方法中被用到，但是又有这样的场景需要创建时，可以用`__unused`修饰`target`。



##### NS_UNAVAILABLE

修饰一个方法为失效方法，子类继承父类的时候，如果不想使用父类方法，就使用`NS_UNAVAILABLE`修饰方法，这样在调用时，编译时期就会报错。

```objective-c
//如果调用，会报Error：'init' is unavailable
- (instancetype)init NS_UNAVAILABLE;
```



##### NS_DESIGNATED_INITIALIZER

指定根初始化器。

标明所有的初始化器最终都会执行这个被修饰了`NS_DESIGNATED_INITIALIZER`的初始化器。

```objective-c
- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability NS_DESIGNATED_INITIALIZER;
```



##### FOUNDATION_EXPORT

比`extern`更具有平台兼容性的一个字段。在普通环境中，和`extern`作用一样。

如果代码不会在其他平台的C/C++环境运行，可以使用`extern`代替`FOUNDATION_EXPORT`

```objective-c
//和extern作用几乎一致
FOUNDATION_EXPORT NSString * const AFNetworkingReachabilityDidChangeNotification;
```

在`NSObjCRuntime.h`中可以查阅到这个宏声明的资料

```objective-c
#if defined(__cplusplus)
#define FOUNDATION_EXTERN extern "C"
#else
#define FOUNDATION_EXTERN extern
#endif

#define FOUNDATION_EXPORT FOUNDATION_EXTERN
#define FOUNDATION_IMPORT FOUNDATION_EXTERN
```



##### DEPRECATED_ATTRIBUTE



##### Block_copy

##### Block_release



### KVO绑定



### 其他

##### 将网络状态以不同维度封装，减少使用者代码量







### 