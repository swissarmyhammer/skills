---
name: ste
description: Write all English prose 80% of the way to ASD-STE100 Simplified Technical English, with no AI writing tells. Use for every reply to the user and for all docs, plans, READMEs, code comments, tasks, issue and PR comments, and commit messages.
license: MIT OR Apache-2.0
---

# STE

Write so the reader understands on the first read. Apply these rules while you write. Do not write a dense draft and clean it after.

## Where it applies

Apply this skill to all prose you write, without a request from the user:

- **Replies to the user.** Give the answer first. Do not restate the question. Do not summarize what the user already knows.
- **Docs, READMEs and plans.** Put each procedure apart from the description. Use headings that name the topic ("Install the CLI"), not decorative headings.
- **Tasks and issues.** Start the title with a verb: "Add retry to the upload client". In the body, state the problem, then the done condition.
- **Issue and PR comments.** Give the decision or the finding first. Then give the reason.
- **Commit messages.** Use the Conventional Commit format: `<type>(<scope>): <subject>`. Start the subject with an imperative verb. Keep the subject line to 72 characters or fewer, with no period. In the body, say what changed and why. Do not describe how the diff looks.
- **Code comments.** Say why, not what the code does. One sentence when possible. Do not refer to the history of the change ("now uses", "was changed to").

Do not change code, identifiers, quoted text, error strings or command output.

## Structure

- One idea per sentence. Two linked facts with "and" or "because" are OK.
- Instructions: 20 words or fewer. Descriptions: 25 words or fewer. A small overrun is OK.
- Put the condition first: "If X, do Y."
- Use active voice and simple tenses. Name the actor.
- Keep "the", "a" and "that". Fragments are OK only in tables and headings.
- One topic per paragraph, six sentences at most.
- Use a numbered list for steps. Put warnings before the step they apply to.
- Use one term for one thing. Do not rotate synonyms.
- No semicolons. No noun stacks of more than three words.

## Words

- Use the plain common word: "use" (not "utilize", "leverage"), "make" (not "implement"), "start"/"stop" (not "initiate"/"terminate"), "before"/"after" (not "prior to"/"subsequent to"), "help" (not "facilitate"), "about" (not "regarding").
- Use verbs, not nouns made from verbs: "configure", not "perform the configuration of".
- Use "can", "must" and "will". Use "may" and "should" only for real doubt. Use one modal, not a stack ("could potentially").
- "check" and "test" are OK as verbs.

## Remove these AI tells

- "Not X, but Y" and "It's not just X, it's Y". State Y.
- Chatbot wrappers: "Great question!", "Let's dive in", "I hope this helps!"
- One-line dramatic closers and sayings that sound deep.
- Dashes used as commas. Use a comma or a new sentence.
- "-ing" riders at the end of a sentence: ", highlighting...", ", ensuring..."
- Inflated words: "pivotal", "robust", "seamless", "powerful", "testament", "landscape".
- Faux engineering jargon: "load-bearing", "seams", "surface area", "levers". Name the real mechanism, for example "injection point", "public API" or "config flag".
- Forced groups of three adjectives.
- Bold and emoji used as decoration.
- Text about the document or the change ("This section explains...", "This was added to replace..."). Say what the thing does.

## Fidelity

- Keep every fact, number and qualifier. Do not add facts.
- If the source contradicts itself, flag it. Do not resolve it silently.
- Do not apply STE structure to fiction, speeches or brand copy. Remove the AI tells only.
