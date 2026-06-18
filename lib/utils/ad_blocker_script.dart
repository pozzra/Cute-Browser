const String adBlockerScript = """
(function() {
  const adSelectors = [
    '.ad', '.ads', '.advert', '.advertisement', '.banner-ad', 
    '#ad', '#ads', '#advert', '#advertisement', 
    '[id^="google_ads"]', '[id^="div-gpt-ad"]',
    '.adsbygoogle', '.fb-ad', '.ad-container',
    'iframe[src*="doubleclick.net"]', 'iframe[src*="googlesyndication.com"]'
  ];

  function removeAds() {
    // 1. Static Ads
    adSelectors.forEach(selector => {
      const elements = document.querySelectorAll(selector);
      elements.forEach(el => {
        if (el.style.display !== 'none') {
           el.style.display = 'none';
           el.style.visibility = 'hidden';
        }
      });
    });
    
    // 2. Direct YouTube Ad Skipping
    const skipButton = document.querySelector('.ytp-ad-skip-button') || 
                       document.querySelector('.ytp-ad-skip-button-modern') ||
                       document.querySelector('.ytp-ad-skip-button-text') ||
                       document.querySelector('.ytp-skip-ad-button');
    if (skipButton) {
      console.log("CuteBrowser: YouTube Ad detected, clicking skip!");
      skipButton.click();
    }

    // 3. Force forward video if it's an unskippable ad
    // Using a more stable approach to avoid player errors
    const video = document.querySelector('video');
    const adShowing = document.querySelector('.ad-showing') || 
                     document.querySelector('.ytp-ad-player-overlay');
                     
    if (video && adShowing) {
        // Mute during ad for "smoothness"
        if (!video.muted) {
            video.muted = true;
            video.dataset.wasAutomuted = "true";
        }
        
        // Speed up the ad instead of jumping to the end to avoid "Video Error"
        if (video.playbackRate < 10) {
            video.playbackRate = 16; 
        }

        // Still try to jump if it's safe (near end)
        if (video.duration > 0 && !isNaN(video.duration)) {
             if (video.currentTime < video.duration - 0.5) {
                video.currentTime = video.duration - 0.1;
             }
        }
    } else if (video && video.dataset.wasAutomuted === "true") {
        video.muted = false;
        video.playbackRate = 1;
        delete video.dataset.wasAutomuted;
    }
  }

  // Initial Run
  removeAds();

  // Use MutationObserver for performance instead of setInterval
  const observer = new MutationObserver((mutations) => {
    // Debounce calls to removeAds
    if (window._adBlockTimeout) clearTimeout(window._adBlockTimeout);
    window._adBlockTimeout = setTimeout(removeAds, 500);
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true
  });
  
  // Safety fallback for very dynamic content
  setInterval(removeAds, 5000);
})();
""";
