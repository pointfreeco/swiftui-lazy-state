#if os(macOS)
  import MacroTesting
  import SnapshotTesting
  import Testing

  @testable import LazyStateMacros

  @Suite(
    .macros(
      [LazyStateMacro.self],
      record: .missing
    )
  )
  struct LazyStateMacroTests {
    @Test
    func basics() {
      assertMacro {
        """
        struct MyView: View {
          @LazyState private var model: Model
          init(id: Int) {
            _model = LazyState(initialValue: { Model(id: id) })
          }
          var body: some View { EmptyView() }
        }
        """
      } expansion: {
        """
        struct MyView: View {
          private var model: Model {
            get {
              _model.wrappedValue
            }
            nonmutating set {
              _model.wrappedValue = newValue
            }
          }

          private var _model: SwiftUI.LazyState<Model>

          private var $model: Binding<Model> {
            get {
              _model.projectedValue
            }
          }

          #sourceLocation(file: "Test.swift", line: 1)

          #LazyStateCheck(Model.self)

          #sourceLocation()
          init(id: Int) {
            _model = LazyState(initialValue: { Model(id: id) })
          }
          var body: some View { EmptyView() }
        }
        """
      }
    }

    @Test
    func rejectsInitializer() {
      assertMacro {
        """
        struct MyView {
          @LazyState private var model: Model = Model(id: 1)
        }
        """
      } diagnostics: {
        """
        struct MyView {
          @LazyState private var model: Model = Model(id: 1)
                                              ┬─────────────
                                              ╰─ 🛑 '@LazyState' properties cannot have an initial value; use '@State', instead
                                                 ✏️ Replace '@LazyState' with '@State'
        }
        """
      } fixes: {
        """
        struct MyView {
          @State private var model: Model = Model(id: 1)
        }
        """
      } expansion: {
        """
        struct MyView {
          @State private var model: Model = Model(id: 1)
        }
        """
      }
    }

    @Test
    func requiresPrivate() {
      assertMacro {
        """
        struct MyView {
          @LazyState var model: Model
        }
        """
      } diagnostics: {
        """
        struct MyView {
          @LazyState var model: Model
          ┬──────────────────────────
          ╰─ 🛑 '@LazyState' properties must be declared 'private' or 'fileprivate'
             ✏️ Insert 'private'
        }
        """
      } fixes: {
        """
        struct MyView {
          @LazyState private var model: Model
        }
        """
      } expansion: {
        """
        struct MyView {
          private var model: Model {
            get {
              _model.wrappedValue
            }
            nonmutating set {
              _model.wrappedValue = newValue
            }
          }

          private var _model: SwiftUI.LazyState<Model>

          private var $model: Binding<Model> {
            get {
              _model.projectedValue
            }
          }

          #sourceLocation(file: "Test.swift", line: 1)

          #LazyStateCheck(Model.self)

          #sourceLocation()
        }
        """
      }
    }

    @Test
    func requiresPrivateReplacingPublic() {
      assertMacro {
        """
        struct MyView {
          @LazyState public var model: Model
        }
        """
      } diagnostics: {
        """
        struct MyView {
          @LazyState public var model: Model
          ┬─────────────────────────────────
          ╰─ 🛑 '@LazyState' properties must be declared 'private' or 'fileprivate'
             ✏️ Replace 'public' with 'private'
        }
        """
      } fixes: {
        """
        struct MyView {
          @LazyState private var model: Model
        }
        """
      } expansion: {
        """
        struct MyView {
          private var model: Model {
            get {
              _model.wrappedValue
            }
            nonmutating set {
              _model.wrappedValue = newValue
            }
          }

          private var _model: SwiftUI.LazyState<Model>

          private var $model: Binding<Model> {
            get {
              _model.projectedValue
            }
          }

          #sourceLocation(file: "Test.swift", line: 1)

          #LazyStateCheck(Model.self)

          #sourceLocation()
        }
        """
      }
    }

    @Test
    func requiresStoredProperty() {
      assertMacro {
        """
        struct MyView {
          @LazyState private var model: Model {
            Model(id: 1)
          }
        }
        """
      } diagnostics: {
        """
        struct MyView {
          @LazyState private var model: Model {
                                 ╰─ 🛑 '@LazyState' can only be applied to stored properties
            Model(id: 1)
          }
        }
        """
      }
    }

    @Test
    func requiresVar() {
      assertMacro {
        """
        struct MyView {
          @LazyState private let model: Model
        }
        """
      } diagnostics: {
        """
        struct MyView {
          @LazyState private let model: Model
                             ┬──
                             ╰─ 🛑 '@LazyState' can only be applied to 'var' declarations
                                ✏️ Replace 'let' with 'var'
        }
        """
      } fixes: {
        """
        struct MyView {
          @LazyState private var model: Model
        }
        """
      } expansion: {
        """
        struct MyView {
          private var model: Model {
            get {
              _model.wrappedValue
            }
            nonmutating set {
              _model.wrappedValue = newValue
            }
          }

          private var _model: SwiftUI.LazyState<Model>

          private var $model: Binding<Model> {
            get {
              _model.projectedValue
            }
          }

          #sourceLocation(file: "Test.swift", line: 1)

          #LazyStateCheck(Model.self)

          #sourceLocation()
        }
        """
      }
    }

    @Test
    func lazyStateCheckFail() {
      assertMacro(["LazyStateCheck": LazyStateCheckFailMacro.self]) {
        """
        #LazyStateCheck(Int.self)
        """
      } diagnostics: {
        """
        #LazyStateCheck(Int.self)
                        ┬───────
                        ╰─ 🛑 '@LazyState' can only be applied to reference types; 'Int' is not a class
        """
      }
    }

    @Test
    func requiresSimpleIdentifier() {
      assertMacro {
        """
        struct MyView {
          @LazyState private var (model, count): (Model, Int)
        }
        """
      } diagnostics: {
        """
        struct MyView {
          @LazyState private var (model, count): (Model, Int)
                                 ┬─────────────
                                 ╰─ 🛑 '@LazyState' requires a simple identifier
        }
        """
      }
    }

    @Test
    func `fileprivate properties are allowed`() {
      assertMacro {
        """
        struct MyView {
          @LazyState fileprivate var model: Model
        }
        """
      } expansion: {
        """
        struct MyView {
          fileprivate var model: Model {
            get {
              _model.wrappedValue
            }
            nonmutating set {
              _model.wrappedValue = newValue
            }
          }

          fileprivate var _model: SwiftUI.LazyState<Model>

          fileprivate var $model: Binding<Model> {
            get {
              _model.projectedValue
            }
          }

          #sourceLocation(file: "Test.swift", line: 1)

          #LazyStateCheck(Model.self)

          #sourceLocation()
        }
        """
      }
    }

    @Test
    func `require a type annotation`() {
      assertMacro {
        """
        struct MyView {
          @LazyState private var model
        }
        """
      } diagnostics: {
        """
        struct MyView {
          @LazyState private var model
                                 ┬────
                                 ╰─ 🛑 '@LazyState' requires an explicit type annotation
        }
        """
      }
    }
  }
#endif
