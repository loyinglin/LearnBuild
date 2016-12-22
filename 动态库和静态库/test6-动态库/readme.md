###前言
[《编译与链接过程的思考》](http://www.jianshu.com/p/2310b61e687e)
 [《静态库与动态库的思考》](http://www.jianshu.com/p/df4876d5b385)

在写完上面两篇思考之后，仔细研读[《程序员的自我修养—链接、装载与库》](https://www.amazon.cn/%E7%A8%8B%E5%BA%8F%E5%91%98%E7%9A%84%E8%87%AA%E6%88%91%E4%BF%AE%E5%85%BB-%E9%93%BE%E6%8E%A5-%E8%A3%85%E8%BD%BD%E4%B8%8E%E5%BA%93-%E6%BD%98%E7%88%B1%E6%B0%91/dp/B0027VSA7U/ref=sr_1_1?ie=UTF8&qid=1481878780&sr=8-1&keywords=%E7%A8%8B%E5%BA%8F%E5%91%98%E7%9A%84%E8%87%AA%E6%88%91%E4%BF%AE%E5%85%BB%E2%80%94%E9%93%BE%E6%8E%A5%E3%80%81%E8%A3%85%E8%BD%BD%E4%B8%8E%E5%BA%93)，对编译、链接、装载、静态库和动态库有连贯的认知。
>这种知识先在学校学习一遍，然后遗忘；
工作用到，百思不得其解；
然后再看书，才能深深记住和理解。

###正文
####机器指令
最初的机器指令，是使用**纸带**来记录；

当变更指令的时候，需要程序员**重新计算**每个子程序的跳转地址。这个操作就是重定位。

但是，如果有**多条纸带**，跳转更为复杂。

####汇编语言
为了解决上面复杂的机器指令跳转，先驱者发明了汇编语言。

举例：一个汇编指令
```
 jmp foo
```

由汇编器在每次汇编程序的时候，重新计算foo这个符号的地址。

>符号（Symbol）表示的是一个地址，可能是函数的起始地址，也可能是变量的起始地址。

随着软件的规模越来越大，代码量越来越大；

人们考虑把不同的功能模块以特定的方式组织起来，便于阅读；

那么如何解决，模块最后组合成一个单一的程序的问题？

####链接
先来看看模块间的调用有哪些：
 * 1、函数调用；
 * 2、变量访问；
其实可以统一为跨模块的符号引用。

**这个统一模块间符号的引用的过程，就是链接。**

链接包括：地址和空间分配、符号决议和重定位。

**简单描述下链接的过程：**
假如主程序main.c 使用了 fun.c 模块的 foo函数，那么main.c在编译的过程，对于调用foo函数的指令，对于指令的目标地址暂时搁置；待到链接的时候，由链接器来填写foo函数的地址。

编译之后会产生目标文件。
目标文件：**编译器编译源代码后产生的文件**，没有经过链接的过程，某些符号还没有调整过，Windows下的.obj文件，Linux下的.o文件，Unix的.out文件。

####静态链接
静态链接：链接器在链接时将静态库合并到可执行程序。

链接器为目标文件分配地址和空间有两层含义：
1、输出的可执行文件的空间；
2、装载后的虚拟地址中的虚拟地址空间；

**链接过程分为两步：**
 * 1、空间和地址分配，扫描所有的目标文件，获得各个段的长度、属性、位置信息，并把所有的符号定义以及引用收集起来，放到全局的符号表中；
通过所有段的长度，计算和合并后的长度和位置，并建立映射关系；

 * 2、符号解析和重定位，使用上一步收集到的信息，读取文件中段的数据和重定位信息，进行符号解析和重定位；

.lib、.a是常见的静态链接库；
静态库的缺点：
**浪费内存和磁盘空间、更新困难；**

####动态链接
动态链接：把链接的过程推迟到运行时再进行。
动态链接涉及到运行时的链接以及文件的装载，故而需要操作系统的支持。
程序与.so文件之间的链接是由动态链接库完成的，静态链接是由静态链接器ld完成的。

**动态库也需要参与链接的过程，否则找不到该符号的信息；**
so保存了完整的符号信息，链接器解析符号时会获取这些信息，用于判断一个符号是否为动态符号；

.dll、.so 是常见的动态链接库；
共享对象的最终装载地址在编译时是不确定的，根据装载时的地址空间的空闲情况，动态分配一块足够大小的虚拟地址空间给响应的共享对象。

**动态链接器是动态链接还是静态链接？**
静态链接。它要解决其他共享对象的依赖问题，不能依赖其他共享对象；

外部符号：在本目标文件引用但没有定义的符号；（External Symbol）
当多个同名符号冲突的时候，先装入的符号优先，这种优先级方式成为**装载序列**。（Load Ordering）


###iOS相关
我们通过一个工程，来验证动态库的动态装载。

**dlfcn.h的方法**
 * dlopen打开动态链接库；
 * dlerror返回错误；
 * dlsym获取函数名或者变量名；
 * dlclose关闭动态库；

**Objective-C的方法**
 * NSClassFromString根据名字返回类；
 * NSSelectorFromString根据名字返回方法；
 * performSelector执行方法；

**工程设置**
**注意**，在Linked的设置里面没有ALib，因为我们是通过dlopen的形式来打开动态库。
BLib中有一个OC类， 其中的+load方法，会显示BLib是何时被装载；
ALib中有一个OC类， 其中的+load方法，会显示ALib是何时被装载；还有一个foo函数，为c函数；
![](http://upload-images.jianshu.io/upload_images/1049769-f24492d0006eb06a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**测试代码**
```
#include <dlfcn.h>

typedef void (*FOO_FUNC)(void);

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self testLib];
    });
}

- (void)testLib {
    NSLog(@"Test lib.");
    void *handle;
    char *error;
    handle = dlopen("ALib.framework/ALib", RTLD_LAZY);
    if (!handle) {
        fprintf(stderr, "%s\n", dlerror());
        return ;
    }
    dlerror();
    FOO_FUNC func = dlsym(handle, "foo");
    if ((error = dlerror()) != NULL)  {
        fprintf(stderr, "%s\n", error);
        return;
    }
    func();
    
    
    Class Alib = NSClassFromString(@"ALib");
    SEL foo = NSSelectorFromString(@"foo");
    
    if (Alib && foo) {
        [[[Alib alloc] init] performSelector:foo withObject:nil];
    }
    
    dlclose(handle);
}

```

**测试输出**
>2016-12-22 13:09:00.653406 testLib[8279:1718634] load Blib
2016-12-22 13:09:04.083711 testLib[8279:1718634] Test lib.
2016-12-22 13:09:04.195297 testLib[8279:1718634] load Alib
foo in ALib.
2016-12-22 13:09:04.195752 testLib[8279:1718634] foo in NSALib.

**结果思考**
Xcode工程link设置上的动态库，会在程序启动时加载到内存，即使你没有用到这个库的函数；（测试代码中没有用到BLib动态库的代码，但是启动即加载了BLib）

`dispatch_after `是为了延迟，模拟动态加载的过程；
动态库ALib在调用的时候再进行了装载，并且c函数和Objective-C方法均可调用；（测试输出中，loadAlib比loadBLib晚了3秒钟）

####Xcode工程设置的Other Linker Flags
 * -ObjC，告诉链接器把库中定义的Objective-C类和Category都加载进来；（如果静态库中有类和category的话，需要添加这个标志）
 * -all_load，-all_laod会强制链接器把目标文件都加载进来，即使没有objc代码。（库中只有category没有类的时候，即使有-ObjC， 仍然无法加载category）
 * -force_load，必须跟一个静态库的路径，与-all_load不同的是只会完全加载一个库，不影响其他库文件；

###总结
在学习现在的知识时，回顾曾经的发展道路，会有意想不到的收获。
>航天飞机的宽度是由马屁股决定的。

代码可以在[Github](https://github.com/loyinglin/LearnBuild/tree/master/%E5%8A%A8%E6%80%81%E5%BA%93%E5%92%8C%E9%9D%99%E6%80%81%E5%BA%93)找到。



　
