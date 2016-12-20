###前言
在上文[《编译与链接过程的思考》](http://www.jianshu.com/p/2310b61e687e)评论中[暴走大牙](http://www.jianshu.com/users/1ec036eb8418)提到了静态库和动态库依赖的问题，还在群里提了几个测试样例和测试工程。
大致介绍下测试工程和如何进行测试：
工程P为主工程，其中有4个子工程A、B、C、D，子工程打包的库为动态库或静态库，子工程之间存在依赖关系。
通过修改主工程的依赖库，以及子工程的依赖关系以及打包类型，测试**动态库依赖静态库**、**静态库依赖动态库**、**静态库依赖静态库**的情况。

###正文
在测试之前，先简单说明下静态库和动态库的打包方式
 * **Cocoa Touch Framework **
* Maco-O Type 为 **Static**
打包的.framework文件为静态库
* Maco-O Type 为 **Dynamic**
打包的.framework文件为动态库
 * **Cocoa Touch Static Library**
打包的.a文件为静态库

![](http://upload-images.jianshu.io/upload_images/1049769-3f24cb4ac55c3cc2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

####静态库依赖静态库
**测试环境**
静态库A、B、C均采用Cocoa Touch Framework的打包方式。
 * 静态库A：提供函数foo();
 * 静态库B：提供函数call_foo_b(); 依赖静态库A，在call_foo_b中调用foo();
 * 静态库C：提供函数foo()；
![](http://upload-images.jianshu.io/upload_images/1049769-ecada6df59740d8c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**测试代码**
```
#include "BLib.h"
#include "CLib.h"

- (void)testLib {
    NSLog(@"Test A.");
    call_foo_b();
    
    NSLog(@"Test B.");
    foo();
}
```
**测试结果**
>2016-12-20 09:54:12.931731 testLib[7671:4787567] Test A.
call_foo in BLib.
foo in ALib.
2016-12-20 09:54:12.931925 testLib[7671:4787567] Test B.
foo in ALib.

 * 对于TestA，我们调用B的call_foo_b，然后在call_foo_b中又调用A的foo，打印的调用顺序为B->A，**正常；**
 * 对于TestB，我们引入C的头文件，然后调用C的foo，打印的调用顺序是A，**异常；**

**结果思考🤔**
静态库的生成只有编译，没有链接；
当工程同时存在库A和C时，两个foo的函数符号在链接的时候，先引入者优先；
>验证：把工程依赖顺序从ABC改成CBA之后，结果输出变为
2016-12-20 10:19:28.613791 testLib[7691:4795943] Test A.
call_foo in BLib.
foo in CLib.
2016-12-20 10:19:28.613871 testLib[7691:4795943] Test B.
foo in CLib.

####静态库依赖动态库
**测试环境**
库A、B、C、D均采用Cocoa Touch Framework的打包方式。
 * 动态库A：提供函数foo();
 * 静态库B：提供函数call_foo_b(); 依赖动态库A，在call_foo_b中调用foo();
 * 动态库C：提供函数foo()；
 * 静态库D：提供函数call_foo_d(); 依赖动态库C，在call_foo_d中调用foo();
![](http://upload-images.jianshu.io/upload_images/1049769-799c81fb07826a06.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


**测试代码**
```
#include "BLib.h"
#include "DLib.h"

- (void)testLib {
    NSLog(@"Test lib.");
    call_foo_b();
    call_foo_d();
}
```

**测试结果**
>2016-12-20 10:36:09.389209 testLib[7707:4799800] Test lib.
call_foo in BLib.
foo in ALib.
call_foo in DLib.
foo in ALib.

 * 对于第一组测试，我们调用静态库B的函数call_foo_b，在函数call_foo_b中调用动态库A的函数，**正常**；
 * 对于第二组测试，我们调用静态库D的函数call_foo_d，在函数call_foo_d中调用动态库A的函数，**异常**；（预想中是调用动态库C的函数）

**结果思考🤔**
静态库的生成只有编译，没有链接；
那么在静态库D生成的过程中，只是确定了静态库D需要用到动态库中的foo函数；
当运行时，加载了动态库A、C，其中两个库均含有foo函数；动态链接器，按照加载的顺序，取到动态库A中的foo函数；
所以静态库B、D调用的foo函数均是动态库A中的foo函数。
>验证：我们调换Link Binary With Libraries 中A和C的位置，结果如下
2016-12-20 10:35:11.048034 testLib[7705:4799491] Test lib.
call_foo in BLib.
foo in CLib.
call_foo in DLib.
foo in CLib.


####动态库依赖静态库
**测试环境**
库A、B、C、D均采用Cocoa Touch Framework的打包方式。
 * 静态库A：提供函数foo();
 * 动态库B：提供函数call_foo_b(); 依赖静态库A，在call_foo_b中调用foo();
 * 静态库C：提供函数foo()；
 * 动态库D：提供函数call_foo_d(); 依赖静态库C，在call_foo_d中调用foo();
![](http://upload-images.jianshu.io/upload_images/1049769-184d1de0e987ef37.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**测试代码**
```
#include "BLib.h"
#include "DLib.h"

- (void)testLib {
    NSLog(@"Test lib.");
    call_foo_b();
    call_foo_d();
}
```
**测试结果**
>2016-12-20 11:08:52.715415 testLib[7746:4810080] Test lib.
call_foo in BLib.
foo in ALib.
call_foo in DLib.
foo in CLib.

 * 对于第一组测试，我们调用动态库B的函数call_foo_b，在函数call_foo_b中调用静态库A的函数，**正常**；
 * 对于第二组测试，我们调用动态库D的函数call_foo_d，在函数call_foo_d中调用静态库C的函数，**正常**；

**结果思考🤔**
工程依赖里面只有动态库B、D，没有静态库A、C；
静态库A、C同名函数foo没有冲突；
这两个现象是原因是动态库在生成的过程中，除了编译还有链接的过程。如果动态库依赖静态库，在生成动态库时会将静态库的代码合并到动态库中。

>**扩展**
如果动态库B、D的函数名字使用一样的call_foo，调用顺序和Link Binary With Libraries相关，与embeded的顺序无关；（embeded只是把动态库放入bundle中，关键在于链接器的顺序）



####动态库依赖动态库
**测试环境**
动态库A、B、C、D均采用Cocoa Touch Framework的打包方式。
 * 动态库A：提供函数foo();
 * 动态库B：提供函数call_foo_b(); 依赖动态库A，在call_foo_b中调用foo();
 * 动态库C：提供函数foo()；
 * 动态库D：提供函数call_foo_d(); 依赖动态库C，在call_foo_d中调用foo();
![](http://upload-images.jianshu.io/upload_images/1049769-ba92ea79ca47e310.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**测试代码**
```
#include "BLib.h"
#include "DLib.h"

- (void)testLib {
    NSLog(@"Test lib.");
    call_foo_b();
    call_foo_d();
}

```
**测试结果**
>2016-12-20 11:08:52.715415 testLib[7746:4810080] Test lib.
call_foo in BLib.
foo in ALib.
call_foo in DLib.
foo in CLib.


 * 对于第一组测试，我们调用动态库B的函数call_foo_b，在函数call_foo_b中调用动态库A的foo函数，**正常**；
 * 对于第二组测试，我们调用动态库D的函数call_foo_d，在函数call_foo_d中调用动态库C的foo函数，**正常**；

**结果思考🤔**
四个动态库都需要Link和Embeded；
与静态库依赖动态库的测试样例不同，这次虽然动态库A、C存在同名函数foo，但是调用的时候没有冲突。
动态库依赖动态库，在生成动态库的时候不会把依赖的动态库合并到动态库中。


###总结
静态库的生成只有编译，没有链接；
动态库的生成除了编译还有链接的过程；
**如果动态库依赖静态库，在生成动态库时会将静态库的代码合并到动态库中；**
 * 静态库A依赖静态库B，使用时需要在Link Binary With Libraries引入静态库A、B；
 * 静态库A依赖动态库B，使用时需要在Link Binary With Libraries引入静态库A和动态库B，并且在Embeded Binaries引入动态库B；
 * 动态库A依赖静态库B，使用时需要在Link Binary With Libraries引入动态库A，并且在Embeded Binaries引入动态库A；
 * 动态库A依赖动态库B，使用时需要在Link Binary With Libraries引入动态库A和B，并且在Embeded Binaries引入动态库A和B；

所有的代码都可以在[这里](https://github.com/loyinglin/LearnBuild/tree/master/%E5%8A%A8%E6%80%81%E5%BA%93%E5%92%8C%E9%9D%99%E6%80%81%E5%BA%93)找到。

###扩展--Cocoa Touch Static Library的打包
Cocoa Touch Static Library打包出来的是.a格式的静态库，会把Link Binary With Libraries里面的静态库一起打包到.a静态库中，测试工程[点我](https://github.com/loyinglin/LearnBuild/tree/master/%E5%8A%A8%E6%80%81%E5%BA%93%E5%92%8C%E9%9D%99%E6%80%81%E5%BA%93/test5-%E9%9D%99%E6%80%81%E5%BA%93%E4%BE%9D%E8%B5%96%E9%9D%99%E6%80%81%E5%BA%93.a%E6%89%93%E5%8C%85%E5%BD%A2%E5%BC%8F)。

**如何打包一个静态库，但是不包含其中的依赖库文件？**
>引入依赖库头文件即可，因为静态库只编译不链接。（但是如果Cocoa Touch Static Library 里面填入了第三方的静态库，会自动打包）

.a和.framework都是静态库格式，只是.framework格式包括了静态库文件、头文件、资源文件，故而更容易使用。

**如何直接使用.a静态库，不要静态库的头文件？**
>Link Binary With Libraries中添加.a静态库；
在使用静态库的函数前添加声明，但是不定义实现；
这样编译时，会根据声明在全局查找定义；
