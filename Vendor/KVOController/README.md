# [KVOController](https://github.com/facebook/KVOController)
[![Build Status](https://img.shields.io/travis/facebook/KVOController/master.svg?style=flat)](https://travis-ci.org/facebook/KVOController)
[![Coverage Status](https://img.shields.io/codecov/c/github/facebook/KVOController/master.svg)](https://codecov.io/github/facebook/KVOController)
[![Version](https://img.shields.io/cocoapods/v/KVOController.svg?style=flat)](http://cocoadocs.org/docsets/KVOController)
[![Platform](https://img.shields.io/cocoapods/p/KVOController.svg?style=flat)](http://cocoadocs.org/docsets/KVOController)

Key-value observing is a particularly useful technique for communicating between layers in a Model-View-Controller application. KVOController builds on Cocoa's time-tested key-value observing implementation. It offers a simple, modern API, that is also thread safe. Benefits include:

- Notification using blocks, custom actions, or NSKeyValueObserving callback.
- No exceptions on observer removal.
- Implicit observer removal on controller dealloc.
- Thread-safety with special guards against observer resurrection – [rdar://15985376](http://openradar.appspot.com/radar?id=5305010728468480).

For more information on KVO, see Apple's [Introduction to Key-Value Observing](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html).

## 关于此版本

此版本不兼容原KVOController接口，在原来基础上，把监听接口作为了NSObject的方法，并且支持对同一个KeyPath添加多个监听block或者action


