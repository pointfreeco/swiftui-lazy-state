import SwiftUI

/// Declares a view property whose value is lazily created by SwiftUI.
///
/// Apply this macro to a stored property of a SwiftUI view in place of `@State` when the property's
/// initial value depends on parameters passed to the view's initializer. Assign the underscored
/// storage a `LazyState` constructed with a closure, and that closure will be invoked only once for
/// the lifetime of the view's identity, no matter how many times the view struct itself is
/// re-created:
///
/// ```swift
/// struct FeatureView: View {
///   @LazyState private var model: FeatureModel
///   init(region: MapRegion) {
///     _model = LazyState { FeatureModel(region: region) }
///   }
///   var body: some View {
///     Text(model.title)
///   }
/// }
/// ```
///
/// Like `@State`, the macro also provides a projected value, so `$model` yields a
/// `Binding<FeatureModel>`.
///
/// The property must be `private` or `fileprivate`, must be a reference type, must have an
/// explicit type annotation, and must not have an inline initial value.
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(_), prefixed(`$`))
public macro LazyState() =
  #externalMacro(
    module: "LazyStateMacros",
    type: "LazyStateMacro"
  )

@_documentation(visibility: private)
@freestanding(declaration)
public macro LazyStateCheck<Value: AnyObject>(_ value: Value.Type) =
  #externalMacro(
    module: "LazyStateMacros",
    type: "LazyStateCheckPassMacro"
  )

@_documentation(visibility: private)
@freestanding(declaration)
public macro LazyStateCheck(_ value: Any.Type) =
  #externalMacro(
    module: "LazyStateMacros",
    type: "LazyStateCheckFailMacro"
  )
