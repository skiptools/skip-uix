// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import androidx.compose.runtime.Composable
import androidx.compose.runtime.saveable.Saver
import androidx.compose.ui.Modifier

/// Context to provide modifiers, parent, etc to composables.
public struct ComposeContext {
    /// Modifiers to apply.
    public var modifier: Modifier = Modifier

    /// Mechanism for a parent view to change how a child view is composed.
    public var composer: Composer?

    /// Use in conjunction with `rememberSaveable` to store view state.
    public var stateSaver: Saver<Any?, Any> = ComposeStateSaver()

    /// The context to pass to child content of a container view.
    ///
    /// By default, modifiers and the `composer` are reset for child content.
    public func content(modifier: Modifier = Modifier, composer: Composer? = nil, stateSaver: Saver<Any?, Any>? = nil) -> ComposeContext {
        var context = self
        context.modifier = modifier
        context.composer = composer
        context.stateSaver = stateSaver ?? self.stateSaver
        return context
    }
}

/// The result of composing content.
///
/// Reserved for future use. Having a return value also expands recomposition scope. See `ComposeView` for details.
public struct ComposeResult {
    public static let ok = ComposeResult()
}

/// Mechanism for a parent view to change how a child view is composed.
public protocol Composer {
}

/// Base type for composers that render content.
public class RenderingComposer : Composer {
    private let compose: (@Composable (View, (Bool) -> ComposeContext) -> Void)?

    /// Optionally provide a compose block to execute instead of subclassing.
    ///
    /// - Note: This is a separate method from the default constructor rather than giving `compose` a default value to work around Kotlin runtime
    ///   crashes related to using composable closures.
    init(compose: @Composable (View, (Bool) -> ComposeContext) -> Void) {
        self.compose = compose
    }

    init() {
        self.compose = nil
    }

    /// Called before a `ComposeView` composes its content.
    public func willCompose() {
    }

    /// Called after a `ComposeView` composes its content.
    public func didCompose(result: ComposeResult) {
    }

    /// Compose the given view's content.
    ///
    /// - Parameter context: The context to use to render the view, optionally retaining this composer.
    @Composable public func Compose(view: View, context: (Bool) -> ComposeContext) {
        if let compose {
            compose(view, context)
        } else {
            view.ComposeContent(context: context(false))
        }
    }
}

/// Base type for composers that are used for side effects.
///
/// Side effect composers are escaping, meaning that if the internal content needs to recompose, the calling context will also recompose.
public class SideEffectComposer : Composer {
    private let compose: (@Composable (View, (Bool) -> ComposeContext) -> ComposeResult)?

    /// Optionally provide a compose block to execute instead of subclassing.
    ///
    /// - Note: This is a separate method from the default constructor rather than giving `compose` a default value to work around Kotlin runtime
    ///   crashes related to using composable closures.
    init(compose: @Composable (View, (Bool) -> ComposeContext) -> ComposeResult) {
        self.compose = compose
    }

    init() {
        self.compose = nil
    }

    @Composable public func Compose(view: View, context: (Bool) -> ComposeContext) -> ComposeResult {
        if let compose {
            return compose(view, context)
        } else {
            return ComposeResult.ok
        }
    }
}

#endif
