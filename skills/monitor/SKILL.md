---
name: monitor
description: Use to monitor, watch, poll, or check back on anything that changes over time, to wait until something happens, or to remind the user. Tells how to do it with a scheduled agent.
license: MIT OR Apache-2.0
---

# Monitor

A scheduled agent is how you monitor. There is no other monitor tool.

## When to use

Use a scheduled agent to watch anything that changes over time: a long command or test run, CI, a file or a folder, the status of another session, a deploy, or a pull request.

"Monitor", "watch", "poll", "check back", "wait until", and "remind me" all mean a scheduled agent.

## Do not wait yourself

- Do not wait by a loop, by a sleep, or by `check agent` or `getLines` again and again in your own session.
- Schedule an agent, and go on with other work. The result of each firing comes back to you as mail.

## Schedule an agent

Call `schedule agent` on the `agents` tool:

- `schedule`: when to fire. A cron line, an ISO date and time, "every 10 minutes", or plain English. The answer shows the normalized schedule, the time zone, and the next 3 firings. Read them. Ambiguous text is refused.
- `prompt`: the task of each firing.
- `agent`: the agent that runs each firing. The default is `default`. Give `tester` to rerun the tests, for example.
- `count` or `until`: when the schedule ends. Give one when you know the end. With neither, it ends after 7 days.
- `title`: a short title, so you can find the schedule later.
- `timeZone`: the time zone of `schedule`. The answer shows UTC as "GMT".

## Write the prompt

Each firing is a new agent run, and its result comes back to you. So put the check and the condition in the prompt:

- The check to do, for example "Read the CI status of PR 42."
- What to report: "Report DONE and the result when the run is finished. Else report the current state in one line."

## Choose the interval

- Fit the interval to how fast the thing changes. For a CI run of 8 minutes, fire every 2 to 3 minutes. For a nightly job, fire daily.
- The shortest interval is 1 minute.
- A firing that is due while the previous one runs is skipped. Missed firings run one time.

## Manage the schedules

- CANCEL the schedule with `cancel schedule` as soon as the condition you waited for is met.
- `list schedules` shows what you have running, with the `id` of each. The other ops take that `id`. `get schedule` shows one.
- `pause schedule` holds a schedule, and `resume schedule` lets it fire again. `start schedule` fires one now.
- A schedule belongs to your session and survives a restart.
