(function () {
  const prefersReducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function typeText(element, text, onComplete) {
    if (!element) return;
    element.classList.remove("is-placeholder", "is-typing");
    element.textContent = "";
    if (prefersReducedMotion) {
      element.textContent = text;
      onComplete?.();
      return;
    }

    element.classList.add("is-typing");
    let index = 0;
    const tick = () => {
      if (index <= text.length) {
        element.textContent = text.slice(0, index);
        index += 1;
        setTimeout(tick, index === 1 ? 500 : 58);
      } else {
        element.classList.remove("is-typing");
        onComplete?.();
      }
    };
    tick();
  }

  function el(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text != null) node.textContent = text;
    return node;
  }

  function createEggsCard() {
    const card = el("div", "demo-item-card");
    card.dataset.demoNewItem = "";

    const check = el("button", "demo-check");
    check.type = "button";
    check.setAttribute("aria-label", "Mark complete");
    const ring = el("span", "demo-check__ring");
    check.appendChild(ring);

    const thumb = document.createElement("img");
    thumb.className = "demo-thumb";
    thumb.src = "/marketing/demo/product-eggs-brown.png";
    thumb.alt = "";
    thumb.width = 38;
    thumb.height = 38;

    const main = el("div", "demo-item-main");
    main.appendChild(el("div", "demo-item-name", "Eggs"));
    main.appendChild(el("div", "demo-item-meta", "Dairy · Walmart"));

    const stepper = el("div", "demo-stepper");
    stepper.appendChild(el("span", "demo-stepper__btn", "−"));
    stepper.appendChild(el("span", "demo-stepper__val", "2"));
    stepper.appendChild(el("span", "demo-stepper__btn", "+"));

    const edit = el("button", "demo-edit", "✎");
    edit.type = "button";
    edit.setAttribute("aria-label", "Edit item");

    const actions = el("div", "demo-item-actions");
    actions.append(stepper, edit);

    card.append(check, thumb, main, actions);
    return card;
  }

  function bindCheckboxes(root) {
    root.querySelectorAll(".demo-check").forEach((btn) => {
      if (btn.dataset.bound) return;
      btn.dataset.bound = "true";
      btn.addEventListener("click", () => {
        const card = btn.closest(".demo-item-card");
        const done = card.classList.toggle("demo-item-card--done");
        const ring = btn.querySelector(".demo-check__ring");
        if (ring) ring.textContent = done ? "✓" : "";
      });
    });
  }

  function initAddDemo(root) {
    const input = root.querySelector("[data-demo-input]");
    const helper = root.querySelector("[data-demo-helper]");
    const submit = root.querySelector("[data-demo-submit]");
    const detection = root.querySelector("[data-demo-detection]");
    const stack = root.querySelector("[data-demo-stack]");
    const phrase = "2 eggs from Walmart";

    const reset = () => {
      submit?.classList.remove("is-visible");
      helper?.classList.remove("is-visible", "is-hidden");
      detection?.classList.remove("is-visible");
      stack?.querySelector("[data-demo-new-item]")?.remove();
      if (input) {
        input.textContent = "Add item…";
        input.classList.add("is-placeholder");
      }
    };

    const run = () => {
      reset();
      setTimeout(() => {
        if (input) {
          input.classList.remove("is-placeholder");
          input.textContent = "";
        }
        helper?.classList.add("is-visible");
        typeText(input, phrase, () => {
          submit?.classList.add("is-visible");
          helper?.classList.add("is-hidden");
          detection?.classList.add("is-visible");
          setTimeout(() => {
            stack?.prepend(createEggsCard());
            bindCheckboxes(root);
            setTimeout(run, 5200);
          }, 650);
        });
      }, 600);
    };

    run();
  }

  function initViewsDemo(root) {
    const panels = root.querySelectorAll("[data-demo-screen]");
    const tabs = root.querySelectorAll("[data-demo-tab]");
    const tabBar = root.querySelector("[data-demo-tabs]");

    const show = (id) => {
      panels.forEach((panel) => {
        panel.classList.toggle("is-active", panel.dataset.demoScreen === id);
      });
      tabs.forEach((tab) => {
        const tabId = tab.dataset.demoTab;
        const isActive =
          (id === "list" && tabId === "list") ||
          (id === "store" && tabId === "store") ||
          (id === "categories" && tabId === "categories");
        tab.classList.toggle("demo-tab--active", isActive);
      });
      if (tabBar) {
        tabBar.classList.toggle("demo-tabs--hidden", id === "list");
      }
    };

    tabs.forEach((tab) => {
      tab.addEventListener("click", () => show(tab.dataset.demoTab));
    });

    if (!prefersReducedMotion) {
      const order = ["list", "store", "categories"];
      let index = 0;
      setInterval(() => {
        index = (index + 1) % order.length;
        show(order[index]);
      }, 3800);
    }

    bindCheckboxes(root);
  }

  function initShareDemo(root) {
    const panels = root.querySelectorAll("[data-demo-share-screen]");
    const order = ["share", "import"];
    let index = 0;

    const show = (id) => {
      panels.forEach((panel) => {
        panel.classList.toggle("is-active", panel.dataset.demoShareScreen === id);
      });
    };

    if (!prefersReducedMotion) {
      setInterval(() => {
        index = (index + 1) % order.length;
        show(order[index]);
      }, 4500);
    }
  }

  document.querySelectorAll("[data-demo]").forEach((root) => {
    bindCheckboxes(root);
    const kind = root.dataset.demo;
    if (kind === "add") initAddDemo(root);
    if (kind === "views") initViewsDemo(root);
    if (kind === "share") initShareDemo(root);
  });
})();
