import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.resize = () => this.drawConnections()
    window.addEventListener("resize", this.resize)
    this.drawConnections()
  }

  disconnect() {
    window.removeEventListener("resize", this.resize)
  }

  selectTab(event) {
    this.activate(event.currentTarget)
  }

  tabKeydown(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    let next = index
    if (event.key === "ArrowRight") next = (index + 1) % this.tabTargets.length
    else if (event.key === "ArrowLeft") next = (index - 1 + this.tabTargets.length) % this.tabTargets.length
    else if (event.key === "Home") next = 0
    else if (event.key === "End") next = this.tabTargets.length - 1
    else return

    event.preventDefault()
    this.activate(this.tabTargets[next])
    this.tabTargets[next].focus()
  }

  activate(tab) {
    this.tabTargets.forEach((item) => {
      const selected = item === tab
      item.setAttribute("aria-selected", selected)
      item.tabIndex = selected ? 0 : -1
      item.classList.toggle("is-active", selected)
    })
    this.panelTargets.forEach((panel) => { panel.hidden = panel.dataset.panel !== tab.dataset.panel })
    requestAnimationFrame(() => {
      this.syncRound()
      this.drawConnections()
    })
  }

  goToRound(event) {
    this.scrollToRound(Number(event.currentTarget.dataset.roundIndex))
  }

  previousRound() {
    this.scrollToRound(this.currentRoundIndex() - 1)
  }

  nextRound() {
    this.scrollToRound(this.currentRoundIndex() + 1)
  }

  scrollToRound(index) {
    const panel = this.activePanel()
    const rounds = [...panel.querySelectorAll(".interactive-bracket__round")]
    const round = rounds[Math.max(0, Math.min(index, rounds.length - 1))]
    if (!round) return

    const viewport = panel.querySelector(".interactive-bracket__viewport")
    viewport.scrollTo({ left: round.offsetLeft - rounds[0].offsetLeft, behavior: "smooth" })
  }

  syncRound() {
    const panel = this.activePanel()
    if (!panel) return

    const current = this.currentRoundIndex()
    panel.querySelectorAll(".interactive-bracket__round-button").forEach((button, index) => {
      button.classList.toggle("is-active", index === current)
      button.setAttribute("aria-current", index === current ? "step" : "false")
    })
  }

  currentRoundIndex() {
    const panel = this.activePanel()
    if (!panel) return 0

    const viewport = panel.querySelector(".interactive-bracket__viewport")
    const rounds = [...panel.querySelectorAll(".interactive-bracket__round")]
    if (!rounds.length) return 0

    const visibleLeft = viewport.scrollLeft + viewport.clientWidth / 3
    return rounds.reduce((index, round, next) =>
      round.offsetLeft - rounds[0].offsetLeft <= visibleLeft ? next : index, 0)
  }

  activePanel() {
    return this.panelTargets.find((panel) => !panel.hidden)
  }

  drawConnections() {
    const panel = this.activePanel()
    const track = panel?.querySelector('.interactive-bracket__track[data-connect="true"]')
    if (!track) return

    track.querySelector(".interactive-bracket__connections")?.remove()
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg")
    svg.classList.add("interactive-bracket__connections")
    svg.setAttribute("width", track.scrollWidth)
    svg.setAttribute("height", track.offsetHeight)
    svg.setAttribute("aria-hidden", "true")
    const origin = track.getBoundingClientRect()
    const rounds = [...track.querySelectorAll(".interactive-bracket__round")]

    rounds.slice(0, -1).forEach((round, index) => {
      const from = [...round.querySelectorAll(".interactive-bracket__match")]
      const to = [...rounds[index + 1].querySelectorAll(".interactive-bracket__match")]
      if (from.length !== to.length && from.length !== to.length * 2) return

      from.forEach((match, matchIndex) => {
        const next = to[from.length === to.length ? matchIndex : Math.floor(matchIndex / 2)]
        const source = match.getBoundingClientRect()
        const destination = next.getBoundingClientRect()
        const x1 = source.right - origin.left
        const y1 = source.top + source.height / 2 - origin.top
        const x2 = destination.left - origin.left
        const y2 = destination.top + destination.height / 2 - origin.top
        const middle = (x1 + x2) / 2
        const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
        path.setAttribute("d", `M ${x1} ${y1} H ${middle} V ${y2} H ${x2}`)
        svg.append(path)
      })
    })
    track.prepend(svg)
  }
}
