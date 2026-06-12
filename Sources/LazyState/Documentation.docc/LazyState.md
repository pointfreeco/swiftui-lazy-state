# ``LazyState``

A macro for dynamically initializing observable references in SwiftUI views.

## Additional Resources

- [GitHub Repo](https://github.com/pointfreeco/swiftui-lazy-state)
- [Discussions](https://github.com/pointfreeco/swiftui-lazy-state/discussions)
- [Point-Free Videos](https://www.pointfree.co/collections/wwdc/wwdc-2026)

## Overview

SwiftUI's `@State` lazily instantiates its initial value, so that a view like this:

```swift
struct FeatureView: View {
  @State private var model = FeatureModel()
  // ...
}
```

…creates only a single `FeatureModel` no matter how many times `FeatureView` is re-created, at
least until the view's identity changes. However, `@State` does not let you initialize that value
from parameters passed to the view's initializer. Doing so with `State(wrappedValue:)` allocates
a fresh `FeatureModel` every time the view is re-created, only to immediately throw it away.

The ``LazyState()`` macro fixes this. Replace `@State` with `@LazyState` and initialize the state
in the view's initializer using a closure, which is only invoked once:

```swift
import LazyState
import SwiftUI

struct FeatureView: View {
  @LazyState private var model: FeatureModel
  init(region: MapRegion) {
    _model = LazyState { FeatureModel(region: region) }
  }
  var body: some View {
    // ...
  }
}
```

The macro expands to the same kind of code that SwiftUI's own `@State` macro expands to.

### Resetting state

Once the lazy state has been initialized it will not be re-initialized when the view is given new
parameters. To create a fresh model when a parameter changes, change the view's identity:

```swift
FeatureView(region: region)
  .id(region)
```

## Topics

### Declaring lazy state

- ``LazyState()``
