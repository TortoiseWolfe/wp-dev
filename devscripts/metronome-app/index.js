import React from 'react';
import ReactDOM from 'react-dom';
import MetronomeApp from './MetronomeApp';

// Check if we're in a WordPress environment by looking for the container
document.addEventListener('DOMContentLoaded', function() {
  const container = document.getElementById('scripthammer-react-app');
  
  if (container) {
    // We're in WordPress environment
    ReactDOM.render(<MetronomeApp />, container);
    console.log('ScriptHammer React Metronome App loaded in WordPress');
  } else {
    // We might be in development environment
    const devContainer = document.getElementById('root');
    if (devContainer) {
      ReactDOM.render(<MetronomeApp />, devContainer);
      console.log('ScriptHammer React Metronome App loaded in development mode');
    } else {
      console.error('No container found for ScriptHammer React Metronome App');
    }
  }
});