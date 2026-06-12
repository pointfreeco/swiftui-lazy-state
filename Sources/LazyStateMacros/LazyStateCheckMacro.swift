import SwiftDiagnostics
public import SwiftSyntax
import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public struct LazyStateCheckPassMacro: DeclarationMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    []
  }
}

public struct LazyStateCheckFailMacro: DeclarationMacro {
  public static func expansion(
    of node: some FreestandingMacroExpansionSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    let type = node.arguments.first?.expression
      .as(MemberAccessExprSyntax.self)?.base?.trimmedDescription
    context.diagnose(
      Diagnostic(
        node: node.arguments.first.map(Syntax.init) ?? Syntax(node),
        message: MacroExpansionErrorMessage(
          """
          '@LazyState' can only be applied to reference types\
          \(type.map { "; '\($0)' is not a class" } ?? "")
          """
        )
      )
    )
    return []
  }
}
