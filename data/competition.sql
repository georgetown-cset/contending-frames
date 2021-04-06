with ln as (
  -- Select analytic corpus
  select
    duplicateGroupId,
    title,
    subTitle,
    content,
    source.category as source_category,
    source.editorialRank as editorialRank,
    extract(year from publishedDate) as year,
    source.name as source_name,
    url,
    entities.properties as semantic_info,
    author.name as author,
    trim(lower(coalesce(title, "") || " " || coalesce(subTitle, "") || " " || coalesce(content, ""))) as text
  from gcp_cset_lexisnexis.raw_news, UNNEST(semantics.entities) as entities
  where
    extract(year from publishedDate) >= 2012
    and extract(year from publishedDate) <= 2020
    and (source.category = 'Press Wire'
       or source.category = 'National'
       or source.category = 'Trade')
    -- Exclude rank 3 here in an attempt to cut down on low-quality hits
    and source.editorialRank in (1, 2)
    and language = 'English'
    and source.location.country = 'United States'
),
keywords as (
  -- Add columns indicating whether text matched various patterns
  select
    duplicateGroupId,
    source_category,
    editorialRank,
    year,
    source_name,
    author,
    semantic_info,
    -- We'll require a mention of AI *somewhere* in the text for these keywords, but it can be anywhere
    regexp_contains(ln.text, r"\bsputnik\b") as sputnik,
    regexp_contains(ln.text, r"\bforeign adversar\w*\b") as foreign_adversary,
    -- These keywords can follow or precede a mention of AI within a given number of characters
    regexp_contains(ln.text, r"\b(ai|artificial intelligence).{0,20}arms race\b")
      or regexp_contains(ln.text, r"\barms race.{0,20}\b(ai|artificial intelligence)\b")
        as arms_race,
    regexp_contains(ln.text, r"\b(ai|artificial intelligence)\b.{0,20}(battl\w*|compet\w*|conflict|rival\w*|war)\b")
      or regexp_contains(ln.text, r"\b(battl\w*|compet\w*|conflict|rival\w*|war).{0,20}\b(ai|artificial intelligence)\b")
        as conflict,
    regexp_contains(ln.text, r"\b(ai|artificial intelligence)\b.{0,20}(dominance|domination|supremacy|superiority)\b")
      or regexp_contains(ln.text, r"\b(dominance|domination|supremacy|superiority).{0,20}\b(ai|artificial intelligence)\b")
        as dominance,
    regexp_contains(ln.text, r"\b(ai|artificial intelligence)\b.{0,20}strategic advantage\b")
      or regexp_contains(ln.text, r"\bstrategic advantage.{0,20}\b(ai|artificial intelligence)\b")
        as strategic_advantage,
    regexp_contains(ln.text, r"\b(ai|artificial intelligence)\b.{0,20}(outpac\w*|overtak\w*)\b")
      or regexp_contains(ln.text, r"\b(outpac\w*|overtak\w*).{0,20}\b(ai|artificial intelligence)\b") as outpace,
    regexp_contains(ln.text, r"\b(america|united states|u\.s\.|usa|china|chinese|beijing|taiwan|taiwanese|korea|russia|moscow|india|pakistan|iran|ally|allies|nato)\b")
      as has_country_reference,
    -- PR Newswire is a high-frequency source of hits; possibly of false positives too
    lower(source_name) in ('pr newswire', 'prweb newswire', 'prweb') as is_pr_newswire,
    text
  from ln
  -- Require a mention of AI somewhere
  where regexp_contains(ln.text, r"\b(ai|artificial intelligence)\b")
  -- Exclude some false positives
    -- Book reviews
    and source_name not like '%Publisher\'s Weekly%'
    and text not like '%indiebound.org%'
    -- A closing paragraph about DIU mission provides the competition keywords here
    and text not like 'defense innovation unit selects google cloud to help u.s. military health system with predictive cancer diagnoses%'
    -- This isn't EN
    and text not like 'in ucraina si torna a sparare%'
    -- Congressional testimony per se isn't mass media
    and source_name != 'CQ Congressional Testimony'
    -- These articles aren't in English
    and source_name != 'International Business Times Italy'
)
-- Select docs with matches
select *
from keywords
where
  sputnik
  or foreign_adversary
  or arms_race
  or conflict
  or dominance
  or strategic_advantage
  or outpace
