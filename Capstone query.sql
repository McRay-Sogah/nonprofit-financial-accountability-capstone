SELECT *
FROM `capstone-mcray.irs_990_capstone.form990_2024_raw`
LIMIT 10;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT ein) AS org_count,
  MIN(tax_pd) AS min_period,
  MAX(tax_pd) AS max_period
FROM `capstone-mcray.irs_990_capstone.form990_2024_raw`;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

CREATE OR REPLACE VIEW
  `capstone-mcray.irs_990_capstone.form990_2024_analysis_view`
AS
SELECT
  ein                                   AS organization_ein,
  tax_pd                                AS tax_period,
  efile                                 AS electronic_filer,

  -- Revenue
  totrevenue                            AS total_revenue,
  totprgmrevnue                         AS program_service_revenue,
  invstmntinc                           AS investment_income,
  grsincfndrsng                         AS gross_fundraising_income,
  netincfndrsng                         AS net_fundraising_income,

  -- Expenses
  totfuncexpns                          AS total_functional_expenses,
  profndraising                         AS fundraising_expenses,
  feesforsrvcmgmt                       AS management_fees,
  accntingfees                          AS accounting_fees,
  legalfees                             AS legal_fees,
  othrsalwages                          AS other_salaries_wages,
  payrolltx                             AS payroll_taxes,

  -- Assets & Stability
  totassetsend                          AS total_assets_end_of_year,
  totliabend                            AS total_liabilities_end_of_year,
  totnetassetend                        AS total_net_assets_end_of_year

FROM `capstone-mcray.irs_990_capstone.form990_2024_raw`
WHERE
  totfuncexpns > 0
  AND totrevenue > 0;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

CREATE OR REPLACE VIEW
  `capstone-mcray.irs_990_capstone.form990_2024_metrics_view` AS

-- This query calculates key nonprofit accountability and decision-making metrics
-- using cleaned IRS Form 990 financial data.

SELECT

  tax_period,
  -- tax_period groups organizations by filing year so we can compare trends over time

  COUNT(DISTINCT organization_ein) AS number_of_organizations,
  -- Counts unique nonprofits filing in each tax period (Sample size)


  -- =========================
  -- SPENDING ACCOUNTABILITY
  -- =========================

  AVG(
    (
      total_functional_expenses
      - (management_fees + accounting_fees + legal_fees)
      - fundraising_expenses
    )
    / NULLIF(total_functional_expenses, 0)
  ) AS avg_program_expense_ratio,
  -- Proportion of expenses directed toward mission-related activities (Mission focus)


  AVG(
    (management_fees + accounting_fees + legal_fees)
    / NULLIF(total_functional_expenses, 0)
  ) AS avg_administrative_expense_ratio,
  -- Administrative and governance burden (Overhead)


  AVG(
    fundraising_expenses
    / NULLIF(total_functional_expenses, 0)
  ) AS avg_fundraising_expense_ratio,
  -- Cost of raising funds (Cost of fundraising)


  -- =========================
  -- FINANCIAL SUSTAINABILITY
  -- =========================

  AVG(
    (total_revenue - total_functional_expenses)
    / NULLIF(total_revenue, 0)
  ) AS avg_operating_margin,
  -- Surplus or deficit relative to revenue (Surplus / deficit)


  AVG(
    total_assets_end_of_year
    / NULLIF(total_functional_expenses, 0)
  ) AS avg_asset_coverage_ratio
  -- Ability to cover expenses with existing assets (Financial resilience)


FROM `capstone-mcray.irs_990_capstone.form990_2024_analysis_view`

-- =========================
-- DATA QUALITY FILTERS
-- =========================
WHERE
  total_functional_expenses > 0
  AND total_revenue > 0

-- =========================
-- AGGREGATION LEVEL
-- =========================
GROUP BY tax_period
ORDER BY tax_period;


-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

SELECT *
FROM `capstone-mcray.irs_990_capstone.form990_2024_metrics_view`;


