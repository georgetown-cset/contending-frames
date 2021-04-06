import matplotlib
import matplotlib.pyplot as plt
import csv
import os
import argparse
import matplotlib.font_manager as font_manager
from matplotlib.ticker import PercentFormatter
import numpy as np

frames = {"economic_gold_rush": 0,
          "world_without_work": 1,
          "killer_robots": 2,
          "competition": 3}


def read_data(input_csv, percent):
    """
    Putting the csv data in the right format to be charted.
    Also extract the frame names and convert our results to percents if we need to
    :param input_csv: The input csv file
    :param percent: Flag for using percentages instead of counts
    :return:
    """
    x = []
    y = []
    frame = input_csv.split("/")[-1].split("-")[0]
    for line in csv.DictReader(open(input_csv, encoding="latin1")):
        x.append(int(line["year"]))
        if percent:
            y.append(float(line["percent"]) * 100)
        else:
            y.append(int(line["count"]))
    return x, y, frame


def plot_data(x, all_y, percent, frame_data, font_path, output_file):
    """
    Plotting the data! We are making subplots over time
    :param x: The time values
    :param all_y: Since we're doing subplots, we have multiple ys. This is an array of them.
    :param percent: Flag for using percentages instead of counts
    :param frame_data: Each frame, in order
    :param font_path: The path to the Roboto font on your system
    :param output_file: The name of the file to store the chart in
    :return:
    """
    # CSET standard colors
    print(font_path)
    colors = ["#003DA6", "#7AC4A5", "#B53A6D", "#F17F4C", "0B1F41", "#63676B"]
    # We have to reference Roboto in a weird way in Python
    # We install it on our system and then into our venv. Anyoneax.xaxis.set_major_locator(MaxNLocator(nbins=4, integer=True)) who runs this will have to provide their own font_path
    prop = font_manager.FontProperties(fname=font_path, size=15)
    # Making subplots
    fig, axs = plt.subplots(1, len(all_y), sharey=True, figsize=(13, 9))
    frame_names = [" ".join(i.split("_")).upper() for i in frame_data]
    # Setting up our subplots
    for index, ax in enumerate(axs):
        # Plotting our lines in the correct colors
        ax.plot(x, all_y[index], color=colors[frames[frame_data[index]]], marker="o")
        ax.grid(which="major")
        # We're specifying the years, which is not great
        # But it's the only way I know to get this alternating year showing/being hidden
        # While still showing the grid and showing the exact years we want
        # Which is what we need if we want to make the font big enough
        ax.set_xticks(np.arange(2012, 2021, 2))
        ax.set_xticklabels([2012, None, 2016, None, 2020], fontdict={'fontsize': 14})
        ax.set_yticklabels(all_y[index], fontsize=14)
        # Set labels CSET grey
        ax.xaxis.label.set_color(colors[5])
        ax.yaxis.label.set_color(colors[5])
        # We only want left ticks for the first chart
        if index != 0:
            ax.tick_params(axis='x', colors=colors[5], size=14, left=False)
            ax.tick_params(axis='y', colors=colors[5], size=14, left=False)
        else:
            ax.tick_params(axis='x', colors=colors[5], size=16)
            ax.tick_params(axis='y', colors=colors[5], size=16)
        # Each x axis gets a label
        ax.set_xlabel(frame_names[index], size=13)
        # Set the y values to percentages if we're doing that
        if percent:
            ax.yaxis.set_major_formatter(PercentFormatter())
    plt.xticks(fontproperties=prop)
    plt.yticks(fontproperties=prop)
    # This is kind of a hack, but we also want a major x-axis label and we want it centered
    # So we're going to make a full-sized subplot and hide everything on it but the label!
    ax = fig.add_subplot(111, frameon=False)
    ax.set_xlabel("YEAR", labelpad=32, fontproperties=prop, color=colors[5], size=18)
    plt.tick_params(labelcolor='none', top=False, bottom=False, left=False, right=False)
    if percent:
        ax.yaxis.set_major_formatter(PercentFormatter())
        ax.set_ylabel("PERCENT OF AI ARTICLES", labelpad=26, fontproperties=prop, color=colors[5], size=18)
    else:
        ax.set_ylabel("ARTICLE COUNT", labelpad=26, fontproperties=prop, color=colors[5], size=18)
    plt.savefig(output_file)
    plt.show()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_dir", type=str, help="The directory of csvs with the by year data.")
    parser.add_argument("output_file", type=str, help="An output file name to write the chart to.")
    parser.add_argument("font_path", type=str, help="The path on your system to the Roboto font.")
    parser.add_argument("-p", "--percent", action="store_true",
                        help="If percent rather than raw counts, use this flag.")
    args = parser.parse_args()
    csvs = os.listdir(args.input_dir)
    # reorder csvs so our charts are all in the same order
    # Again, this is not the prettiest way to do this, but it lets us put all the csvs in one directory
    # Instead of having to pass each of them separately as a command line argument
    new_csvs = [i for i in csvs if "economic" in i]
    new_csvs.extend([i for i in csvs if "world" in i])
    new_csvs.extend([i for i in csvs if "killer" in i])
    new_csvs.extend([i for i in csvs if "competition" in i])
    all_y = []
    frame_data = []
    for i in new_csvs:
        x, y, frame = read_data(os.path.join(args.input_dir, i), args.percent)
        all_y.append(y)
        frame_data.append(frame)
    # Note: suggested font_path looks like:
    # "...../rhetorical-frame-queries/venv/lib/python3.<version>/site-packages/matplotlib/mpl-data/fonts/ttf/Roboto-Regular.ttf"
    plot_data(x, all_y, args.percent, frame_data, args.font_path, args.output_file)


if __name__ == "__main__":
    main()
