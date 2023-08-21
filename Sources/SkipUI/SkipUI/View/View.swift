// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
// SKIP INSERT: import androidx.compose.foundation.background
// SKIP INSERT: import androidx.compose.foundation.layout.height
// SKIP INSERT: import androidx.compose.foundation.layout.width
// SKIP INSERT: import androidx.compose.runtime.Composable
// SKIP INSERT: import androidx.compose.ui.Modifier
// SKIP INSERT: import androidx.compose.ui.draw.alpha
// SKIP INSERT: import androidx.compose.ui.draw.rotate
// SKIP INSERT: import androidx.compose.ui.draw.scale
// SKIP INSERT: import androidx.compose.ui.platform.testTag
// SKIP INSERT: import androidx.compose.ui.semantics.contentDescription
// SKIP INSERT: import androidx.compose.ui.semantics.semantics
// SKIP INSERT: import androidx.compose.ui.unit.dp

public protocol View {
    /// The transpiler adds `Compose(ctx)` tail calls to compose each view.
    // SKIP INSERT:
    // @Composable fun Compose(ctx: ComposeContext): Unit = body().Compose(ctx)
    //
    // SKIP DECLARE: fun body(): View = EmptyView()
    @ViewBuilder var body: any View { get }
}

extension View {
    @Composable public func Compose() {
        Compose(ComposeContext())
    }
}
#else

/// A type that represents part of your app's user interface and provides
/// modifiers that you use to configure views.
///
/// You create custom views by declaring types that conform to the `View`
/// protocol. Implement the required ``View/body-swift.property`` computed
/// property to provide the content for your custom view.
///
///     struct MyView: View {
///         var body: some View {
///             Text("Hello, World!")
///         }
///     }
///
/// Assemble the view's body by combining one or more of the built-in views
/// provided by SkipUI, like the ``Text`` instance in the example above, plus
/// other custom views that you define, into a hierarchy of views. For more
/// information about creating custom views, see <doc:Declaring-a-Custom-View>.
///
/// The `View` protocol provides a set of modifiers — protocol
/// methods with default implementations — that you use to configure
/// views in the layout of your app. Modifiers work by wrapping the
/// view instance on which you call them in another view with the specified
/// characteristics, as described in <doc:Configuring-Views>.
/// For example, adding the ``View/opacity(_:)`` modifier to a
/// text view returns a new view with some amount of transparency:
///
///     Text("Hello, World!")
///         .opacity(0.5) // Display partially transparent text.
///
/// The complete list of default modifiers provides a large set of controls
/// for managing views.
/// For example, you can fine tune <doc:View-Layout>,
/// add <doc:View-Accessibility> information,
/// and respond to <doc:View-Input-and-Events>.
/// You can also collect groups of default modifiers into new,
/// custom view modifiers for easy reuse.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public protocol View {

    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    associatedtype Body : View

    @ViewBuilder @MainActor var body: Body { get }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Optional : View where Wrapped : View {

    public var body: some View { get { return stubView() } }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Never : View {
}

#endif
