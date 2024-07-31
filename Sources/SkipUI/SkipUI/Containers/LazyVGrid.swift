// Copyright 2023 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

#if SKIP
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
#else
import struct CoreGraphics.CGFloat
#endif

public struct LazyVGrid: View {
    let columns: [GridItem]
    let alignment: HorizontalAlignment
    let spacing: CGFloat?
    let content: ComposeBuilder

    public init(columns: [GridItem], alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, pinnedViews: PinnedScrollableViews = [], @ViewBuilder content: () -> any View) {
        self.columns = columns
        self.alignment = alignment
        self.spacing = spacing
        self.content = ComposeBuilder.from(content)
    }

    #if SKIP
    @Composable override func ComposeContent(context: ComposeContext) {
        let (gridCells, cellAlignment, horizontalSpacing) = GridItem.asGridCells(items: columns)
        let boxAlignment = cellAlignment?.asComposeAlignment() ?? androidx.compose.ui.Alignment.Center
        let horizontalArrangement = Arrangement.spacedBy((horizontalSpacing ?? 8.0).dp, alignment: alignment.asComposeAlignment())
        let verticalArrangement = Arrangement.spacedBy((spacing ?? 8.0).dp)
        let isScrollEnabled = EnvironmentValues.shared._scrollAxes.contains(.vertical)

        // Collect all top-level views to compose. The LazyVerticalGrid itself is not a composable context, so we have to execute
        // our content's Compose function to collect its views before entering the LazyVerticalGrid body, then use LazyVerticalGrid's
        // LazyGridScope functions to compose individual items
        let collectingComposer = LazyItemCollectingComposer()
        let viewsCollector = context.content(composer: collectingComposer)
        content.Compose(context: viewsCollector)

        let searchableState = EnvironmentValues.shared._searchableState
        let isSearchable = searchableState?.isOnNavigationStack == false

        let itemContext = context.content()
        let factoryContext = remember { mutableStateOf(LazyItemFactoryContext()) }
        ComposeContainer(axis: .vertical, modifier: context.modifier, fillWidth: true, fillHeight: true) { modifier in
            // Integrate with our scroll-to-top and ScrollViewReader
            let gridState = rememberLazyGridState(initialFirstVisibleItemIndex = isSearchable ? 1 : 0)
            let coroutineScope = rememberCoroutineScope()
            PreferenceValues.shared.contribute(context: context, key: ScrollToTopPreferenceKey.self, value: {
                coroutineScope.launch {
                    gridState.animateScrollToItem(0)
                }
            })
            let scrollToID: (Any) -> Void = { id in
                if let itemIndex = factoryContext.value.index(for: id) {
                    coroutineScope.launch {
                        if Animation.isInWithAnimation {
                            gridState.animateScrollToItem(itemIndex)
                        } else {
                            gridState.scrollToItem(itemIndex)
                        }
                    }
                }
            }
            PreferenceValues.shared.contribute(context: context, key: ScrollToIDPreferenceKey.self, value: scrollToID)

            LazyVerticalGrid(state: gridState, modifier: modifier, columns: gridCells, horizontalArrangement: horizontalArrangement, verticalArrangement: verticalArrangement, userScrollEnabled: isScrollEnabled) {
                factoryContext.value.initialize(
                    startItemIndex: isSearchable ? 1 : 0,
                    item: { view in
                        item {
                            Box(contentAlignment: boxAlignment) {
                                view.Compose(context: itemContext)
                            }
                        }
                    },
                    indexedItems: { range, identifier, _, _, _, factory in
                        let count = range.endExclusive - range.start
                        let key: ((Int) -> String)? = identifier == nil ? nil : { composeBundleString(for: identifier!($0)) }
                        items(count: count, key: key) { index in
                            Box(contentAlignment: boxAlignment) {
                                factory(index + range.start).Compose(context: itemContext)
                            }
                        }
                    },
                    objectItems: { objects, identifier, _, _, _, factory in
                        let key: (Int) -> String = { composeBundleString(for: identifier(objects[$0])) }
                        items(count: objects.count, key: key) { index in
                            Box(contentAlignment: boxAlignment) {
                                factory(objects[index]).Compose(context: itemContext)
                            }
                        }
                    },
                    objectBindingItems: { objectsBinding, identifier, _, _, _, _, factory in
                        let key: (Int) -> String = { composeBundleString(for: identifier(objectsBinding.wrappedValue[$0])) }
                        items(count: objectsBinding.wrappedValue.count, key: key) { index in
                            Box(contentAlignment: boxAlignment) {
                                factory(objectsBinding, index).Compose(context: itemContext)
                            }
                        }
                    },
                    sectionHeader: { view in
                        item(span: { GridItemSpan(maxLineSpan) }) {
                            Box(contentAlignment: androidx.compose.ui.Alignment.Center) {
                                view.Compose(context: itemContext)
                            }
                        }
                    },
                    sectionFooter: { view in
                        item(span: { GridItemSpan(maxLineSpan) }) {
                            Box(contentAlignment: androidx.compose.ui.Alignment.Center) {
                                view.Compose(context: itemContext)
                            }
                        }
                    }
                )
                if isSearchable {
                    item(span: { GridItemSpan(maxLineSpan) }) {
                        let modifier = Modifier.padding(start: 16.dp, end: 16.dp, top: 16.dp, bottom: 8.dp).fillMaxWidth()
                        SearchField(state: searchableState!, context: context.content(modifier: modifier))
                    }
                }
                for view in collectingComposer.views {
                    if let factory = view as? LazyItemFactory {
                        factory.composeLazyItems(context: factoryContext.value)
                    } else {
                        factoryContext.value.item(view)
                    }
                }
            }
        }
    }
    #else
    public var body: some View {
        stubView()
    }
    #endif
}
