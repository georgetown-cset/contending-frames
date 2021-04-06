import matplotlib
import matplotlib.pyplot as plt
import csv
import argparse
import matplotlib.font_manager as font_manager
from matplotlib.ticker import PercentFormatter

def read_data(input_csv, percent):
    """
    Putting the csv data in the right format to be charted.
    Also convert our results to percents if we need to.
    :param input_csv: The input csv containing our data
    :param percent: Is the data representing a percentage?
    :return:
    """
    labels = []
    nums = []
    for line in csv.DictReader(open(input_csv, encoding="latin1")):
        labels.append(line["frame"])
        if percent:
            nums.append(float(line["percent"])*100)
        else:
            nums.append(int(line["count"]))
    labels[0] = "Economic\nGold Rush"
    labels[1] = "World Without\nWork"
    return labels, nums


def make_chart(labels, nums, percent, font_path, output_file):
    """
    Make our bar chart
    :param labels: The labels for each bar
    :param nums: The heights of each bar
    :param percent: Is the bar representing a percentage?
    :param font_path: The path to the Roboto font. This should be in our venv.
    :param output_file: The file we want to store our chart in
    :return:
    """
    # CSET standard colors
    colors = ["#003DA6", "#7AC4A5", "#B53A6D", "#F17F4C", "#0B1F41"]
    # The color for the labels, CSET grey
    label_color = "#63676B"
    prop = font_manager.FontProperties(fname=font_path, size=16)
    # We're hardcoding our figure size so everything fits nicely
    plt.figure(figsize=(9, 8))
    ax = plt.axes()
    # Making the bar chart. We don't want bars that are quite as thick as the default.
    plt.bar(labels, nums, color=colors, width=0.6)
    # Setting our font for the ticks and labels
    plt.xticks(fontproperties=prop)
    plt.yticks(fontproperties=prop)
    plt.xlabel("FRAME", fontproperties=prop)
    # Setting the numbers to percents if we're using them.
    if percent:
        plt.ylabel("PERCENT OF ARTICLES", fontproperties=prop)
        ax.yaxis.set_major_formatter(PercentFormatter())
    else:
        plt.ylabel("COUNT OF ARTICLES", fontproperties=prop)
    # Setting our label colors
    ax.xaxis.label.set_color(label_color)
    ax.yaxis.label.set_color(label_color)
    ax.tick_params(axis='x', colors=label_color)
    ax.tick_params(axis='y', colors=label_color)
    plt.savefig(output_file)
    plt.show()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input_csv", type=str, help="The csv with the data.")
    parser.add_argument("output_file", type=str, help="An output file name to write the chart to.")
    parser.add_argument("font_path", type=str, help="The path on your system to the Roboto font.")
    parser.add_argument("-p", "--percent", action="store_true", help="If percent rather than raw counts, use this flag.")
    args = parser.parse_args()
    labels, nums = read_data(args.input_csv, args.percent)
    make_chart(labels, nums, args.percent, args.font_path, args.output_file)

if __name__ == "__main__":
    main()