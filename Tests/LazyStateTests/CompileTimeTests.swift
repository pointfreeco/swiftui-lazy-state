import LazyState
import SwiftUI

enum LazyStateQualification {
  struct LazyState {}
  class Model {}

  struct MyView: View {
    @LazyState private var model: Model
    init(model: Model) {
      _model = SwiftUI.LazyState { Model() }
    }
    var body: some View {}
  }
}
