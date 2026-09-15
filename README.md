# @LazyState

[![CI](https://github.com/pointfreeco/swiftui-lazy-state/actions/workflows/ci.yml/badge.svg)](https://github.com/pointfreeco/swiftui-lazy-state/actions/workflows/ci.yml)
[![Slack](https://img.shields.io/badge/slack-chat-informational.svg?label=Slack&logo=slack)](https://www.pointfree.co/slack-invite)

A macro for dynamically initializing observable references in SwiftUI views.

## Learn More

The `@LazyState` macro was motivated and designed over the course of episodes on
[Point-Free](https://www.pointfree.co), a video series exploring advanced programming topics in
the Swift language, hosted by [Brandon Williams](https://twitter.com/mbrandonw) and
[Stephen Celis](https://twitter.com/stephencelis).

You can watch all of the episodes [here](https://www.pointfree.co/collections/wwdc/wwdc-2026).

<a href="https://www.pointfree.co/collections/wwdc/wwdc-2026">
  <img alt="video poster image" src="https://imagedelivery.net/6_EEbfI_pxOPJCtc6OUKCg/2fd4916c-658b-4781-b1b8-34ca1fa8d400/public" width="600">
</a>

## The problem

The `@State` macro in SwiftUI will lazily instantiate objects so that views like this: 

```swift
import SwiftUI 

@Observable class FeatureModel { /* ... */ }

struct FeatureView: View {
  @State private var model = FeatureModel()
  // ...
}
```

…create only a single instance of `FeatureModel` no matter how many times `FeatureView` is created,
at least until the view's identity changes.

It does not, however, allow you to initialize state based on parameters that can be passed in from
the outside. For example, if `FeatureModel` required a parameter to be initialized, then doing this:

```swift
import SwiftUI 

@Observable class FeatureModel {
  init(region: MapRegion) { /* ... */ }
  …
}

struct FeatureView: View {
  @State private var model: FeatureModel
  init(region: MapRegion) {
    _model = State(wrappedValue: FeatureModel(region: region))
  }
}
```

…causes a fresh `FeatureModel` to be allocated and immediately deallocated every time the
`FeatureView` is recreated. This can lead to work being executed in your objects that you do not
expect.

## The `@LazyState` solution

This library ships a `@LazyState` macro that fixes the above problem. Simply replace `@State` with
`@LazyState` and initialize the lazy state in the initializer of your view:

```diff
+import LazyState
 import SwiftUI 

 struct FeatureView: View {
-  @State private var model: FeatureModel
+  @LazyState private var model: FeatureModel
   init(region: MapRegion) {
-    _model = State(wrappedValue: FeatureModel(region: region))
+    _model = LazyState { FeatureModel(region: region) }
   }
 }
```

The `FeatureModel` will be created only a single time, no matter how many times `FeatureView` is
created, at least until the view's identity changes.

## The Apple solution

The `@LazyState` macro seems like such an easy solution to the problem that you may wonder why
SwiftUI doesn't have this tool. Or why `@State` isn't lazy by default. A few reasons:

  * `@State` does not have this behavior by default because it can subtly break existing
    applications in certain edge cases. There was a moment during the iOS 17 beta that `@State` was
    made lazy, but it was ultimately reverted.
  * One must be aware of how view identity works to wield this tool properly. Once a view's state
    is initialized it cannot be updated from the outside by providing a new parameter. The state
    must be updated by other means, such as using `onChange(of:)` or `task(id:)` in the view,
    or changing the view's identity.

The pattern that Apple shows in its many demo apps requires you to hold onto optional state as well
as any parameters you want to pass to the object:

```diff
 struct FeatureView: View {
-  @State private var model: FeatureModel
+  @State private var model: FeatureModel?
+  let region: MapRegion
   // ...
 }
```

And initialize the model in an `onAppear`:

```swift
.onAppear {
  model = FeatureModel(region: region)
}
```

This is not ideal for a few reasons:

  * One must hold onto extra state in the view (_i.e._ `region`) that is not needed anywhere in the
    view other than to initialize the model.
  * One must introduce optional chaining and `nil`-coalescing throughout the view hierarchy to work
    around the fact that `model` is now optional.
  * One can no longer derive bindings by doing `$model.results`.
  * `onAppear` is called every time the view appears, not just when the feature is first presented.

Further, this pattern has the same drawback described above that one must be familiar with how
view identity works in SwiftUI to wield correctly. We personally feel that `@LazyState` improves
upon all of these points.

## Does `@LazyState` use private APIs?

No, not at all. The `@LazyState` macro expands code that is very similar to what the `@State`
macro expands to, which is 100% public API in SwiftUI. In particular, it uses a `LazyState` type
that is a public (but undocumented) type in SwiftUI that has been around since the iOS 17 generation
of Apple platforms.

## Requirements

* **Xcode 27 or later** is required to compile this library.
* **iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1** or later are required to use the
  `@LazyState` macro.

## Community

If you want to discuss this library or have a question about how to use it to solve a particular
problem, there are a number of places you can discuss with fellow
[Point-Free](http://www.pointfree.co) enthusiasts:

* For long-form discussions, we recommend the
  [discussions](http://github.com/pointfreeco/swiftui-lazy-state/discussions) tab of this repo.
* For casual chat, we recommend the [Point-Free Community Slack](http://pointfree.co/slack-invite).

## Installation

You can add LazyState to an Xcode project by adding it to your project as a package.

> https://github.com/pointfreeco/swiftui-lazy-state

If you want to use LazyState in a [SwiftPM](https://swift.org/package-manager/) project, it's as
simple as adding it to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/pointfreeco/swiftui-lazy-state", from: "1.0.0")
]
```

And then adding the product to any target that needs access to the library:

```swift
.product(name: "LazyState", package: "swiftui-lazy-state"),
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
