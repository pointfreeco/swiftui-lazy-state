import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct LazyStateMacrosPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    LazyStateCheckFailMacro.self,
    LazyStateCheckPassMacro.self,
    LazyStateMacro.self,
  ]
}
