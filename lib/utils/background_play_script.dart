const String backgroundPlayScript = """
(function() {
  const mockTrue = { get: function() { return true; }, configurable: true };
  const mockFalse = { get: function() { return false; }, configurable: true };
  const mockVisible = { get: function() { return 'visible'; }, configurable: true };

  const applyMocks = () => {
    Object.defineProperty(document, 'hidden', mockFalse);
    Object.defineProperty(document, 'visibilityState', mockVisible);
    Object.defineProperty(document, 'webkitVisibilityState', mockVisible);
    try {
      if (typeof document.hasFocus === 'function') {
        document.hasFocus = () => true;
      } else {
        Object.defineProperty(document, 'hasFocus', { value: () => true, configurable: true });
      }
    } catch(e) {}
  };

  if (typeof window.IntersectionObserver !== 'undefined') {
    window.IntersectionObserver = class {
      constructor(callback) { this.callback = callback; }
      observe(target) {
        if (typeof this.callback === 'function') {
           this.callback([{ target, isIntersecting: true, intersectionRatio: 1.0 }]);
        }
      }
      unobserve() {}
      disconnect() {}
    };
  }

  if (window.AudioContext || window.webkitAudioContext) {
    const OriginalAC = window.AudioContext || window.webkitAudioContext;
    window.AudioContext = window.webkitAudioContext = function() {
      const ac = new OriginalAC();
      Object.defineProperty(ac, 'state', { get: function() { return 'running'; } });
      
      // Silent Loop: Keeps the AudioContext pipeline alive even when there's no active media.
      // This is crucial for background playback on many Android devices.
      try {
        const oscillator = ac.createOscillator();
        const gainNode = ac.createGain();
        gainNode.gain.value = 0.001; // Extremely low but not zero
        oscillator.connect(gainNode);
        gainNode.connect(ac.destination);
        oscillator.start(0);
      } catch(e) { console.log("CuteBrowser: Silent loop init failed", e); }
      
      return ac;
    };
  }

  let userPaused = false;
  let lastUserAction = 0;
  
  // Capture more events, especially pointer events the modern players use
  ['click', 'touchstart', 'mousedown', 'keydown', 'touchend', 'scroll', 'touchmove', 'pointerdown', 'pointerup', 'pointermove'].forEach(name => {
    window.addEventListener(name, () => { lastUserAction = Date.now(); }, { capture: true, passive: true });
  });

  const forcePlay = (v) => {
    if (userPaused) return;
    if (v.paused && !v.ended && v.readyState > 1) {
      v.play().catch(() => {});
    }
  };

  const sync = () => {
    applyMocks();
    const videos = document.querySelectorAll('video, audio');
    videos.forEach(v => {
      if (!v._notiAttached) {
        v.addEventListener('play', () => { 
           // If it plays, and there was a recent user action, consider it user-initiated
           if (Date.now() - lastUserAction < 5000) userPaused = false; 
        });
        v.addEventListener('pause', () => {
          // If paused by a user action, respect it
          if (Date.now() - lastUserAction < 5000) {
            userPaused = true;
          } else {
            // Delay force play slightly to avoid racing with site logic
            setTimeout(() => { if(!userPaused) forcePlay(v); }, 150);
          }
        });
        v.addEventListener('ratechange', () => forcePlay(v));
        // Also listen for ended to avoid infinite loop restarting a finished video
        v.addEventListener('ended', () => {
          if (document.title.includes('YouTube') && !userPaused) {
             // YouTube next may need a push
             setTimeout(() => sync(), 1000);
          }
        });
        v._notiAttached = true;
      }
      // Do not force play on every sync tick if user paused it
      if (!userPaused) {
        forcePlay(v);
      }
    });

    if ('mediaSession' in navigator) {
       const isPlaying = Array.from(videos).some(v => !v.paused);
       navigator.mediaSession.playbackState = isPlaying ? 'playing' : 'paused';
       if (window.PlaybackChannel) {
         window.PlaybackChannel.postMessage(JSON.stringify({ 
           type: 'status', 
           playing: isPlaying,
           title: document.title.replace(' - YouTube', '')
         }));
       }
    }
  };

  ['visibilitychange', 'webkitvisibilitychange', 'blur', 'focusout', 'pagehide', 'pageshow'].forEach(name => {
    window.addEventListener(name, (e) => { 
      e.stopImmediatePropagation(); 
      applyMocks();
      // Only force play on visibility changes if the user didn't pause before backgrounding
      if (!userPaused) sync(); 
    }, true);
  });

  if ('mediaSession' in navigator) {
    navigator.mediaSession.setActionHandler('play', () => { userPaused = false; sync(); });
    navigator.mediaSession.setActionHandler('pause', () => { userPaused = true; document.querySelectorAll('video, audio').forEach(v => v.pause()); });
    
    // Attempt to keep MediaSession alive even if silenced
    const updateMeta = () => {
      if (!navigator.mediaSession) return;
      let title = document.title.replace(' - YouTube', '');
      let artist = "Cute Browser";
      const sel = {
        t: ['h1.title yt-formatted-string', '.slim-video-metadata-title', '.ytm-slim-video-metadata-title', '.video-title', 'h1.watch-title-container'],
        c: ['#owner-sub-count', '.ytm-slim-owner-channel-name', '.item-channel-name', '.yt-user-info a']
      };
      for (let s of sel.t) { let el = document.querySelector(s); if (el && el.innerText) { title = el.innerText; break; } }
      for (let s of sel.c) { let el = document.querySelector(s); if (el && el.innerText) { artist = el.innerText; break; } }

      if (navigator.mediaSession.metadata?.title !== title || navigator.mediaSession.metadata?.artist !== artist) {
        navigator.mediaSession.metadata = new MediaMetadata({
          title, artist, album: "Cute Browser",
          artwork: [{ src: 'https://cdn-icons-png.flaticon.com/512/3670/3670163.png', sizes: '512x512', type: 'image/png' }]
        });
        if (window.PlaybackChannel) {
          window.PlaybackChannel.postMessage(JSON.stringify({ 
            type: 'metadata', 
            title: title, 
            artist: artist 
          }));
        }
      }
    };
    setInterval(updateMeta, 2000);
  }

  window.syncAllVideos = sync;
  
  // Faster interval for core sync, though browser will throttle this to ~1min in background anyway.
  // The silent loop helps prevent the engine from totally suspending.
  setInterval(sync, 3000); 

  applyMocks();
  sync();
  console.log("CuteBrowser: Background Play (v14 Silent Loop) Active");
})();
""";
