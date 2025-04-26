import React, { useState, useEffect, useRef } from 'react';
import { Play, Pause, Volume2, VolumeX } from 'lucide-react';

const MetronomeApp = () => {
  // Define preset patterns
  const presetPatterns = {
    "Basic Rock": [
      { name: 'Kick', pattern: [1, 0, 0, 0, 1, 0, 0, 0], muted: false, volume: 0.8 },
      { name: 'Snare', pattern: [0, 0, 1, 0, 0, 0, 1, 0], muted: false, volume: 0.8 },
      { name: 'Hi-Hat', pattern: [1, 1, 1, 1, 1, 1, 1, 1], muted: false, volume: 0.6 },
      { name: 'Ride', pattern: [0, 0, 0, 0, 0, 0, 0, 0], muted: true, volume: 0.5 }
    ],
    "Disco": [
      { name: 'Kick', pattern: [1, 0, 0, 1, 1, 0, 0, 1], muted: false, volume: 0.8 },
      { name: 'Snare', pattern: [0, 0, 1, 0, 0, 0, 1, 0], muted: false, volume: 0.8 },
      { name: 'Hi-Hat', pattern: [1, 1, 1, 1, 1, 1, 1, 1], muted: false, volume: 0.6 },
      { name: 'Ride', pattern: [0, 0, 0, 0, 0, 0, 0, 0], muted: true, volume: 0.5 }
    ],
    "Hip Hop": [
      { name: 'Kick', pattern: [1, 0, 0, 0, 0, 0, 1, 0], muted: false, volume: 0.8 },
      { name: 'Snare', pattern: [0, 0, 1, 0, 0, 0, 1, 0], muted: false, volume: 0.8 },
      { name: 'Hi-Hat', pattern: [1, 0, 1, 0, 1, 0, 1, 0], muted: false, volume: 0.6 },
      { name: 'Ride', pattern: [0, 1, 0, 1, 0, 1, 0, 1], muted: false, volume: 0.5 }
    ],
    "Jazz": [
      { name: 'Kick', pattern: [1, 0, 0, 0, 0, 0, 0, 0], muted: false, volume: 0.8 },
      { name: 'Snare', pattern: [0, 0, 1, 0, 0, 0, 1, 0], muted: false, volume: 0.8 },
      { name: 'Hi-Hat', pattern: [0, 0, 0, 0, 0, 0, 0, 0], muted: true, volume: 0.6 },
      { name: 'Ride', pattern: [1, 1, 1, 1, 1, 1, 1, 1], muted: false, volume: 0.5 }
    ],
    "Waltz (3/4)": [
      { name: 'Kick', pattern: [1, 0, 0, 1, 0, 0, 0, 0], muted: false, volume: 0.8 },
      { name: 'Snare', pattern: [0, 0, 0, 0, 0, 1, 0, 0], muted: false, volume: 0.8 },
      { name: 'Hi-Hat', pattern: [1, 0, 1, 1, 0, 1, 0, 0], muted: false, volume: 0.6 },
      { name: 'Ride', pattern: [0, 0, 0, 0, 0, 0, 0, 0], muted: true, volume: 0.5 }
    ]
  };

  // State
  const [tempo, setTempo] = useState(120);
  const [isPlaying, setIsPlaying] = useState(false);
  const [activeStep, setActiveStep] = useState(0);
  const [currentPreset, setCurrentPreset] = useState("Basic Rock");
  const [trackState, setTrackState] = useState(presetPatterns["Basic Rock"]);
  const [audioInitialized, setAudioInitialized] = useState(false);

  // Refs
  const timerRef = useRef(null);
  const audioRef = useRef({
    kick: null,
    snare: null,
    hihat: null,
    ride: null
  });

  // Initialize audio
  useEffect(() => {
    if (!audioInitialized) {
      // Create kick audio
      const kickAudio = new Audio();
      kickAudio.src = "data:audio/wav;base64,UklGRnQGAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YU8GAACA/4L/e/+g/7r/2P/P/+3/CQDr/wQANQAbAA4AWQBDAC4AZQBuAEwAWgB0AG0AXwBIAD4AbQA8ACAAKAA5AP//CgAjAOT/6P/V/8z/xP+s/53/hP9y/3X/Yf8//2L/Sf8//0H/V/81/zj/Pf9J/0X/Sf9g/2v/X/9s/4b/ff+S/6z/qP+y/8z/1P/z/xEACwAYACwAMABBAGUAWwBbAGUAZgCCAJAAkACVAJ8AnQCjAKMArAC4AKUAowCnAKQAmgCDAIYAgABkAFoATAA9ADAAGwD6//L/2P/A/7z/qP+R/4b/c/9s/2L/U/9F/z7/Pf85/zv/M/8s/y//Nv8+/z//R/9Q/1j/X/93/4L/h/+X/6r/tv/L/9X/6v/9/w0AKwA4AFQAYABtAIUAkwCjAKwAvgDLANIA5QDqAPwADgEOARUBGgEeASABHwEWARIBDQECAfcA6gDhAM8AvQCrAJQAgQByAF0APgAyAB8ABQDw/9X/wP+w/5X/e/9j/1X/Sv87/yz/JP8a/xH/Dv8N/wj/Cv8L/xL/Gf8f/yT/L/89/0z/XP9p/3v/iv+c/63/wf/W/+r//v8VACkAPQBTAGkAfQCQAKQAuADMAOIA9gAGARUBIgEvATwBRgFPAVYBWwFeAWABYQFeAVsBVgFPAUgBQQE4ASsBHwEQAQEB8ADfAM8AvgCsAJkAhgBxAF4ASQA2ACEA//7q/tX+w/6v/pr+if52/mn+XP5S/kj+Pf44/jP+MP4v/i7+Mf4z/jj+P/5G/k/+W/5n/nT+g/6S/qL+sv7C/tX+5v75/g7/If81/0n/Xf9z/4j/nf+z/8n/4f/3/w0AIwA4AE0AYgB3AIwAoACzAMYA2QDqAPwADQEdASsBOQFEAVABWgFjAWsBcAF1AXcBdwF3AXcBdAFxAWwBZwFgAVcBTQFBAToB";
      kickAudio.volume = 0.8;
      kickAudio.preload = "auto";
      
      // Create snare audio
      const snareAudio = new Audio();
      snareAudio.src = "data:audio/wav;base64,UklGRtwAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YbgAAACBAAAAwf/a/wQA2f/s//v/CQDb/+L//v8UANv/4/8PAC8A+//y/yQADAAbABEAJAALADgAGQA1ABsAQAABADoABgAvABsAIAAmAAsAEAAbAPz/8P/0/+f/zP/P/7v/wf+h/6z/hP+Z/2z/fv9V/2j/RP9R/zj/QP8s/zT/JP8n/yn/J/8t/yX/Mf8z/0H/Nf9R/0H/YP9U/3X/av+D/37/lP+S/6T/pP+2/7f/x//K/9j/3v/r//P///8=";
      snareAudio.volume = 0.7;
      snareAudio.preload = "auto";
      
      // Create hi-hat audio
      const hihatAudio = new Audio();
      hihatAudio.src = "data:audio/wav;base64,UklGRtwAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YbgAAACBAAAAwf/a/wQA2f/s//v/CQDb/+L//v8UANv/4/8PAC8A+//y/yQADAAbABEAJAALADgAGQA1ABsAQAABADoABgAvABsAIAAmAAsAEAAbAPz/8P/0/+f/zP/P/7v/wf+h/6z/hP+Z/2z/fv9V/2j/RP9R/zj/QP8s/zT/JP8n/yn/J/8t/yX/Mf8z/0H/Nf9R/0H/YP9U/3X/av+D/37/lP+S/6T/pP+2/7f/x//K/9j/3v/r//P///8=";
      hihatAudio.volume = 0.5;
      hihatAudio.preload = "auto";
      
      // Create ride audio
      const rideAudio = new Audio();
      rideAudio.src = "data:audio/wav;base64,UklGRpoBAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YYYBAACj/2n/0f8BAAAAEQAxQG4/WSdjKIgSfwFk8iLr9OL63P/Yrtu14MLcZua28If6MQEiCGkPgBV2GjEeyyCjInMhQR6rGvwVEw9ICLEDdfzf9iLz6+//8RD2c/oM/hoC4AnnDFsPzA/AD7IOVQyMCK8G1AOlAFT/uf2m+574bvuX/hsB9QNXB5EJrAvbDBQMsAqfCIAGIwQ5AVH/Mv2B+3P6efo0+5L8+f23/9EBsAMeBRgG0gZVBrEF7QVSBO8BXwD0/rb94vyL/Kj8Vf0W/tb+//9OAZUD8gR0BckF0QUBBQoE6gLLAZQATP9z/vT9af0V/ev8xPyi/K/8EP1l/bP9Jf6Z/vP+SP+d//H/PgCOAN8AIgFmAbIB8QEuAmkCngLSAggDPQNtA54D1AMDBDQEYQSKBLMExwTZBOgE9gQCBQYFCQUIBQkFBgXnBA8F3QTPBLcElQR2BE8EJwQCBNgDsQOKA2kDQwMeA/gC1QKyApIChA==";
      rideAudio.volume = 0.6;
      rideAudio.preload = "auto";
      
      // Store audio elements in ref
      audioRef.current = {
        kick: kickAudio,
        snare: snareAudio,
        hihat: hihatAudio,
        ride: rideAudio
      };
      
      setAudioInitialized(true);
    }
  }, [audioInitialized]);

  // Play a sound
  const playSound = (sound) => {
    try {
      // Create audio context for more reliable sound
      const context = new (window.AudioContext || window.webkitAudioContext)();
      const gainNode = context.createGain();
      gainNode.connect(context.destination);
      
      // Configure sound based on djembe type
      switch(sound) {
        case 'kick': // Bass tone (low djembe sound)
          createDjembeBass(context, gainNode);
          break;
        case 'snare': // Tone (mid djembe sound)
          createDjembeTone(context, gainNode);
          break;
        case 'hihat': // Slap (high djembe sound)
          createDjembeSlap(context, gainNode);
          break;
        case 'ride': // Muted slap (softer high sound)
          createDjembeMutedSlap(context, gainNode);
          break;
        default:
          break;
      }
      
      // Close context after sound has played
      setTimeout(() => {
        context.close();
      }, 800);
    } catch (e) {
      console.log("Audio play error:", e);
    }
  };
  
  // Djembe bass sound (deep, resonant)
  const createDjembeBass = (context, gainNode) => {
    // Main tone
    const osc = context.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(80, context.currentTime);
    
    // Filtering to get warmer sound
    const filter = context.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(200, context.currentTime);
    filter.Q.setValueAtTime(2, context.currentTime);
    
    // Envelope
    gainNode.gain.setValueAtTime(0, context.currentTime);
    gainNode.gain.linearRampToValueAtTime(0.9, context.currentTime + 0.02);
    gainNode.gain.setValueAtTime(0.9, context.currentTime + 0.02);
    gainNode.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 0.7);
    
    // Connect and play
    osc.connect(filter);
    filter.connect(gainNode);
    osc.start(context.currentTime);
    osc.stop(context.currentTime + 0.7);
    
    // Add a bit of attack noise for realism
    addAttackNoise(context, gainNode, 0.2, 70, 200);
  };
  
  // Djembe tone sound (mid-range, resonant)
  const createDjembeTone = (context, gainNode) => {
    // Main tone (higher than bass)
    const osc = context.createOscillator();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(190, context.currentTime);
    
    // Filtering for warm tone
    const filter = context.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.setValueAtTime(250, context.currentTime);
    filter.Q.setValueAtTime(1.5, context.currentTime);
    
    // Envelope - shorter than bass
    gainNode.gain.setValueAtTime(0, context.currentTime);
    gainNode.gain.linearRampToValueAtTime(0.7, context.currentTime + 0.01);
    gainNode.gain.setValueAtTime(0.7, context.currentTime + 0.01);
    gainNode.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 0.4);
    
    // Connect and play
    osc.connect(filter);
    filter.connect(gainNode);
    osc.start(context.currentTime);
    osc.stop(context.currentTime + 0.4);
    
    // Add attack noise
    addAttackNoise(context, gainNode, 0.3, 200, 600);
  };
  
  // Djembe slap sound (sharp, high)
  const createDjembeSlap = (context, gainNode) => {
    // Create noise for the slap
    addAttackNoise(context, gainNode, 0.5, 800, 5000);
    
    // Add a bit of tone
    const osc = context.createOscillator();
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(380, context.currentTime);
    
    // Envelope - very short attack and decay
    const oscGain = context.createGain();
    oscGain.gain.setValueAtTime(0, context.currentTime);
    oscGain.gain.linearRampToValueAtTime(0.4, context.currentTime + 0.005);
    oscGain.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 0.15);
    
    // Connect and play
    osc.connect(oscGain);
    oscGain.connect(gainNode);
    osc.start(context.currentTime);
    osc.stop(context.currentTime + 0.15);
  };
  
  // Djembe muted slap (softer high sound)
  const createDjembeMutedSlap = (context, gainNode) => {
    // Mostly noise-based with some tonal qualities
    addAttackNoise(context, gainNode, 0.3, 300, 2000);
    
    // Add tone with frequency shift
    const osc = context.createOscillator();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(320, context.currentTime);
    osc.frequency.exponentialRampToValueAtTime(180, context.currentTime + 0.1);
    
    // Envelope - muted sound decays quickly
    const oscGain = context.createGain();
    oscGain.gain.setValueAtTime(0, context.currentTime);
    oscGain.gain.linearRampToValueAtTime(0.3, context.currentTime + 0.01);
    oscGain.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 0.2);
    
    // Connect and play
    osc.connect(oscGain);
    oscGain.connect(gainNode);
    osc.start(context.currentTime);
    osc.stop(context.currentTime + 0.2);
  };
  
  // Helper function to add attack noise for more realistic djembe sounds
  const addAttackNoise = (context, gainNode, volume, lowFreq, highFreq) => {
    // Create noise for the attack
    const noise = context.createBufferSource();
    const bufferSize = context.sampleRate * 0.2; // 200ms of noise
    const buffer = context.createBuffer(1, bufferSize, context.sampleRate);
    const data = buffer.getChannelData(0);
    
    // Fill buffer with noise
    for (let i = 0; i < bufferSize; i++) {
      data[i] = Math.random() * 2 - 1;
    }
    
    // Create a bandpass filter to shape the noise
    const filter = context.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.value = (lowFreq + highFreq) / 2;
    filter.Q.value = 1;
    
    // Envelope for the noise
    const noiseGain = context.createGain();
    noiseGain.gain.setValueAtTime(0, context.currentTime);
    noiseGain.gain.linearRampToValueAtTime(volume, context.currentTime + 0.005);
    noiseGain.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 0.1);
    
    // Connect and play
    noise.buffer = buffer;
    noise.connect(filter);
    filter.connect(noiseGain);
    noiseGain.connect(gainNode);
    noise.start(context.currentTime);
  };

  // Toggle play/pause
  const togglePlay = () => {
    setIsPlaying(!isPlaying);
  };

  // Toggle track mute
  const toggleMute = (trackIndex) => {
    const newTrackState = [...trackState];
    newTrackState[trackIndex].muted = !newTrackState[trackIndex].muted;
    setTrackState(newTrackState);
  };

  // Update pattern for a track
  const toggleStep = (trackIndex, stepIndex) => {
    const newTrackState = [...trackState];
    newTrackState[trackIndex].pattern[stepIndex] = newTrackState[trackIndex].pattern[stepIndex] ? 0 : 1;
    setTrackState(newTrackState);
  };

  // Update volume for a track
  const updateVolume = (trackIndex, volume) => {
    const newTrackState = [...trackState];
    newTrackState[trackIndex].volume = volume;
    setTrackState(newTrackState);
    
    // Update audio volume
    switch(trackIndex) {
      case 0:
        if (audioRef.current.kick) audioRef.current.kick.volume = volume;
        break;
      case 1:
        if (audioRef.current.snare) audioRef.current.snare.volume = volume;
        break;
      case 2:
        if (audioRef.current.hihat) audioRef.current.hihat.volume = volume;
        break;
      case 3:
        if (audioRef.current.ride) audioRef.current.ride.volume = volume;
        break;
      default:
        break;
    }
  };

  // Load a preset pattern
  const loadPreset = (presetName) => {
    if (presetPatterns[presetName]) {
      setCurrentPreset(presetName);
      setTrackState([...presetPatterns[presetName]]);
    }
  };

  // Metronome effect
  useEffect(() => {
    if (isPlaying && audioInitialized) {
      // Clear existing timer
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
      
      // Calculate beat interval in milliseconds
      const beatInterval = (60 / tempo) * 1000 / 2; // 16th notes
      
      // Start timer
      let step = activeStep;
      timerRef.current = setInterval(() => {
        // Play sounds for current step
        trackState.forEach((track, trackIndex) => {
          if (!track.muted && track.pattern[step] === 1) {
            switch(trackIndex) {
              case 0: 
                playSound('kick');
                break;
              case 1:
                playSound('snare');
                break;
              case 2:
                playSound('hihat');
                break;
              case 3:
                playSound('ride');
                break;
              default:
                break;
            }
          }
        });
        
        // Update step counter
        step = (step + 1) % 8;
        setActiveStep(step);
      }, beatInterval);
    } else if (!isPlaying && timerRef.current) {
      clearInterval(timerRef.current);
    }
    
    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, [isPlaying, tempo, trackState, audioInitialized]);

  return (
    <div className="p-4 max-w-3xl mx-auto rounded-lg shadow-md" style={{ backgroundColor: '#d9cdb9', color: '#3d3223', boxShadow: '0 4px 6px rgba(61,50,35,0.3)' }}>
      <h1 className="text-2xl font-bold mb-4 text-center" style={{ color: '#3d3223' }}>4-Track Metronome</h1>
      
      {/* Preset Selector */}
      <div className="mb-4">
        <label className="block font-semibold mb-2" style={{ color: '#3d3223' }}>Beat Pattern:</label>
        <div className="grid grid-cols-3 gap-2 mb-2">
          {Object.keys(presetPatterns).map((preset) => (
            <button
              key={preset}
              onClick={() => loadPreset(preset)}
              style={{
                backgroundColor: currentPreset === preset ? '#805c34' : '#e6dbc9',
                color: currentPreset === preset ? '#f0e8d9' : '#3d3223',
                border: currentPreset === preset ? 'none' : '1px solid #805c34',
                borderRadius: '0.25rem',
                padding: '0.5rem'
              }}
            >
              {preset}
            </button>
          ))}
        </div>
      </div>
      
      {/* Tempo Control */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <label className="font-semibold" style={{ color: '#3d3223' }}>Tempo: {tempo} BPM</label>
          <button 
            onClick={togglePlay}
            style={{
              backgroundColor: isPlaying ? '#9b4729' : '#e2a240', 
              color: '#f0e8d9',
              padding: '0.5rem',
              borderRadius: '9999px',
              boxShadow: '0 0 8px rgba(226, 162, 64, 0.9), 0 0 15px rgba(0, 0, 0, 0.4)',
              border: '2px solid #f0e8d9',
              minHeight: '48px',
              minWidth: '48px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center'
            }}
          >
            {isPlaying ? <Pause size={24} /> : <Play size={24} />}
          </button>
        </div>
        <input 
          type="range" 
          min="60" 
          max="200" 
          value={tempo} 
          onChange={(e) => setTempo(parseInt(e.target.value))}
          className="w-full"
          style={{ accentColor: '#805c34' }}
        />
      </div>
      
      {/* Track Sequencer */}
      <div className="space-y-4">
        {trackState.map((track, trackIndex) => (
          <div key={trackIndex} style={{ 
            backgroundColor: '#f0e8d9', 
            padding: '0.75rem', 
            borderRadius: '0.25rem', 
            boxShadow: '0 1px 3px rgba(61,50,35,0.2)',
            border: '1px solid #c1b59e' 
          }}>
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center">
                <button 
                  onClick={() => toggleMute(trackIndex)}
                  style={{
                    padding: '0.25rem',
                    marginRight: '0.5rem',
                    borderRadius: '9999px',
                    backgroundColor: track.muted ? '#c1b59e' : '#805c34',
                    color: track.muted ? '#3d3223' : '#f0e8d9'
                  }}
                >
                  {track.muted ? <VolumeX size={16} /> : <Volume2 size={16} />}
                </button>
                <span className="font-medium" style={{ color: '#3d3223' }}>{track.name}</span>
              </div>
              <input 
                type="range"
                min="0"
                max="1"
                step="0.1"
                value={track.volume}
                onChange={(e) => updateVolume(trackIndex, parseFloat(e.target.value))}
                className="w-24"
                style={{ accentColor: '#805c34' }}
              />
            </div>
            
            <div className="grid grid-cols-8 gap-2">
              {track.pattern.map((on, stepIndex) => (
                <div 
                  key={stepIndex}
                  onClick={() => toggleStep(trackIndex, stepIndex)}
                  style={{
                    height: '2rem',
                    borderRadius: '0.25rem',
                    cursor: 'pointer',
                    border: '2px solid',
                    backgroundColor: on ? '#805c34' : '#e6dbc9',
                    borderColor: on ? '#5c4027' : '#c1b59e',
                    boxShadow: activeStep === stepIndex && isPlaying ? '0 0 0 2px rgba(153, 101, 21, 0.9)' : 'none'
                  }}
                />
              ))}
            </div>
          </div>
        ))}
      </div>
      
      <div className="mt-4 text-center text-sm" style={{ color: '#3d3223' }}>
        Click on cells to toggle beats on/off. Use the mute buttons to silence tracks.
      </div>
    </div>
  );
};

export default MetronomeApp;