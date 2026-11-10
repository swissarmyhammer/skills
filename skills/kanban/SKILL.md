---
name: kanban
description: Use to read or change the kanban board to add, find, assign, move, or update a task. Tells how to use the tool.
compatibility: Requires the `tools.kanban.runKanban` function of a code-mode host such as FoundationModelsMultitool, with the `KanbanTool` of FoundationModelsKanban. The model calls it in the `runCode` tool.
---

# Kanban

How to use the `tools.kanban.runKanban` tool.

## Tasks and subtasks

- The board is the one record of the tasks for all agent sessions. The board has columns, and each column has tasks. This is a classic Kanban board.
- A subtask is one line of a GFM checklist (`- [ ]` or `- [x]`) in the `body` of the task. There is no subtask API.
- The column of a task tells the state of its work. Keep each task in the column that agrees with the work. See [Choose the column](#choose-the-column).

## Call the tool

In the `runCode` tool, call `tools.kanban.runKanban({ query, variables })`. `query` is one GraphQL document. `variables` is an object, or a string that holds a JSON object. The result is the GraphQL response: `data`, `errors`, and `extensions`.

```js
const r = await tools.kanban.runKanban({ query: `{ board { name summary { total ready done } } }` });
return { board: r.data.board, errors: r.errors ?? [], warnings: r.extensions?.warnings ?? [] };
```

```json
{"board":{"name":"my-project","summary":{"done":0,"ready":0,"total":0}},"errors":[],"warnings":[]}
```

- Check `errors` before you read `data`. A call that fails gives `errors` and no `data`, so `r.data.addTask` stops the snippet with "undefined is not an object", and you do not see the real error. Start each read with this line:

  ```js
  if (r.errors?.length) return { errors: r.errors };
  ```

  The short examples below leave it out. Add it in your own calls.
- Each error has `extensions.code`, for example `NOT_FOUND`. The `message` tells you how to correct the call.
- Read `extensions.warnings` after each call. A warning tells you that the call did the work in a different way than you asked. Each warning has a `message` and a `code`. The call is done, and its changes are written.
- Each mutation takes one `input` argument, and `input` is required. A mutation with no field to give takes `input: {}`.
- All mutation fields of one document are one transaction.
- To learn the schema, query `__schema` or `__type`.

## The board

- The board is in the `.kanban/` folder at the top folder of the git worktree (`git rev-parse --show-toplevel`). Each worktree has its own board. Commit `.kanban/` with the code. Thus the task changes go on the branch of the code, and git merges the boards when it merges the branches.
- Outside git, the board is in the nearest folder, from the working directory up, that has a `.kanban/` folder. When no folder has one, the first mutation makes `.kanban/` in the working directory.
- A query on a repo that has no board gives an empty board, and it writes no file. The first mutation makes the board, with the columns `todo`, `doing`, `review`, and `done`. The board name is the name of the folder.
- The warning `BOARD_IN_SUBFOLDER` tells you that the tool does not use a `.kanban/` in a subfolder of the repo. Tell the user to run `collectBoards`. The warning `BOARD_ID_SHARED` tells you that two folders have the same board ID, for example a copied folder. Tell the user.
- A `.kanban/` folder of the old Rust kanban gives `INCOMPATIBLE_BOARD`. Do not change that folder. Tell the user to remove it. Remove it only when the user tells you to remove it.
- A call names the current board, unless an input `board` field or a full `kanban://` URI names a different board.
- Each session has its own actor. Your changes have your actor. `{ viewer { actor { id } } }` gives the id of your actor.

## Add tasks

`addTask` puts a task at the end of the first column. Put the subtasks in the body as a checklist. The examples of this skill run in order on one board, so the later examples use these tasks.

```js
const r = await tools.kanban.runKanban({
  query: `mutation($checklist: String!) {
    login: addTask(input: { title: "Fix the login bug", tags: ["bug"], body: $checklist }) {
      title column { name } tags { name } progress { completed total }
    }
    docs: addTask(input: { title: "Write the docs", tags: ["docs"] }) { title column { name } }
  }`,
  variables: { checklist: "- [ ] Find the cause\n- [ ] Add a test" }
});
return r.data;
```

```json
{"docs":{"column":{"name":"To Do"},"title":"Write the docs"},"login":{"column":{"name":"To Do"},"progress":{"completed":0,"total":2},"tags":[{"name":"bug"}],"title":"Fix the login bug"}}
```

- `addTask` takes `title`, `body`, `column`, `assignees`, `tags`, `dependsOn`, `priority`, `ordinal`, and `board`. Only `title` is required.
- An `addTask` with no `assignees` assigns your actor, when your actor was on the board before the call. When your actor was not on the board, the task has no assignee.
- Each `id` in a response is a full URI, for example `kanban://github.com/owner/repo/task/<ULID>`. Each task also has a `shortId`. When you name a task in text, write `^` and the `shortId`, for example `^rc9rb4g`. Copy the `shortId` from the response. Do not make a short form of the ULID yourself.

## Work with a task

### Get the next ready task

`nextTask` gives the first ready task in board order: the column order, then the place in the column. A ready task is live and not done, and no dependency blocks it. Add a filter when you must choose the work. When no task is ready, `nextTask` is `null`.

```js
const r = await tools.kanban.runKanban({ query: `{ board { nextTask(filter: "#bug") { id title ready } } }` });
const t = r.data.board.nextTask;
if (!t) return { next: null };
return { title: t.title, ready: t.ready };
```

```json
{"ready":true,"title":"Fix the login bug"}
```

### Assign and move a task

There is no claim operation. Two agents can get the same task from `nextTask`. To take a task, assign your actor, and move the task to the column for work that is in progress, in one document. On the default board, that column is `doing`. `assignTask` and `unassignTask` take the task `id` and one `actor`. Both fields are required, and the actor must be on the board. A comment with no `actor` has your actor as its `author`, and it puts your actor on the board. Thus a comment also gives you your actor id.

```js
const t = (await tools.kanban.runKanban({ query: `{ board { nextTask(filter: "#bug") { id } } }` })).data.board.nextTask;
const c = await tools.kanban.runKanban({
  query: `mutation($id: ID!) { addComment(input: { task: $id, body: "Picked up." }) { author { id } } }`,
  variables: { id: t.id }
});
const me = c.data.addComment.author.id;
const r = await tools.kanban.runKanban({
  query: `mutation($id: ID!, $me: ID!) {
    assignTask(input: { id: $id, actor: $me }) { title }
    moveTask(input: { id: $id, column: "doing" }) { column { name } assignees { id } }
  }`,
  variables: { id: t.id, me }
});
const moved = r.data.moveTask;
return { column: moved.column.name, mine: moved.assignees.some(a => a.id === me) };
```

```json
{"column":"Doing","mine":true}
```

### Read a task

`task(id:)` gives one task: for example its title, its body with the checklist, its column, and its comments.

```js
const r = await tools.kanban.runKanban({
  query: `{ board { task(id: "fix-the-login-bug") { title body column { name } comments { body } } } }`
});
return r.data.board.task;
```

```json
{"body":"- [ ] Find the cause\n- [ ] Add a test","column":{"name":"Doing"},"comments":[{"body":"Picked up."}],"title":"Fix the login bug"}
```

### Check off a subtask

Change its `- [ ]` to `- [x]` in the body with `updateTask`. Keep all other text of the body. `body` is the full new text: the tool calculates the change.

```js
const t = (await tools.kanban.runKanban({ query: `{ board { task(id: "fix-the-login-bug") { id body } } }` })).data.board.task;
const r = await tools.kanban.runKanban({
  query: `mutation($id: ID!, $body: String!) { updateTask(input: { id: $id, body: $body }) { progress { completed total } } }`,
  variables: { id: t.id, body: t.body.replace("- [ ] Find the cause", "- [x] Find the cause") }
});
return r.data.updateTask.progress;
```

```json
{"completed":1,"total":2}
```

- `updateTask` takes the task `id`, and the fields to change: `title`, `body`, `assignees`, `tags`, `dependsOn`, `column`, and `priority`. A field that you do not send does not change. A `null` clears the field.
- `assignees`, `tags`, and `dependsOn` replace the full list.

### Add a comment

`addComment` takes `task` and `body`, as in [Assign and move a task](#assign-and-move-a-task). A comment with no `actor` has your actor as its `author`.

### Choose the column

Each board can have different columns. Do not use a fixed list of columns, and do not move a task to "the next column" with no thought. Read the columns of the board. Then use your judgement to choose the column that agrees with the state of the work now.

`columns` gives the columns in board order: the first column first, and the last column last. A task in the last column is done.

```js
const r = await tools.kanban.runKanban({ query: `{ board { columns { name order trigger next } } }` });
return { columns: r.data.board.columns.map(c => c.name) };
```

```json
{"columns":["To Do","Doing","Review","Done"]}
```

To choose the column:

1. Read the name of each column, and its `body` when the name is not sufficient. The body can tell what the column is for.
2. Find the state of the work. Read the checklist, the comments, and the result of your work, for example the tests.
3. Choose the column whose purpose agrees with that state. On the default board:
   - `todo`: the work did not start.
   - `doing`: an agent works on the task now.
   - `review`: the work is complete, and it must be examined.
   - `done`: the work is examined and accepted.
4. When you are not sure, choose the column that tells less progress.

Rules:

- Do not move a task to a column that tells more progress than is true. For example, do not move a task to `review` when a subtask is not done or a test fails.
- Do not skip a column whose purpose applies to the task. For example, do not move a task from `doing` to `done` when the board has a `review` column.
- A task can move back. For example, when a review finds a problem, move the task back to the column for work in progress.
- When you cannot continue the work, keep the task in its column. Add a comment that tells why the work stopped and what is necessary to continue.
- When the reason for the move is not clear from the task, add a comment that tells why you moved it.
- A column with a `trigger` starts that skill when a task goes into the column. When `next` is `true`, the task moves to the column after it when the skill ends. Before you move a task to such a column, make sure that the skill must run.
- Use the slug or the name of a column that the board has. A column slug that no column has makes a new column. Make a new column only when the user tells you to.

### Move a task to a column

`moveTask` takes the task `id` and a `column`. With no `before`, `after`, or `ordinal`, the task goes to the end of the column. `completeTask` takes only the task `id`, and moves the task to the end of the last column. Choose the column first, as in [Choose the column](#choose-the-column).

```js
const r = await tools.kanban.runKanban({ query: `mutation { moveTask(input: { id: "fix-the-login-bug", column: "review" }) { column { name } } }` });
return r.data.moveTask;
```

```json
{"column":{"name":"Review"}}
```

- A `before` or `after` task that is not in the column puts the task at the end of the column, and the response gives a warning.

### Delete a task

`deleteTask` takes the task `id`, and deletes the task. A list does not show a deleted task, and a dependency on it does not block. `undeleteTask` takes the task `id`, and makes the task live again.

## Task refs

An input or an argument that takes a task accepts each of these refs:

| Ref | Example |
|---|---|
| The full URI | `kanban://github.com/owner/repo/task/01KT6SA4911JQPK09YQRC9RB4G` |
| The full ULID | `01KT6SA4911JQPK09YQRC9RB4G` |
| The short id: the last 7 characters of the ULID, in lowercase | `rc9rb4g` |
| The short id with `^` | `^rc9rb4g` |
| The stored form `<type>/<id>` | `task/rc9rb4g` |
| The slug of the title | `fix-the-login-bug` |
| A ULID prefix that only one task has | `01KT6SA49` |

```js
const t = (await tools.kanban.runKanban({ query: `{ board { task(id: "fix-the-login-bug") { id shortId } } }` })).data.board.task;
const ulid = t.id.split("/").pop();
const refs = [t.id, ulid, t.shortId, "^" + t.shortId, "task/" + t.shortId, "fix-the-login-bug"];
const titles = [];
for (const ref of refs) {
  const r = await tools.kanban.runKanban({ query: `query($ref: ID!) { board { task(id: $ref) { title } } }`, variables: { ref } });
  titles.push(r.data.board.task.title);
}
const prefix = await tools.kanban.runKanban({
  query: `query($ref: ID!) { board { task(id: $ref) { title } } }`,
  variables: { ref: ulid.slice(0, 2) }
});
return { titles, prefix: prefix.errors[0].extensions.code };
```

```json
{"prefix":"AMBIGUOUS_ID","titles":["Fix the login bug","Fix the login bug","Fix the login bug","Fix the login bug","Fix the login bug","Fix the login bug"]}
```

- Only the full URI can name a task on a different board. Each other ref names a task of the current board, or of the board that the `board` field names. A short ref never names a task on a different board.
- A ULID or a short id wins over a title slug.
- Two tasks can have the same short id or the same title slug. Then the ref names the first match: a live task before a deleted task, then the lowest ULID. The response gives a warning.
- A ULID prefix that two or more tasks have gives `AMBIGUOUS_ID`. The message lists the matching ids. Send the full id.
- A column, an actor, or a tag ref is its slug or its name, for example `doing` or `Doing`.

## Dependencies

A dependency blocks a task when it is not done, or when it leads back to the task through dependencies (a cycle). The tool ignores a dependency on a deleted task. A task is done when it is in the last column (the column with the highest `order`).

- Put the dependencies in `dependsOn`. The input name `blockedBy` also works, but `dependsOn` is the correct name.
- A dependency on a task of the same board can be each ref of the table above. A dependency on a task of a different repo must be the full `kanban://<board-key>/task/<ULID>` URI.
- `blockedBy` in a response lists the dependencies that block the task. A dependency that does not resolve is not in it.
- A dependency that no loaded board has blocks the task, and `unresolvedDependsOn` shows its URI. The write gives a warning: `DEPENDENCY_BOARD_NOT_FOUND` for a board that the tool cannot find, or `DEPENDENCY_TASK_NOT_FOUND` for a task that a found board does not have.
- A dependency that makes a cycle gives `DEPENDENCY_CYCLE`.

```js
const r = await tools.kanban.runKanban({
  query: `mutation {
    addTask(input: {
      title: "Ship the release",
      dependsOn: ["write-the-docs", "kanban://github.com/example/other/task/01J00000000000000000000000"]
    }) { ready virtualTags blockedBy { title } unresolvedDependsOn }
  }`
});
return { task: r.data.addTask, warnings: r.extensions.warnings.map(w => w.code) };
```

```json
{"task":{"blockedBy":[{"title":"Write the docs"}],"ready":false,"unresolvedDependsOn":["kanban://github.com/example/other/task/01J00000000000000000000000"],"virtualTags":["BLOCKED","MEDIUM"]},"warnings":["DEPENDENCY_BOARD_NOT_FOUND"]}
```

A full task URL in the body is also a dependency. A task URL in a code block, in inline code, or in a heading is not a dependency.

```js
const docs = (await tools.kanban.runKanban({ query: `{ board { task(id: "write-the-docs") { id } } }` })).data.board.task;
const body = "Do this after " + docs.id + " is done.\n\nThe example `" + docs.id + "` is not a dependency.";
const r = await tools.kanban.runKanban({
  query: `mutation($body: String!) { addTask(input: { title: "Announce the release", body: $body }) { dependsOn { title } } }`,
  variables: { body }
});
return r.data.addTask;
```

```json
{"dependsOn":[{"title":"Write the docs"}]}
```

When the docs task is done, the announce task is ready. The ship task stays blocked, because its other dependency does not resolve. `blockedBy` is empty, so read `unresolvedDependsOn`.

```js
await tools.kanban.runKanban({ query: `mutation { moveTask(input: { id: "write-the-docs", column: "done" }) { title } }` });
const r = await tools.kanban.runKanban({
  query: `{ board {
    announce: task(id: "announce-the-release") { ready }
    ship: task(id: "ship-the-release") { ready blockedBy { title } unresolvedDependsOn }
  } }`
});
return r.data.board;
```

```json
{"announce":{"ready":true},"ship":{"blockedBy":[],"ready":false,"unresolvedDependsOn":["kanban://github.com/example/other/task/01J00000000000000000000000"]}}
```

`updateTask` with `dependsOn` replaces the list. A dependency that the new list does not have is removed, also its URL in the body.

```js
const r = await tools.kanban.runKanban({
  query: `mutation { updateTask(input: { id: "ship-the-release", dependsOn: ["write-the-docs"] }) { ready dependsOn { title } unresolvedDependsOn } }`
});
return r.data.updateTask;
```

```json
{"dependsOn":[{"title":"Write the docs"}],"ready":true,"unresolvedDependsOn":[]}
```

## Virtual tags

The tool calculates these tags. A filter uses them as `#READY`, `#DONE`, and so on. A real tag cannot have one of these names.

| Tag | The task |
|---|---|
| `READY` | is live and not done, and no dependency blocks it. |
| `BLOCKED` | is live, and a dependency that is not deleted is not done or leads back to the task. |
| `CONFLICT` | has a conflict block in its body, from a merge of two body changes. |
| `DELETED` | is deleted. A list shows a deleted task only when the filter names `#DELETED`, or has a `^id` or `~task` atom. |
| `DONE` | is live, and it is in the terminal column: the last column. |
| `HIGH` | is in the first third of the open tasks, in board order. |
| `MEDIUM` | is in the second third of the open tasks. |
| `LOW` | is in the last third of the open tasks. |

BLOCKING is not a virtual tag: `#BLOCKING` is an ordinary tag filter. To find the work that blocks a task, read its `blockedBy`.

## Filters

`tasks`, `nextTask`, `searchTasks`, `history`, and the `tasks` field of a column, an actor, or a tag take one `filter`. There is no `column`, `tag`, or `assignee` argument: write the atom.

| Atom | Matches |
|---|---|
| `#tag` | the tasks with this tag, also a virtual tag |
| `@actor` | the tasks that this actor is assigned to |
| `%column` | the tasks in this column |
| `^id` | the task with this ref, and the tasks that depend on it. `id` is a ULID, a short id, a short id with `^` (`^^rc9rb4g`), or a title slug (`^fix-the-login-bug`). A shared short id or title slug matches each task that has it. |
| `~type` | each node of this type: `task`, `column`, `tag`, `actor`, `comment`, or `board`. Use it with `history`. |
| a `kanban://` URL | the same as the atom of its node type, for example `@kanban://<board-key>/actor/<slug>` |
| `&&` or `and` | both sides |
| `\|\|` or `or` | one side or the two sides |
| `!` or `not` | the opposite |
| `( )` | a group |
| two atoms next to each other | both atoms: `#bug @alice` is `#bug && @alice` |

- A list with no filter gives each task that is not deleted, also the done tasks. Use `!#DONE` for the open tasks.
- A filter that does not parse gives `INVALID_FILTER`, with the position and a correct example.
- `tasks` gives pages. A page has 10 tasks when you do not give `first`. To get all tasks, give a larger `first`, or read `pageInfo { hasNextPage endCursor }` and send `endCursor` as `after` for the next page. `totalCount` gives the number of tasks that match.
- `searchTasks(query: "...")` finds tasks by their text. It also takes `filter` and `first`.

```js
const login = (await tools.kanban.runKanban({ query: `{ board { task(id: "fix-the-login-bug") { assignees { id } } } }` })).data.board.task;
const filters = {
  ready: "#READY",
  done: "#DONE",
  bugsInReview: "#bug && %review",
  afterDocs: "^write-the-docs && !#DONE",
  high: "#HIGH",
  mine: "@" + login.assignees[0].id
};
const lists = {};
for (const [name, filter] of Object.entries(filters)) {
  const r = await tools.kanban.runKanban({
    query: `query($filter: String!) { board { tasks(filter: $filter) { nodes { title } } } }`,
    variables: { filter }
  });
  lists[name] = r.data.board.tasks.nodes.map(t => t.title);
}
return lists;
```

```json
{"afterDocs":["Ship the release","Announce the release"],"bugsInReview":["Fix the login bug"],"done":["Write the docs"],"high":["Ship the release"],"mine":["Ship the release","Announce the release","Fix the login bug"],"ready":["Ship the release","Announce the release","Fix the login bug"]}
```

## Priority

A task has no priority field. The place of the task in its column is its priority. `HIGH`, `MEDIUM`, and `LOW` come from that place. To change the priority, move the task with `moveTask` and `before` or `after` a different task. Give only one of `before`, `after`, and `ordinal`: two of them give `CONFLICTING_PLACEMENT`.

A `priority` input of `addTask` or `updateTask` also moves the task in its column, and gives the warning `PRIORITY_IS_POSITION`. `moveTask` has no `priority` input. The case of the value does not matter.

| `priority` value | Move |
|---|---|
| `urgent`, `critical`, `high`, `P0`, `P1`, `true` | to the top of the column |
| `low`, `P3`, `P4` | to the end of the column |
| `medium`, `normal`, `P2`, and each other value | no move |

```js
const r = await tools.kanban.runKanban({
  query: `mutation {
    moveTask(input: { id: "announce-the-release", column: "todo", before: "ship-the-release" }) { title }
    addTask(input: { title: "Fix the crash", tags: ["bug"], priority: "urgent" }) { title }
  }`
});
const todo = await tools.kanban.runKanban({ query: `{ board { tasks(filter: "%todo") { nodes { title virtualTags } } } }` });
return { warnings: r.extensions.warnings.map(w => w.code), todo: todo.data.board.tasks.nodes };
```

```json
{"todo":[{"title":"Fix the crash","virtualTags":["READY","HIGH"]},{"title":"Announce the release","virtualTags":["READY","HIGH"]},{"title":"Ship the release","virtualTags":["READY","MEDIUM"]}],"warnings":["PRIORITY_IS_POSITION"]}
```

## Tags

- `tagTask` and `untagTask` take the task `id` and a `tags` list. They add and remove only these tags. `addTask` and `updateTask` take a full `tags` list. A tag that the board does not have is made.
- A `#tag` in the body is also a tag. `untagTask` also removes it from the body.
- `renameTag` with `from` and `to` renames a tag. The old name then points to the new tag.

```js
const r = await tools.kanban.runKanban({
  query: `mutation {
    tagTask(input: { id: "fix-the-crash", tags: ["release"] }) { tags { name } }
    untagTask(input: { id: "fix-the-crash", tags: ["bug"] }) { tags { name } }
  }`
});
return r.data;
```

```json
{"tagTask":{"tags":[{"name":"bug"},{"name":"release"}]},"untagTask":{"tags":[{"name":"release"}]}}
```

## Forgiving names

The tool accepts a name that is close enough, for example `createTask`, `task_id`, `labels`, or `status`. It changes the name to the canonical name, and `extensions.rewrites` tells you the change. Use the canonical names of this skill: a name that is close to two names gives `AMBIGUOUS_NAME`. The tool removes a parameter of the old Rust kanban that it does not have (for example `project`, `due`, or `exclude_done`). The call continues, and a warning tells you what to use.
