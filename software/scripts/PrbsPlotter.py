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

def calculateExpectedRate(bandwidth, packetLength):
    return 0 #channels*lanes/((packetLength+1)4e-9) #not if bandwidth cap is reached

def prepDicts(index, dicts):
    for d in dicts:
        if index not in d:
            d[index] = {}

def queryData(db_con):
    # prep data base for query
    cur = db_con.cursor()
    statement = '''SELECT set_num_lanes, set_num_vc, set_packet_length, tx_bandwidth, tx_frame_rate, tx_bandwidth_max, tx_frame_rate_max, tx_bandwidth_min, tx_frame_rate_min, lane, channel FROM raw_data'''

    # get data from data base
    ret = cur.execute(statement)
    return ret

def flowSelect(data, aggregate, barData, barAggregate, yHigh, yLow, namer, displayFilter, displayMax, displayError, graphType):
    
    passedData = aggregate if(displayMax) else data
    
    # display data 
    if(graphType == 'scatter'):
        
        passedData = aggregate if(displayMax) else data
        displayFromDictsScatter(passedData, yHigh, yLow, namer, displayError, len(passedData)) 
        
    elif(graphType == 'bar'):
        passedData = barAggregate if(displayMax) else barData
        displayFromDictsBar(passedData, namer, len(passedData)) 
        
    else:
        print("invalid graph type")
    
    

def displayFromDictsBar(
    data, 
    namer, 
    colorCount
):

    colormap = plt.get_cmap('gist_rainbow')
    fig = plt.figure()
    ax = fig.add_subplot(111)
    ax.set_prop_cycle('color', plt.cm.Spectral(np.linspace(0,1,colorCount)))
    
    spacer = 0
    width = .05
    
    # display all rows
    for sets in data: 
        
        sortedData = dict(sorted(data[sets].items(), key=lambda k: k[0][0]*k[0][1]))
        
        xaxis = np.arange(len(sortedData))
                    
        plt.bar(xaxis+width*(spacer - len(data)/2), list(sortedData.values()), width = width, label = namer(sets))

        spacer +=1
    
        plt.xticks(np.arange(len(sortedData)), sortedData.keys())
                
        
    
                
def displayFromDictsScatter(
    data, 
    yhigh,
    ylow,
    namer, 
    displayError,
    colorCount
):

    colormap = plt.get_cmap('gist_rainbow')
    fig = plt.figure()
    ax = fig.add_subplot(111)
    ax.set_prop_cycle('color', plt.cm.Spectral(np.linspace(0,1,colorCount)))
    
    # display all rows
    for sets in data:            
        plt.plot(list(data[sets].keys()), list(data[sets].values()), 'o', linestyle = 'solid', label = namer(sets))

        if(displayError):
            color = next(ax._get_lines.prop_cycler)['color']
            plt.plot(list(data[sets].keys()), list(yhigh[sets].values()), '1', markersize = 15, color = color)
            plt.plot(list(data[sets].keys()), list(ylow[sets].values()), '2', markersize = 15, color = color)
                    

def collectDataVsFrameSize(
    rows, 
    dataIndex, 
    collectionFilter, 
    namer, 
    displayFilter, 
    displayMax, 
    displayError,
    graphType
):
    
    # initialize dicts
    data    = {}
    tot     = {}
    barData = {}
    barTot  = {}
    
    yhigh   = {}
    ylow    = {}

    # collect data
    for rw in rows:

        indexA = math.log2(rw[2])
        indexB = (rw[0], rw[1])

        if(collectionFilter(rw)):

            prepDicts(indexB,[data, tot, yhigh, ylow])
            
            if(rw[9] == -1):
                tot[indexB][indexA] = rw[dataIndex]

            elif(dataIndex == 5):
                data[indexB][indexA] = calculateBandwidthError(rw[2], rw[4], rw[3])
                
            else:
                data[indexB][indexA] = rw[dataIndex]
                
                yhigh[indexB][indexA] = rw[dataIndex+2]
                ylow[indexB][indexA] = rw[dataIndex+4]
                
                

    # display data 
    flowSelect(data, tot, barData, barTot, yhigh, ylow, namer, displayFilter, displayMax, displayError, graphType)

    # set x axis label
    plt.xlabel("log2 of frame size") 

def collectDataVsVc(
    rows, 
    dataIndex, 
    collectionFilter, 
    namer, 
    displayFilter, 
    displayMax, 
    displayError,
    graphType
):
    
    # initialize dicts
    data    = {}
    tot     = {}
    barData = {}
    barTot  = {}
    
    yhigh   = {}
    ylow    = {}
    


    # collect data
    for rw in rows:

        indexA = (int(math.log2(rw[2])))
        indexB = (rw[0], rw[1])

        if(collectionFilter(rw)):

            prepDicts(indexB,[data, tot])
            prepDicts(indexA,[barData, barTot])

            if(rw[9] == -1):
                barTot[indexA][indexB] = rw[dataIndex]
                tot[indexB][indexA] = rw[dataIndex]
                
            else:
                barData[indexA][indexB] = rw[dataIndex]
                data[indexB][indexA] = rw[dataIndex]
                
                #yhigh[index].append(rw[dataIndex+2])
                #ylow[index].append(rw[dataIndex+4])

    flowSelect(data, tot, barData, barTot, yhigh, ylow, namer, displayFilter, displayMax, displayError, graphType)

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
    displayError = False,
    graphType = 'scatter'
):

    # query sql data base
    rows = queryData(db_con)

    # collect and display data
    if(funcSelect == 1):
        collectDataVsVc(rows, dataIndex, collectionFilter, namer, displayFilter, displayAggregate, displayError, graphType)
    elif(funcSelect == 2):
        collectDataVsFrameSize(rows, dataIndex, collectionFilter, namer, displayFilter, displayAggregate, displayError, graphType)
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