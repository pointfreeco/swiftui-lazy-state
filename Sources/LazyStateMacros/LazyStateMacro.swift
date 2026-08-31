import SwiftDiagnostics
public import SwiftSyntax
import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

public struct LazyStateMacro: AccessorMacro, PeerMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [AccessorDeclSyntax] {
    guard let binding = declaration.as(VariableDeclSyntax.self) else {
      return []
    }
    guard let property = Property(binding) else {
      return []
    }
    return [
      """
      get {
        \(raw: property.backingName).wrappedValue
      }
      """,
      """
      nonmutating set {
        \(raw: property.backingName).wrappedValue = newValue
      }
      """,
    ]
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let binding = declaration.as(VariableDeclSyntax.self) else {
      return []
    }
    guard let property = Property(binding, attribute: node, context: context) else {
      return []
    }
    var declarations: [DeclSyntax] = [
      """
      \(raw: property.modifiers)var \(raw: property.backingName): SwiftUI.LazyState<\(raw: property.type)>
      """,
      """
      \(raw: property.modifiers)var \(raw: property.projectedName): Binding<\(raw: property.type)> {
        get {
          \(raw: property.backingName).projectedValue
        }
      }
      """,
    ]
    if let location = context.location(
      of: declaration,
      at: .afterLeadingTrivia,
      filePathMode: .filePath
    ),
      let file = location.file.as(StringLiteralExprSyntax.self),
      let line = Int(location.line.trimmedDescription),
      line > 1
    {
      declarations.append(
        contentsOf: [
          DeclSyntax(
            PoundSourceLocationSyntax(
              arguments: PoundSourceLocationArgumentsSyntax(
                fileName: SimpleStringLiteralExprSyntax(
                  openingQuote: .stringQuoteToken(),
                  segments: SimpleStringLiteralSegmentListSyntax(
                    file.segments.compactMap { $0.as(StringSegmentSyntax.self) }
                  ),
                  closingQuote: .stringQuoteToken()
                ),
                lineNumber: .integerLiteral("\(line - 1)")
              )
            )
          ),
          "#LazyStateCheck(\(raw: property.type).self)",
          DeclSyntax(PoundSourceLocationSyntax()),
        ]
      )
    }
    return declarations
  }
}

extension LazyStateMacro {
  private struct Property {
    let modifiers: String
    let type: String
    let backingName: String
    let projectedName: String

    init?(
      _ declaration: VariableDeclSyntax,
      attribute: AttributeSyntax,
      context: some MacroExpansionContext
    ) {
      guard let property = Self(declaration) else {
        Self.propertyDiagnostic(for: declaration, attribute: attribute, in: context)
        return nil
      }
      self = property
    }

    init?(_ declaration: VariableDeclSyntax) {
      guard declaration.bindings.count == 1,
        let binding = declaration.bindings.first,
        declaration.bindingSpecifier.tokenKind == .keyword(.var),
        declaration.modifiers.contains(where: {
          Self.allowedAccessModifiers.contains($0.name.tokenKind)
        }),
        binding.accessorBlock == nil,
        binding.initializer == nil,
        let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
        let type = binding.typeAnnotation?.type
      else {
        return nil
      }

      self.modifiers =
        declaration.modifiers.trimmedDescription.isEmpty
        ? ""
        : declaration.modifiers.trimmedDescription + " "
      self.type = type.trimmedDescription
      self.backingName = "_\(pattern.identifier.text)"
      self.projectedName = "$\(pattern.identifier.text)"
    }

    private static let allowedAccessModifiers: Set<TokenKind> = [
      .keyword(.private),
      .keyword(.fileprivate),
    ]

    private static func propertyDiagnostic(
      for declaration: VariableDeclSyntax,
      attribute: AttributeSyntax,
      in context: some MacroExpansionContext
    ) {
      guard declaration.bindings.count == 1,
        let binding = declaration.bindings.first
      else {
        return
      }
      if declaration.bindingSpecifier.tokenKind != .keyword(.var) {
        context.diagnose(
          Diagnostic(
            node: Syntax(declaration.bindingSpecifier),
            message: MacroExpansionErrorMessage(
              "'@LazyState' can only be applied to 'var' declarations"
            ),
            fixIt: FixIt(
              message: MacroExpansionFixItMessage(
                "Replace '\(declaration.bindingSpecifier.text)' with 'var'"
              ),
              changes: [
                .replace(
                  oldNode: Syntax(declaration.bindingSpecifier),
                  newNode: Syntax(
                    TokenSyntax.keyword(
                      .var,
                      leadingTrivia: declaration.bindingSpecifier.leadingTrivia,
                      trailingTrivia: declaration.bindingSpecifier.trailingTrivia
                    )
                  )
                )
              ]
            )
          )
        )
        return
      }
      if !declaration.modifiers.contains(where: {
        allowedAccessModifiers.contains($0.name.tokenKind)
      }) {
        let accessModifiers: Set<TokenKind> = [
          .keyword(.internal),
          .keyword(.open),
          .keyword(.package),
          .keyword(.public),
        ]
        var modifiers = declaration.modifiers
        let fixItMessage: String
        if let index = modifiers.firstIndex(where: { accessModifiers.contains($0.name.tokenKind) })
        {
          fixItMessage = "Replace '\(modifiers[index].name.text)' with 'private'"
          modifiers[index].name = .keyword(
            .private,
            leadingTrivia: modifiers[index].name.leadingTrivia,
            trailingTrivia: modifiers[index].name.trailingTrivia
          )
        } else {
          fixItMessage = "Insert 'private'"
          modifiers.insert(
            DeclModifierSyntax(name: .keyword(.private), trailingTrivia: .space),
            at: modifiers.startIndex
          )
        }
        context.diagnose(
          Diagnostic(
            node: Syntax(declaration),
            message: MacroExpansionErrorMessage(
              "'@LazyState' properties must be declared 'private' or 'fileprivate'"
            ),
            fixIt: FixIt(
              message: MacroExpansionFixItMessage(fixItMessage),
              changes: [
                .replace(
                  oldNode: Syntax(declaration),
                  newNode: Syntax(declaration.with(\.modifiers, modifiers))
                )
              ]
            )
          )
        )
        return
      }
      if binding.accessorBlock != nil {
        context.diagnose(
          Diagnostic(
            node: Syntax(binding),
            message: MacroExpansionErrorMessage(
              "'@LazyState' can only be applied to stored properties"
            )
          )
        )
        return
      }
      if let initializer = binding.initializer {
        context.diagnose(
          Diagnostic(
            node: Syntax(initializer),
            message: MacroExpansionErrorMessage(
              "'@LazyState' properties cannot have an initial value; use '@State', instead"
            ),
            fixIt: FixIt(
              message: MacroExpansionFixItMessage("Replace '@LazyState' with '@State'"),
              changes: [
                .replace(
                  oldNode: Syntax(attribute),
                  newNode: Syntax(
                    attribute.with(
                      \.attributeName,
                      TypeSyntax(IdentifierTypeSyntax(name: "State"))
                        .with(\.leadingTrivia, attribute.attributeName.leadingTrivia)
                        .with(\.trailingTrivia, attribute.attributeName.trailingTrivia)
                    )
                  )
                )
              ]
            )
          )
        )
        return
      }
      if binding.pattern.as(IdentifierPatternSyntax.self) == nil {
        context.diagnose(
          Diagnostic(
            node: Syntax(binding.pattern),
            message: MacroExpansionErrorMessage(
              "'@LazyState' requires a simple identifier"
            )
          )
        )
        return
      }
      if binding.typeAnnotation?.type == nil {
        context.diagnose(
          Diagnostic(
            node: Syntax(binding.pattern),
            message: MacroExpansionErrorMessage(
              "'@LazyState' requires an explicit type annotation"
            )
          )
        )
      }
    }
  }
}
