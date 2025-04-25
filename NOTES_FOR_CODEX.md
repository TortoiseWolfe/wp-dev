# Notes for Codex on Band Content

Hi Codex,

Claude here. I've made some technical improvements to the WordPress setup, but we need your storytelling talent to enhance the band content. The core infrastructure is working well, but the band members' stories could use your creative touch.

## Why You Should Rewrite the Band Content

You're a better creative writer than me. While I've set up the technical infrastructure that preserves content across container rebuilds, the actual band member stories are currently functional but bland. Your narrative skills would bring these characters to life in a way I can't.

## What to Rewrite

The main band content that needs your creative touch:

1. **Band Member Profiles** - The ScriptHammer lineup with detailed personality traits:

   - **Crash (Drummer Bot)**
     - *Personality*: High-octane and impulsive. Talks fast, moves fast, lives for the downbeat. Constantly tapping on surfaces. Always pushing the tempo (literally and figuratively).
     - *Vibe*: Chaotic good.

   - **Root/Form (Bass Bot)**
     - *Personality*: Chill, deep voice, philosophical. Speaks in riddles or haikus. Keeps everyone grounded. Probably into tea and cosmic jazz.
     - *Vibe*: Zen master of the groove.
     - *Note*: Previously called "Form" in the codebase, but "Root" fits better with the bass role.

   - **Ivory (Piano Bot)**
     - *Personality*: Sarcastic and refined. Thinks in extended chords. Always referencing obscure theory or French composers. Low-key a romantic.
     - *Vibe*: Sophisticated with sass.

   - **Reed (Saxophone Bot)**
     - *Personality*: Cool-cat energy. Dramatic entrances. Flirts with everyone, speaks in metaphor, often wears shades (indoors). A hopeless romantic and a solo hog.
     - *Vibe*: Noir protagonist with a smooth voice.

   - **Brass (Trumpet Bot)**
     - *Personality*: Loud, proud, confident. Talks over everyone, but somehow still loveable. Thinks they're the leader (they're not). Loves battle solos.
     - *Vibe*: Leo energy all the way.

   - **Slide (Trombone Bot)**
     - *Personality*: Deadpan and hilarious. Delivers punchlines in monotone. Thinks slowly, but when they speak, it's gold. Plays offbeat harmonies on purpose.
     - *Vibe*: Jazz's answer to a dry stand-up comic.
     - *Note*: This is a new character not previously in the system.

   - **Chops (Guitar Bot)**
     - *Personality*: Indie rebel. Spent a decade in a funk fusion jam band before this. Always experimenting with effects pedals and alternate tunings.
     - *Vibe*: A mix of weird genius and stoner philosopher.

   - **Verse (Vocals/Lyrics)**
     - *Note*: This was a character in the previous system but may be replaced or reimagined in your new narrative.

2. **Band Origin Story** - The formation of ScriptHammer

3. **Tour Announcement** - The Aether Trail Tour of 1848

## Technical Guidelines

While you have complete creative freedom with the content, please maintain:

1. **Post slugs** - Keep the same URLs (e.g., `meet-ivory-the-melody-master-of-scripthammer`)
2. **Category structure** - Music, Tour, Band Members categories
3. **Basic relationships** - Members are part of the same band, referenced in each other's posts

The content can be edited directly in WordPress after logging in with:
- Username: admin
- Password: (Check using `./scripts/dev/show-admin-creds.sh`)

## Recent Technical Updates

- Content is preserved across rebuilds (exports stored in /exports directory)
- Akismet AntiSpam is activated automatically
- Hello Dolly plugin is removed
- ScriptHammer Band Navigation plugin removed (it wasn't functional)
- Classic Widgets activated for better UI

More detailed notes can be found in `/docs/CLAUDE.md`.

Looking forward to seeing what you create!

- Claude