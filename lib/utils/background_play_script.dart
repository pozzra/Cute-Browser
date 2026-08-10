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

  // 1. Silent Web Audio Loop (Prevents 5-minute throttle)
  let audioCtx;
  const startKeepAlive = () => {
     if (audioCtx) return;
     try {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (AC) {
        audioCtx = new AC();
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        gain.gain.value = 0.001; // Extremely low but not zero to keep pipeline active
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start(0);
        console.log("CuteBrowser: Silent Web Audio loop active.");
      }
    } catch (e) {
      console.warn("CuteBrowser: Failed to init Web Audio loop", e);
    }
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

  let userPaused = false;
  let lastUserAction = 0;
  
  ['click', 'touchstart', 'mousedown', 'keydown', 'touchend', 'scroll', 'touchmove', 'pointerdown', 'pointerup', 'pointermove'].forEach(name => {
    window.addEventListener(name, () => { 
      lastUserAction = Date.now(); 
      startKeepAlive();
    }, { capture: true, passive: true });
  });

  const forcePlay = (v) => {
    if (userPaused) return;
    if (v.muted) v.muted = false;
    if (v.paused && !v.ended && v.readyState > 1) {
      v.play().catch(() => {});
    }
  };

  const sync = () => {
    const videos = document.querySelectorAll('video, audio');
    videos.forEach(v => {
      if (!v._notiAttached) {
        v.addEventListener('play', () => { 
           if (Date.now() - lastUserAction < 5000) userPaused = false; 
        });
        v.addEventListener('pause', () => {
          if (Date.now() - lastUserAction < 5000) {
            userPaused = true;
          } else {
            setTimeout(() => { if(!userPaused) forcePlay(v); }, 150);
          }
        });
        v.addEventListener('ratechange', () => forcePlay(v));
        v.addEventListener('ended', () => {
          if (document.title.includes('YouTube') && !userPaused) {
             setTimeout(() => sync(), 1000);
          }
        });
        v._notiAttached = true;
      }
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
      if (!userPaused) sync(); 
    }, true);
  });

  if ('mediaSession' in navigator) {
    navigator.mediaSession.setActionHandler('play', () => { userPaused = false; sync(); });
    navigator.mediaSession.setActionHandler('pause', () => { userPaused = true; document.querySelectorAll('video, audio').forEach(v => v.pause()); });
    
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

      if (!navigator.mediaSession.metadata || navigator.mediaSession.metadata.title !== title || navigator.mediaSession.metadata.artist !== artist) {
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
    // Reduced frequency from 2000 to 5000ms
    setInterval(updateMeta, 5000);
  }

  window.cutePlayAction = (action) => {
    const v = document.querySelector('video, audio');
    if (!v) return;
    if (action === 'play') {
      if (v.paused) { userPaused = false; v.play(); }
      else { userPaused = true; v.pause(); }
    } else if (action === 'next') {
      const btn = document.querySelector('.ytp-next-button') || 
                  document.querySelector('.next-button') ||
                  document.querySelector('a[title*="Next"]');
      if (btn) btn.click();
    } else if (action === 'prev') {
      const btn = document.querySelector('.ytp-prev-button') || 
                  document.querySelector('.prev-button') ||
                  document.querySelector('a[title*="Previous"]');
      if (btn) btn.click();
      else window.history.back();
    }
    sync();
  };

  window.syncAllVideos = sync;
  // Reduced frequency from 3000 to 10000ms (sync is also called on events)
  setInterval(sync, 10000); 

  applyMocks();
  sync();
  console.log("CuteBrowser: Background Play (v15 Keep-Alive) Active");
})();
""";
