# Sanlam Life, Wealth & Retirement: Data Modernization

> **Project 1 | (Sanlam Data Modernization)**
> From messy files to a trusted warehouse, and from the warehouse to decisions.

**Planning board:** [Trello: Final Project (Sanlam Life, Wealth & Retirement)](https://trello.com/b/esJOc8H0/final-projectsanlam-life-wealth-retirement)

> All data is fictional training data. Identity-like values are not real and must never be used to contact anyone or make real decisions. This project does not replace legal, actuarial, tax or regulatory advice.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Objectives](#2-objectives)
3. [Mandatory Technology Stack](#3-mandatory-technology-stack)
4. [Data Flow](#4-data-flow)
5. [Source Files](#5-source-files)
6. [Target Warehouse Design](#6-target-warehouse-design)
7. [Team and Responsibilities](#7-team-and-responsibilities)
8. [Delivery Plan and Sprints](#8-delivery-plan-and-sprints)
9. [Anomaly Catalogue (Planning Baseline)](#9-anomaly-catalogue-planning-baseline)
10. [Business Metrics and Analysis Pages](#10-business-metrics-and-analysis-pages)
11. [Deliverables](#11-deliverables)
12. [Acceptance Tests](#12-acceptance-tests)
13. [Project Rules and Reasons for Rejection](#13-project-rules-and-reasons-for-rejection)
14. [Proposed Repository Structure](#14-proposed-repository-structure)
15. [Working Agreements](#15-working-agreements)
16. [Risks and Mitigations](#16-risks-and-mitigations)
17. [Definition of Done](#17-definition-of-done)

---

## 1. Project Overview

Sanlam looks after people's life cover, retirement savings and investments. Its records live in many systems built over many years: the same person can appear twice, product names are spelled differently, and a claim can point to a policy that is missing from the file. Unreconciled records lead to poor decisions on pricing, claims, sales channels and retirement-fund cash.

Our job is to build a **repeatable path from messy files to a trusted database, and then to decisions**:

- **Clean** the raw files with **pandas**
- **Model and prove** the data in **PostgreSQL**
- **Report** the results in **Power BI**

The outcome is not just a clean file. It is a set of documented rules that lets another analyst explain where every number came from.

## 2. Objectives

- Profile every raw file and record the "before" numbers.
- Detect, correct, flag or quarantine every anomaly under documented rules, and log every change.
- Build a scripted star-schema warehouse (`sanlam_dw`) that can be rebuilt from an empty database.
- Prove that rows and money reconcile between source and warehouse.
- Prove that the full pipeline is repeatable (run twice, same result).
- Build a Power BI report with four analysis pages that answer the business questions.
- Verify every headline number three ways: Power BI, SQL and pandas.
- Defend our decisions in an oral defence.

## 3. Mandatory Technology Stack

Each tool has one main job. Using a tool for another tool's job is not accepted.

| Tool | Used for | Not used for |
| --- | --- | --- |
| **pandas** (Python 3.10+, pandas 2.x) | Reading raw files, profiling, cleaning, standardising labels, parsing dates and numbers, anomaly detection, duplicate matching, quarantine / audit / crosswalk tables, preparing tables for loading, independent recomputation of totals | Dashboards; surrogate keys, constraints or the star schema; hidden fixes (every correction is logged) |
| **PostgreSQL** (14+) | Raw, staging, warehouse, quarantine and audit tables; keys and constraints; dimensions and facts; Type 2 history; control and reporting views; reconciliation queries; read-only role for Power BI | Receiving uncleaned data in the warehouse schema; hand-typed data; cleaning logic that belongs in pandas |
| **Power BI Desktop** | Connecting to PostgreSQL, semantic model, DAX measures, report pages, row-level security, refresh documentation | Cleaning data. Power Query may only rename columns, set data types and remove unused columns. No Excel or CSV as the final data source |

**Hosting note:** PostgreSQL is hosted on **Supabase** (a new project named `sanlam-warehouse`). All database work the brief assigns to PostgreSQL is done there. Connection details are kept in a local `.env` file and are never committed.

## 4. Data Flow

| # | Stage | What happens | Evidence we keep |
| --- | --- | --- | --- |
| 1 | Raw files | Files are read exactly as received and never edited by hand | Original files unchanged; file names, sizes, row counts recorded |
| 2 | Profile (pandas) | "Before" numbers are measured for every file | Profile tables saved |
| 3 | Clean and validate (pandas) | Rules applied, every correction logged, untrusted rows quarantined | Clean, audit, quarantine and crosswalk tables |
| 4 | Load to staging (pandas to PostgreSQL) | Clean, audit and quarantine tables written to `stg` and `ops` | Row counts per table |
| 5 | Model (PostgreSQL SQL) | Dimensions and facts built from staging with surrogate keys and rules | Numbered SQL scripts |
| 6 | Prove (SQL and pandas) | Rows and money reconciled; load run twice | Control views and saved results |
| 7 | Report (Power BI) | Power BI connects to PostgreSQL views; measures and pages built | `.pbix` file and screenshots |
| 8 | Verify (SQL, pandas, Power BI) | Every headline number checked three ways | Verification sheet |

**Database schemas:** `raw`, `stg` (staging), `sanlam_dw` (warehouse), `ops` (audit, quarantine and profile tables).

## 5. Source Files

Six raw tables are expected. For each one we write the sentence: *"This file contains ______, one row per ______."*

| File | One row means |
| --- | --- |
| `policies` | One insurance or savings policy |
| `clients` | One client record (duplicates likely) |
| `payments` | One ledger or premium transaction, including reversals |
| `claims` | One claim against a policy |
| `advisors` | One adviser, with channel and network |
| `two_pot_savings` | One account snapshot with savings, retirement and vested balances |

## 6. Target Warehouse Design

| Table | Purpose |
| --- | --- |
| Date | One row per calendar day, shared by every fact |
| Channel, Client, Adviser, Product, Policy | Descriptive dimensions; client and adviser may keep dated versions (Type 2) |
| Policy premium (fact) | One row per premium or payment transaction |
| Claim (fact) | One row per claim, with dates, status, type, claim amount and paid amount |
| Payment (fact) | One row per ledger transaction (amount, method, status, reversal flag) |
| Two-Pot snapshot (fact) | One row per account per snapshot date: savings, retirement and vested balances, reported total, withdrawals |
| Quarantine | Records held back, each with reason code, source file, status and timestamps |
| Change audit | Every correction: table, row, field, old value, new value, rule code |
| Entity crosswalk | Links duplicate IDs to the surviving ID, with match method and reviewed flag |
| Views | Quality counts, paid claims by month, control totals and the reporting views Power BI reads |

**Design decisions to document during Sprint 2:**

- Grain statement for each fact table (one sentence each).
- Type 1 vs Type 2 choice per changing attribute, with reasons. **At least one dimension must be Type 2** with exactly one current version per business key.
- Exact numeric types for money (never floating point) and proper date types.
- An "Unknown" member only for legitimate late-arriving dimensions, never to hide an orphan that belongs in quarantine.
- A read-only database role for Power BI, limited to the reporting views.

## 7. Team and Responsibilities

Team of 3. Update names and confirm the split with the team.

| Member | Role | Main focus |
| --- | --- | --- |
| [Member 1] | [e.g. Data Engineering lead] | [e.g. pandas profiling, cleaning, audit and quarantine tables] |
| [Member 2] | [e.g. Database Architect] | [e.g. PostgreSQL / Supabase schemas, SQL scripts, reconciliation] |
| [Member 3] | [e.g. BI Developer] | [e.g. Power BI model, DAX, report pages, RLS] |

Shared by everyone: anomaly catalogue and rule cards, verification sheet, quality report, definition cards and oral-defence rehearsal.

## 8. Delivery Plan and Sprints

The board on Trello is organised into sprints. Due dates are added on each card.

### Sprint 0: Setup

- [ ] Create GitHub repo structure and agree branch and commit rules
- [ ] Create the Supabase project `sanlam-warehouse`
- [ ] Create schemas `raw`, `stg`, `sanlam_dw`, `ops`
- [ ] Set up `.env` (not committed) and `.env.example`
- [ ] Confirm pandas can write a test table into `stg`
- [ ] Confirm Power BI Desktop can read that test table (test now, not in Week 3)
- [ ] Create the Trello board, labels and sprint lists

### Sprint 1 (Week 1): Profile and clean in pandas

- [ ] Write a "one row means" sentence for each of the six files
- [ ] Copy the business questions from the brief
- [ ] Profile every file by script: row counts, blanks per column, date ranges, min and max amounts, distinct values, repeating IDs
- [ ] Save profile tables to `ops` and export a copy (the "before" numbers)
- [ ] Build the anomaly catalogue (A01 onwards) with a four-line rule card per code
- [ ] Decide correct, quarantine or flag for every anomaly and implement each as a small, named pandas function
- [ ] Resolve duplicate people (exact-ID pass first, then candidate name and birth-date matches for review) and build the reversible crosswalk
- [ ] Build the audit and quarantine tables
- [ ] Make the pipeline repeatable: stable source row key, load-batch ID, deterministic rules and fixed sort order
- [ ] Reconcile every file: rows read = loaded + quarantined + dropped
- [ ] Agree definitions for premium basis (written, collected or earned) and claim basis (paid or incurred)

### Sprint 2 (Week 2): Build and prove the warehouse in PostgreSQL

- [ ] Draw the star schema with grain statements
- [ ] Record Type 1 / Type 2 decisions (at least one Type 2 dimension)
- [ ] Write numbered, re-runnable SQL scripts: schemas, tables, keys, constraints, indexes, views, read-only role
- [ ] Load staging and `ops` tables from pandas
- [ ] Load dimensions first (date, channel, product, then clients, advisers, policies), then facts, looking up surrogate keys in SQL
- [ ] Send anything without a parent to quarantine with a reason code
- [ ] Check Two-Pot balances in SQL (savings + retirement + vested = reported total; negative components)
- [ ] Reconcile rows and money (SQL vs independent pandas totals)
- [ ] Build control and quality views and save screenshots and result files
- [ ] Run the whole pipeline twice and record the proof
- [ ] Capture before and after counts for the quality report

### Sprint 3 (Week 3): Power BI report and defence

- [ ] Write a definition card for every metric
- [ ] Connect Power BI to the PostgreSQL reporting views using the read-only role (Import mode unless justified in writing)
- [ ] Build the semantic model: star layout, one-to-many single-direction relationships, one marked date table, dedicated measures table
- [ ] Use parameters for server and database names
- [ ] Build the four analysis pages, each with a headline (what changed, why it matters, recommended action)
- [ ] Create at least one row-level security role and test it with "View as"
- [ ] Document refresh assumptions
- [ ] Complete the verification sheet: at least 10 headline numbers, at least one per page, matched three ways
- [ ] Run the privacy check (no names or IDs in the report or audit logs)
- [ ] Finish the quality report and rehearse the oral defence out loud

## 9. Anomaly Catalogue (Planning Baseline)

Starting codes from the brief. We add any new anomaly found in the data and confirm what actually exists, because the brief's list may not be complete.

| Code | Problem | Usual decision |
| --- | --- | --- |
| A01 | Duplicate client | Merge only under a defensible rule; keep a crosswalk |
| A02 | Malformed date | Impute only with a written rule and an is-imputed flag; otherwise quarantine |
| A03 | Numeric outlier | Flag plausible large claims; cap only a clear entry error |
| A04 | Orphan reference (policy, client or adviser key has no parent) | Quarantine, noting which key type is missing |
| A05 | Illogical timeline (ends before start, claim before inception, future-dated payment) | Quarantine unless evidence supports a fix |
| A06 | Category variant (e.g. Blue Star, BlueStar, BLUE STAR) | Standardise after confirming meaning; log it |
| A07 | Balance inconsistency (Two-Pot components do not add up, or implausibly negative) | Flag or quarantine; never force the numbers to fit |
| A08 | Duplicate transaction | Check first: could these be genuine repeated instalments? |

**Every code gets a rule card** with four lines: how it is detected, whether it could be legitimate, whether we correct or quarantine, and what we record.

**Decision order:**

1. Can we prove the right value? If not, quarantine.
2. Is the fix safe and rule-based (like standardising a spelling)? If yes, correct it and log it.
3. Could it be real but unusual (a very large death claim)? If yes, keep it visible and flag it. Never cap or delete it.

**Sign convention:** negative amounts are not automatically errors; they may be valid reversals. The convention is documented before cleaning starts.

## 10. Business Metrics and Analysis Pages

### Metrics

Every metric gets a definition card: name, plain meaning, formula in words, data used, exclusions, one limitation, and where it is calculated (a named SQL view or a named DAX measure).

| Metric | In words |
| --- | --- |
| Rolling 12-month loss ratio | Claims paid in the last 12 months divided by premiums in the last 12 months (state paid vs incurred and written vs collected vs earned) |
| Claim frequency | Number of claims divided by policies in force |
| Claim severity | Total claim amount divided by number of claims |
| 12-month persistency | Policies still in force 12 months after inception divided by policies incepted (exclude policies under 12 months old) |
| Commission efficiency | Commission paid divided by net premium production |
| Withdrawal velocity | Savings withdrawals in the period divided by the opening savings balance (state how zero or negative openings are handled) |
| Anomaly rate | Flagged records divided by records ingested |
| Cleaning efficiency | Automatically corrected records divided by flagged records |
| Quarantine resolution rate | Resolved quarantined records divided by all quarantined records |

Rates are shown alongside counts because source volumes differ.

### Four analysis pages

| # | Page | What it must show |
| --- | --- | --- |
| 1 | Portfolio loss ratio | Product and adviser-channel combinations with the highest rolling 12-month paid claims relative to premium; frequency separated from severity; a clearly labelled premium basis |
| 2 | Retirement liquidity | AUM across savings, retirement and vested components; trend in savings withdrawals; a 2x withdrawal-velocity stress using opening balances |
| 3 | Channel productivity | Net premium after cancellations and reversals by channel; commission as a share of net premium; 12-month persistency |
| 4 | Data quality | Which sources and anomaly types drive defects; corrected, quarantined, resolved and dropped counts; rates, not just counts |

**Two-Pot note:** the reform took effect on 1 September 2024. Our work is analytics, not a legal-rule engine. We state our assumptions and note that current rules must be verified.

## 11. Deliverables

| # | Deliverable | Tool |
| --- | --- | --- |
| 1 | Profile pack (before and after, saved in `ops` and exported) | pandas |
| 2 | Cleaning pipeline (raw files to clean, quarantine, audit and crosswalk tables, no manual step) | pandas |
| 3 | Anomaly catalogue and rule cards | Document |
| 4 | Database scripts (numbered, re-runnable) | PostgreSQL |
| 5 | Reconciliation evidence (rows, money, run-twice proof, control view screenshots) | SQL and pandas |
| 6 | Power BI report (`.pbix`, four pages, measures table, RLS, parameters) | Power BI |
| 7 | Verification sheet (10+ headline numbers checked three ways) | All three |
| 8 | Quality report (before and after counts, lineage map from raw to warehouse columns) | Document |
| 9 | Definition cards (one per metric) | Document |
| 10 | Oral defence | Live |

## 12. Acceptance Tests

| Test | We pass when |
| --- | --- |
| Rebuild test | The instructor empties the database, runs our pandas pipeline and SQL scripts in order with no manual step, and the warehouse is rebuilt |
| Row reconciliation | For every file, rows read = loaded + quarantined + dropped |
| Money reconciliation | Warehouse totals equal independently computed source totals, with quarantined amounts listed separately |
| Two-Pot balance test | Savings + retirement + vested equals the reported total for every loaded snapshot; differences sit in quarantine or are flagged |
| Re-run test | Running the whole pipeline twice leaves row counts and totals unchanged |
| Integrity test | No fact points to a missing parent, foreign keys are enforced, each Type 2 business key has exactly one current version |
| Refresh test | The Power BI file refreshes against the instructor's database by changing parameters only |
| Verification test | All headline numbers match across Power BI, SQL and pandas within rounding |
| Privacy test | No names, ID numbers or other identifiers visible in the report or audit logs |

## 13. Project Rules and Reasons for Rejection

**Rules that must be true at hand-in**

- **Cleaning is code.** Every rule is applied in pandas and can be re-run from the raw files.
- **Raw files are evidence.** Never changed, renamed or overwritten.
- **The warehouse is scripted.** Rebuildable from an empty database.
- **SQL builds the star.** No DataFrames pushed straight into warehouse tables.
- **Power BI reads PostgreSQL only,** through a read-only role, preferably to reporting views.
- **One definition per metric.** Row-level logic in SQL views, totals in DAX measures.
- **Three-way proof** on every headline number.
- **Run it twice** gives identical row counts and totals.
- **No secrets in files.** Passwords and machine-specific paths are kept in configuration or Power BI parameters.

**Work can be rejected if**

- Data was cleaned in Excel, a text editor, Power Query, DAX or by hand in the database.
- Raw files were edited, renamed or overwritten.
- Power BI reads CSV or Excel, or connects with a role that can write.
- Warehouse facts were loaded straight from a DataFrame without SQL lookups and foreign keys.
- Passwords or personal identifiers appear in scripts, notebooks, the `.pbix`, dashboards or audit logs.
- A genuine large value was capped or deleted without a documented rule proving a data-entry error.
- Headline numbers differ between tools without explanation.
- The pipeline gives different results when run twice.

## 14. Repository Structure

```
Sanlam-Life-Wealth-1-Retirement/
├── raw_data/       # raw source files exactly as received, never edited
├── Notebook/       # pandas notebooks: profiling, cleaning, audit and crosswalk tables
├── clean_data/     # cleaned tables produced by the notebooks
├── quarantine/     # records held back, each with a reason code
└── README.md
```

Folders for the SQL scripts, Power BI file and documentation will be added as those sprints start.

## 15. Working Agreements

- **Branching:** work on feature branches, merge to `main` through pull requests with at least one reviewer.
- **Commits:** small, clear messages (e.g. `profile: add blank counts for claims`).
- **Secrets:** `.env` is git-ignored. No passwords, keys or personal identifiers in the repo.
- **Raw data:** never modified. Any change to data happens in the pipeline and is logged.
- **Documentation first:** each rule, decision and definition is written down as it is made.
- **Trello:** one card per task, moved through the sprint lists; each card names an owner and a due date.
- **Testing early:** pandas-to-database and Power BI-to-database connections are tested in Sprint 0.

## 16. Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| No local PostgreSQL available | Use Supabase-hosted PostgreSQL; keep scripts portable and re-runnable |
| Power BI cannot connect late in the project | Test the connection in Sprint 0 (server, port, database, role permissions, security settings) |
| Team work not yet merged on GitHub | Agree repo structure early; merge feature branches at the end of every sprint |
| Totals differ between pandas, SQL and Power BI | Check row counts, totals, quarantined rows, duplicates, then sign convention; in Power BI also check relationship direction, date table and page filters |
| Cleaning logic leaks into Power Query or DAX | Review the Power Query steps list at each sprint review |
| Legitimate large claims wrongly capped | Flag and keep visible; cap only with a documented rule proving an entry error |
| Pipeline not repeatable | Stable source row keys, load-batch IDs, deterministic rules, fixed sort order; test the re-run each sprint |
| Identifiers leak into dashboards or audit logs | Use surrogate keys and masked values; run the privacy check before hand-in |
| Time pressure in Week 3 | Finish Sprint 1 and 2 evidence early; prepare definition cards and verification sheet during Sprint 2 |

## 17. Definition of Done

A task is done when:

- It is implemented in the correct tool (pandas, PostgreSQL or Power BI).
- It can be re-run from scratch with no manual step.
- Its decision, rule or definition is documented.
- Its evidence (counts, screenshots, result files) is saved in the repo.
- It has been reviewed by another team member.
- Its Trello card is moved to Done.

---

*Simulated training material. All data is fictional.*
