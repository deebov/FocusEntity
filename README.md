# FocusEntity

This package was inspired by Apple's examples and Max Frazer's package and is alternative to [FocusEntity](https://github.com/maxxfrazer/FocusEntity/) except that this package uses RayCasting method instead of HitTest

![build](https://github.com/deebov/FocusEntity/workflows/build/badge.svg)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-v1.1.0-orange.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)](https://swift.org/)


## Minimum Requirements
  - Swift 5.0
  - iOS 13.0 (RealityKit)
  - Xcode 11

If you're unfamiliar with using RealityKit, I would also recommend reading Max Frazer's articles on [Getting Started with RealityKit](https://medium.com/@maxxfrazer/getting-started-with-realitykit-3b401d6f6f).

## Installation

### Swift Package Manager

Add the URL of this repository to your Xcode 11+ Project.

`https://github.com/deebov/FocusEntity.git`

---
## Usage

See the [Example](./FocusEntity-Example) for a full working example using SwiftUI

- After installing, import `FocusEntity` to your .swift file
- Create an instance of `let focusSquare = FocusSquare()`, or another `FocusEntity` class.
- Set `focusSquare.arViewDelegate` to the `ARView` it is to be rendered within.
- Set the FocusEntity to auto-update: `focusSquare.setAutoUpdate(to: true)`


If something's not making sense in the Example, [send me a tweet](https://twitter.com/deebov) or Fork & open a Pull Request on this repository to make something more clear.

---

The original code to create this repository has been adapted from one of Apple's examples from 2018, [license also included](LICENSE.origin). I have merely adapted the code to be used and distributed from within a Swift Package, and now further adapted to work with [RealityKit](https://developer.apple.com/documentation/realitykit).
