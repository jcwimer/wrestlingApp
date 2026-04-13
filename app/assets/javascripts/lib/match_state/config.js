/*
State page config contract
==========================

The state page responds to these top-level config objects:

1. `wrestler_actions`
   Drives the wrestler-side UI from top to bottom inside each wrestler panel.
   The controller renders these sections in order, so the order in this object
   controls the visual order underneath each wrestler's name, school, and score.
   Supported sections:
   - `match_actions`
   - `timers`
   - `extra_actions`

   Each section may define:
   - `title`
   - `description`
   - `items`

   How the state page uses it:
   - `match_actions.items`
     Each item is either:
     - a literal action key, or
     - a special alias such as `global` or `position`
     The state page expands those aliases into the currently legal actions for
     that wrestler and renders them as buttons.
   - `timers.items`
     Each item is a timer key. The state page renders the timer display plus
     start/stop/reset buttons for each listed timer.
   - `extra_actions.items`
     Each item is a literal action key rendered as an always-visible button
     underneath the timer section.

2. `actionsByKey`
   Canonical definitions for match actions and history actions.
   This is the source of truth for how a button behaves and how an action
   should appear in the event log.
   Each action may define:
   - `label`
   - `availability`
   - `statCode`
   - `effect`
   - `progression`

   How the state page uses it:
   - `label`
     Used for button text and event log text.
   - `availability`
     Used when `wrestler_actions.match_actions.items` includes aliases like
     `global` or `position`.
   - `effect`
     Used by the rules engine to update score and match position when replaying
     the event list.
   - `statCode`
     Used when rewriting the hidden `w1_stat` / `w2_stat` fields from the
     structured event log for websocket sync and match submission.
   - `progression`
     Used for progressive actions like stalling, caution, and penalty to decide
     if the opponent should automatically receive a linked point-scoring event.

   Supported `availability` values used by the wrestler-side UI:
   - `global`
   - `neutral`
   - `top`
   - `bottom`
   - `extra`

3. `timers`
   Canonical timer definitions keyed by timer name.
   This controls both the timer controls in the wrestler panel and how timer
   usage is labeled in the event log.

   How the state page uses it:
   - `label`
     Displayed next to the running timer value in the wrestler panel.
   - `maxSeconds`
     Used to initialize, reset, clamp, and render the timer.
   - `historyLabel`
     Used when a timer stop event is recorded in history.
   - `statCode`
     Used when rewriting the hidden `w1_stat` / `w2_stat` fields for timer-used
     events.

4. `phases`
   Defines the period / choice sequence for this wrestling style.
   The active phase drives:
   - the main match clock
   - phase labels
   - start-of-period position behavior
   - choice button behavior
   - event grouping in the history list

   How the state page uses it:
   - chooses which phase sequence to use from bracket position
   - builds the main match clock state for timed phases
   - determines whether the current phase is a period or a choice phase
   - determines how a period starts (`neutral` or from a prior choice)
*/

const RULESETS = {
  folkstyle_usa: {
    id: "folkstyle_usa",

    wrestler_actions: {
      match_actions: {
        title: "Match Actions",
        description: "Scoring and match-state actions available based on current position.",
        items: ["global", "position"]
      },
      timers: {
        title: "Wrestler Timers",
        description: "Track blood, injury, recovery, and head/neck time for this wrestler.",
        items: ["blood", "injury", "recovery", "head_neck"]
      },
      extra_actions: {
        title: "Extra Actions",
        description: "Force the match into a specific position and record it in history.",
        items: ["position_neutral", "position_top", "position_bottom"]
      }
    },

    actionsByKey: {
      stalling: {
        label: "Stalling",
        availability: "global",
        statCode: "S",
        effect: { points: 0 },
        progression: [0, 1, 1, 2]
      },
      caution: {
        label: "Caution",
        availability: "global",
        statCode: "C",
        effect: { points: 0 },
        progression: [0, 0, 1]
      },
      penalty: {
        label: "Penalty",
        availability: "global",
        statCode: "P",
        effect: { points: 0 },
        progression: [1, 1, 2]
      },
      minus_1: {
        label: "-1 Point",
        availability: "global",
        statCode: "-1",
        effect: { points: -1 }
      },
      plus_1: {
        label: "+1 Point",
        availability: "global",
        statCode: "+1",
        effect: { points: 1 }
      },
      plus_2: {
        label: "+2 Points",
        statCode: "+2",
        effect: { points: 2 }
      },
      takedown_3: {
        label: "Takedown +3",
        availability: "neutral",
        statCode: "T3",
        effect: { points: 3, nextPosition: "top" }
      },
      nearfall_2: {
        label: "Nearfall +2",
        availability: "top",
        statCode: "N2",
        effect: { points: 2 }
      },
      nearfall_3: {
        label: "Nearfall +3",
        availability: "top",
        statCode: "N3",
        effect: { points: 3 }
      },
      nearfall_4: {
        label: "Nearfall +4",
        availability: "top",
        statCode: "N4",
        effect: { points: 4 }
      },
      nearfall_5: {
        label: "Nearfall +5",
        availability: "top",
        statCode: "N5",
        effect: { points: 5 }
      },
      escape_1: {
        label: "Escape +1",
        availability: "bottom",
        statCode: "E1",
        effect: { points: 1, nextPosition: "neutral" }
      },
      reversal_2: {
        label: "Reversal +2",
        availability: "bottom",
        statCode: "R2",
        effect: { points: 2, nextPosition: "top" }
      },
      position_neutral: {
        label: "Neutral",
        availability: "extra",
        statCode: "|Neutral|",
        effect: { points: 0, nextPosition: "neutral" }
      },
      position_top: {
        label: "Top",
        availability: "extra",
        statCode: "|Top|",
        effect: { points: 0, nextPosition: "top" }
      },
      position_bottom: {
        label: "Bottom",
        availability: "extra",
        statCode: "|Bottom|",
        effect: { points: 0, nextPosition: "bottom" }
      },
      choice_top: {
        label: "Choice: Top",
        statCode: "|Chose Top|"
      },
      choice_bottom: {
        label: "Choice: Bottom",
        statCode: "|Chose Bottom|"
      },
      choice_neutral: {
        label: "Choice: Neutral",
        statCode: "|Chose Neutral|"
      },
      choice_defer: {
        label: "Choice: Defer",
        statCode: "|Deferred|"
      }
    },

    timers: {
      blood: { maxSeconds: 300, label: "Blood", historyLabel: "Blood Time Used", statCode: "Blood Time" },
      injury: { maxSeconds: 90, label: "Injury", historyLabel: "Injury Time Used", statCode: "Injury Time" },
      recovery: { maxSeconds: 120, label: "Recovery", historyLabel: "Recovery Time Used", statCode: "Recovery Time" },
      head_neck: { maxSeconds: 300, label: "Head/Neck", historyLabel: "Head/Neck Time Used", statCode: "Head/Neck Time" }
    },

    phases: {
      championship: {
        label: "Championship Format",
        sequence: [
          { key: "period_1", label: "Period 1", type: "period", startsIn: "neutral", clockSeconds: 120 },
          { key: "choice_1", label: "Choice 1", type: "choice", chooser: "either", options: ["top", "bottom", "neutral", "defer"] },
          { key: "period_2", label: "Period 2", type: "period", startsFromChoice: "choice_1", clockSeconds: 120 },
          { key: "choice_2", label: "Choice 2", type: "choice", chooser: "other", options: ["top", "bottom", "neutral"] },
          { key: "period_3", label: "Period 3", type: "period", startsFromChoice: "choice_2", clockSeconds: 120 },
          { key: "sv_1", label: "SV-1", type: "period", startsIn: "neutral", clockSeconds: 60, overtimeType: "SV-1" },
          { key: "choice_3", label: "Choice 3", type: "choice", chooser: "either", options: ["top", "bottom", "defer"] },
          { key: "tb_1a", label: "TB-1A", type: "period", startsFromChoice: "choice_3", clockSeconds: 30, overtimeType: "TB-1" },
          { key: "choice_4", label: "Choice 4", type: "choice", chooser: "other", options: ["top", "bottom"] },
          { key: "tb_1b", label: "TB-1B", type: "period", startsFromChoice: "choice_4", clockSeconds: 30, overtimeType: "TB-1" },
          { key: "choice_5", label: "Choice 5", type: "choice", chooser: "either", options: ["top", "bottom"] },
          { key: "utb", label: "UTB", type: "period", startsFromChoice: "choice_5", clockSeconds: 30, overtimeType: "UTB" }
        ]
      },
      consolation: {
        label: "Consolation Format",
        sequence: [
          { key: "period_1", label: "Period 1", type: "period", startsIn: "neutral", clockSeconds: 60 },
          { key: "choice_1", label: "Choice 1", type: "choice", chooser: "either", options: ["top", "bottom", "neutral", "defer"] },
          { key: "period_2", label: "Period 2", type: "period", startsFromChoice: "choice_1", clockSeconds: 120 },
          { key: "choice_2", label: "Choice 2", type: "choice", chooser: "other", options: ["top", "bottom", "neutral"] },
          { key: "period_3", label: "Period 3", type: "period", startsFromChoice: "choice_2", clockSeconds: 120 },
          { key: "sv_1", label: "SV-1", type: "period", startsIn: "neutral", clockSeconds: 60, overtimeType: "SV-1" },
          { key: "choice_3", label: "Choice 3", type: "choice", chooser: "either", options: ["top", "bottom", "defer"] },
          { key: "tb_1a", label: "TB-1A", type: "period", startsFromChoice: "choice_3", clockSeconds: 30, overtimeType: "TB-1" },
          { key: "choice_4", label: "Choice 4", type: "choice", chooser: "other", options: ["top", "bottom"] },
          { key: "tb_1b", label: "TB-1B", type: "period", startsFromChoice: "choice_4", clockSeconds: 30, overtimeType: "TB-1" },
          { key: "choice_5", label: "Choice 5", type: "choice", chooser: "either", options: ["top", "bottom"] },
          { key: "utb", label: "UTB", type: "period", startsFromChoice: "choice_5", clockSeconds: 30, overtimeType: "UTB" }
        ]
      }
    }
  }
}

function phaseStyleKeyForBracketPosition(bracketPosition) {
  if (!bracketPosition) return "championship"

  if (
    bracketPosition.includes("Conso") ||
    ["3/4", "5/6", "7/8"].includes(bracketPosition)
  ) {
    return "consolation"
  }

  return "championship"
}

function buildActionEffects(actionsByKey) {
  return Object.fromEntries(
    Object.entries(actionsByKey)
      .filter(([, action]) => action.effect)
      .map(([key, action]) => [key, action.effect])
  )
}

function buildActionLabels(actionsByKey, timers) {
  const actionLabels = Object.fromEntries(
    Object.entries(actionsByKey)
      .filter(([, action]) => action.label)
      .map(([key, action]) => [key, action.label])
  )

  Object.entries(timers || {}).forEach(([timerKey, timer]) => {
    if (timer.historyLabel) {
      actionLabels[`timer_used_${timerKey}`] = timer.historyLabel
    }
  })

  return actionLabels
}

function buildProgressionRules(actionsByKey) {
  return Object.fromEntries(
    Object.entries(actionsByKey)
      .filter(([, action]) => Array.isArray(action.progression))
      .map(([key, action]) => [key, action.progression])
  )
}

export function getMatchStateConfig(rulesetId, bracketPosition) {
  const ruleset = RULESETS[rulesetId] || RULESETS.folkstyle_usa
  const phaseStyleKey = phaseStyleKeyForBracketPosition(bracketPosition)
  const phaseStyle = ruleset.phases[phaseStyleKey]

  return {
    ...ruleset,
    actionEffects: buildActionEffects(ruleset.actionsByKey),
    actionLabels: buildActionLabels(ruleset.actionsByKey, ruleset.timers),
    progressionRules: buildProgressionRules(ruleset.actionsByKey),
    matchFormat: { id: phaseStyleKey, label: phaseStyle.label },
    phaseSequence: phaseStyle.sequence
  }
}
