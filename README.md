# PresentFlow

PresentFlow 是基于 ViewFlow 的 展示流操作模块，为 SwiftUI 提供方便的展示和消失界面功能。

PresentFlow 是自定义 RSV(Resource & State & View) 设计模式中 State 层的应用模块，同时也是 View 层的应用模块。负责 View 的提供可操作的展示流。

[![Swift](https://github.com/miejoy/present-flow/actions/workflows/test.yml/badge.svg)](https://github.com/miejoy/present-flow/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/miejoy/present-flow/branch/main/graph/badge.svg)](https://codecov.io/gh/miejoy/present-flow)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/swift-5.4-brightgreen.svg)](https://swift.org)

## 依赖

- iOS 15.0+ / macOS 12+
- Xcode 14.0+
- Swift 5.6+

## 简介

### 该模块包含如下内容:

1、PresentState: 展示核心状态，对应 Store 叫展示管理器，外部可通过这个管理器对展示流进行各种操作，如果 展示、消失、冻结等
2、PresentAction: 展示管理器操作事件，主要对外提供 展示(present)、消失(dismiss)、冻结(freeze) 三类事件
3、PresentFlowView: 展示流包装界面，如果需要可操作的展示流，必须在最跟不使用该界面包装起来，用 PresentModifier 修饰是同样的效果
4、PresentableView: 可展示界面协议，所以需要展示的界面需要遵循这个协议
5、PresentRoute: 展示界面路由，每个可展示界面都有一个默认的展示路由，可通过这个路由找到展示流中的对应界面
6、PresentCenter: 展示中心，用于注册可展示界面

### 为 SwiftUI 提供的如下环境变量:

1、presentManager: 展示管理器，实际是展示状态的存储器，外部可通过这个管理器对展示流进行各种操作
2、presentLevel: 当前展示层级，外部仅提供读取，不支持人为设置
3、presentedCloseView: 导航栏左侧关闭按钮，可通过设置环境变量全局修改

## 安装

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

在项目中的 Package.swift 文件添加如下依赖:

```swift
dependencies: [
    .package(url: "https://github.com/miejoy/present-flow.git", from: "0.1.0"),
]
```

## 使用

### 前置准备工作

1、使用 PresentFlowView 包装需要展示流的界面（这里使用展示修饰器 PresentModifier() 是一样的效果）
2、使用 registerPresentOn 方法注册可展示界面，注册的界面可直接用路由来展示，不需要知道对应界面

```swift
import SwiftUI
import PresentFlow

@main
struct MainView: View {
    var body: some View {
        // 使用数据流包装器
        PresentFlowView {
            PresentRootView()
        }
        .registerPresentOn { presentCenter in
            // 注册路由对应展示界面
            presentCenter.registerPresentableView(PresentThirdView.self, for: RouteTo.thirdView)
            presentCenter.registerPresentableView(PresentFourthView.self, for: RouteTo.fourthView)
        }
    }
}

### 使用展示管理器展示界面

有如下两种方式出发点展示:
1、使用展示管理器提供的方法展示界面
2、使用 DataFlow 方式发送展示事件

有如下两类方式展示界面:
1、使用 PresentableView 对应界面类型直接展示，这种适用于当前界面知道被展示界面类型时使用
2、使用 PresentRoute 方式展示界面，这种方式适用于当前界面不知道被展示界面的具体类型时使用

```swift
import SwiftUI
import PresentFlow

struct PresentRootView: View {
    
    // 读取环境中的展示管理器
    @Environment(\.presentManager) var presentManager
    
    var body: some View {
        VStack {
            Button(action: {
                // 推荐
                presentManager.present(PresentFirstView.self)
            }) {
                Text("Present One")
            }
            Button(action: {
                // 可以用展示管理器直接展示
                presentManager.present(PresentFirstView.self)
                // 也可以用 DataFlow 方式发送展示事件
                presentManager.send(action: .present(PresentSecondView.self))
            }) {
                Text("Present Two")
            }
            Button(action: {
                // 使用路由方式展示界面
                presentManager.present(PresentThirdView.defaultRoute, "test")
            }) {
                Text("Present With Route")
            }
        }
    }
}
```

### 使用展示管理器消失界面

有如下两种方式消失界面:
1、使用系统的 dismiss 环境变量消失界面(推荐)
2、使用展示管理器提供的方法消失界面（销毁当前界面需要配合 presentLevel 使用）

```swift
import SwiftUI
import PresentFlow

struct PresentFirstView: VoidPresentableView {
    
    @Environment(\.dismiss) var dismiss         // 推荐
    @Environment(\.presentManager) var presentManager
    @Environment(\.presentLevel) var level
    
    var content: some View {
        VStack {
            Button(action: {
                // 使用系统默认消失方法同样有效
                dismiss()
            }) {
                Text("Dismiss Use Default")
            }
            Button(action: {
                // 使用展示管理器消失顶层界面
                presentManager.dismiss()
            }) {
                Text("Dismiss Use Manager")
            }
            Button(action: {
                // 使用展示管理器消失当前界面
                presentManager.dismissViewOnLevel(level)
            }) {
                Text("Dismiss Use Manager")
            }
        }
    }
}
```

### 使用展示管理器冻结界面

冻结的界面只能用代码消失，或者解冻后消失。可以防止用户用手势消失界面

```swift
import SwiftUI
import PresentFlow

struct PresentSecondView: VoidPresentableView {
    @Environment(\.presentManager) var presentManager
    @Environment(\.presentLevel) var level
    
    var content: some View {
        VStack {
            Button(action: {
                presentManager.send(action: .freezeTopView())
            }) {
                Text("Freeze Top View")
            }
            Button(action: {
                presentManager.send(action: .freezeViewOnLevel(level))
            }) {
                Text("Freeze This View")
            }
            Button(action: {
                presentManager.send(action: .unfreezeViewOnLevel(level))
            }) {
                Text("Unfreeze This View")
            }
        }
    }
}
```

## 作者

Raymond.huang: raymond0huang@gmail.com

## License

PresentFlow is available under the MIT license. See the LICENSE file for more info.

