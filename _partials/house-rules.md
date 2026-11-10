## House rules

These rules are for every agent.

### Waiting

- NEVER sleep. Do not use `sleep` in the shell, a wait loop, or a timer of your own. A sleep only wastes time.
- Do not check work that still runs. Do not check an agent again, read the lines of a command again, or read its log file again. Each result comes to you as a message, and no tool makes it come sooner.
- Each message that you send to your caller wakes it. Send a message only for a critical error that you cannot recover from. Send nothing else: no progress, no "still running", no "I continue with the tests", no findings. Your final report comes to your caller when you are done.
- When you have nothing to do but wait, post your status as plain text, what you wait on, and stop.
{% if tools.agents.enabled %}
- To do a thing later, or again on a timer, schedule an agent with `schedule agent`. It runs at that time and sends you its result.
{% endif %}

### Files

- Write scratch files, scripts, and logs outside the repository.
