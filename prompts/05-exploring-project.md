# Prompts: Exploring and Understanding a Project

These prompts are useful when you join a new project, onboard to an
unfamiliar codebase, or need to understand context before making changes.
They work especially well with dbt MCP connected.

---

## Understand a model you didn't write

```
Look at [model_path] and explain:
1. What does this model do? (grain, purpose)
2. What are its upstream dependencies?
3. What are the key business rules or transformations?
4. Are there any potential issues or things I should be careful about?

Keep the explanation concise — I want to understand it in 2 minutes.
```

---

## Explore project structure

```
Look at the models/ directory structure and give me an overview:
1. How many models are there in each layer (staging, intermediate, marts)?
2. What entities does this project model?
3. What sources does it use?
4. Are there any models without tests or documentation?

Summarize in a short paragraph per layer.
```

---

## Understand lineage for a specific model

```
Show me the full lineage for [model_name]:
1. What sources/seeds does it ultimately depend on?
2. What intermediate models does it pass through?
3. What other models reference it downstream?

Draw the chain from source to final consumer.
```

---

## Check test coverage

```
Audit test coverage across the project:
1. Which models have no tests at all?
2. Which primary keys are missing unique + not_null?
3. Which foreign keys are missing relationships tests?
4. Any columns that look like they should have accepted_values but don't?

List the gaps, ordered by severity.
```

---

## Understand a failing CI run

```
Our CI run failed. Here's the output:

[paste dbt build output]

Tell me:
1. Which specific model or test failed?
2. What's the root cause?
3. Is this a code issue or a data issue?
4. What should I look at first?
```

---

## Compare two models

```
Compare [model_a] and [model_b]:
1. What columns do they share?
2. What's different in their grain?
3. When should someone use one vs the other?
4. Is there any duplication between them that could be refactored?
```

---

## Data profiling before building

```
Before I build a new model, I want to understand the source data.

Query [source/model] and show me:
1. Row count
2. Count of distinct values for [key columns]
3. Distribution of [categorical column]
4. Min, max, avg for [numeric columns]
5. Count and percentage of nulls for each column
6. Any obvious data quality issues

This helps me decide how to structure the model.
```

---

## Key principles for "explore" prompts

1. **Ask for context before making changes** — understand first, modify second
2. **Use MCP** — these prompts are 10x better when Claude can actually see the project structure
3. **Ask for concise answers** — "explain in 2 minutes", "summarize in a paragraph"
4. **Profile data before building** — prevents surprises during model development
