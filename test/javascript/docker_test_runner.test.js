import fs from "node:fs"
import os from "node:os"
import path from "node:path"
import { spawnSync } from "node:child_process"
import { fileURLToPath } from "node:url"
import { afterEach, describe, expect, it } from "vitest"

const runner = fileURLToPath(new URL("../../bin/run-tests-with-docker.sh", import.meta.url))
const directories = []

afterEach(() => {
  for (const directory of directories.splice(0)) fs.rmSync(directory, { recursive: true, force: true })
})

function run(failure = "", cleanupFailure = false) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "docker-test-runner-"))
  directories.push(directory)
  const log = path.join(directory, "commands.jsonl")
  fs.writeFileSync(path.join(directory, "docker"), `#!/usr/bin/env node
const fs = require("node:fs")
const args = process.argv.slice(2)
fs.appendFileSync(process.env.DOCKER_TEST_LOG, JSON.stringify(args) + "\\n")
if (args[0] === process.env.DOCKER_TEST_FAILURE) process.exit(47)
if (args[0] === "rm" && process.env.DOCKER_TEST_CLEANUP_FAILURE === "true") process.exit(31)
if (args[0] === "create") console.log("review-container")
`, { mode: 0o755 })
  const result = spawnSync("bash", [runner], {
    encoding: "utf8",
    env: {
      ...process.env,
      PATH: `${directory}${path.delimiter}${process.env.PATH}`,
      DOCKER_TEST_LOG: log,
      DOCKER_TEST_FAILURE: failure,
      DOCKER_TEST_CLEANUP_FAILURE: String(cleanupFailure)
    }
  })
  const commands = fs.existsSync(log) ? fs.readFileSync(log, "utf8").trim().split("\n").map(JSON.parse) : []
  return { ...result, commands }
}

describe.skipIf(process.platform === "win32")("Docker test runner", () => {
  it("copies the checkout before starting tests without a daemon-host bind mount", () => {
    const { status, commands } = run()
    expect(status).toBe(0)
    expect(commands.map(args => args[0])).toEqual(["build", "create", "cp", "start", "rm"])
    expect(commands[1]).toEqual([
      "create", "--user", "0:0", "--workdir", "/rails",
      "-e", "HOME=/tmp", "-e", "BUNDLE_WITHOUT=production",
      "wrestlingdevtests", "bash", "/rails/bin/run-all-tests.sh"
    ])
    expect(commands[2][1]).toBe(`${path.dirname(path.dirname(runner))}/.`)
    expect(commands[2][2]).toBe("review-container:/rails")
    expect(commands[3]).toEqual(["start", "--attach", "review-container"])
    expect(commands[4]).toEqual(["rm", "--force", "--volumes", "review-container"])
  })

  it.each([
    ["build", ["build"]],
    ["create", ["build", "create"]],
    ["cp", ["build", "create", "cp", "rm"]],
    ["start", ["build", "create", "cp", "start", "rm"]]
  ])("propagates %s failures and cleans up any created container", (failure, expected) => {
    const { status, commands } = run(failure)
    expect(status).toBe(47)
    expect(commands.map(args => args[0])).toEqual(expected)
  })

  it("preserves the test failure when cleanup also fails", () => {
    const { status, stderr, commands } = run("start", true)
    expect(status).toBe(47)
    expect(commands.at(-1)).toEqual(["rm", "--force", "--volumes", "review-container"])
    expect(stderr).toContain("Could not remove test container review-container")
  })
})
