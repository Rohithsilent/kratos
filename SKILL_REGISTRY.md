# Antigravity Skills Registry

This document serves as the dynamic skill registry for the Antigravity agent in the current environment.

## 📦 Imported Skills

The following skills have been successfully scanned from `~/.gemini/antigravity/skills` and are **Active**:

1. **`ui-ux-pro-max`** - Primary UI/UX design intelligence.
2. **`brand-identity`** - Single source of truth for brand guidelines.
3. **`brainstorming`** - Explores intent, requirements, and design.
4. **`error-handling-patterns`** - Master error handling patterns for resiliency.
5. **`skill-creator`** - Scaffolds new agent skills.
6. **`writing-plans`** - Granular step-by-step implementation planning.
7. **`frontend-design`** - Create distinctive, production-grade frontend interfaces with high design quality.

*(Note: Duplicate or invalid skills have been safely ignored. Existing skills remain intact.)*

## 🚦 Activation Rules

Antigravity will auto-enable relevant skills based on your prompt intent:

- **Frontend & UI Requests**: Automatically triggers `ui-ux-pro-max` and `frontend-design`.
- **Component Consistency**: Automatically triggers `brand-identity` (as the `design-system` alternative).
- **Mobile App Generation**: Uses Flutter best practices prioritizing `ui-ux-pro-max` and `frontend-design`.
- **Modern Interactions**: Prioritizes smooth, modern interactions via `ui-ux-pro-max` and `frontend-design` guidelines.

## 🥇 Skill Priority

1. `ui-ux-pro-max` *(Primary UI generation skill)*
2. `frontend-design` *(Primary frontend aesthetic and design implementation skill)*
3. `flutter-ui` *(Subsumed via Flutter stack preferences)*
4. `design-system` *(Mapped to `brand-identity` / `ui-ux-pro-max` / `frontend-design`)*
5. `mobile-ui` *(Mapped to `ui-ux-pro-max` / `frontend-design`)*
6. `animation` *(Smooth interactions rule)*
7. `dashboard-ui` *(Mapped to SaaS rules in `ui-ux-pro-max`)*

## 🎨 Project Preferences

- **Preferred Stack**: Flutter + Tailwind + Modern UI Systems
- **Theme Preferences**:
  - Premium futuristic fitness aesthetic
  - Red/black color palette
  - Dark mode first
  - Minimal clean layouts
  - Smooth animations

## ⚙️ Dependency Resolution

- UI/UX generation seamlessly falls back to **Flutter** for mobile elements.
- **`brand-identity`** is loaded prior to **`ui-ux-pro-max`** when strict brand tokens are defined.
- **`brainstorming`** is executed before **`writing-plans`** when starting new features.
