import { describe, expect, it } from "vitest"
import { getMatchStateConfig } from "match-state-config"
import { buildInitialState } from "match-state-engine"
import {
  buttonClassForParticipant,
  choiceViewModel,
  displayLabelForParticipant,
  eventLogSections,
  humanizeChoice
} from "match-state-presenters"

describe("match state presenters", () => {
  it("maps assignment to display labels and button classes", () => {
    const assignment = { w1: "green", w2: "red" }

    expect(displayLabelForParticipant(assignment, "w1")).toBe("Green")
    expect(displayLabelForParticipant(assignment, "w2")).toBe("Red")
    expect(buttonClassForParticipant(assignment, "w1")).toBe("btn-success")
    expect(buttonClassForParticipant(assignment, "w2")).toBe("btn-danger")
    expect(humanizeChoice("defer")).toBe("Defer")
  })

  it("builds choice view model with defer blocking another defer", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    const phase = config.phaseSequence[1]
    state.events = [{
      id: 1,
      phaseKey: phase.key,
      phaseLabel: phase.label,
      clockSeconds: 0,
      participantKey: "w1",
      actionKey: "choice_defer"
    }]

    const viewModel = choiceViewModel(config, state, phase, {
      w1: { name: "Wrestler 1" },
      w2: { name: "Wrestler 2" }
    })

    expect(viewModel.label).toBe("Choose wrestler and position")
    expect(viewModel.selectionText).toContain("Green deferred")
    expect(viewModel.buttons.map((button) => [button.participantKey, button.choiceKey])).toEqual([
      ["w2", "top"],
      ["w2", "bottom"],
      ["w2", "neutral"]
    ])
  })

  it("builds event log sections with formatted action labels", () => {
    const config = getMatchStateConfig("folkstyle_usa", "Bracket Round of 64")
    const state = buildInitialState(config)
    state.events = [
      {
        id: 1,
        phaseKey: "period_1",
        phaseLabel: "Period 1",
        clockSeconds: 100,
        participantKey: "w1",
        actionKey: "takedown_3"
      },
      {
        id: 2,
        phaseKey: "period_1",
        phaseLabel: "Period 1",
        clockSeconds: 80,
        participantKey: "w2",
        actionKey: "timer_used_blood",
        elapsedSeconds: 15
      }
    ]

    const sections = eventLogSections(config, state, (seconds) => `F-${seconds}`)

    expect(sections).toHaveLength(1)
    expect(sections[0].label).toBe("Period 1")
    expect(sections[0].items).toEqual([
      {
        id: 2,
        participantKey: "w2",
        colorLabel: "Red",
        actionLabel: "Blood Time Used: F-15",
        clockLabel: "F-80"
      },
      {
        id: 1,
        participantKey: "w1",
        colorLabel: "Green",
        actionLabel: "Takedown +3",
        clockLabel: "F-100"
      }
    ])
  })
})
