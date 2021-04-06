-- Creating a new table with all artificial intelligence articles and the columns of interest
create or replace table rhetorical_frames.artificial_intelligence as
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
  -- Filter only articles containing AI or artificial intelligence
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
    text
  from ln
  -- Require a mention of AI somewhere
  where regexp_contains(ln.text, r"\bai\b|artificial intelligence\b")
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
from keywords