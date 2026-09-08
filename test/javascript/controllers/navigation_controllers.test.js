import { beforeEach, describe, expect, it, vi } from "vitest"
import NavbarCollapseController from "../../../app/assets/javascripts/controllers/navbar_collapse_controller.js"
import DropdownController from "../../../app/assets/javascripts/controllers/dropdown_controller.js"
import DismissController from "../../../app/assets/javascripts/controllers/dismiss_controller.js"
import CollapseController from "../../../app/assets/javascripts/controllers/collapse_controller.js"

function makeClassList(initial = []) {
  const classes = new Set(initial)
  return {
    add: vi.fn((value) => classes.add(value)),
    remove: vi.fn((value) => classes.delete(value)),
    toggle: vi.fn((value) => {
      if (classes.has(value)) {
        classes.delete(value)
        return false
      }
      classes.add(value)
      return true
    }),
    contains: vi.fn((value) => classes.has(value))
  }
}

describe("navbar collapse controller", () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it("shows the panel on desktop connect", () => {
    const controller = new NavbarCollapseController()
    controller.panelTarget = { classList: makeClassList() }
    controller.toggleTarget = { setAttribute: vi.fn() }
    controller.mediaQuery = { matches: true, addEventListener: vi.fn(), removeEventListener: vi.fn() }

    controller.handleMediaChange()

    expect(controller.panelTarget.classList.add).toHaveBeenCalledWith("wd-collapse--open")
    expect(controller.toggleTarget.setAttribute).toHaveBeenCalledWith("aria-expanded", "true")
  })

  it("toggles the panel on mobile", () => {
    const controller = new NavbarCollapseController()
    controller.panelTarget = { classList: makeClassList() }
    controller.toggleTarget = { setAttribute: vi.fn() }
    controller.mediaQuery = { matches: false, addEventListener: vi.fn(), removeEventListener: vi.fn() }

    controller.toggle()

    expect(controller.panelTarget.classList.toggle).toHaveBeenCalledWith("wd-collapse--open")
    expect(controller.toggleTarget.setAttribute).toHaveBeenCalledWith("aria-expanded", true)
  })
})

describe("dropdown controller", () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    global.document = {
      addEventListener: vi.fn(),
      removeEventListener: vi.fn()
    }
  })

  it("opens and closes the menu", () => {
    const controller = new DropdownController()
    controller.element = { classList: makeClassList(), contains: vi.fn(() => false) }
    controller.toggleTarget = { setAttribute: vi.fn(), focus: vi.fn() }

    controller.open()
    expect(controller.element.classList.add).toHaveBeenCalledWith("wd-dropdown--open")

    controller.close()
    expect(controller.element.classList.remove).toHaveBeenCalledWith("wd-dropdown--open")
  })
})

describe("dismiss controller", () => {
  it("removes the alert element", () => {
    const controller = new DismissController()
    controller.element = { remove: vi.fn() }

    controller.dismiss({ preventDefault: vi.fn() })

    expect(controller.element.remove).toHaveBeenCalled()
  })
})

describe("collapse controller", () => {
  it("toggles panel visibility", () => {
    const controller = new CollapseController()
    controller.panelTarget = { classList: makeClassList() }
    controller.toggleTarget = { setAttribute: vi.fn() }

    controller.toggle({ preventDefault: vi.fn() })

    expect(controller.panelTarget.classList.toggle).toHaveBeenCalledWith("wd-collapse--open")
    expect(controller.toggleTarget.setAttribute).toHaveBeenCalledWith("aria-expanded", true)
  })
})
