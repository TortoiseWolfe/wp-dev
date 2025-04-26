<?php
/**
 * ScriptHammer Metronome App
 * 
 * This file creates a fully functional metronome/drum sequencer application
 * that demonstrates the integration of interactive applications within WordPress.
 * The implementation uses vanilla JavaScript and the Web Audio API for sound generation.
 * 
 * In the future, a more sophisticated React-based implementation will be integrated
 * using ReactPress, with build artifacts placed in:
 * wp-content/plugins/reactpress/apps/scripthammer-app/
 */

// Exit if accessed directly
if (!defined('ABSPATH')) {
    exit;
}

/**
 * Register the ScriptHammer React app placeholder shortcode
 */
function scripthammer_reactapp_placeholder_init() {
    add_shortcode('scripthammer_react_app', 'render_scripthammer_react_placeholder');
}
add_action('init', 'scripthammer_reactapp_placeholder_init');

/**
 * Render the placeholder for the React app
 * 
 * @return string HTML content for the placeholder
 */
function render_scripthammer_react_placeholder() {
    // Generate a unique ID for this instance
    $instance_id = 'metronome-' . uniqid();
    
    // Interactive metronome app with working functionality
    $output = '<div id="' . $instance_id . '" class="metronome-app" style="max-width: 800px; margin: 20px auto; background-color: #d9cdb9; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(61,50,35,0.3); font-family: sans-serif;">';
    
    // Title
    $output .= '<h1 style="text-align: center; margin-top: 0; color: #3d3223;">Interactive Metronome</h1>';
    
    // Pattern selector
    $output .= '<div style="margin-bottom: 20px;">';
    $output .= '<label style="color: #3d3223;"><strong>Beat Pattern:</strong></label>';
    $output .= '<div class="pattern-buttons" style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-top: 10px;">';
    $output .= '<button data-pattern="basic" style="padding: 8px 0; background-color: #805c34; color: #f0e8d9; border: none; border-radius: 4px; cursor: pointer;">Basic Rock</button>';
    $output .= '<button data-pattern="disco" style="padding: 8px 0; background-color: #e6dbc9; color: #3d3223; border: 1px solid #805c34; border-radius: 4px; cursor: pointer;">Disco</button>';
    $output .= '<button data-pattern="hiphop" style="padding: 8px 0; background-color: #e6dbc9; color: #3d3223; border: 1px solid #805c34; border-radius: 4px; cursor: pointer;">Hip Hop</button>';
    $output .= '<button data-pattern="jazz" style="padding: 8px 0; background-color: #e6dbc9; color: #3d3223; border: 1px solid #805c34; border-radius: 4px; cursor: pointer;">Jazz</button>';
    $output .= '<button data-pattern="waltz" style="padding: 8px 0; background-color: #e6dbc9; color: #3d3223; border: 1px solid #805c34; border-radius: 4px; cursor: pointer;">Waltz (3/4)</button>';
    $output .= '<button data-pattern="custom" style="padding: 8px 0; background-color: #e6dbc9; color: #3d3223; border: 1px solid #805c34; border-radius: 4px; cursor: pointer;">Custom</button>';
    $output .= '</div>';
    $output .= '</div>';
    
    // Tempo controls
    $output .= '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">';
    $output .= '<span class="tempo-display" style="font-size: 18px; font-weight: bold; color: #3d3223;">Tempo: 120 BPM</span>';
    $output .= '<button class="play-button" style="background-color: #ff5a36; color: #ffffff; border: 3px solid #ffffff; width: 60px; height: 60px; border-radius: 50%; font-size: 24px; cursor: pointer; box-shadow: 0 0 12px rgba(255, 90, 54, 0.9), 0 0 20px rgba(0, 0, 0, 0.5), 0 0 0 2px rgba(255, 255, 255, 0.3); text-align: center; line-height: 54px; position: relative; overflow: hidden; animation: pulse-play 2s infinite;">▶</button>
    <style>
    @keyframes pulse-play {
      0% { transform: scale(1); box-shadow: 0 0 12px rgba(255, 90, 54, 0.8), 0 0 20px rgba(0, 0, 0, 0.5), 0 0 0 2px rgba(255, 255, 255, 0.3); }
      50% { transform: scale(1.05); box-shadow: 0 0 16px rgba(255, 90, 54, 1), 0 0 24px rgba(0, 0, 0, 0.6), 0 0 0 3px rgba(255, 255, 255, 0.5); }
      100% { transform: scale(1); box-shadow: 0 0 12px rgba(255, 90, 54, 0.8), 0 0 20px rgba(0, 0, 0, 0.5), 0 0 0 2px rgba(255, 255, 255, 0.3); }
    }
    </style>';
    $output .= '</div>';
    $output .= '<input type="range" class="tempo-slider" min="60" max="200" value="120" style="width: 100%; margin-bottom: 20px; accent-color: #805c34;">';
    
    // Track 1: Kick
    $output .= '<div class="track" data-track="kick" style="background-color: #f0e8d9; padding: 15px; margin-bottom: 15px; border-radius: 4px; box-shadow: 0 1px 3px rgba(61,50,35,0.2); border: 1px solid #c1b59e;">';
    $output .= '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">';
    $output .= '<div style="display: flex; align-items: center;">';
    $output .= '<button class="mute-button" style="width: 24px; height: 24px; border-radius: 50%; border: none; background-color: #805c34; color: #f0e8d9; margin-right: 8px; font-size: 12px;">🔊</button>';
    $output .= '<span style="color: #3d3223;">Kick</span>';
    $output .= '</div>';
    $output .= '<input type="range" class="volume-slider" min="0" max="1" step="0.1" value="0.8" style="width: 100px; accent-color: #805c34;">';
    $output .= '</div>';
    $output .= '<div class="beat-cells" style="display: grid; grid-template-columns: repeat(8, 1fr); gap: 8px;">';
    $output .= '<div class="beat active" data-beat="0" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="1" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="2" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="3" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat active" data-beat="4" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="5" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="6" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="7" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '</div>';
    $output .= '</div>';
    
    // Track 2: Snare
    $output .= '<div class="track" data-track="snare" style="background-color: #f0e8d9; padding: 15px; margin-bottom: 15px; border-radius: 4px; box-shadow: 0 1px 3px rgba(61,50,35,0.2); border: 1px solid #c1b59e;">';
    $output .= '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">';
    $output .= '<div style="display: flex; align-items: center;">';
    $output .= '<button class="mute-button" style="width: 24px; height: 24px; border-radius: 50%; border: none; background-color: #805c34; color: #f0e8d9; margin-right: 8px; font-size: 12px;">🔊</button>';
    $output .= '<span style="color: #3d3223;">Snare</span>';
    $output .= '</div>';
    $output .= '<input type="range" class="volume-slider" min="0" max="1" step="0.1" value="0.8" style="width: 100px; accent-color: #805c34;">';
    $output .= '</div>';
    $output .= '<div class="beat-cells" style="display: grid; grid-template-columns: repeat(8, 1fr); gap: 8px;">';
    $output .= '<div class="beat" data-beat="0" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="1" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat active" data-beat="2" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="3" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="4" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="5" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat active" data-beat="6" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="7" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '</div>';
    $output .= '</div>';
    
    // Track 3: Hi-Hat
    $output .= '<div class="track" data-track="hihat" style="background-color: #f0e8d9; padding: 15px; margin-bottom: 15px; border-radius: 4px; box-shadow: 0 1px 3px rgba(61,50,35,0.2); border: 1px solid #c1b59e;">';
    $output .= '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">';
    $output .= '<div style="display: flex; align-items: center;">';
    $output .= '<button class="mute-button" style="width: 24px; height: 24px; border-radius: 50%; border: none; background-color: #805c34; color: #f0e8d9; margin-right: 8px; font-size: 12px;">🔊</button>';
    $output .= '<span style="color: #3d3223;">Hi-Hat</span>';
    $output .= '</div>';
    $output .= '<input type="range" class="volume-slider" min="0" max="1" step="0.1" value="0.6" style="width: 100px; accent-color: #805c34;">';
    $output .= '</div>';
    $output .= '<div class="beat-cells" style="display: grid; grid-template-columns: repeat(8, 1fr); gap: 8px;">';
    $output .= '<div class="beat active" data-beat="0" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '<div class="beat active" data-beat="1" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '<div class="beat active" data-beat="2" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '<div class="beat active" data-beat="3" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '<div class="beat active" data-beat="4" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '<div class="beat active" data-beat="5" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '<div class="beat active" data-beat="6" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '<div class="beat active" data-beat="7" style="height: 30px; border-radius: 4px; background-color: #805c34; border: 2px solid #5c4027; cursor: pointer;"></div>';
    $output .= '</div>';
    $output .= '</div>';
    
    // Track 4: Ride
    $output .= '<div class="track" data-track="ride" style="background-color: #f0e8d9; padding: 15px; margin-bottom: 15px; border-radius: 4px; box-shadow: 0 1px 3px rgba(61,50,35,0.2); border: 1px solid #c1b59e;">';
    $output .= '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">';
    $output .= '<div style="display: flex; align-items: center;">';
    $output .= '<button class="mute-button muted" style="width: 24px; height: 24px; border-radius: 50%; border: none; background-color: #c1b59e; color: #3d3223; margin-right: 8px; font-size: 12px;">M</button>';
    $output .= '<span style="color: #3d3223;">Ride</span>';
    $output .= '</div>';
    $output .= '<input type="range" class="volume-slider" min="0" max="1" step="0.1" value="0.5" style="width: 100px; accent-color: #805c34;">';
    $output .= '</div>';
    $output .= '<div class="beat-cells" style="display: grid; grid-template-columns: repeat(8, 1fr); gap: 8px;">';
    $output .= '<div class="beat" data-beat="0" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="1" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="2" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="3" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="4" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="5" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="6" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '<div class="beat" data-beat="7" style="height: 30px; border-radius: 4px; background-color: #e6dbc9; border: 2px solid #c1b59e; cursor: pointer;"></div>';
    $output .= '</div>';
    $output .= '</div>';
    
    // Instructions
    $output .= '<div style="text-align: center; font-size: 14px; color: #3d3223; margin-top: 20px;">';
    $output .= 'Click on cells to toggle beats on/off. Use the mute buttons to silence tracks.';
    $output .= '</div>';
    
    // Add the JavaScript for the metronome functionality
    $output .= '<script>
    document.addEventListener("DOMContentLoaded", function() {
        // Initialize the metronome for this instance
        initMetronome("' . $instance_id . '");
    });

    function initMetronome(instanceId) {
        const container = document.getElementById(instanceId);
        if (!container) return;
        
        // Audio Context and sounds
        let audioContext;
        let isPlaying = false;
        let timerID = null;
        let currentStep = 0;
        let tempo = 120;
        
        // Get elements
        const playButton = container.querySelector(".play-button");
        const tempoSlider = container.querySelector(".tempo-slider");
        const tempoDisplay = container.querySelector(".tempo-display");
        const tracks = container.querySelectorAll(".track");
        const patternButtons = container.querySelectorAll(".pattern-buttons button");
        
        // Beat patterns
        const patterns = {
            "basic": {
                "kick": [1, 0, 0, 0, 1, 0, 0, 0],
                "snare": [0, 0, 1, 0, 0, 0, 1, 0],
                "hihat": [1, 1, 1, 1, 1, 1, 1, 1],
                "ride": [0, 0, 0, 0, 0, 0, 0, 0]
            },
            "disco": {
                "kick": [1, 0, 0, 1, 1, 0, 0, 1],
                "snare": [0, 0, 1, 0, 0, 0, 1, 0],
                "hihat": [1, 1, 1, 1, 1, 1, 1, 1],
                "ride": [0, 0, 0, 0, 0, 0, 0, 0]
            },
            "hiphop": {
                "kick": [1, 0, 0, 0, 0, 0, 1, 0],
                "snare": [0, 0, 1, 0, 0, 0, 1, 0],
                "hihat": [1, 0, 1, 0, 1, 0, 1, 0],
                "ride": [0, 1, 0, 1, 0, 1, 0, 1]
            },
            "jazz": {
                "kick": [1, 0, 0, 0, 0, 0, 0, 0],
                "snare": [0, 0, 1, 0, 0, 0, 1, 0],
                "hihat": [0, 0, 0, 0, 0, 0, 0, 0],
                "ride": [1, 1, 1, 1, 1, 1, 1, 1]
            },
            "waltz": {
                "kick": [1, 0, 0, 1, 0, 0, 0, 0],
                "snare": [0, 0, 0, 0, 0, 1, 0, 0],
                "hihat": [1, 0, 1, 1, 0, 1, 0, 0],
                "ride": [0, 0, 0, 0, 0, 0, 0, 0]
            },
            "custom": {
                "kick": [1, 0, 0, 0, 1, 0, 0, 0],
                "snare": [0, 0, 1, 0, 0, 0, 1, 0],
                "hihat": [1, 1, 1, 1, 1, 1, 1, 1],
                "ride": [0, 0, 0, 0, 0, 0, 0, 0]
            }
        };
        
        // Set up event listeners
        playButton.addEventListener("click", togglePlay);
        tempoSlider.addEventListener("input", updateTempo);
        
        // Set up track controls
        tracks.forEach(track => {
            const trackType = track.dataset.track;
            const muteButton = track.querySelector(".mute-button");
            const volumeSlider = track.querySelector(".volume-slider");
            const beatCells = track.querySelectorAll(".beat");
            
            // Mute button
            muteButton.addEventListener("click", () => {
                muteButton.classList.toggle("muted");
                if (muteButton.classList.contains("muted")) {
                    muteButton.style.backgroundColor = "#c1b59e";
                    muteButton.style.color = "#3d3223";
                    muteButton.textContent = "M";
                } else {
                    muteButton.style.backgroundColor = "#805c34";
                    muteButton.style.color = "#f0e8d9";
                    muteButton.textContent = "🔊";
                }
            });
            
            // Beat cells
            beatCells.forEach(cell => {
                cell.addEventListener("click", () => {
                    cell.classList.toggle("active");
                    if (cell.classList.contains("active")) {
                        cell.style.backgroundColor = "#805c34";
                        cell.style.borderColor = "#5c4027";
                    } else {
                        cell.style.backgroundColor = "#e6dbc9";
                        cell.style.borderColor = "#c1b59e";
                    }
                });
            });
        });
        
        // Pattern buttons
        patternButtons.forEach(button => {
            button.addEventListener("click", () => {
                const patternName = button.dataset.pattern;
                loadPattern(patternName);
                
                // Update button styles
                patternButtons.forEach(btn => {
                    btn.style.backgroundColor = "#e6dbc9";
                    btn.style.color = "#3d3223";
                    btn.style.border = "1px solid #805c34";
                });
                button.style.backgroundColor = "#805c34";
                button.style.color = "#f0e8d9";
                button.style.border = "none";
            });
        });
        
        // Functions
        function togglePlay() {
            if (!audioContext) {
                initAudio();
            }
            
            isPlaying = !isPlaying;
            
            if (isPlaying) {
                currentStep = 0;
                playButton.textContent = "⏸";
                playButton.style.backgroundColor = "#3b7adb"; // Blue for pause
                playButton.style.animation = "none"; // Stop animation when playing
                playButton.style.transform = "scale(1)"; // Reset scale
                playTick();
            } else {
                playButton.textContent = "▶";
                playButton.style.backgroundColor = "#ff5a36"; // Bright orange-red for high visibility
                playButton.style.animation = "pulse-play 2s infinite"; // Restart animation
                window.clearTimeout(timerID);
            }
        }
        
        function updateTempo() {
            tempo = parseInt(tempoSlider.value);
            tempoDisplay.textContent = `Tempo: ${tempo} BPM`;
        }
        
        function loadPattern(patternName) {
            if (!patterns[patternName]) return;
            
            const pattern = patterns[patternName];
            
            tracks.forEach(track => {
                const trackType = track.dataset.track;
                const beatCells = track.querySelectorAll(".beat");
                
                if (pattern[trackType]) {
                    beatCells.forEach((cell, index) => {
                        const isActive = pattern[trackType][index] === 1;
                        cell.classList.toggle("active", isActive);
                        cell.style.backgroundColor = isActive ? "#805c34" : "#e6dbc9";
                        cell.style.borderColor = isActive ? "#5c4027" : "#c1b59e";
                    });
                }
            });
        }
        
        function initAudio() {
            try {
                // Create audio context
                audioContext = new (window.AudioContext || window.webkitAudioContext)();
            } catch (e) {
                console.error("Web Audio API is not supported in this browser");
            }
        }
        
        function playTick() {
            // Calculate beat interval in milliseconds
            const beatInterval = (60 / tempo) * 1000 / 2; // 16th notes
            
            // Schedule the next tick
            timerID = window.setTimeout(function() {
                if (isPlaying) {
                    playStep();
                    
                    // Move to next step
                    currentStep = (currentStep + 1) % 8;
                    
                    // Schedule next tick
                    playTick();
                }
            }, beatInterval);
        }
        
        function playStep() {
            // Highlight current step
            highlightCurrentStep();
            
            // Play sounds for current step
            tracks.forEach(track => {
                const trackType = track.dataset.track;
                const muteButton = track.querySelector(".mute-button");
                const volumeSlider = track.querySelector(".volume-slider");
                const beatCells = track.querySelectorAll(".beat");
                const currentBeat = beatCells[currentStep];
                
                // Check if beat is active and track is not muted
                if (currentBeat && 
                    currentBeat.classList.contains("active") && 
                    !muteButton.classList.contains("muted")) {
                    
                    // Play the sound
                    const volume = parseFloat(volumeSlider.value);
                    playSound(trackType, volume);
                }
            });
        }
        
        function highlightCurrentStep() {
            // Remove highlight from all cells
            const allBeats = container.querySelectorAll(".beat");
            allBeats.forEach(beat => {
                beat.style.boxShadow = "none";
            });
            
            // Add highlight to current step
            const currentBeats = container.querySelectorAll(`.beat[data-beat="${currentStep}"]`);
            currentBeats.forEach(beat => {
                beat.style.boxShadow = "0 0 0 2px rgba(153, 101, 21, 0.9)"; // Golden brown highlight
            });
        }
        
        function playSound(type, volume) {
            if (!audioContext) return;
            
            try {
                // Create oscillator
                const osc = audioContext.createOscillator();
                const gainNode = audioContext.createGain();
                gainNode.gain.value = volume;
                
                // Configure sound based on type
                switch(type) {
                    case "kick":
                        // Low frequency sound
                        osc.type = "sine";
                        osc.frequency.setValueAtTime(150, audioContext.currentTime);
                        osc.frequency.exponentialRampToValueAtTime(60, audioContext.currentTime + 0.08);
                        gainNode.gain.setValueAtTime(volume, audioContext.currentTime);
                        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.2);
                        break;
                    case "snare":
                        // Noise-like sound
                        osc.type = "triangle";
                        osc.frequency.setValueAtTime(250, audioContext.currentTime);
                        gainNode.gain.setValueAtTime(volume, audioContext.currentTime);
                        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1);
                        
                        // Add noise
                        addNoise(0.1, volume * 0.7);
                        break;
                    case "hihat":
                        // High frequency sound
                        osc.type = "square";
                        osc.frequency.setValueAtTime(800, audioContext.currentTime);
                        gainNode.gain.setValueAtTime(volume * 0.3, audioContext.currentTime);
                        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.05);
                        
                        // Add noise
                        addNoise(0.05, volume * 0.5);
                        break;
                    case "ride":
                        // Metallic sound
                        osc.type = "sine";
                        osc.frequency.setValueAtTime(600, audioContext.currentTime);
                        gainNode.gain.setValueAtTime(volume * 0.3, audioContext.currentTime);
                        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
                        break;
                    default:
                        osc.type = "sine";
                        osc.frequency.setValueAtTime(440, audioContext.currentTime);
                        break;
                }
                
                // Connect and start
                osc.connect(gainNode);
                gainNode.connect(audioContext.destination);
                osc.start();
                osc.stop(audioContext.currentTime + 0.5);
            } catch (e) {
                console.error("Error playing sound:", e);
            }
        }
        
        function addNoise(duration, volume) {
            try {
                // Create buffer for noise
                const bufferSize = audioContext.sampleRate * duration;
                const buffer = audioContext.createBuffer(1, bufferSize, audioContext.sampleRate);
                const data = buffer.getChannelData(0);
                
                // Fill buffer with random values (white noise)
                for (let i = 0; i < bufferSize; i++) {
                    data[i] = Math.random() * 2 - 1;
                }
                
                // Create source and gain
                const noise = audioContext.createBufferSource();
                noise.buffer = buffer;
                
                const noiseGain = audioContext.createGain();
                noiseGain.gain.setValueAtTime(volume, audioContext.currentTime);
                noiseGain.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + duration);
                
                // Connect and start
                noise.connect(noiseGain);
                noiseGain.connect(audioContext.destination);
                noise.start();
            } catch (e) {
                console.error("Error creating noise:", e);
            }
        }
    }
    </script>';
    
    $output .= '</div>';
    
    return $output;
}

/**
 * Add a ReactPress integration note to the admin footer
 */
function scripthammer_reactpress_admin_footer_text($footer_text) {
    $current_screen = get_current_screen();
    
    // Only show on specific admin pages if needed
    if ($current_screen && ($current_screen->base === 'dashboard' || 
                          strpos($current_screen->base, 'scripthammer') !== false)) {
        $footer_text = 'React integration planned via ReactPress | ' . $footer_text;
    }
    
    return $footer_text;
}
add_filter('admin_footer_text', 'scripthammer_reactpress_admin_footer_text');