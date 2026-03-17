Tier 0: High value, tiny implementation cost (ship immediately)

1. One-click “Run Now” handoff after PASS

What: After Preflight PASS, show a single CTA: Launch Glassbox Pipeline with this Ready-to-Run Pack.

Why it prints money: users feel the workflow is “complete,” fewer drop-offs, fewer reruns due to manual wiring mistakes.

Implementation: store the RunPack path + a launch payload; prefill pipeline job params.

2. “Explain my FAIL” remediation generator

What: When FAIL/WARN, generate a structured fix list with:

“What failed” (exact field/file)

“Why it matters” (1 line)

“How to fix” (copy-paste snippet or example row)

Why: reduces support tickets and makes the Certifier feel premium even if free.

3. Compatibility tag + schema version lock

What: output compat_tag, schema_version, pipeline_version_range.

Why: gives you a hard, defensible gate and prevents nightmare bug reports from mismatched inputs.

4. Preflight “Cost + time estimate” (rough, but helpful)

What: estimate run time / cost range based on input sizes + selected modules.

Why: procurement + engineers love it; reduces “surprise bill” anxiety.

Effort: modest; even coarse heuristics are fine if labeled as estimate.

Tier 1: Highest bang features (still relatively easy) 5) Output Viewer v1 (read-only, deterministic)

You described this already — it’s a winner. Keep it narrow:

v1 Viewer:

Browse outputs from GCS URI (preferred) or uploaded zip

Render:

run summary (manifest, status, modules)

key tables (CSV/JSON/Parquet-to-table)

links to artifacts (PDF/HTML)

evidence index (citations, hashes, file tree)

Why: “I can see what I got” is huge trust + reduces customer confusion.

6. “Run History” + shareable run link (within their project)

What: list of past runs (run_id, date, status, inputs hash, output path).

Why: the minute they see history, it feels like a real product, not a one-off script.

7. Template generator / sample pack

What: “Download sample input pack” + “Generate config starter”.

Why: eliminates cold start friction.
