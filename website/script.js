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

// Theme Toggle
const themeBtn = document.getElementById("theme-toggle");
const body = document.body;

// Check Local Storage
if (localStorage.getItem("theme") === "dark") {
  body.classList.add("dark-mode");
}

themeBtn.addEventListener("click", () => {
  body.classList.toggle("dark-mode");
  if (body.classList.contains("dark-mode")) {
    localStorage.setItem("theme", "dark");
  } else {
    localStorage.setItem("theme", "light");
  }
});
