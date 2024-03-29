// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import {render, cancel} from "../vendor/timeago.js"

let Hooks = {}

Hooks.TimeAgo = {
  mounted() {
    render(this.el, 'en_short')
  },
  updated() {
    render(this.el, 'en_short')
  },
  destroyed() {
    cancel(this.el)
  }
}

// https://elixirforum.com/t/how-can-i-implement-an-infinite-scroll-in-liveview/30457
// https://developer.mozilla.org/en-US/docs/Web/API/IntersectionObserver
Hooks.InfiniteScroll = {
  cursor() {
    return this.el.dataset.cursor;
  },
  maybeLoadMore(entries) {
    const target = entries[0];
    if (target.isIntersecting && this.cursor() && !this.loadMore) {
      this.loadMore = true;
      this.pushEvent("load-more", {});
    }
  },
  mounted() {
    this.loadMore = false;
    this.handleEvent("load-more", () => {
      this.loadMore = false;
    })

    const options = {
      root: null,
      rootMargin: "-90% 0px 10% 0px",
      threshold: 1.0
    };
    this.observer = new IntersectionObserver(this.maybeLoadMore.bind(this), options);
    this.observer.observe(this.el);
  },
  reconnected() {
    this.loadMore = false;
  },
  beforeDestroy() {
    this.observer.unobserve(this.el);
  },
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// tailwind ui mobile nav
const $toggleMenu = document.getElementById("toggle-menu")
const $burger = document.getElementById("burger")
const $xMark = document.getElementById("x-mark")
const $mobileMenu = document.getElementById("mobile-menu")

$toggleMenu.addEventListener("click", event => {
  event.preventDefault();
  ["hidden", "block"].forEach(className => {
    $burger.classList.toggle(className)
    $xMark.classList.toggle(className)
  })
  $mobileMenu.classList.toggle("hidden")
})

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

