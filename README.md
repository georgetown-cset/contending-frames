# Contending Frames

This repo contains replication code for "Contending Frames: Evaluating Rhetorical Dynamics in AI."

The main results can be found [here](analysis/Results.xlsx).

## Queries 

Below are two examples of building the results for a frame.

### Economic Gold Rush

1. Identify articles of interest: [economic_gold_rush_frame.sql](data/economic_gold_rush_frame.sql)

2. Store relevant data for articles of interest: [saving_economic_gold_rush_frame_data.sql](data/saving_economic_gold_rush_frame_data.sql)

3. Count articles by year: [economic_gold_rush_counts_by_year.sql](data/economic_gold_rush_counts_by_year.sql)

4. Count articles by author: [economic_gold_rush_counts_by_author.sql](data/economic_gold_rush_counts_by_author.sql)

5. Count articles by source/publisher: [economic_gold_rush_counts_by_source.sql](data/economic_gold_rush_counts_by_source.sql)

6. Count people mentioned in articles by numbers of articles they're mentioned in: [economic_gold_rush_counts_by_person_mentions.sql](data/economic_gold_rush_counts_by_person_mentions.sql)

7. Count companies and organizations mentioned in articles by numbers of articles they're mentioned in: [economic_gold_rush_counts_by_organization_mentions.sql](data/economic_gold_rush_counts_by_organization_mentions.sql)

### Competition 

Run `main.py`. Step (1) above is run from Python using [competition.sql](data/competition.sql) and the remainder 
using the queries defined in `main.py`, borrowed from the corresponding queries above. Output is written to 
[analysis](analysis). 

## Cleaning up Authors

Set up a Python environment:

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Then run code as follows:

`python3 clean_authors.py <frame_name> <output_csv>`

For example, if you want to clean the authors field for the economic gold
rush frame, run as follows:

`python3 clean_authors.py economic_gold_rush output.csv`

