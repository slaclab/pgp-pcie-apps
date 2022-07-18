from pickle import FALSE
from tokenize import Double
from mpl_toolkits import mplot3d

import matplotlib.pyplot as plt
import sqlite3
import argparse
import math

def plot3D(x, y, z):

    fig = plt.figure() 
    ax = plt.axes(projection='3d')

    ax.scatter3D(x, y, z, c=z, cmap='Greens')

    ax.set_xlabel('Rate')
    ax.set_ylabel('Packet Length')
    ax.set_zlabel('Bandwidth')

def queryData(db_con):
    # prep data base for query
    cur = db_con.cursor()
    statement = '''SELECT set_num_lanes, set_rate, set_packet_length, tx_bandwidth, tx_frame_rate, iteration_num, lane FROM raw_data'''

    # get data from data base
    ret = cur.execute(statement)
    return ret

def displayFromArrays(x, y, total, tOffSet, namer, displayFilter):

    # display all rows
    for sets in range(len(x)-1):
        if(displayFilter(y[sets], total[sets])):
            plt.plot(x[sets], y[sets], 'o', linestyle = 'solid', label = namer(sets))
            plt.plot(tOffSet, total[sets], 'o', color = 'red', linestyle = 'dashed', label = str(namer(sets))+ " max")

    # create legend
    legend = plt.legend(loc = 'best')

def plotBwVsNumVc(db_con, dataIndex = 3, collectionFilter = lambda index: index==19*5000, displayFilter = lambda val, max: True, namer = lambda num: 2**(num+1)):

    # query sql data base
    rows = queryData(db_con)

    # initialize arrays
    xdata = [[]*20 for i in range(20)]
    ydata = [[]*20 for i in range(20)]
    tot = [[]*7 for i in range(20)]
    xtotals = [1.1, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1]

    # collect data
    for rw in rows:
        if(collectionFilter(rw[1])):
            if(rw[6] == -1):
                tot[int(math.log2(rw[2]))-1].append(rw[dataIndex])
                print(rw)
                print("")
            else:
                xdata[int(math.log2(rw[2]))-1].append(rw[0])
                ydata[int(math.log2(rw[2]))-1].append(rw[dataIndex])
                print(rw)
        else:
            print(rw[1]/5000)

    # display data            
    displayFromArrays(xdata, ydata, tot, xtotals, namer, displayFilter)    



# Set the argument parser
parser = argparse.ArgumentParser()

parser.add_argument(
    "--lowerBound",
    "-l",
    type     = int,
    required = False,
    default  = 0,
    help     = "lower bound for plot range",
)

parser.add_argument(
    "--upperBound",
    "-u",
    type     = int,
    required = False,
    default  = 1,
    help     = "upper bound for number of plots",
)

parser.add_argument(
    "--dataIndex",
    "-i",
    type     = int,
    required = False,
    default  = 3,
    help     = "3 for bandwidth, 4 for frame rate",
)


# Get the arguments
args = parser.parse_args()

# connect to data base
db_con = sqlite3.connect("test5")

# collect and plot data
plotBwVsNumVc(db_con, args.dataIndex)

# set axis labels

if(args.dataIndex == 3):
    ylabel = "Bandwidth"
elif(args.dataIndex == 4):
    ylabel = "Frame Rate"
else:
    ylabel = "Unknown"

plt.ylabel(ylabel)
plt.xlabel("Active Channels")

# show plot
plt.show()