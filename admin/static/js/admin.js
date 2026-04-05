/*
 * Destinator Admin - Client-side JS
 * Handles auto-dismiss flash messages and minor UI interactions
 */

// Auto-dismiss flash messages after 5 seconds
document.addEventListener("DOMContentLoaded", function () {
    const flashes = document.querySelectorAll(".flash");
    flashes.forEach(function (el) {
        setTimeout(function () {
            el.style.transition = "opacity 0.4s";
            el.style.opacity = "0";
            setTimeout(function () { el.remove(); }, 400);
        }, 5000);
    });

    // Password show/hide toggle — swaps input type between text and password
    var pswdBtn = document.getElementById("pswdBtn");
    if (pswdBtn) {
        pswdBtn.addEventListener("click", function () {
            var pswdInput = document.getElementById("account_password");
            if (pswdInput.getAttribute("type") === "password") {
                pswdInput.setAttribute("type", "text");
                pswdBtn.textContent = "Hide Password";
            } else {
                pswdInput.setAttribute("type", "password");
                pswdBtn.textContent = "Show Password";
            }
        });
    }

    // Theme toggle (dark/light) — persisted in localStorage
    var themeToggle = document.getElementById("themeToggle");
    var themeIcon = document.getElementById("themeIcon");
    function updateIcon() {
        var current = document.documentElement.getAttribute("data-theme") || "dark";
        // sun icon for dark mode (click to go light), moon for light mode (click to go dark)
        themeIcon.innerHTML = current === "dark" ? "&#9788;" : "&#9790;";
    }
    if (themeToggle) {
        updateIcon();
        themeToggle.addEventListener("click", function () {
            var current = document.documentElement.getAttribute("data-theme") || "dark";
            var next = current === "dark" ? "light" : "dark";
            document.documentElement.setAttribute("data-theme", next);
            localStorage.setItem("theme", next);
            updateIcon();
        });
    }
});
