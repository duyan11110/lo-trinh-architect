---
id: frontend.l1.responsive-basics
lang: en
track: frontend
level: 1
stage: 1
module: calling-apis
main_path: true
title: "LayoutBuilder: layout for the space you actually have"
duration_min: 12
skills: [frontend.ui.responsive]
prereqs: [frontend.l1.creating-an-order]
related: []
vocab: [responsive]
example_tag: stage-1
versions_used: [flutter]
content_version: 1
status: draft
---

## Before you start

- [[frontend.l1.creating-an-order]] — you know how the app sends a new order and shows its result, and you have used the product screen that lists what can be ordered.

## The situation

The product screen shows one product per row, which looks right on a phone. Someone opens the web version of the app on a wide office monitor, and the same list now stretches each row across almost two thousand pixels: a name at the far left, a price at the far right, and a lot of empty space between. A teammate suggests checking whether the screen is wider than 1920 pixels and switching to a grid if it is. Another asks what happens when the same app runs in a narrow browser window on that same monitor. Which width should the layout actually look at?

## Core concepts

- **responsive** — a layout that adapts to the space it is actually given, instead of assuming one fixed screen size.
- `LayoutBuilder` — a widget that calls a builder function with the constraints its parent gives it, so the builder can return a different subtree for different space.
- arrangement — how the same pieces are placed: one column, or several.

## How it works

```mermaid
flowchart TD
  P[parent passes constraints] --> L[LayoutBuilder]
  L --> Q{maxWidth below 600?}
  Q -->|yes| LV[one column: ListView of ProductTile]
  Q -->|no| GV[grid: GridView of ProductTile]
```

A **responsive** layout adapts to the space it is given. In Flutter, that space arrives as constraints: during layout, each parent tells its child the smallest and largest width and height it may take. Most widgets use those constraints without you seeing them. `LayoutBuilder` hands them to you, by calling a builder function with them, so the widget you return can depend on how much room there really is.

That is the whole trick in the diagram. The builder reads `constraints.maxWidth`, compares it with a width the team chose, and returns one subtree or another. Both subtrees can use the same pieces. Only the arrangement changes: a single column when space is tight, several columns when there is room.

The number being compared matters less than what it is compared with. A layout that checks the size of the whole screen, or assumes a phone's width, breaks as soon as the widget sits somewhere else: a narrow browser window on a big monitor, a panel beside another panel, a tablet turned sideways. The constraints describe the space this widget actually has, wherever it ends up, so a decision based on them keeps working.

## In the Đơn Hàng system

`ProductCatalog` in `DonHang.App/lib/widgets/product_catalog.dart` at stage-1 is the responsive version of the product list:

```dart file=DonHang.App/lib/widgets/product_catalog.dart tag=stage-1 lines=17-37
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < wideLayoutMinWidth) {
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) => ProductTile(product: products[index]),
          );
        }
        final columns = (constraints.maxWidth / columnWidth).floor();
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 72,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => ProductTile(product: products[index]),
        );
      },
    );
  }
```

When `maxWidth` is below `wideLayoutMinWidth`, 600, it returns a `ListView` with one `ProductTile` per row. Otherwise it works out how many 300-pixel columns fit, rounding down, and returns a `GridView` of the same `ProductTile`s. At stage-1 no screen uses `ProductCatalog` yet; the product screen still builds its own `ListView`. Its widget test, in `DonHang.App/test/product_catalog_test.dart`, shows both arrangements by giving it two widths:

```dart file=DonHang.App/test/product_catalog_test.dart tag=stage-1 lines=16-36
  Widget catalogWithWidth(double width) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, height: 400, child: ProductCatalog(products: products)),
          ),
        ),
      );

  testWidgets('a narrow width shows a single-column list', (tester) async {
    await tester.pumpWidget(catalogWithWidth(360));

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('a wide width shows a grid of the same tiles', (tester) async {
    await tester.pumpWidget(catalogWithWidth(900));

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ProductTile), findsNWidgets(2));
  });
```

`catalogWithWidth` places the catalog inside a box of the given width, so the constraints `LayoutBuilder` receives are 360 or 900 pixels wide, whatever the test screen's own size is. At 360 the test finds a list and no grid; at 900 it finds a grid holding the same two tiles.

## Beginners often think…

- **"Responsive design is only relevant for a web browser, not a Flutter app running on a phone or tablet."** → Actually any widget can be given less or more room than you expected: a tablet shows a wider screen, and a phone turned sideways gets a different width. You notice this when a layout written for one phone width looks cramped or stretched on a tablet, although no browser is involved.
- **"Using a fixed pixel width for every widget makes a layout more predictable, and predictable is what responsive means."** → Actually a fixed width is predictable only on the screen it was chosen for; responsive means the layout follows the space it is given. You notice this when a list with fixed 400-pixel rows overflows a 360-pixel phone and leaves most of a monitor empty.

## Try it (3 minutes)

Using the `ProductCatalog` code above, predict what it builds when `LayoutBuilder` reports each of these `maxWidth` values:

1. 360
2. 599
3. 600
4. 900
5. 1250

Expected result: 1 — a `ListView`, one tile per row. 2 — still a `ListView`, because 599 is below 600. 3 — a `GridView` with 2 columns: 600 divided by 300 is 2. 4 — a `GridView` with 3 columns. 5 — a `GridView` with 4 columns: 1250 divided by 300 is about 4.17, rounded down to 4.

The same monitor shows the app in a browser window 500 pixels wide. What does `ProductCatalog` build, and why would a check on the monitor's width get this wrong?

<details><summary>Suggested answer</summary>

It builds the one-column `ListView`, because the constraints it receives are about 500 pixels wide, below 600. A check on the monitor's width would see a very wide screen and choose the grid, squeezing several columns into a window that has room for one. `LayoutBuilder` looks at the space the widget actually has, not the device it happens to run on.

</details>

## Connections

- [[frontend.l1.accessibility-basics]] — the `ProductTile` used in both arrangements, and making it usable by everyone.
- [[frontend.l1.build-layout-paint]] — where constraints come from during layout.

## Five-line summary

1. A **responsive** layout adapts to the space it is actually given, not to one assumed screen size.
2. `LayoutBuilder` passes a widget's constraints to a builder, which can return different subtrees for different widths.
3. `ProductCatalog` returns a one-column `ListView` below 600 pixels and a `GridView` of 300-pixel columns above.
4. Both arrangements use the same `ProductTile`; responsiveness changes the arrangement, not the pieces.
5. Checking the screen's width breaks when the widget gets less room; checking its constraints keeps working.
