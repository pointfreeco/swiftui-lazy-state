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

### Parent-child communication to existing lazy state

Once the lazy state has been initialized it will not be re-initialized when the view is given new
parameters. To propagate changes from the parent to the child you can employ one of two techniques
depending on your situation:

* **Resetting state**: You can completely blow away existing state and re-instantiate fresh state
by changing by reassigning the state from scratch:

  ```diff
   import LazyState
   import SwiftUI

   struct FeatureView: View {
  +  let region: MapRegion
     @LazyState private var model: FeatureModel
     init(region: MapRegion) {
  +    self.region = region
       _model = LazyState { FeatureModel(region: region) }
     }
     var body: some View {
       VStack {
         Text(model.title)
         TextField("Query", text: $model.query)
       }
  +    .onChange(of: region) {
  +      model = FeatureModel(region: region)
  +    }
     }
   }
  ```

  This requires you to hold onto the data that can cause the state to reset and then listen for
changes to that data.

* **Updating child state from the parent**: If you do not want to totally reset the child view's
model, but instead communicate new information to it from a parent, you can employ the above pattern
and invoke a method on the model instead of reassigning the model:

  ```diff
   import LazyState
   import SwiftUI

   struct FeatureView: View {
  +  let region: MapRegion
     @LazyState private var model: FeatureModel
     init(region: MapRegion) {
  +    self.region = region
       _model = LazyState { FeatureModel(region: region) }
     }
     var body: some View {
       VStack {
         Text(model.title)
         TextField("Query", text: $model.query)
       }
  +    .onChange(of: region) {
  +      model.regionUpdated(region)
  +    }
     }
   }
  ```

## Topics

### Declaring lazy state

- ``LazyState()``
