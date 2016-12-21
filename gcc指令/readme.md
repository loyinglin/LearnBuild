###前言
最近遇到一个错误，如下
![](http://upload-images.jianshu.io/upload_images/1049769-eaa10726a7104222.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
在解决过程中，回顾了很多知识，于是有了这篇文章。
关键词：**预处理、编译、汇编、链接、动态链接库、静态链接库、真机调试**。

###正文
以.c文件的编译流程为例，如下图。
我们按照以下的步骤，用gcc对代码进行编译。
![编译流程图](http://upload-images.jianshu.io/upload_images/1049769-46e925867b626a2d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
test.c的代码如下
```
#include <stdio.h>
int main()
{
    puts("It's OK.");
	return 0;
}
```
####gcc指令处理
 * 预处理
````
gcc -E test.c -o test.i
```
 * 编译
```
gcc -S test.i -o test.s
```
 * 汇编
```
gcc -c test.s -o test.o
```
 * 链接
```
gcc test.o -o test
```

>指令解释
-E                      Only run the preprocessor
-S                      Only run preprocess and compilation steps
-c                      Only run preprocess, compile, and assemble steps
-o <file>               Write output to <file>

####静态连接与动态链接
#####1、静态链接
静态连接就是把静态连接库（.a文件）中的文件链接到可执行文件中；
>.a文件是多个.o文件的组合；
.o文件是对象文件，里面是机器指令；
链接就是多个.o文件打包成可执行文件；

#####2、动态链接
动态链接就是仅在可执行文件中加入相关描述文件，执行时再动态加载相应的动态链接库；
#####3、链接过程
链接的过程，也就是**符号重定位**。
c/c++ 程序的编译是以文件为单位进行的，因此每个 c/cpp 文件也叫作一个编译单元(translation unit), 源文件先是被编译成一个个目标文件, 再由链接器把这些目标文件组合成一个可执行文件或库，链接的过程，其核心工作是解决模块间各种符号(变量，函数)相互引用的问题，对符号的引用本质是对其在内存中具体地址的引用，因此确定符号地址是编译，链接，加载过程中一项不可缺少的工作，这就是所谓的符号重定位。**本质上来说，符号重定位要解决的是当前编译单元如何访问「外部」符号这个问题。**
>此段引用自[linux 下动态链接实现原理](http://www.cnblogs.com/catch/p/3857964.html)，有更详细的原理介绍。

###iOS相关
下图是我们Xcode工程的设置，我们来一一解析。
![](http://upload-images.jianshu.io/upload_images/1049769-e18df792c5c9ab2f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
**Embedded Binaries**
 * GPUImage.framework
 * lib.framework

这两个是动态库，framework的内容格式如下
![](http://upload-images.jianshu.io/upload_images/1049769-177c3c22f69b31c7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**Linked Frameworks and Libraries**
 * libstdc++.6.tbd 
tbd是dylib的优化版本
>官方的解释：the .tbd files are new "text-based stub libraries", that provide a much more compact version of the stub libraries for use in the SDK, and help to significantly reduce its download size
 * libXG-SDK.a
信鸽推送的静态链接库
 * lib*.framework、GPUImage.framework
直播的framework和GPUImage
 * libPods-Live.a
CocoaPods管理并生成的静态链接库
>在Build Phases的设置里面
Check Pods Manifest.lock 设置的脚本会检查Podfile.lock 和 Manifest.lock 的差异，判断是否需要重新pod install
Embed Pods Frameworks、Copy Pods Resources 是另外两个脚本

了解完工程的基本设置后，我们来定位前面提到的问题。
进行的操作是Archive -> Export -> Ad Hoc，提示的错误信息是
`Found an unexpected Mach-O header code`.
点击show logs，然后选择standard.log
![](http://upload-images.jianshu.io/upload_images/1049769-396c977ff00f138c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
log的描述是`did not contain a "archived-expanded-entitlements.xcent" resource`。
>这个问题在[stackoverflow](http://stackoverflow.com/questions/26559948/found-an-unexpected-mach-o-header-code-1918975009-in-xcode-6)也有人提问过，但是不是我遇到的情况。
so给出的建议是：
Go to BUILD PHASES -> COPY BUNDLE RESOURCES, you will find there some framework. Remove from this section and add it to LINK BINARY WITH LIBRARIES. It will work..

检查工程的设置，发现是同事把一个静态库放到了**Embedded Binaries**项里面，然而静态库是不能打包到ipa里面。（静态库里的代码会编译链接到可执行文件，资源文件需要重新打包成一个bundle文件放入ipa包）
>思考题🤔：CocoaPods很多第三方库是包括UI资源的，然而我们知道.a文件是不包括资源的，那么第三方库的资源如何处理的？

###动态库、静态库的制作
简书已经有非常详细的教程，介绍[静态库和动态库的制作](http://www.jianshu.com/p/42070c513104)。

###Debug调试
上架AppStore的应用，在Xcode就可以查看线上的crash信息。
但有时候，真机调试的出现闪退，我们通过Xcode读取真机的crash日志，发现日志是这样的：
![](http://upload-images.jianshu.io/upload_images/1049769-5774b1e7e9cebf40.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
提供的是，crash时候的地址信息。
我们知道，编译时期函数的地址就已经确定，那么根据地址信息应该是能定位到函数。
>当把Objective-C代码编译成汇编、再转译成二进制机器码后，会生成一个dSYM文件包（内含符号表，负责翻译崩溃报告成可读代码）。.dSYM文件是一个目录，包含一个十六进制的函数地址映射信息的文件，Debug的symbols都在这个文件中(包括文件名、函数名、行号等)。Xcode项目每次编译后，都会生成一个新的.dSYM文件，故而真机上的崩溃日志需要检查对应的符号表。

[APPLE](https://developer.apple.com/library/content/technotes/tn2151/_index.html)的官网介绍了一个指令:
```
// 记得把live改成你对应的包名
atos -o live.app/live -arch arm64 0x1000d51c0 -l 0x100064000
```
打开安装到真机的.app文件夹，按照上面的格式输入crash时候的地址信息即可。
如果发现出来的是一个毫不相关的函数，用`dwarfdump --uuid live.app/live` 指令确定下Binary Images是否和crash一致。


###总结
在写文章过程中，简单复习了下编译原理与汇编语言，深感程序员的技能树太过庞大，随便一个分支就够学习一辈子。
平时开发遇到问题，习惯性的刨根问底，这次简单把这些知识串联起来，并和工程作相应结合，加深记忆。
文章如有疏漏，敬请指出。


####引用
 * [《程序员的自我修养—链接、装载与库》](https://www.amazon.cn/%E7%A8%8B%E5%BA%8F%E5%91%98%E7%9A%84%E8%87%AA%E6%88%91%E4%BF%AE%E5%85%BB-%E9%93%BE%E6%8E%A5-%E8%A3%85%E8%BD%BD%E4%B8%8E%E5%BA%93-%E6%BD%98%E7%88%B1%E6%B0%91/dp/B0027VSA7U/ref=sr_1_1?ie=UTF8&qid=1481878780&sr=8-1&keywords=%E7%A8%8B%E5%BA%8F%E5%91%98%E7%9A%84%E8%87%AA%E6%88%91%E4%BF%AE%E5%85%BB%E2%80%94%E9%93%BE%E6%8E%A5%E3%80%81%E8%A3%85%E8%BD%BD%E4%B8%8E%E5%BA%93)
 * [C程序编译过程浅析](http://smilejay.com/2012/01/c_compilation_stages/)