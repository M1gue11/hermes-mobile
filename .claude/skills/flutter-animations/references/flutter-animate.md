# flutter_animate

Declarative, composable animations via the `flutter_animate` package. Aggressively
reduces boilerplate by using `.animate()` extension methods on any widget instead of
manually orchestrating `AnimationController` + `StatefulWidget`.

Package: `flutter_animate` (add with `flutter pub add flutter_animate`).

## When to use it (and when not to)

Use for UI polish: entrance effects, fade/slide/scale, shimmer, looping accents, and
state-driven micro-interactions. It is the **preferred default** for that kind of work.

It is sugar over the native animation system. Reach for the native APIs (see the other
references in this skill) when you need:
- `Hero` shared-element transitions between screens.
- A staggered timeline where many widgets share one `AnimationController`.
- Physics simulations (spring, fling, gravity).
- Fine lifecycle control (status listeners, manual forward/reverse orchestration).

## 1. Core extension syntax

Prefer the `.animate()` extension on any widget, followed by chained effects, over the
explicit `Animate(effects: [...], child: ...)` constructor.

```dart
// Best practice: extension chaining
Text("Hello World!")
  .animate()
  .fade(duration: 500.ms)
  .scale(curve: Curves.easeOutBack);
```

```dart
// Avoid explicit nesting unless building a highly complex reusable list
Animate(
  effects: [FadeEffect(), ScaleEffect()],
  child: Text("Hello World!"),
)
```

## 2. Time extensions (num)

Always use the `num` duration extensions for readability:

- `500.ms` (milliseconds)
- `2.seconds`
- `1.5.minutes`

## 3. Sequencing with `.then()`

Chained effects run in parallel by default. Use `.then()` to run the next effect
sequentially - it sets a new baseline time equal to the previous effect's completion.

```dart
Column(
  children: [
    Text("Step 1").animate().fadeIn(duration: 400.ms).slideX(),
    Text("Step 2").animate()
      .fadeIn(duration: 400.ms)
      .then(delay: 200.ms) // starts 200ms AFTER its own fade completes
      .slideY(),
  ],
)
```

## 4. State-driven animations (`target`)

The most powerful feature: eliminate `AnimatedContainer`/`AnimatedOpacity` by driving
the animation from state with `target`. `target: 1` rests at `end` values; `target: 0`
reverses cleanly to `begin` values.

```dart
// Inside a build method that reads state or Riverpod
bool isHovered = ref.watch(hoverStateProvider);

MyButton()
  .animate(target: isHovered ? 1 : 0) // driven entirely by state
  .fade(end: 0.8)
  .scaleXY(end: 1.1, curve: Curves.easeOutExpo);
```

## 5. Infinite loops & callbacks

Use `onPlay` to manipulate the internal controller (e.g. repeat indefinitely).

```dart
Icon(Icons.warning)
  .animate(onPlay: (controller) => controller.repeat(reverse: true))
  .fadeOut(curve: Curves.easeInOut);
```

## 6. Value listeners & custom effects

Extract the raw `0.0 -> 1.0` value to drive a custom painter or complex lerp.

```dart
// Listen (side-effects)
Text("Hello").animate().fadeIn(duration: 1.seconds)
  .listen(callback: (value) => print('Current alpha: $value'));
```

```dart
// CustomEffect (build from interpolation)
Text("Color Shift").animate().custom(
  duration: 300.ms,
  builder: (context, value, child) => Container(
    color: Color.lerp(Colors.red, Colors.blue, value),
    child: child,
  ),
);
```

## 7. Toggles & widget swapping

- `ToggleEffect` yields a `bool` based on whether the animation finished - useful for
  flipping raw properties (e.g. an `AbsorbPointer` lock).
- `SwapEffect` replaces the entire rendered widget at the end of the timeline.

```dart
// Button fades out, then is instantly replaced by a loader when the fade completes
SubmitButton().animate()
  .fadeOut(duration: 300.ms)
  .swap(builder: (context, child) => const CircularProgressIndicator());
```

## 8. Animating lists

For staggered list entrances, use `AnimateList` (or `.animate()` per item with an
increasing delay via `.then()` / interval). Extract shared `List<Effect>` into constants
for a consistent design language.

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| `Animate(effects: [...], child: w)` | `w.animate().fade().scale()` |
| `AnimationController` in a `StatefulWidget` for simple polish | `target:` or `onPlay:` |
| Hardcoded `Duration(milliseconds: 500)` | `500.ms` extension |
| Repeating the same effect list everywhere | Extract `List<Effect>` into a constant |

## Constraints

- **Extension priority:** default to `.animate()` chaining unless generating an
  `AnimateList`.
- **State simplicity:** do not define an `AnimationController` in a `StatefulWidget` when
  `target:`/`onPlay:` achieves the goal.
- **Reuse effects:** for a design system, extract `List<Effect>` arrays into global
  constants to guarantee app-wide transition consistency.
