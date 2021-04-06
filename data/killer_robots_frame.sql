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
    REGEXP_CONTAINS(LOWER(text), r'(lethal.?autonomous.?weapons?)') AS lethal_aut_weapons,
    REGEXP_CONTAINS(LOWER(text), r'(fully.?autonomous.?weapons?)') AS fully_aut_weapons,
    REGEXP_CONTAINS(LOWER(text), r'(slaughterbots?)') AS slaughterbots,
    REGEXP_CONTAINS(LOWER(text), r'(international.?humanitarian.?law)') AS intl_human_law,
    REGEXP_CONTAINS(LOWER(text), r'(laws?.?of.?war)') AS laws_of_war,
    REGEXP_CONTAINS(LOWER(text), r'(killer.?robots?)') AS killer_robots,
    REGEXP_CONTAINS(LOWER(text), r'(meaningful.?human.?control)') AS meaningful_human_control,
    REGEXP_CONTAINS(LOWER(text), r'(retaining.?human.?control)') AS retaining_human_control,
    REGEXP_CONTAINS(LOWER(text), r'(campaign to stop killer robots?)') AS campaign_stop_killer_bots,
    REGEXP_CONTAINS(LOWER(text), r'(international committee for robot arms control)') AS intl_committee_robot_arms_cntl,
    REGEXP_CONTAINS(LOWER(text), r'(threat.?to.?humanity)') AS threat_to_human,
    REGEXP_CONTAINS(LOWER(text), r'(martens clause)') AS martens_clause,
    REGEXP_CONTAINS(LOWER(text), r'(convention on conventional weapons)') AS convent_con_weapons,
    REGEXP_CONTAINS(LOWER(text), r'(autonomy)') AS autonomy,
    REGEXP_CONTAINS(LOWER(text), r'(semi.?autonomous weapons?.?systems)') AS semi_aut_weapons,
    REGEXP_CONTAINS(LOWER(text), r'(autonomous.?weapons?)') AS aut_weapon,
    REGEXP_CONTAINS(LOWER(text), r'(dod directive 3000.?09)') AS dod_directive,
    REGEXP_CONTAINS(LOWER(text), r'(existential.?risk)') AS existential_risk,
    REGEXP_CONTAINS(LOWER(text), r'(prohibition.{0,20}\bai\b)') AS prohibition_ai,
    REGEXP_CONTAINS(LOWER(text), r'(\bai\b.{0,20}prohibition)') AS ai_prohibition,
    REGEXP_CONTAINS(LOWER(text), r'(\bban\b.{0,20}\bai\b)') AS ban_ai,
    REGEXP_CONTAINS(LOWER(text), r'(\bai\b.{0,20}\bban\b)') AS ai_ban,
    text
  from ln
  -- Require a mention of AI somewhere
  where regexp_contains(ln.text, r"\bai\b|artificial intelligence\b")
),
hits as (
  -- Select docs with matches from the analytic corpus
  select *
  from keywords
  where 
    lethal_aut_weapons
    or fully_aut_weapons  
    or slaughterbots
    or keywords.intl_human_law
    or keywords.laws_of_war 
    or keywords.killer_robots  
    or keywords.meaningful_human_control 
    or keywords.retaining_human_control 
    or keywords.campaign_stop_killer_bots 
    or keywords.intl_committee_robot_arms_cntl 
    or keywords.threat_to_human 
    or keywords.martens_clause 
    or keywords.convent_con_weapons 
    or keywords.aut_weapon
    or keywords.dod_directive 
    or keywords.existential_risk
)
select
 -- Summarize the results
  title,
  url,
  source_category,
  editorialRank,
  (lethal_aut_weapons or fully_aut_weapons or aut_weapon) as weapons,
  (slaughterbots or killer_robots) as robots,
  (intl_human_law or intl_committee_robot_arms_cntl or martens_clause or convent_con_weapons or laws_of_war) as intl_law,
  (meaningful_human_control or retaining_human_control) as human_control,
  (existential_risk or threat_to_human) as threat,
  campaign_stop_killer_bots,
  dod_directive,
from hits
