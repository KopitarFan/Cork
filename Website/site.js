const header = document.querySelector("[data-site-header]");

function updateHeader() {
  if (!header || header.classList.contains("solid-header")) return;
  header.classList.toggle("is-scrolled", window.scrollY > 24);
}

updateHeader();
window.addEventListener("scroll", updateHeader, { passive: true });

document.querySelectorAll("[data-current-year]").forEach((element) => {
  element.textContent = String(new Date().getFullYear());
});

const galleryImage = document.querySelector("[data-gallery-image]");
const galleryTitle = document.querySelector("[data-gallery-title]");
const galleryCaption = document.querySelector("[data-gallery-caption]");
const galleryTabs = [...document.querySelectorAll("[data-gallery-tab]")];

galleryTabs.forEach((tab) => {
  const preload = new Image();
  preload.src = tab.dataset.image;

  tab.addEventListener("click", () => {
    if (!galleryImage || tab.getAttribute("aria-selected") === "true") return;

    galleryTabs.forEach((item) => item.setAttribute("aria-selected", "false"));
    tab.setAttribute("aria-selected", "true");
    galleryImage.classList.add("is-changing");

    window.setTimeout(() => {
      galleryImage.src = tab.dataset.image;
      galleryImage.alt = tab.dataset.alt;
      galleryTitle.textContent = tab.dataset.title;
      galleryCaption.textContent = tab.dataset.caption;
      galleryImage.classList.remove("is-changing");
    }, 110);
  });

  tab.addEventListener("keydown", (event) => {
    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return;

    event.preventDefault();
    const currentIndex = galleryTabs.indexOf(tab);
    const direction = event.key === "ArrowRight" ? 1 : -1;
    const nextIndex = (currentIndex + direction + galleryTabs.length) % galleryTabs.length;
    galleryTabs[nextIndex].focus();
    galleryTabs[nextIndex].click();
  });
});
