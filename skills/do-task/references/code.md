
## Steps

### Learn the task

Read the task from the caller. 
A cause or a fix in the task, from the caller or from a diagnosis, is a hypothesis. Check it against the code before you use it.

{% if tools.kanban.enabled %}
Create one kanban task for this work. If the scope is a kanban task, use that task, and do not create another.
{% endif %}

### Develop a hypothesis

Provide what you have learned to ONE `planner` subagent, charged with developing a hypothesis and a plan to complete the task.

{% if tools.kanban.enabled %}
Order the planner to put its hypothesis and plan on the task with a comment, using the `addComment` call from the kanban skill.
{% endif %}

### Check the plan

Give the task and the plan, as they are, to ONE `double-check` subagent. Tell it that it checks a plan, before the code changes. It must check the plan against the task, and against the existing tests of each function that the plan changes.

{% if tools.kanban.enabled %}
Order the checker to put its verdict on the task with a comment, using the `addComment` call from the kanban skill.
{% endif %}

- `VERDICT: PASS`: go to the next step with the plan.
- `VERDICT: REVISE`: give the task, the plan, and the findings, as they are, to a new `planner` subagent. It gives a new plan that answers each finding. Check the new plan with `double-check` again.

Do not check the plan yourself. Do not change the plan or the findings yourself.

### Test the hypothesis

Work the checked plan.

#### Implement

Give the checked plan to ONE `coder` subagent to implement, with its test.

{% if tools.kanban.enabled %}
Comment on the task with your progress.
{% endif %}

#### Test

This is when you verify that you didn't break anything by running all the tests looking for reression.

If there are test failures, repair them with a `coder` subagent. Repeat until all tests are passing.

Once you are satisified a hypothesis is solving the task, proceed to double check.

{% if tools.kanban.enabled %}
Comment on the task with your progress.
{% endif %}

#### Review

Give the task, the checked plan, and the change, as they are, to ONE `double-check` subagent. Tell it that it checks a change, after the code changes. It must answer:

- Did the change complete the assigned task?
- Is it a good job: correct, and only the change asked for?
- Is it proven with unit tests: a test that fails before the change and passes after it?

{% if tools.kanban.enabled %}
Order the checker to put its verdict on the task with a comment, using the `addComment` call from the kanban skill.
{% endif %}

- `VERDICT: REVISE`: give the findings, as they are, to a `coder` subagent to fix, then check the change with `double-check` again. If the findings show that the plan is wrong, go back to "Develop a hypothesis" with what you learned.
- `VERDICT: PASS`: you are done, proceed to finalize.

{% if tools.kanban.enabled %}
Comment on the task with your progress.
{% endif %}

#### Finalize

If no hypothesis remains and you did not solve the task, report this.{% if tools.kanban.enabled %} Comment on the task with your failure.{% endif %}

If a hypothesis did solve the task, report that the task is complete.{% if tools.kanban.enabled %} Comment on the task with the result.{% endif %}

{% if tools.kanban.enabled %}Finish the board first: the last comment, and the move of the task to done. Then make the final commit with the `committer` agent, with the code, the tests and `.kanban/` together. Do not start a second committer for `.kanban/` only.{% else %}Then make the final commit with the `committer` agent.{% endif %}

## DO

- Focus on only the change asked for.
- When the code disagrees with the task or the diagnosis, follow the code, and say so in the report.
- Commit often, with the `committer` agent. This allows you to easily undo and back up.
- If you cannot complete the task, stop and say why. Give what you found.

## DO NOT

- Change code or test yourself, delegate to sub agents to get a fresh context.

## Report

When you complete the task, give a short report:

- The cause of the problem, or the behavior that you added, in one or two sentences.

The caller sends this report to the user, so give only the necessary data.
