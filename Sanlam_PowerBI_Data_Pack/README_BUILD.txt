SANLAM PROJECT 1 - POWER BI DATA PACK (simulated training data)
================================================================
A .pbix can only be created by Power BI Desktop, so this pack gets you
to the finished report in roughly 30-45 minutes. The full visual-by-visual
instructions and pictures are in Sanlam_Project1_PowerBI_Build_Guide.docx.

WHAT IS IN THE FOLDER
  CSV tables (clean, ISO dates, ZAR, masked IDs):
    dim_policy, dim_advisor, dim_client
    fact_claims, fact_payments, fact_two_pot
    dq_row_counts, dq_anomaly_log, dq_quarantine, dim_source_table
  Sanlam_Tables_DAX_new_table.dax          -> dim_date + 3 helper tables
  Sanlam_All_Measures_DAX_query_view.dax   -> all 43 measures in one paste

QUICK START
 1. Home > Get data > Text/CSV. Load the 10 CSVs (or Get data > Folder).
    Check types: *_date = Date, amounts = Fixed decimal, is_outlier and
    resolved_flag = True/False, *_key = Whole number.
 2. Modeling > New table: paste each table from
    Sanlam_Tables_DAX_new_table.dax (dim_date, dim_source_table,
    Component, Outlier Switch). Mark dim_date as the date table and
    sort Month by Month End.
 3. Modeling > New parameter > Numeric range: name "Stress Multiplier",
    min 1, max 4, increment 0.5, default 2.
 4. Model view - create these Many-to-one, Single-direction relationships:
      fact_claims[policy_key]      -> dim_policy[policy_key]
      fact_payments[policy_key]    -> dim_policy[policy_key]
      fact_two_pot[policy_key]     -> dim_policy[policy_key]
      dim_policy[advisor_key]      -> dim_advisor[advisor_key]
      dim_policy[client_key]       -> dim_client[client_key]
      fact_claims[claim_date]      -> dim_date[Date]
      fact_payments[transaction_date] -> dim_date[Date]
      fact_two_pot[snapshot_date]  -> dim_date[Date]
      dq_row_counts[table_name]    -> dim_source_table[table_name]
      dq_anomaly_log[table_name]   -> dim_source_table[table_name]
 5. Home > Enter data: create an empty table named  _Measures.
 6. View > DAX query view: paste Sanlam_All_Measures_DAX_query_view.dax,
    Run, then "Update model with changes".
 7. Build the four pages from the guide (Sections 3-6). Hide the *_key and
    source_row_key columns.
 8. Check the numbers against Section 1.3 of the guide
    (for example Loss Ratio 93.3%, Paid Claims R341.2m, Net Premium R126.0m).

KNOWN LIMITS - READ BEFORE PRESENTING
  * 1,447 rows in fact_two_pot (8%) belong to policies that were
    quarantined in dim_policy, so their policy_key has no match. They do not
    affect Page 2 (no policy slicing) but in a production warehouse they
    should cascade to quarantine, not load with an orphan key.
  * dq_row_counts rows_loaded counts rows that passed source validation.
    rows_in_model is lower for claims and payments because children of
    quarantined policies were held back as well. Reconciliation Difference
    uses rows_read - loaded - quarantined - dropped and is 0 for every table.
  * The client crosswalk (duplicate -> survivor) is intentionally NOT in this
    pack; keep it in PostgreSQL behind access control.
  * dq_anomaly_log has no original/corrected value columns; add them from
    your own pipeline if you need the full correction audit.
  * Quarantine resolution rate reads 0% on a first load - that is correct.
