// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.requiredHeight
import androidx.compose.foundation.layout.requiredHeightIn
import androidx.compose.foundation.layout.requiredWidth
import androidx.compose.foundation.layout.requiredWidthIn
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/// Compose a view with the given frame.
@Composable func FrameLayout(view: View, context: ComposeContext, width: CGFloat?, height: CGFloat?, alignment: Alignment) {
    var modifier = context.modifier
    if let width {
        modifier = modifier.requiredWidth(width.dp)
    }
    if let height {
        modifier = modifier.requiredHeight(height.dp)
    }
    let contentContext = context.content()
    ComposeContainer(modifier: modifier, fixedWidth: width != nil, fixedHeight: height != nil) { modifier in
        Box(modifier: modifier, contentAlignment: alignment.asComposeAlignment()) {
            view.Compose(context: contentContext)
        }
    }
}

/// Compose a view with the given frame.
@Composable func FrameLayout(view: View, context: ComposeContext, minWidth: CGFloat?, idealWidth: CGFloat?, maxWidth: CGFloat?, minHeight: CGFloat?, idealHeight: CGFloat?, maxHeight: CGFloat?, alignment: Alignment) {
    // We translate 0,.infinity to a non-expanding fill in either dimension. If the min is not zero, we can't use a fill
    // because it could set a weight on the view in an HStack or VStack, which will only give the view space after all
    // other views and potentially give it less than its minimum. We use a max of Double.MAX_VALUE instead
    var modifier = context.modifier
    if maxWidth == .infinity {
        if let minWidth, minWidth > 0.0 {
            modifier = modifier.requiredWidthIn(min: minWidth.dp, max: Double.MAX_VALUE.dp)
        } else {
            modifier = modifier.fillWidth(expandContainer: false)
        }
    } else if minWidth != nil || maxWidth != nil {
        modifier = modifier.requiredWidthIn(min: minWidth != nil ? minWidth!.dp : Dp.Unspecified, max: maxWidth != nil ? maxWidth!.dp : Dp.Unspecified)
    }
    if maxHeight == .infinity {
        if let minHeight, minHeight > 0.0 {
            modifier = modifier.requiredHeightIn(min: minHeight.dp, max: Double.MAX_VALUE.dp)
        } else {
            modifier = modifier.fillHeight(expandContainer: false)
        }
    } else if minHeight != nil || maxHeight != nil {
        modifier = modifier.requiredHeightIn(min: minHeight != nil ? minHeight!.dp : Dp.Unspecified, max: maxHeight != nil ? maxHeight!.dp : Dp.Unspecified)
    }
    let contentContext = context.content()
    ComposeContainer(modifier: modifier, fixedWidth: maxWidth != nil && maxWidth != Double.infinity, fixedHeight: maxHeight != nil && maxHeight != Double.infinity) { modifier in
        Box(modifier: modifier, contentAlignment: alignment.asComposeAlignment()) {
            view.Compose(context: contentContext)
        }
    }
}

/// Compose a view with the given background.
@Composable func BackgroundLayout(view: View, context: ComposeContext, background: View, alignment: Alignment) {
    TargetViewLayout(target: view, targetIndex: 1, context: context, dependent: background, alignment: alignment)
}

/// Compose a view with the given overlay.
@Composable func OverlayLayout(view: View, context: ComposeContext, overlay: View, alignment: Alignment) {
    TargetViewLayout(target: view, targetIndex: 0, context: context, dependent: overlay, alignment: alignment)
}

@Composable private func TargetViewLayout(target: View, targetIndex: Int, context: ComposeContext, dependent: View, alignment: Alignment) {
    let contentContext = context.content()
    Layout(modifier: context.modifier, content: {
        if targetIndex == 0 {
            target.Compose(context: contentContext)
        }
        // Dependent view lays out with fixed bounds dictated by the target view size
        ComposeContainer(fixedWidth: true, fixedHeight: true) { modifier in
            dependent.Compose(context: context.content(modifier: modifier))
        }
        if targetIndex != 0 {
            target.Compose(context: contentContext)
        }
    }) { measurables, constraints in
        // Base layout entirely on the target view size
        let targetPlaceable = measurables[targetIndex].measure(constraints)
        let dependentPlaceable = measurables[1 - targetIndex].measure(Constraints(maxWidth: targetPlaceable.width, maxHeight: targetPlaceable.height))
        layout(width: targetPlaceable.width, height: targetPlaceable.height) {
            let (x, y) = placeView(width: dependentPlaceable.width, height: dependentPlaceable.height, inWidth: targetPlaceable.width, inHeight: targetPlaceable.height, alignment: alignment)
            dependentPlaceable.placeRelative(x: x, y: y)
            targetPlaceable.placeRelative(x: 0, y: 0)
        }
    }
}

private func placeView(width: Int, height: Int, inWidth: Int, inHeight: Int, alignment: Alignment) -> (Int, Int) {
    let centerX = (inWidth - width) / 2
    let centerY = (inHeight - height) / 2
    switch alignment {
    case .leading, .leadingFirstTextBaseline, .leadingLastTextBaseline:
        return (0, centerY)
    case .trailing, .trailingFirstTextBaseline, .trailingLastTextBaseline:
        return (inWidth - width, centerY)
    case .top:
        return (centerX, 0)
    case .bottom:
        return (centerX, inHeight - height)
    case .topLeading:
        return (0, 0)
    case .topTrailing:
        return (inWidth - width, 0)
    case .bottomLeading:
        return (0, inHeight - height)
    case .bottomTrailing:
        return (inWidth - width, inHeight - height)
    default:
        return (centerX, centerY)
    }
}

#endif