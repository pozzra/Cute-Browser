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
    adSelectors.forEach(selector => {
      const elements = document.querySelectorAll(selector);
      elements.forEach(el => {
        el.style.display = 'none';
        el.style.visibility = 'hidden';
      });
    });
    
    // Direct YouTube Ad Skipping
    const skipButton = document.querySelector('.ytp-ad-skip-button') || 
                       document.querySelector('.ytp-ad-skip-button-modern') ||
                       document.querySelector('.ytp-ad-skip-button-text') ||
                       document.querySelector('.ytp-skip-ad-button');
    if (skipButton) {
      console.log("CuteBrowser: YouTube Ad detected, clicking skip!");
      skipButton.click();
    }

    // Force forward video if it's an unskippable ad
    const video = document.querySelector('video');
    const adBeingShown = document.querySelector('.ad-showing') || 
                        document.querySelector('.ytp-ad-player-overlay') || 
                        document.querySelector('.ytp-ad-visit-advertiser-button');
    if (video && adBeingShown) {
        // Mute during ad for "smoothness"
        if (!video.muted) {
            video.muted = true;
            video.dataset.wasAutomuted = "true";
        }
        
        if (video.duration > 0 && !isNaN(video.duration)) {
            const isActuallyAd = document.querySelector('.ytp-ad-text') || 
                                document.querySelector('.ytp-ad-preview-text') ||
                                document.querySelector('.ytp-ad-skip-button');
            if (isActuallyAd) {
                video.currentTime = video.duration;
            }
        }
    } else if (video && video.dataset.wasAutomuted === "true") {
        video.muted = false;
        delete video.dataset.wasAutomuted;
    }
  }

  // Run on load
  removeAds();

  // Run periodically to catch dynamic ads (faster for "smoothness")
  setInterval(removeAds, 200);
})();
""";
