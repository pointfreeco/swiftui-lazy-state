// swift-tools-version: 6.4

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "LazyState",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .tvOS(.v15),
    .watchOS(.v9),
  ],
  products: [
    .library(
      name: "LazyState",
      targets: ["LazyState"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"605.0.0"),
  ],
  targets: [
    .macro(
      name: "LazyStateMacros",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "LazyState",
      dependencies: ["LazyStateMacros"]
    ),
    .testTarget(
      name: "LazyStateTests",
      dependencies: [
        "LazyState",
        "LazyStateMacros",
        .product(name: "MacroTesting", package: "swift-macro-testing"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
  ]
)

for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(contentsOf: [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  ])
}
