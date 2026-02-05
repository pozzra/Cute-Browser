const String googleLoginFixScript = """
(function() {
  // 1. Mask navigator.webdriver
  Object.defineProperty(navigator, 'webdriver', {
    get: () => false
  });

  // 2. Add fake chrome object if missing
  if (!window.chrome) {
    window.chrome = {
      runtime: {},
      loadTimes: function() {},
      csi: function() {},
      app: {}
    };
  }

  // 3. Mask window.outerHeight and window.outerWidth
  if (window.outerHeight === 0) window.outerHeight = window.innerHeight;
  if (window.outerWidth === 0) window.outerWidth = window.innerWidth;

  // 4. Force platform to Linux or Mac to avoid WebView detection
  Object.defineProperty(navigator, 'platform', {
    get: () => 'Linux armv8l'
  });

  // 5. Mask Vendor and AppName
  Object.defineProperty(navigator, 'vendor', {
    get: () => 'Google Inc.'
  });

  // 6. Fake Battery API if missing (WebView often lacks it)
  if (!navigator.getBattery) {
    navigator.getBattery = () => Promise.resolve({
      charging: true,
      chargingTime: 0,
      dischargingTime: Infinity,
      level: 1,
      onchargingchange: null,
      onchargingtimechange: null,
      ondischargingtimechange: null,
      onlevelchange: null
    });
  }

  // 7. Try to mask the fact that it's a WebView
  // Some sites check for certain APIs that are usually present in Chrome but not WebView
  if (!window.navigator.languages || window.navigator.languages.length === 0) {
    Object.defineProperty(navigator, 'languages', {
      get: () => ['en-US', 'en']
    });
  }

  console.log("CuteBrowser: Identity hardening applied.");
})();
""";
