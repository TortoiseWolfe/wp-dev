# ScriptHammer Metronome App

This project provides a functional metronome/drum sequencer for WordPress. There are two implementations:

1. **Direct Integration (Current)**: A vanilla JavaScript implementation embedded directly via shortcode
2. **React App (Future)**: A React-based implementation for integration via ReactPress

## Features

- Four-track drum sequencer
- Multiple preset beat patterns (Basic Rock, Disco, Hip Hop, Jazz, Waltz)
- Adjustable tempo (60-200 BPM)
- Mute/unmute tracks
- Volume control per track
- Real-time audio using Web Audio API

## Current Implementation

The current implementation uses vanilla JavaScript and the Web Audio API for sound generation. It's embedded in WordPress through a mu-plugin that registers the `[scripthammer_react_app]` shortcode. This provides:

- Interactive UI with click-to-toggle beats
- Working audio - press play to hear the drum pattern
- Multiple preset patterns
- Beat step highlighting

The JavaScript is directly embedded in the WordPress plugin for simple deployment.

## Installation

### For development

1. Clone this repository
2. Run `npm install`
3. Run `npm start`

### For WordPress integration

1. Build the app with `npm run build`
2. Copy the build files to `/wp-content/plugins/reactpress/apps/scripthammer-app/`
3. Register the app with ReactPress using the WordPress CLI:
   ```
   wp reactpress register scripthammer-app
   ```

## Embedding the App

Once installed, you can embed the app in WordPress using the shortcode `[scripthammer_react_app]` on any post or page.

## Screenshots

![Metronome App Preview](./metronome-preview.png)