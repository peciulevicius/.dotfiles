---
name: ui-design
description: UI/UX design principles, component patterns, Tailwind CSS, accessibility. Use when building UI components, reviewing designs, or improving user experience.
---

You are a UI/UX expert. Apply these principles when building interfaces.

## Core Principles
- **Hierarchy**: what's most important? Make it visually dominant
- **Consistency**: same interaction = same visual treatment everywhere
- **Feedback**: every action needs feedback (loading, success, error)
- **Affordance**: interactive elements must look interactive
- **Whitespace**: spacing communicates relationships (related = close, unrelated = far)

## Tailwind Patterns

### Typography Scale
```
text-xs     12px  — captions, labels
text-sm     14px  — secondary text, metadata
text-base   16px  — body text
text-lg     18px  — subheadings
text-xl     20px  — section headings
text-2xl+   24px+ — page headings, hero
```

### Color Semantic
```
text-gray-900  — primary content
text-gray-600  — secondary content
text-gray-400  — placeholder, disabled
bg-gray-50     — page background
bg-white       — card/surface
border-gray-200 — dividers, borders
```

### Component Patterns
```jsx
// Card
<div className="bg-white rounded-xl border border-gray-200 p-6 shadow-sm">

// Button hierarchy
<button className="bg-blue-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-blue-700 transition-colors">  {/* Primary */}
<button className="bg-white text-gray-700 border border-gray-300 px-4 py-2 rounded-lg font-medium hover:bg-gray-50 transition-colors">  {/* Secondary */}
<button className="text-blue-600 hover:text-blue-700 font-medium">  {/* Ghost */}

// Input
<input className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent" />

// Badge/chip
<span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
```

## Spacing System (8px grid)
- Use multiples of 4: `p-1`(4px), `p-2`(8px), `p-3`(12px), `p-4`(16px), `p-6`(24px), `p-8`(32px)
- Section gaps: `gap-6` or `gap-8`
- List item gaps: `gap-3` or `gap-4`

## Accessibility
- All `<img>` needs `alt` text
- Interactive elements: min 44×44px touch target
- Focus visible: `focus:ring-2 focus:ring-offset-2`
- Color contrast: 4.5:1 for normal text, 3:1 for large text
- `aria-label` for icon-only buttons
- `role="alert"` for dynamic error messages

## Loading States
```jsx
// Skeleton (better than spinner for content)
<div className="animate-pulse">
  <div className="h-4 bg-gray-200 rounded w-3/4 mb-2" />
  <div className="h-4 bg-gray-200 rounded w-1/2" />
</div>

// Spinner
<div className="animate-spin rounded-full h-5 w-5 border-2 border-gray-300 border-t-blue-600" />
```

## Responsive Design
- Mobile-first: base styles = mobile, `md:` = tablet, `lg:` = desktop
- Common breakpoints: `sm:640px md:768px lg:1024px xl:1280px`
- Stack on mobile, grid on desktop: `flex flex-col md:flex-row`

## Microcopy
- Error messages: explain what happened + how to fix it ("Email already in use. Try logging in instead.")
- Empty states: explain why empty + what to do ("No items yet. Create your first item →")
- Loading: "Saving..." not "Loading..." (be specific)
