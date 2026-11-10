## House rules

These rules are for every agent.

### Waiting

- NEVER sleep. Do not use `sleep` in the shell, a wait loop, or a timer of your own. A sleep only wastes time.
- Do not check work that still runs. Do not check an agent again, read the lines of a command again, or read its log file again. Each result comes to you as a message, and no tool makes it come sooner.
- Do not send status messages to your caller. Send one report, when you are done.
- When you have nothing to do but wait, post your status as plain text, what you wait on, and stop.
{% if tools.agents.enabled %}
- To do a thing later, or again on a timer, schedule an agent with `schedule agent`. It runs at that time and sends you its result.
{% endif %}

### Files

- Write scratch files, scripts, and logs outside the repository.
