# crucible

yo — this is a test repo for fun. was bored and vibecoded an FPS with Opus 4.6.

arena multiplayer shooter in Godot 4.6. inspired by quake / apex / the usual stuff. mostly just me throwing ideas at Claude and seeing what sticks.

## what works right now

- dedicated server + clients over ENet (UDP 27015)
- movement: bunnyhop with momentum boost chains, quake-style air strafe, slide (sprint+ctrl), grappling hook (Q)
- two guns — primary blaster (20 dmg, fast fire rate) and heavy blaster (50 dmg, slow). headshots do 1.5×
- melee swing (V)
- hp, damage, respawn after 3s
- kill/death tracking
- placeholder arena to run around in
- can run headless as a dedicated server (tested, not deployed yet)

## controls

| key | action |
|---|---|
| WASD | move |
| mouse | aim |
| space | jump |
| shift | sprint |
| ctrl | slide (while sprinting) |
| Q | grappling hook |
| LMB | shoot |
| V | melee |
| 1 / 2 | swap weapon |
| esc | release mouse |

## how to run

need Godot 4.6.2 (forward+ renderer).

1. clone the repo
2. open `project.godot` in Godot
3. hit F5

dedicated server mode:
```
godot --headless -- --server
```
clients connect from the main menu by typing the server IP.

## roadmap (stuff Opus still has to do lol)

- [ ] 4 characters with abilities — VENOM (poison dots), BULWARK (deployable shield), VOLT (lightning dash), HAWK TUAH (still workshopping what this one does)
- [ ] round system — best of 7, 90s timer, last player alive wins the round
- [ ] powerups: quad damage, haste, armor, medkit
- [ ] pre-match lobby with character select + ready-up
- [ ] killfeed in the corner
- [ ] hit markers when you land a shot
- [ ] damage direction indicator when you get hit
- [ ] an actual arena (the current one is literally just boxes on a plane)
- [ ] wallrun (tried once, shelved it — might come back to it)
- [ ] export presets + deploy to the oracle ARM64 VPS
- [ ] actually playtest this with a friend instead of shooting at nothing alone

## credits

everything was vibecoded with Claude Opus 4.6. commits are co-authored so you can see which chunks were AI (spoiler: all of them). assets are kenney blaster-kit + stylized nature megakit + mixamo animations.

## license

MIT. do whatever.
