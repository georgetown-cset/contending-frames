with ln as (
  -- Select analytic corpus
  select
    title,
    subTitle,
    content,
    source.category as source_category,
    source.editorialRank as editorialRank,
    matchingKeywords,
    extract(year from publishedDate) as year,
    source.name as source_name,
    url,
    lower(coalesce(title, "") || " " || coalesce(subTitle, "") || " " || coalesce(content, "")) as text
  from gcp_cset_lexisnexis.raw_news
  where
    extract(year from publishedDate) >= 2012
    and extract(year from publishedDate) <= 2020
    and (source.category = 'Press Wire'
       or source.category = 'National'
       or source.category = 'Trade')
    -- I excluded rank 3 here in an attempt to cut down on low-quality hits
    and source.editorialRank in (1, 2)
    and language = 'English'
    and source.location.country = 'United States'
),
keywords as (
  -- Add columns indicating whether text matched various patterns
  select
    title,
    url,
    source_category,
    editorialRank,
    matchingKeywords,
    year,
    source_name,
    REGEXP_CONTAINS(LOWER(text), r'(displace.{0,20}job.{0,20}\bai\b)') AS displace_job_ai,
    REGEXP_CONTAINS(LOWER(text), r'(\bai\b.{0,20}displace.*job)') AS ai_displace_job,
    REGEXP_CONTAINS(LOWER(text), r'(replace.{0,20}job.{0,20}\bai\b)') AS replace_job_ai,
    REGEXP_CONTAINS(LOWER(text), r'(\bai\b.{0,20}replace.{0,20}job)') AS ai_replace_job,
    REGEXP_CONTAINS(LOWER(text), r'(obsolete.{0,20}\bai\b)') AS obsolete_ai,
    REGEXP_CONTAINS(LOWER(text), r'(\bai\b.{0,20}obsolete)') AS ai_obsolete,
    REGEXP_CONTAINS(LOWER(text), r'(automation.{0,20}job)') AS automation_job,
    REGEXP_CONTAINS(LOWER(text), r'(automate.{0,20}job)') AS automate_job,
    REGEXP_CONTAINS(LOWER(text), r'(job.{0,20}automation)') AS job_automation,
    REGEXP_CONTAINS(LOWER(text), r'(job.{0,20}automate)') AS job_automate,
    REGEXP_CONTAINS(LOWER(text), r'(global useless class)') AS global_useless_class,
    REGEXP_CONTAINS(LOWER(text), r'(employment.?polarization)') AS employment_polarization,
    REGEXP_CONTAINS(LOWER(text), r'(livelihoods)') AS livelihoods,
    REGEXP_CONTAINS(LOWER(text), r'(compensation)') AS compensation,
    REGEXP_CONTAINS(LOWER(text), r'(mass joblessness)') AS mass_joblessness,
    REGEXP_CONTAINS(LOWER(text), r'(out of a job)') AS out_of_job,
    REGEXP_CONTAINS(LOWER(text), r'(robot apocalypse)') AS robot_apocalypse,
    REGEXP_CONTAINS(LOWER(text), r'(unemploy)') AS unemploy,
    REGEXP_CONTAINS(LOWER(text), r'(fourth.?industrial.?revolution)') AS fourth_industrial_revolution,
    REGEXP_CONTAINS(LOWER(text), r'(unions?)') AS unions,
    REGEXP_CONTAINS(LOWER(text), r'(jobless.?recovery)') AS jobless_recovery,
    REGEXP_CONTAINS(LOWER(text), r'(reskill)') AS reskill,
    REGEXP_CONTAINS(LOWER(text), r'(winners and losers)') AS winners_losers,
    REGEXP_CONTAINS(LOWER(text), r'(blue.?collar)') AS blue_collar,
    REGEXP_CONTAINS(LOWER(text), r'(white.?collar)') AS white_collar,
    REGEXP_CONTAINS(LOWER(text), r'(jobs.?eliminated)') AS jobs_eliminated,
    REGEXP_CONTAINS(LOWER(text), r'(steal.?jobs?)') AS steal_jobs,
    REGEXP_CONTAINS(LOWER(text), r'(coming for y?our job)') AS coming_for_job,
    REGEXP_CONTAINS(LOWER(text), r'(take y?our job)') AS take_job,
    REGEXP_CONTAINS(LOWER(text), r'(job killer)') AS job_killer,
    REGEXP_CONTAINS(LOWER(text), r'(threaten.{0,20}jobs?)') AS threaten_jobs,
    REGEXP_CONTAINS(LOWER(text), r'(job.{0,20}extinct)') AS job_extinct,
    text
  from ln
  -- Require a mention of AI somewhere
  where regexp_contains(lower(ln.text), r"\bai\b|artificial intelligence\b")
),
hits as (
  -- Select docs with matches from the analytic corpus
  select *
  from keywords
  where 
    keywords.global_useless_class 
    or keywords.employment_polarization 
    or keywords.take_job 
    or keywords.job_killer 
    or
    (keywords.displace_job_ai
    or keywords.ai_displace_job 
    or keywords.replace_job_ai 
    or keywords.ai_replace_job 
    or keywords.obsolete_ai 
    or keywords.ai_obsolete 
    or keywords.automation_job 
    or keywords.automate_job 
    or keywords.job_automation 
    or keywords.job_automate 
    or keywords.mass_joblessness 
    or keywords.out_of_job 
    or keywords.unemploy 
    or keywords.jobless_recovery 
    or keywords.jobs_eliminated 
    or keywords.steal_jobs 
    or keywords.threaten_jobs 
    or keywords.job_extinct 
    or keywords.coming_for_job)
    and (
    keywords.livelihoods 
    or keywords.compensation 
    or keywords.robot_apocalypse 
    or keywords.fourth_industrial_revolution 
    or keywords.reskill 
    or keywords.winners_losers 
    or keywords.blue_collar 
    or keywords.white_collar) 
)
select
 -- Summarize the results
  title,
  url,
  source_category,
  editorialRank,
  (global_useless_class or employment_polarization) as inequality,
  (take_job or job_killer) as job_killer,
  (displace_job_ai or ai_displace_job or ai_replace_job or replace_job_ai 
  or jobs_eliminated or job_extinct or out_of_job or unemploy) as job_loss,
  (obsolete_ai or ai_obsolete or automate_job or automation_job or job_automate or job_automation) as automation,
  (steal_jobs or threaten_jobs or coming_for_job) as steal_jobs,
  (mass_joblessness or jobless_recovery) as joblessness,
  (livelihoods or compensation) as career,
  reskill,
  (blue_collar or white_collar) as collar,
  robot_apocalypse,
  fourth_industrial_revolution as industrial_rev,
  winners_losers
from hits
