// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import SkipModel

import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.focus.FocusRequester

public final class FocusState<Value>: StateTracker {
    public init() {
        _wrappedValue = initialValue
        StateTracking.register(self)
    }

    internal var initialValue: Value {
        return false as Value // FIXME: Should be set to `nil` or `false` based on the type of Value, but it must be reified to check?
    }

    public var wrappedValue: Value {
        get {
            if let _wrappedValueState {
                return _wrappedValueState.value
            }
            return _wrappedValue
        }
        set {
            _wrappedValue = newValue
            _wrappedValueState?.value = _wrappedValue
        }
    }
    private var _wrappedValue: Value
    private var _wrappedValueState: MutableState<Value>?

    public func trackState() {
        _wrappedValueState = mutableStateOf(_wrappedValue)
    }
}

extension View {
    public func focused<Value>(_ binding: FocusState<Value>, equals value: Value) -> some View {
        return ComposeModifierView(targetView: self) { context in
            let focusRequester = remember { FocusRequester() }
            context.modifier = context.modifier
                .focusRequester(focusRequester)
                .onFocusChanged {
                    if $0.hasFocus {
                        binding.wrappedValue = value
                    } else if binding.wrappedValue == value {
                        binding.wrappedValue = binding.initialValue
                    }
                }
            if value == binding.wrappedValue {
                SideEffect { focusRequester.requestFocus() }
            }
            return ComposeResult.ok
        }
        return self
    }

    public func focused(_ condition: FocusState<Bool>) -> some View {
        return focused(condition, equals: true)
    }
}
#endif

// TODO: Process for use in SkipUI

#if false
import protocol Combine.ObservableObject

/// Values describe different focus interactions that a view can support.
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public struct FocusInteractions : OptionSet, Sendable {

    /// The view has a primary action that can be activated via focus gestures.
    ///
    /// On macOS and iOS, focus-driven activation interactions are only possible
    /// when all-controls keyboard navigation is enabled. On tvOS and watchOS,
    /// focus-driven activation interactions are always possible.
    public static let activate: FocusInteractions = { fatalError() }()

    /// The view captures input from non-spatial sources like a keyboard or
    /// Digital Crown.
    ///
    /// Views that support focus-driven editing interactions become focused when
    /// the user taps or clicks on them, or when the user issues a focus
    /// movement command.
    public static let edit: FocusInteractions = { fatalError() }()

    /// The view supports whatever focus-driven interactions are commonly
    /// expected for interactive content on the current platform.
    public static var automatic: FocusInteractions { get { fatalError() } }

    /// The corresponding value of the raw type.
    ///
    /// A new instance initialized with `rawValue` will be equivalent to this
    /// instance. For example:
    ///
    ///     enum PaperSize: String {
    ///         case A4, A5, Letter, Legal
    ///     }
    ///
    ///     let selectedSize = PaperSize.Letter
    ///     print(selectedSize.rawValue)
    ///     // Prints "Letter"
    ///
    ///     print(selectedSize == PaperSize(rawValue: selectedSize.rawValue)!)
    ///     // Prints "true"
    public var rawValue: Int { get { fatalError() } }

    /// Creates a new option set from the given raw value.
    ///
    /// This initializer always succeeds, even if the value passed as `rawValue`
    /// exceeds the static properties declared as part of the option set. This
    /// example creates an instance of `ShippingOptions` with a raw value beyond
    /// the highest element, with a bit mask that effectively contains all the
    /// declared static members.
    ///
    ///     let extraOptions = ShippingOptions(rawValue: 255)
    ///     print(extraOptions.isStrictSuperset(of: .all))
    ///     // Prints "true"
    ///
    /// - Parameter rawValue: The raw value of the option set to create. Each bit
    ///   of `rawValue` potentially represents an element of the option set,
    ///   though raw values may include bits that are not defined as distinct
    ///   values of the `OptionSet` type.
    public init(rawValue: Int) { fatalError() }

    /// The type of the elements of an array literal.
    public typealias ArrayLiteralElement = FocusInteractions

    /// The element type of the option set.
    ///
    /// To inherit all the default implementations from the `OptionSet` protocol,
    /// the `Element` type must be `Self`, the default.
    public typealias Element = FocusInteractions

    /// The raw type that can be used to represent all values of the conforming
    /// type.
    ///
    /// Every distinct value of the conforming type has a corresponding unique
    /// value of the `RawValue` type, but there may be values of the `RawValue`
    /// type that don't have a corresponding value of the conforming type.
    public typealias RawValue = Int
}

/// A property wrapper type that can read and write a value that SkipUI updates
/// as the placement of focus within the scene changes.
///
/// Use this property wrapper in conjunction with ``View/focused(_:equals:)``
/// and ``View/focused(_:)`` to
/// describe views whose appearance and contents relate to the location of
/// focus in the scene. When focus enters the modified view, the wrapped value
/// of this property updates to match a given prototype value. Similarly, when
/// focus leaves, the wrapped value of this property resets to `nil`
/// or `false`. Setting the property's value programmatically has the reverse
/// effect, causing focus to move to the view associated with the
/// updated value.
///
/// In the following example of a simple login screen, when the user presses the
/// Sign In button and one of the fields is still empty, focus moves to that
/// field. Otherwise, the sign-in process proceeds.
///
///     struct LoginForm {
///         enum Field: Hashable {
///             case username
///             case password
///         }
///
///         @State private var username = ""
///         @State private var password = ""
///         @FocusState private var focusedField: Field?
///
///         var body: some View {
///             Form {
///                 TextField("Username", text: $username)
///                     .focused($focusedField, equals: .username)
///
///                 SecureField("Password", text: $password)
///                     .focused($focusedField, equals: .password)
///
///                 Button("Sign In") {
///                     if username.isEmpty {
///                         focusedField = .username
///                     } else if password.isEmpty {
///                         focusedField = .password
///                     } else {
///                         handleLogin(username, password)
///                     }
///                 }
///             }
///         }
///     }
///
/// To allow for cases where focus is completely absent from a view tree, the
/// wrapped value must be either an optional or a Boolean. Set the focus binding
/// to `false` or `nil` as appropriate to remove focus from all bound fields.
/// You can also use this to remove focus from a ``TextField`` and thereby
/// dismiss the keyboard.
///
/// ### Avoid ambiguous focus bindings
///
/// The same view can have multiple focus bindings. In the following example,
/// setting `focusedField` to either `name` or `fullName` causes the field
/// to receive focus:
///
///     struct ContentView: View {
///         enum Field: Hashable {
///             case name
///             case fullName
///         }
///         @FocusState private var focusedField: Field?
///
///         var body: some View {
///             TextField("Full Name", ...)
///                 .focused($focusedField, equals: .name)
///                 .focused($focusedField, equals: .fullName)
///         }
///     }
///
/// On the other hand, binding the same value to two views is ambiguous. In
/// the following example, two separate fields bind focus to the `name` value:
///
///     struct ContentView: View {
///         enum Field: Hashable {
///             case name
///             case fullName
///         }
///         @FocusState private var focusedField: Field?
///
///         var body: some View {
///             TextField("Name", ...)
///                 .focused($focusedField, equals: .name)
///             TextField("Full Name", ...)
///                 .focused($focusedField, equals: .name) // incorrect re-use of .name
///         }
///     }
///
/// If the user moves focus to either field, the `focusedField` binding updates
/// to `name`. However, if the app programmatically sets the value to `name`,
/// SkipUI chooses the first candidate, which in this case is the "Name"
/// field. SkipUI also emits a runtime warning in this case, since the repeated
/// binding is likely a programmer error.
///
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@frozen @propertyWrapper public struct FocusState<Value> : DynamicProperty where Value : Hashable {

    /// A property wrapper type that can read and write a value that indicates
    /// the current focus location.
    @frozen @propertyWrapper public struct Binding {

        /// The underlying value referenced by the bound property.
        public var wrappedValue: Value { get { fatalError() } nonmutating set { } }

        /// A projection of the binding value that returns a binding.
        ///
        /// Use the projected value to pass a binding value down a view
        /// hierarchy.
        public var projectedValue: FocusState<Value>.Binding { get { fatalError() } }

        public init(wrappedValue: Value) { fatalError() }

    }

    /// The current state value, taking into account whatever bindings might be
    /// in effect due to the current location of focus.
    ///
    /// When focus is not in any view that is bound to this state, the wrapped
    /// value will be `nil` (for optional-typed state) or `false` (for `Bool`-
    /// typed state).
    public var wrappedValue: Value { get { fatalError() } nonmutating set { } }

    /// A projection of the focus state value that returns a binding.
    ///
    /// When focus is outside any view that is bound to this state, the wrapped
    /// value is `nil` for optional-typed state or `false` for Boolean state.
    ///
    /// In the following example of a simple navigation sidebar, when the user
    /// presses the Filter Sidebar Contents button, focus moves to the sidebar's
    /// filter text field. Conversely, if the user moves focus to the sidebar's
    /// filter manually, then the value of `isFiltering` automatically
    /// becomes `true`, and the sidebar view updates.
    ///
    ///     struct Sidebar: View {
    ///         @State private var filterText = ""
    ///         @FocusState private var isFiltering: Bool
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 Button("Filter Sidebar Contents") {
    ///                     isFiltering = true
    ///                 }
    ///
    ///                 TextField("Filter", text: $filterText)
    ///                     .focused($isFiltering)
    ///             }
    ///         }
    ///     }
    public var projectedValue: FocusState<Value>.Binding { get { fatalError() } }

    /// Creates a focus state that binds to a Boolean.
    public init() where Value == Bool { fatalError() }

    /// Creates a focus state that binds to an optional type.
    public init<T>() where Value == T?, T : Hashable { fatalError() }
}

/// A convenience property wrapper for observing and automatically unwrapping
/// state bindings from the focused view or one of its ancestors.
///
/// If multiple views publish bindings using the same key, the wrapped property
/// will reflect the value of the binding from the view closest to focus.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper public struct FocusedBinding<Value> : DynamicProperty {

    /// A new property wrapper for the given key path.
    ///
    /// The value of the property wrapper is updated dynamically as focus
    /// changes and different published bindings go in and out of scope.
    ///
    /// - Parameter keyPath: The key path for the focus value to read.
    public init(_ keyPath: KeyPath<FocusedValues, Binding<Value>?>) { fatalError() }

    /// The unwrapped value for the focus key given the current scope and state
    /// of the focused view hierarchy.
    @inlinable public var wrappedValue: Value? { get { fatalError() } nonmutating set { } }

    /// A binding to the optional value.
    ///
    /// The unwrapped value is `nil` when no focused view hierarchy has
    /// published a corresponding binding.
    public var projectedValue: Binding<Value?> { get { fatalError() } }
}

/// A property wrapper type for an observable object supplied by the focused
/// view or one of its ancestors.
///
/// Focused objects invalidate the current view whenever the observable object
/// changes. If multiple views publish a focused object using the same key, the
/// wrapped property will reflect the object that's closest to the focused view.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@frozen @propertyWrapper public struct FocusedObject<ObjectType> : DynamicProperty where ObjectType : ObservableObject {

    /// A wrapper around the underlying focused object that can create bindings
    /// to its properties using dynamic member lookup.
    @dynamicMemberLookup @frozen public struct Wrapper {

        /// Returns a binding to the value of a given key path.
        ///
        /// - Parameter keyPath: A key path to a specific value on the
        ///   wrapped object.
        /// - Returns: A new binding.
        public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, T>) -> Binding<T> { get { fatalError() } }
    }

    /// The underlying value referenced by the focused object.
    ///
    /// This property provides primary access to the value's data. However, you
    /// don't access `wrappedValue` directly. Instead, you use the property
    /// variable created with the ``FocusedObject`` attribute.
    ///
    /// When a mutable value changes, the new value is immediately available.
    /// However, a view displaying the value is updated asynchronously and may
    /// not show the new value immediately.
    @MainActor @inlinable public var wrappedValue: ObjectType? { get { fatalError() } }

    /// A projection of the focused object that creates bindings to its
    /// properties using dynamic member lookup.
    ///
    /// Use the projected value to pass a focused object down a view hierarchy.
    @MainActor public var projectedValue: FocusedObject<ObjectType>.Wrapper? { get { fatalError() } }

    /// Creates a focused object.
    public init() { fatalError() }
}

/// A property wrapper for observing values from the focused view or one of its
/// ancestors.
///
/// If multiple views publish values using the same key, the wrapped property
///  will reflect the value from the view closest to focus.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
@propertyWrapper public struct FocusedValue<Value> : DynamicProperty {

    /// A new property wrapper for the given key path.
    ///
    /// The value of the property wrapper is updated dynamically as focus
    /// changes and different published values go in and out of scope.
    ///
    /// - Parameter keyPath: The key path for the focus value to read.
    public init(_ keyPath: KeyPath<FocusedValues, Value?>) { fatalError() }

    /// The value for the focus key given the current scope and state of the
    /// focused view hierarchy.
    ///
    /// Returns `nil` when nothing in the focused view hierarchy exports a
    /// value.
    @inlinable public var wrappedValue: Value? { get { fatalError() } }
}

/// A protocol for identifier types used when publishing and observing focused
/// values.
///
/// Unlike ``EnvironmentKey``, `FocusedValueKey` has no default value
/// requirement, because the default value for a key is always `nil`.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public protocol FocusedValueKey {

    associatedtype Value
}

/// A collection of state exported by the focused view and its ancestors.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct FocusedValues {

    /// Reads and writes values associated with a given focused value key.
    public subscript<Key>(key: Key.Type) -> Key.Value? where Key : FocusedValueKey { get { fatalError() } }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension FocusedValues : Equatable {
}

/// Prioritizations for default focus preferences when evaluating where
/// to move focus in different circumstances.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct DefaultFocusEvaluationPriority : Sendable {

    /// Use the default focus preference when focus moves into the affected
    /// branch automatically, but ignore it when the movement is driven by a
    /// user-initiated navigation command.
    public static let automatic: DefaultFocusEvaluationPriority = { fatalError() }()

    /// Always use the default focus preference when focus moves into the
    /// affected branch.
    public static let userInitiated: DefaultFocusEvaluationPriority = { fatalError() }()
}


extension View {

    /// Defines a region of the window in which default focus is evaluated by
    /// assigning a value to a given focus state binding.
    ///
    /// By default, SkipUI evaluates default focus when the window first
    /// appears, and when a focus state binding update moves focus
    /// automatically, but not when responding to user-driven navigation
    /// commands.
    ///
    /// Clients can override the default behavior by specifying an evaluation
    /// priority of ``DefaultFocusEvaluationPriority/userInitiated``, which
    /// causes SkipUI to use the client's preferred default focus in response
    /// to user-driven focus navigation as well as automatic changes.
    ///
    /// In the following example, focus automatically goes to the second of the
    /// two text fields when the view is first presented in the window.
    ///
    ///     WindowGroup {
    ///         VStack {
    ///             TextField(...)
    ///                 .focused($focusedField, equals: .firstField)
    ///             TextField(...)
    ///                 .focused($focusedField, equals: .secondField)
    ///         }
    ///         .defaultFocus($focusedField, .secondField)
    ///     }
    ///
    /// - Parameters:
    ///   - binding: A focus state binding to update when evaluating default
    ///     focus in the modified view hierarchy.
    ///   - value: The value to set the binding to during evaluation.
    ///   - priority: An indication of how to prioritize the preferred default
    ///     focus target when focus moves into the modified view hierarchy.
    ///     The default value is `automatic`, which means the preference will
    ///     be given priority when focus is being initialized or relocated
    ///     programmatically, but not when responding to user-directed
    ///     navigation commands.
    /// - Returns: The modified view.
    @available(iOS 17.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func defaultFocus<V>(_ binding: FocusState<V>.Binding, _ value: V, priority: DefaultFocusEvaluationPriority = .automatic) -> some View where V : Hashable { return stubView() }

}


extension View {

    /// Specifies if the view is focusable.
    ///
    /// - Parameters isFocusable: A Boolean value that indicates whether this
    ///   view is focusable.
    ///
    /// - Returns: A view that sets whether a view is focusable.
    @available(iOS 17.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func focusable(_ isFocusable: Bool = true) -> some View { return stubView() }


    /// Specifies if the view is focusable, and if so, what focus-driven
    /// interactions it supports.
    ///
    /// By default, SkipUI enables all possible focus interactions. However, on
    /// macOS and iOS it is conventional for button-like views to only accept
    /// focus when the user has enabled keyboard navigation system-wide in the
    /// Settings app. Clients can reproduce this behavior with custom views by
    /// only supporting `.activate` interactions.
    ///
    ///     MyTapGestureView(...)
    ///         .focusable(interactions: .activate)
    ///
    /// - Note: The focus interactions allowed for custom views changed in
    ///   macOS 14—previously, custom views could only become focused with
    ///   keyboard navigation enabled system-wide. Clients built using older
    ///   SDKs will continue to see the older focus behavior, while custom views
    ///   in clients built using macOS 14 or later will always be focusable
    ///   unless the client requests otherwise by specifying a restricted set of
    ///   focus interactions.
    ///
    /// - Parameters:
    ///   - isFocusable: `true` if the view should participate in focus;
    ///     `false` otherwise. The default value is `true`.
    ///   - interactions: The types of focus interactions supported by the view.
    ///     The default value is `.automatic`.
    /// - Returns: A view that sets whether its child is focusable.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public func focusable(_ isFocusable: Bool = true, interactions: FocusInteractions) -> some View { return stubView() }


    /// Adds a condition that controls whether this view can display focus
    /// effects, such as a default focus ring or hover effect.
    ///
    /// The higher views in a view hierarchy can override the value you set on
    /// this view. In the following example, the button does not display a focus
    /// effect because the outer `focusEffectDisabled(_:)` modifier overrides
    /// the inner one:
    ///
    ///     HStack {
    ///         Button("Press") {}
    ///             .focusEffectDisabled(false)
    ///     }
    ///     .focusEffectDisabled(true)
    ///
    /// - Parameter disabled: A Boolean value that determines whether this view
    ///   can display focus effects.
    /// - Returns: A view that controls whether focus effects can be displayed
    ///   in this view.
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public func focusEffectDisabled(_ disabled: Bool = true) -> some View { return stubView() }

}


@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Modifies this view by binding its focus state to the given state value.
    ///
    /// Use this modifier to cause the view to receive focus whenever the
    /// the `binding` equals the `value`. Typically, you create an enumeration
    /// of fields that may receive focus, bind an instance of this enumeration,
    /// and assign its cases to focusable views.
    ///
    /// The following example uses the cases of a `LoginForm` enumeration to
    /// bind the focus state of two ``TextField`` views. A sign-in button
    /// validates the fields and sets the bound `focusedField` value to
    /// any field that requires the user to correct a problem.
    ///
    ///     struct LoginForm {
    ///         enum Field: Hashable {
    ///             case usernameField
    ///             case passwordField
    ///         }
    ///
    ///         @State private var username = ""
    ///         @State private var password = ""
    ///         @FocusState private var focusedField: Field?
    ///
    ///         var body: some View {
    ///             Form {
    ///                 TextField("Username", text: $username)
    ///                     .focused($focusedField, equals: .usernameField)
    ///
    ///                 SecureField("Password", text: $password)
    ///                     .focused($focusedField, equals: .passwordField)
    ///
    ///                 Button("Sign In") {
    ///                     if username.isEmpty {
    ///                         focusedField = .usernameField
    ///                     } else if password.isEmpty {
    ///                         focusedField = .passwordField
    ///                     } else {
    ///                         handleLogin(username, password)
    ///                     }
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// To control focus using a Boolean, use the ``View/focused(_:)`` method
    /// instead.
    ///
    /// - Parameters:
    ///   - binding: The state binding to register. When focus moves to the
    ///     modified view, the binding sets the bound value to the corresponding
    ///     match value. If a caller sets the state value programmatically to the
    ///     matching value, then focus moves to the modified view. When focus
    ///     leaves the modified view, the binding sets the bound value to
    ///     `nil`. If a caller sets the value to `nil`, SkipUI automatically
    ///     dismisses focus.
    ///   - value: The value to match against when determining whether the
    ///     binding should change.
    /// - Returns: The modified view.
    public func focused<Value>(_ binding: FocusState<Value>.Binding, equals value: Value) -> some View where Value : Hashable { return stubView() }


    /// Modifies this view by binding its focus state to the given Boolean state
    /// value.
    ///
    /// Use this modifier to cause the view to receive focus whenever the
    /// the `condition` value is `true`. You can use this modifier to
    /// observe the focus state of a single view, or programmatically set and
    /// remove focus from the view.
    ///
    /// In the following example, a single ``TextField`` accepts a user's
    /// desired `username`. The text field binds its focus state to the
    /// Boolean value `usernameFieldIsFocused`. A "Submit" button's action
    /// verifies whether the name is available. If the name is unavailable, the
    /// button sets `usernameFieldIsFocused` to `true`, which causes focus to
    /// return to the text field, so the user can enter a different name.
    ///
    ///     @State private var username: String = ""
    ///     @FocusState private var usernameFieldIsFocused: Bool
    ///     @State private var showUsernameTaken = false
    ///
    ///     var body: some View {
    ///         VStack {
    ///             TextField("Choose a username.", text: $username)
    ///                 .focused($usernameFieldIsFocused)
    ///             if showUsernameTaken {
    ///                 Text("That username is taken. Please choose another.")
    ///             }
    ///             Button("Submit") {
    ///                 showUsernameTaken = false
    ///                 if !isUserNameAvailable(username: username) {
    ///                     usernameFieldIsFocused = true
    ///                     showUsernameTaken = true
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// To control focus by matching a value, use the
    /// ``View/focused(_:equals:)`` method instead.
    ///
    /// - Parameter condition: The focus state to bind. When focus moves
    ///   to the view, the binding sets the bound value to `true`. If a caller
    ///   sets the value to  `true` programmatically, then focus moves to the
    ///   modified view. When focus leaves the modified view, the binding
    ///   sets the value to `false`. If a caller sets the value to `false`,
    ///   SkipUI automatically dismisses focus.
    ///
    /// - Returns: The modified view.
    public func focused(_ condition: FocusState<Bool>.Binding) -> some View { return stubView() }

}

extension View {

    /// Modifies this view by injecting a value that you provide for use by
    /// other views whose state depends on the focused view hierarchy.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to associate `value` with when adding
    ///     it to the existing table of exported focus values.
    ///   - value: The focus value to export.
    /// - Returns: A modified representation of this view.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    public func focusedValue<Value>(_ keyPath: WritableKeyPath<FocusedValues, Value?>, _ value: Value) -> some View { return stubView() }


    /// Creates a new view that exposes the provided value to other views whose
    /// state depends on the focused view hierarchy.
    ///
    /// Use this method instead of ``View/focusedSceneValue(_:_:)`` when your
    /// scene includes multiple focusable views with their own associated
    /// values, and you need an app- or scene-scoped element like a command or
    /// toolbar item that operates on the value associated with whichever view
    /// currently has focus. Each focusable view can supply its own value:
    ///
    ///
    ///
    /// - Parameters:
    ///   - keyPath: The key path to associate `value` with when adding
    ///     it to the existing table of exported focus values.
    ///   - value: The focus value to export, or `nil` if no value is
    ///     currently available.
    /// - Returns: A modified representation of this view.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func focusedValue<Value>(_ keyPath: WritableKeyPath<FocusedValues, Value?>, _ value: Value?) -> some View { return stubView() }


    /// Modifies this view by injecting a value that you provide for use by
    /// other views whose state depends on the focused scene.
    ///
    /// Use this method instead of ``View/focusedValue(_:_:)`` for values that
    /// must be visible regardless of where focus is located in the active
    /// scene. For example, if an app needs a command for moving focus to a
    /// particular text field in the sidebar, it could use this modifier to
    /// publish a button action that's visible to command views as long as the
    /// scene is active, and regardless of where focus happens to be in it.
    ///
    ///     struct Sidebar: View {
    ///         @FocusState var isFiltering: Bool
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 TextField(...)
    ///                     .focused(when: $isFiltering)
    ///                     .focusedSceneValue(\.filterAction) {
    ///                         isFiltering = true
    ///                     }
    ///             }
    ///         }
    ///     }
    ///
    ///     struct NavigationCommands: Commands {
    ///         @FocusedValue(\.filterAction) var filterAction
    ///
    ///         var body: some Commands {
    ///             CommandMenu("Navigate") {
    ///                 Button("Filter in Sidebar") {
    ///                     filterAction?()
    ///                 }
    ///             }
    ///             .disabled(filterAction == nil)
    ///         }
    ///     }
    ///
    ///     struct FilterActionKey: FocusedValuesKey {
    ///         typealias Value = () -> Void
    ///     }
    ///
    ///     extension FocusedValues {
    ///         var filterAction: (() -> Void)? {
    ///             get { self[FilterActionKey.self] }
    ///             set { self[FilterActionKey.self] = newValue }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - keyPath: The key path to associate `value` with when adding
    ///     it to the existing table of published focus values.
    ///   - value: The focus value to publish.
    /// - Returns: A modified representation of this view.
    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    public func focusedSceneValue<T>(_ keyPath: WritableKeyPath<FocusedValues, T?>, _ value: T) -> some View { return stubView() }


    /// Creates a new view that exposes the provided value to other views whose
    /// state depends on the active scene.
    ///
    /// Use this method instead of ``View/focusedValue(_:_:)`` for values that
    /// must be visible regardless of where focus is located in the active
    /// scene. For example, if an app needs a command for moving focus to a
    /// particular text field in the sidebar, it could use this modifier to
    /// publish a button action that's visible to command views as long as the
    /// scene is active, and regardless of where focus happens to be in it.
    ///
    ///     struct Sidebar: View {
    ///         @FocusState var isFiltering: Bool
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 TextField(...)
    ///                     .focused(when: $isFiltering)
    ///                     .focusedSceneValue(\.filterAction) {
    ///                         isFiltering = true
    ///                     }
    ///             }
    ///         }
    ///     }
    ///
    ///     struct NavigationCommands: Commands {
    ///         @FocusedValue(\.filterAction) var filterAction
    ///
    ///         var body: some Commands {
    ///             CommandMenu("Navigate") {
    ///                 Button("Filter in Sidebar") {
    ///                     filterAction?()
    ///                 }
    ///             }
    ///             .disabled(filterAction == nil)
    ///         }
    ///     }
    ///
    ///     struct FilterActionKey: FocusedValuesKey {
    ///         typealias Value = () -> Void
    ///     }
    ///
    ///     extension FocusedValues {
    ///         var filterAction: (() -> Void)? {
    ///             get { self[FilterActionKey.self] }
    ///             set { self[FilterActionKey.self] = newValue }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - keyPath: The key path to associate `value` with when adding
    ///     it to the existing table of published focus values.
    ///   - value: The focus value to publish, or `nil` if no value is
    ///     currently available.
    /// - Returns: A modified representation of this view.
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    public func focusedSceneValue<T>(_ keyPath: WritableKeyPath<FocusedValues, T?>, _ value: T?) -> some View { return stubView() }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension View {

    /// Creates a new view that exposes the provided object to other views whose
    /// whose state depends on the focused view hierarchy.
    ///
    /// Use this method instead of ``View/focusedSceneObject(_:)`` when your
    /// scene includes multiple focusable views with their own associated data,
    /// and you need an app- or scene-scoped element like a command or toolbar
    /// item that operates on the data associated with whichever view currently
    /// has focus. Each focusable view can supply its own object:
    ///
    ///     struct MessageView: View {
    ///         @StateObject private var message = Message(...)
    ///
    ///         var body: some View {
    ///             TextField(...)
    ///                 .focusedObject(message)
    ///         }
    ///     }
    ///
    /// Interested views can then use the ``FocusedObject`` property wrapper to
    /// observe and update the focused view's object. In this example, an app
    /// command updates the focused view's data, and is automatically disabled
    /// when focus is in an unrelated part of the scene:
    ///
    ///     struct MessageCommands: Commands {
    ///         @FocusedObject private var message: Message?
    ///
    ///         var body: some Commands {
    ///             CommandGroup(after: .pasteboard) {
    ///                 Button("Add Duck to Message") {
    ///                     message?.text.append(" 🦆")
    ///                 }
    ///                 .keyboardShortcut("d")
    ///                 .disabled(message == nil)
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - object: The observable object to associate with focus.
    /// - Returns: A view that supplies an observable object when in focus.
    public func focusedObject<T>(_ object: T) -> some View where T : ObservableObject { return stubView() }


    /// Creates a new view that exposes the provided object to other views whose
    /// state depends on the focused view hierarchy.
    ///
    /// Use this method instead of ``View/focusedSceneObject(_:)`` when your
    /// scene includes multiple focusable views with their own associated data,
    /// and you need an app- or scene-scoped element like a command or toolbar
    /// item that operates on the data associated with whichever view currently
    /// has focus. Each focusable view can supply its own object:
    ///
    ///     struct MessageView: View {
    ///         @StateObject private var message = Message(...)
    ///
    ///         var body: some View {
    ///             TextField(...)
    ///                 .focusedObject(message)
    ///         }
    ///     }
    ///
    /// Interested views can then use the ``FocusedObject`` property wrapper to
    /// observe and update the focused view's object. In this example, an app
    /// command updates the focused view's data, and is automatically disabled
    /// when focus is in an unrelated part of the scene:
    ///
    ///     struct MessageCommands: Commands {
    ///         @FocusedObject private var message: Message?
    ///
    ///         var body: some Commands {
    ///             CommandGroup(after: .pasteboard) {
    ///                 Button("Add Duck to Message") {
    ///                     message?.text.append(" 🦆")
    ///                 }
    ///                 .keyboardShortcut("d")
    ///                 .disabled(message == nil)
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - object: The observable object to associate with focus, or `nil` if
    ///     no object is currently available.
    /// - Returns: A view that supplies an observable object when in focus.
    public func focusedObject<T>(_ object: T?) -> some View where T : ObservableObject { return stubView() }


    /// Creates a new view that exposes the provided object to other views whose
    /// whose state depends on the active scene.
    ///
    /// Use this method instead of ``View/focusedObject(_:)`` for observable
    /// objects that must be visible regardless of where focus is located in the
    /// active scene. This is sometimes needed for things like main menu and
    /// discoverability HUD commands that observe and update data from the
    /// active scene but aren't concerned with what the user is actually focused
    /// on. The scene's root view can supply the scene's state object:
    ///
    ///     struct RootView: View {
    ///         @StateObject private var sceneData = SceneData()
    ///
    ///         var body: some View {
    ///             NavigationSplitView {
    ///                 ...
    ///             }
    ///             .focusedSceneObject(sceneData)
    ///         }
    ///     }
    ///
    /// Interested views can then use the ``FocusedObject`` property wrapper to
    /// observe and update the active scene's state object. In this example, an
    /// app command updates the active scene's data, and is enabled as long as
    /// any scene is active.
    ///
    ///     struct MessageCommands: Commands {
    ///         @FocusedObject private var sceneData: SceneData?
    ///
    ///         var body: some Commands {
    ///             CommandGroup(after: .newItem) {
    ///                 Button("New Message") {
    ///                     sceneData?.addMessage()
    ///                 }
    ///                 .keyboardShortcut("n", modifiers: [.option, .command])
    ///                 .disabled(sceneData == nil)
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - object: The observable object to associate with the scene.
    /// - Returns: A view that supplies an observable object while the scene
    ///   is active.
    public func focusedSceneObject<T>(_ object: T) -> some View where T : ObservableObject { return stubView() }


    /// Creates a new view that exposes the provided object to other views whose
    /// whose state depends on the active scene.
    ///
    /// Use this method instead of ``View/focusedObject(_:)`` for observable
    /// objects that must be visible regardless of where focus is located in the
    /// active scene. This is sometimes needed for things like main menu and
    /// discoverability HUD commands that observe and update data from the
    /// active scene but aren't concerned with what the user is actually focused
    /// on. The scene's root view can supply the scene's state object:
    ///
    ///     struct RootView: View {
    ///         @StateObject private var sceneData = SceneData()
    ///
    ///         var body: some View {
    ///             NavigationSplitView {
    ///                 ...
    ///             }
    ///             .focusedSceneObject(sceneData)
    ///         }
    ///     }
    ///
    /// Interested views can then use the ``FocusedObject`` property wrapper to
    /// observe and update the active scene's state object. In this example, an
    /// app command updates the active scene's data, and is enabled as long as
    /// any scene is active.
    ///
    ///     struct MessageCommands: Commands {
    ///         @FocusedObject private var sceneData: SceneData?
    ///
    ///         var body: some Commands {
    ///             CommandGroup(after: .newItem) {
    ///                 Button("New Message") {
    ///                     sceneData?.addMessage()
    ///                 }
    ///                 .keyboardShortcut("n", modifiers: [.option, .command])
    ///                 .disabled(sceneData == nil)
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - object: The observable object to associate with the scene, or `nil`
    ///     if no object is currently available.
    /// - Returns: A view that supplies an observable object while the scene
    ///   is active.
    public func focusedSceneObject<T>(_ object: T?) -> some View where T : ObservableObject { return stubView() }

}

#endif
