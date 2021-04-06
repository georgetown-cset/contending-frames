-- Creating a new, smaller table with only economic gold rush frame articles and the columns of interest
create or replace table rhetorical_frames.economic_gold_rush as
with ln as (
  -- Select analytic corpus
  select
    id,
    -- This lets us deduplicate articles that are almost identical but published multiple places etc.
    duplicateGroupId,
    title,
    subTitle,
    content,
    matchingKeywords,
    -- NER info
    entities.properties as semantic_info,
    -- Author data
    author.name as author,
    extract(year from publishedDate) as year,
    -- The publisher/source
    source.name as source_name,
    url,
    lower(coalesce(title, "") || " " || coalesce(subTitle, "") || " " || coalesce(content, "")) as text
  from gcp_cset_lexisnexis.raw_news, UNNEST(semantics.entities) as entities
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
    id,
    duplicateGroupId,
    title,
    url,
    author,
    matchingKeywords,
    semantic_info,
    year,
    source_name,
    REGEXP_CONTAINS(LOWER(text), r'(14.?trillion.?boost)') AS num_trillion_boost,
    REGEXP_CONTAINS(LOWER(text), r'(fourteen.?trillion.?boost)') AS fourteen_trillion_boost,
    REGEXP_CONTAINS(LOWER(text), r'(transform.?economy)') AS transform_economy,
    REGEXP_CONTAINS(LOWER(text), r'(biggest.?commercial.?opportunity)') AS biggest_commercial_opportunity,
    REGEXP_CONTAINS(LOWER(text), r'(ai.?revolution)') AS ai_revolution,
    REGEXP_CONTAINS(LOWER(text), r'(total.?economic.?gains?)') AS total_economic_gains,
    REGEXP_CONTAINS(LOWER(text), r'(golden.?opportunity)') AS golden_opportunity,
    REGEXP_CONTAINS(LOWER(text), r'(cumulative.?gdp)') AS cumulative_gdp,
    REGEXP_CONTAINS(LOWER(text), r'(global.?economic.?activity)') AS global_economic_activity,
    REGEXP_CONTAINS(LOWER(text), r'(higher.?productivity.?growth)') AS higher_productivity_growth,
    REGEXP_CONTAINS(LOWER(text), r'(productivity.?dividend)') AS productivity_dividend,
    REGEXP_CONTAINS(LOWER(text), r'(positive.?contribution)') AS positive_contribution,
    REGEXP_CONTAINS(LOWER(text), r'(productivity.?leap)') AS productivity_leap,
    REGEXP_CONTAINS(LOWER(text), r'(labor.?productivity.?improvement)') AS labor_prod_improvement,
    REGEXP_CONTAINS(LOWER(text), r'(opportunity.{0,20}\bai\b)') AS opportunity_ai,
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
    num_trillion_boost
    or fourteen_trillion_boost
    or transform_economy
    or biggest_commercial_opportunity
    or ai_revolution
    or total_economic_gains
    or golden_opportunity
    or cumulative_gdp
    or global_economic_activity
    or higher_productivity_growth
    or productivity_dividend
    or productivity_leap
    or positive_contribution
    or labor_prod_improvement
    or opportunity_ai
)
select
 -- Save off the results
  id,
  duplicateGroupId,
  title,
  url,
  year,
  source_name,
  author,
  semantic_info
from hits