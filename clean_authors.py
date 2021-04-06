import argparse
from collections import Counter
from google.cloud import bigquery
import csv


def clean_authors(frame):
    """
    Cleaning the authors field from Lexis Nexis for a particular set of articles selected based on its rhetorical frame.
    :param frame: the rhetorical frame
    :return:
    """
    author_counts = Counter()
    query = f"""SELECT
                  LOWER(author) as author,
                  COUNT(DISTINCT duplicateGroupId) AS count
                FROM
                  `gcp-cset-projects.rhetorical_frames.{frame}`
                GROUP BY
                  author
                ORDER BY
                  2 DESC"""
    # Pass the project ID here in case it isn't set via environment variable
    client = bigquery.Client(project='gcp-cset-projects')
    query_job = client.query(query)
    authors = query_job.result()
    for author_pair in authors:
        if author_pair["author"] is None:
            author_counts.update({"No author information": author_pair["count"]})
            # we don't want to deal with Nones in any other situations
            continue
        temp_author = author_pair["author"].replace(", cnn", "").replace(", inc", "").replace(" and ", "; ")
        temp_author = temp_author.replace(", ", "; ").replace("by ", "").replace(" staff writer", "")
        temp_author = temp_author.replace(" staff", "").replace(" correspondent", "")
        temp_author = temp_author.replace("- with contributions ", "").replace("(", "").replace(")", "")
        temp_author = temp_author.replace("forbes councils member", "")
        if "; " in temp_author:
            new_authors = temp_author.split(";")
            author_counts.update({i.strip(): author_pair["count"] for i in new_authors})
        else:
            author_counts.update({temp_author.strip(): author_pair["count"]})
    return author_counts


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("frame", type=str, help="The frame whose authors you want to clean up.")
    parser.add_argument("output_file", type=str, help="A csv file for writing cleaned author data.")
    args = parser.parse_args()
    authors = clean_authors(args.frame)
    fieldnames = ["author", "count"]
    with open(args.output_file, "w") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for author, count in authors.most_common():
            js = {"author": author, "count": count}
            writer.writerow(js)


if __name__ == "__main__":
    main()
