---
name: animations
description: Framer Motion (web) + Reanimated + Moti (mobile) animations. Shimmer skeletons, gradient text, spring press, stagger reveals, layout animations. SvelteKit transitions. Use when adding motion, loading states, or interactive feedback to UI.
---

You are an animation expert for web (Framer Motion) and mobile (Reanimated + Moti). Apply these patterns.

## Rule: Animate State Changes, Not Decoration

Animate to communicate: loading, success, transition, feedback. Never animate just to look fancy.

---

## Web — Framer Motion

### Install
```bash
pnpm add framer-motion
```

### Core Patterns
```tsx
import { motion, AnimatePresence } from 'framer-motion'

// Spring press feedback (buttons, cards)
<motion.button
  whileTap={{ scale: 0.97 }}
  whileHover={{ scale: 1.02 }}
  transition={{ type: 'spring', stiffness: 400, damping: 25 }}
>
  Click me
</motion.button>

// Fade + slide in on mount
<motion.div
  initial={{ opacity: 0, y: 16 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.3, ease: 'easeOut' }}
>
  Content
</motion.div>

// Stagger children
const container = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.08 },
  },
}
const item = {
  hidden: { opacity: 0, y: 12 },
  show: { opacity: 1, y: 0 },
}

<motion.ul variants={container} initial="hidden" animate="show">
  {items.map((i) => (
    <motion.li key={i.id} variants={item}>{i.name}</motion.li>
  ))}
</motion.ul>

// Layout animation (reorder, resize)
<motion.div layout layoutId="card-123">
  {/* Animates size/position changes automatically */}
</motion.div>

// Exit animation
<AnimatePresence>
  {isOpen && (
    <motion.div
      key="modal"
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
    >
      Modal content
    </motion.div>
  )}
</AnimatePresence>
```

### Shimmer Skeleton (Web)
```tsx
// With Tailwind + CSS animation
function Skeleton({ className }: { className?: string }) {
  return (
    <div
      className={cn(
        'animate-pulse rounded-md bg-muted',
        className
      )}
    />
  )
}

// Shimmer variant with gradient sweep
function ShimmerSkeleton({ className }: { className?: string }) {
  return (
    <div className={cn('relative overflow-hidden rounded-md bg-muted', className)}>
      <div className="absolute inset-0 -translate-x-full animate-[shimmer_1.5s_infinite] bg-gradient-to-r from-transparent via-white/20 to-transparent" />
    </div>
  )
}
// In tailwind.config: add keyframes { shimmer: { '100%': { transform: 'translateX(100%)' } } }
```

### Gradient Text Animation
```tsx
<span className="animate-gradient bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 bg-clip-text text-transparent bg-[length:200%_auto]">
  Animated gradient text
</span>
// tailwind keyframe: animate-gradient → backgroundPosition 0% to 200%
```

---

## SvelteKit — Built-in Transitions

```svelte
<script>
  import { fade, fly, scale, slide } from 'svelte/transition'
  import { spring } from 'svelte/motion'

  let count = spring(0, { stiffness: 0.1, damping: 0.8 })
</script>

<!-- Fade in/out -->
{#if show}
  <div transition:fade={{ duration: 200 }}>Content</div>
{/if}

<!-- Fly in from bottom -->
{#if show}
  <div transition:fly={{ y: 20, duration: 300 }}>Content</div>
{/if}

<!-- Stagger list (use each with delay) -->
{#each items as item, i}
  <div
    in:fly={{ y: 12, delay: i * 60, duration: 250 }}
    out:fade={{ duration: 150 }}
  >
    {item.name}
  </div>
{/each}
```

---

## Mobile — Reanimated + Moti

### Install
```bash
npx expo install react-native-reanimated moti
```

### Spring Press (Moti)
```tsx
import { MotiView, MotiPressable } from 'moti'

// Press feedback
<MotiPressable
  animate={({ pressed }) => ({
    scale: pressed ? 0.96 : 1,
  })}
  transition={{ type: 'spring', damping: 20, stiffness: 300 }}
>
  <Button>Press me</Button>
</MotiPressable>
```

### Fade + Slide In
```tsx
<MotiView
  from={{ opacity: 0, translateY: 16 }}
  animate={{ opacity: 1, translateY: 0 }}
  transition={{ type: 'spring', damping: 20 }}
>
  <Text>Hello</Text>
</MotiView>
```

### Stagger List
```tsx
import { stagger, useAnimationState } from 'moti'

{items.map((item, index) => (
  <MotiView
    key={item.id}
    from={{ opacity: 0, translateX: -20 }}
    animate={{ opacity: 1, translateX: 0 }}
    transition={{ delay: index * 80, type: 'spring', damping: 18 }}
  >
    <ListItem item={item} />
  </MotiView>
))}
```

### Shimmer Skeleton (Mobile)
```tsx
import { Skeleton } from 'moti/skeleton'

// Light theme
<Skeleton colorMode="light" width={200} height={20} radius={4} />

// Dark theme
<Skeleton colorMode="dark" width="100%" height={120} radius={8} />

// In a card skeleton
function CardSkeleton() {
  return (
    <View style={{ gap: 8, padding: 16 }}>
      <Skeleton colorMode="light" width={120} height={14} />
      <Skeleton colorMode="light" width="100%" height={14} />
      <Skeleton colorMode="light" width="80%" height={14} />
    </View>
  )
}
```

### Reanimated Spring (raw)
```tsx
import Animated, { useSharedValue, withSpring, useAnimatedStyle } from 'react-native-reanimated'

const scale = useSharedValue(1)

const animatedStyle = useAnimatedStyle(() => ({
  transform: [{ scale: scale.value }],
}))

const handlePress = () => {
  scale.value = withSpring(0.95, {}, () => {
    scale.value = withSpring(1)
  })
}

<Animated.View style={animatedStyle}>
  <Pressable onPress={handlePress}>...</Pressable>
</Animated.View>
```

---

## Quick Reference

| Goal | Web | Mobile |
|------|-----|--------|
| Press feedback | `whileTap={{ scale: 0.97 }}` | `MotiPressable` spring |
| Fade in | `initial={{ opacity: 0 }} animate={{ opacity: 1 }}` | `MotiView from/animate` |
| Stagger list | `variants` with `staggerChildren` | `delay: index * 80` |
| Shimmer loading | CSS `animate-pulse` or gradient | `moti/skeleton Skeleton` |
| Exit animation | `AnimatePresence` + `exit` | Conditional mount |
| Layout shift | `motion.div layout` | `useAnimatedLayout` |
