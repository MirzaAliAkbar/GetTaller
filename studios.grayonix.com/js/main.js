// Grayonix Studios - Main JavaScript
// Navigation interactivity and smooth scrolling

document.addEventListener('DOMContentLoaded', function() {
  // Get DOM elements
  const hamburgerMenu = document.querySelector('#hamburger-menu');
  const navMenu = document.querySelector('#nav-menu');
  const navLinks = document.querySelectorAll('.nav-link');

  // Hamburger menu toggle
  hamburgerMenu.addEventListener('click', function() {
    hamburgerMenu.classList.toggle('active');
    navMenu.classList.toggle('active');
  });

  // Handle nav link clicks: close menu and smooth scroll
  navLinks.forEach(link => {
    link.addEventListener('click', function(e) {
      // Get the target section id from href
      const targetId = this.getAttribute('href');

      // Close the menu
      hamburgerMenu.classList.remove('active');
      navMenu.classList.remove('active');

      // Smooth scroll to target section
      if (targetId.startsWith('#')) {
        e.preventDefault();
        const targetSection = document.querySelector(targetId);
        if (targetSection) {
          targetSection.scrollIntoView({ behavior: 'smooth' });
        }
      }
    });
  });

  // Track scroll position and highlight active section
  window.addEventListener('scroll', function() {
    let currentSection = '';

    // Check which section is in view (with offset for sticky navbar)
    const sections = document.querySelectorAll('main section[id]');
    sections.forEach(section => {
      const sectionTop = section.offsetTop;
      const sectionHeight = section.clientHeight;

      // If section is visible on screen (top portion)
      if (window.pageYOffset >= sectionTop - 150) {
        currentSection = section.getAttribute('id');
      }
    });

    // Remove active class from all links
    navLinks.forEach(link => {
      link.classList.remove('active');
    });

    // Add active class to current section's link
    if (currentSection) {
      const activeLink = document.querySelector(`.nav-link[href="#${currentSection}"]`);
      if (activeLink) {
        activeLink.classList.add('active');
      }
    }
  });
});
