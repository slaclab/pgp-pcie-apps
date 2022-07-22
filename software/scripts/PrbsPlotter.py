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
    return ((packetLength+1)*32*8)*frameRate/(bandwidth*1e6)

def prepDicts(index, dicts):
    for d in dicts:
        if index not in d:
            d[index] = []

def queryData(db_con):
    # prep data base for query
    cur = db_con.cursor()
    statement = '''SELECT set_num_lanes, set_num_vc, set_packet_length, tx_bandwidth, tx_frame_rate, tx_bandwidth_max, tx_frame_rate_max, tx_bandwidth_min, tx_frame_rate_min, lane FROM raw_data'''

    # get data from data base
    ret = cur.execute(statement)
    return ret

def displayFromDicts(
    x, 
    y, 
    total, 
    tOffSet,
    yhigh,
    ylow,
    namer, 
    displayFilter, 
    displayMax,
    displayError,
    colorCount
):

    colormap = plt.get_cmap('gist_rainbow')
    fig = plt.figure()
    ax = fig.add_subplot(111)
    ax.set_prop_cycle('color', plt.cm.Spectral(np.linspace(0,1,colorCount)))
    
    # display all rows
    for sets in x:
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
    
    # initialize dicts
    xdata   = {}
    ydata   = {}
    yhigh   = {}
    ylow    = {}
    ytot    = {}
    xtot    = {}

    # collect data
    for rw in rows:

        index = (rw[0], rw[1])

        if(collectionFilter(rw)):

            prepDicts(index,[xdata, ydata, yhigh, ylow, ytot, xtot])

            if(rw[9] == -1):
                ytot[index].append(rw[dataIndex])
                xtot[index].append(math.log2(rw[2]))

            elif(dataIndex == 5):
                xdata[index].append(math.log2(rw[2]))
                ydata[index].append(calculateBandwidthError(rw[2], rw[4], rw[3]))
                
            else:
                xdata[index].append(math.log2(rw[2]))
                ydata[index].append(rw[dataIndex])
                
                yhigh[index].append(rw[dataIndex+2])
                ylow[index].append(rw[dataIndex+4])
                
                

    # display data            
    displayFromDicts(xdata, ydata, ytot, xtot, yhigh, ylow, namer, displayFilter, displayMax, displayError, 8) 

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
    
    # initialize dicts
    xdata   = {}
    ydata   = {}
    yhigh   = {}
    ylow    = {}
    ytot    = {}
    xtot    = {}


    # collect data
    for rw in rows:

        index = (int(math.log2(rw[2]))-1)

        if(collectionFilter(rw)):

            prepDicts(index,[xdata, ydata, yhigh, ylow, ytot, xtot])

            if(rw[9] == -1):
                ytot[index].append(rw[dataIndex])
                xtot[index].append((rw[0], rw[1]))
                
            else:
                xdata[index].append(rw[0])
                ydata[index].append(rw[dataIndex])
                
                yhigh[index].append(rw[dataIndex+2])
                ylow[index].append(rw[dataIndex+4])

    # display data            
    displayFromDicts(xdata, ydata, ytot, xtot, yhigh, ylow, namer, displayFilter, displayMax, displayError, 20) 

    # set x axis label
    plt.xlabel("Active Channels")

def plotData(
    db_con, 
    funcSelect, 
    dataIndex, 
    displayAggregate, 
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
        collectDataVsVc(rows, dataIndex, collectionFilter, namer, displayFilter, displayAggregate, displayError)
    elif(funcSelect == 2):
        collectDataVsFrameSize(rows, dataIndex, collectionFilter, namer, displayFilter, displayAggregate, displayError)
    else:
        print("invalid function selection")
    
    # set y axis label
    if(dataIndex == 3):
        ylabel = "Bandwidth"
    elif(dataIndex == 4):
        ylabel = "Frame Rate"
    else:
        ylabel = "Unknown"

    if(displayAggregate):
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
db_con = sqlite3.connect("test7")

# collect and plot data
#plotBwVsNumVc(db_con, args.dataIndex, True)



# show plot
#plt.show()