// Set current year in footer
document.getElementById("year").textContent = new Date().getFullYear();

// Scroll Reveal Animation
const observerOptions = {
  threshold: 0.1,
  rootMargin: "0px 0px -50px 0px",
};

const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add("visible");
      observer.unobserve(entry.target);
    }
  });
}, observerOptions);

document.querySelectorAll(".scroll-reveal").forEach((el) => {
  observer.observe(el);
});

// Smooth Scroll for Anchors
document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener("click", function (e) {
    if (this.getAttribute("href") === "#") return; // Ignore js links
    e.preventDefault();
    document.querySelector(this.getAttribute("href")).scrollIntoView({
      behavior: "smooth",
    });
  });
});

// iOS Alert
function iosAlert() {
  alert("iOS Version Coming Soon! Stay polished ✨");
}

// Theme Toggle & Asset Switching
const themeBtn = document.getElementById("theme-toggle");
const appPreview = document.getElementById("app-preview");
const body = document.body;

function updateThemeAssets() {
  const isDark = body.classList.contains("dark-mode");
  const themeIcon = themeBtn.querySelector("i");

  if (isDark) {
    themeIcon.classList.replace("fa-moon", "fa-sun");
    if (appPreview)
      appPreview.src = "assets/image/app_preview_dark.jpg";
    localStorage.setItem("theme", "dark");
  } else {
    themeIcon.classList.replace("fa-sun", "fa-moon");
    if (appPreview)
      appPreview.src = "assets/image/app_preview_light.jpg";
    localStorage.setItem("theme", "light");
  }
}

// Check Local Storage on load
if (localStorage.getItem("theme") === "dark") {
  body.classList.add("dark-mode");
}
updateThemeAssets();

themeBtn.addEventListener("click", () => {
  body.classList.toggle("dark-mode");
  updateThemeAssets();
});

// Mobile Menu Toggle
const menuToggle = document.getElementById("menu-toggle");
const navMenu = document.getElementById("nav-menu");
const menuOverlay = document.getElementById("menu-overlay");

function toggleMenu() {
  navMenu.classList.toggle("active");
  menuOverlay.classList.toggle("active");
  const menuIcon = menuToggle.querySelector("i");
  if (navMenu.classList.contains("active")) {
    menuIcon.classList.replace("fa-bars", "fa-times");
  } else {
    menuIcon.classList.replace("fa-times", "fa-bars");
  }
}

menuToggle.addEventListener("click", toggleMenu);
menuOverlay.addEventListener("click", toggleMenu);

// Close menu when clicking links
document.querySelectorAll(".nav-menu a").forEach((link) => {
  link.addEventListener("click", () => {
    if (navMenu.classList.contains("active")) {
      toggleMenu();
    }
  });
});
