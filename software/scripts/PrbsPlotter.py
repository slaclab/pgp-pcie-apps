from pickle import FALSE
from tokenize import Double
from mpl_toolkits import mplot3d

import matplotlib.pyplot as plt
import sqlite3
import argparse
import math
import numpy as np


# standard collection filters:
#lambda row: row[1]==19*5000

#standard display filters:
#

def plot3D(x, y, z):

    fig = plt.figure() 
    ax = plt.axes(projection='3d')

    ax.scatter3D(x, y, z, c=z, cmap='Greens')

    ax.set_xlabel('Rate')
    ax.set_ylabel('Packet Length')
    ax.set_zlabel('Bandwidth')

def calculateBandwidthError(packetLength, frameRate, bandwidth):
    return ((packetLength+1)*32)*frameRate/(bandwidth*1e6)

def queryData(db_con):
    # prep data base for query
    cur = db_con.cursor()
    statement = '''SELECT set_num_lanes, set_rate, set_packet_length, tx_bandwidth, tx_frame_rate, tx_bandwidth_max, tx_frame_rate_max, tx_bandwidth_min, tx_frame_rate_min, lane lane FROM raw_data'''

    # get data from data base
    ret = cur.execute(statement)
    return ret

def displayFromArrays(
    x, 
    y, 
    total, 
    tOffSet,
    yhigh,
    ylow,
    namer, 
    displayFilter, 
    displayMax,
    displayError
):

    colormap = plt.get_cmap('gist_rainbow')
    fig = plt.figure()
    ax = fig.add_subplot(111)
    ax.set_prop_cycle('color', plt.cm.Spectral(np.linspace(0,1,20)))
    
    # display all rows
    for sets in range(len(x)-1):
        if(displayFilter(y[sets], total[sets], sets)):
            if(not displayMax):
                plt.plot(x[sets], y[sets], 'o', linestyle = 'solid', label = namer(sets))
                if(displayError):
                    color = next(ax._get_lines.prop_cycler)['color']
                    plt.plot(x[sets], yhigh[sets], '1', markersize = 15, color = color)
                    plt.plot(x[sets], ylow[sets], '2', markersize = 15, color = color)
            else:
                plt.plot(tOffSet[sets], total[sets], 'o', linestyle = 'dashed', label = str(namer(sets)))

def collectDataVsFrameSize(
    rows, 
    dataIndex, 
    collectionFilter, 
    namer, 
    displayFilter, 
    displayMax, 
    displayError
):
    
        # initialize arrays
    xdata   = [[] for i in range(9)]
    ydata   = [[] for i in range(9)]
    yhigh   = [[] for i in range(9)]
    ylow    = [[] for i in range(9)]
    ytot    = [[] for i in range(9)]
    xtot    = [[] for i in range(9)]

    # collect data
    for rw in rows:
        if(collectionFilter(rw)):
            if(rw[9] == -1):
                ytot[rw[0]-1].append(rw[dataIndex])
                xtot[rw[0]-1].append(math.log2(rw[2]))
            elif(dataIndex == 5):
                xdata[rw[0]-1].append(math.log2(rw[2]))
                ydata[rw[0]-1].append(calculateBandwidthError(rw[2], rw[4], rw[3])/rw[0])
                
            else:
                xdata[rw[0]-1].append(math.log2(rw[2]))
                ydata[rw[0]-1].append(rw[dataIndex])
                
                yhigh[rw[0]-1].append(rw[dataIndex+2])
                ylow[rw[0]-1].append(rw[dataIndex+4])
                
                

    # display data            
    displayFromArrays(xdata, ydata, ytot, xtot, yhigh, ylow, namer, displayFilter, displayMax, displayError) 

    # set x axis label
    plt.xlabel("log2 of frame size") 

def collectDataVsVc(
    rows, 
    dataIndex, 
    collectionFilter, 
    namer, 
    displayFilter, 
    displayMax, 
    displayError
):
    
    # initialize arrays
    xdata = [[]*20 for i in range(20)]
    ydata = [[]*20 for i in range(20)]
    yhigh = [[]*20 for i in range(20)]
    ylow = [[]*20 for i in range(20)]
    tot = [[]*7 for i in range(20)]
    xtotals = [[1, 2, 3, 4, 5, 6, 7, 8] for i in range(20)]

    # collect data
    for rw in rows:
        if(collectionFilter(rw)):
            if(rw[9] == -1):
                tot[int(math.log2(rw[2]))-1].append(rw[dataIndex])
                
            else:
                xdata[int(math.log2(rw[2]))-1].append(rw[0])
                ydata[int(math.log2(rw[2]))-1].append(rw[dataIndex])
                
                yhigh[int(math.log2(rw[2]))-1].append(rw[dataIndex+2])
                ylow[int(math.log2(rw[2]))-1].append(rw[dataIndex+4])

    # display data            
    displayFromArrays(xdata, ydata, tot, xtotals, yhigh, ylow, namer, displayFilter, displayMax, displayError) 

    # set x axis label
    plt.xlabel("Active Channels")

def plotData(
    db_con, 
    funcSelect, 
    dataIndex, 
    displayMax, 
    collectionFilter = lambda row: True, 
    displayFilter = lambda val, maxi, index: True, 
    namer = lambda num: 2**(num+1), 
    legendTitle = 'Frame size in words',
    displayError = False
):

    # query sql data base
    rows = queryData(db_con)

    # collect and dispaly data
    if(funcSelect == 1):
        collectDataVsVc(rows, dataIndex, collectionFilter, namer, displayFilter, displayMax, displayError)
    elif(funcSelect == 2):
        collectDataVsFrameSize(rows, dataIndex, collectionFilter, namer, displayFilter, displayMax, displayError)
    else:
        print("invalid function selection")
    
    # set y axis label
    if(dataIndex == 3):
        ylabel = "Bandwidth"
    elif(dataIndex == 4):
        ylabel = "Frame Rate"
    else:
        ylabel = "Unknown"

    if(displayMax):
        ylabel = "Aggregate " + ylabel
    plt.ylabel(ylabel)
    
    # create legend
    legend = plt.legend(title = legendTitle, loc = 'upper right')
    


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
    default  = 4,
    help     = "3 for bandwidth, 4 for frame rate",
)


# Get the arguments
args = parser.parse_args()

# connect to data base
db_con = sqlite3.connect("test6")

# collect and plot data
#plotBwVsNumVc(db_con, args.dataIndex, True)



# show plot
#plt.show()