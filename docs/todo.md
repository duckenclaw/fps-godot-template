# Roadmap

## Movement (done)
- [x] idle state
- [x] moving state
- [x] crouching state
- [x] jumping state
- [x] falling state
- [x] sliding state
- [x] wallruning state
- [x] dashing state
- [x] camera tilt
- [x] sfx for movement
- [x] screen shake

## Items & interaction (done)
- [x] equipping items
- [x] inventory
- [x] moving objects through "interact" (grab controller + movable group)
- [x] hands model and animations
- [x] item registry (ItemDB)

## UI (done)
- [x] graphics menu
- [x] options menu
- [x] pause menu
- [x] key rebinding
- [x] language selector

## Framework / production systems (done)
- [x] FP Framework addon (plugin auto-registers autoloads)
- [x] EventBus (decoupled gameplay events)
- [x] SceneManager (async load + fade transitions + level registry)
- [x] AudioManager (music crossfade + pooled SFX) + default bus layout fix
- [x] SaveManager (slotted save/load, quick save/load F5/F9)
- [x] Localization (CSV translations + in-game language switch)
- [x] Health component (event-driven damage/death, difficulty scaling)
- [x] Player death + respawn
- [x] Debug overlay (F3)
- [x] Utils helpers
- [x] level template + "Making a Game" guide

## Backlog / nice to have
- [ ] dialogic addon integration
- [ ] enemy/AI example using the Health component
- [ ] font fallback for non-Latin locales (PixeloidMono is Latin-only)
- [ ] save-slot selection UI (SaveManager already supports multiple slots)
- [ ] loading screen UI hooked to SceneManager.load_progress
- [ ] generalize StateMachine.State typing for reuse by enemies/NPCs
