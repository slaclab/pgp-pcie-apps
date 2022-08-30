from pickle import FALSE
from tokenize import Double
from mpl_toolkits import mplot3d

import matplotlib.pyplot as plt
import sqlite3
import argparse
import math
import numpy as np


##############################
# uses the set packet length
# to determine the actual
# bandwidth and compares it to
# the measured bandwidth
##############################
def calculateBwFrRatio(frameRate, bandwidth):
    return bandwidth/frameRate

##############################
# takes a list of dicts and 
# and creates a dict at a given
# index if non already exists
############################## 
def prepDicts(index, dicts):

    # iterate through dicts
    for d in dicts:

        # check if index is already set
        if index not in d:
            d[index] = {}

##############################
# query all the data from the
# SQLite3 database
##############################
def queryData(db_con):

    # prep database for query
    cur = db_con.cursor()
    statement = '''SELECT set_num_lanes, set_num_vc, set_packet_length, tx_bandwidth, tx_frame_rate, tx_bandwidth_max, tx_frame_rate_max, tx_bandwidth_min, tx_frame_rate_min, lane, channel FROM raw_data'''

    # get data from database
    ret = cur.execute(statement)
    
    return ret

##############################
# determines which display
# function, and data set to use
##############################
def flowSelect(
    data, 
    aggregate, 
    barData, 
    barAggregate, 
    yHigh, 
    yLow, 
    namer, 
    displayMax, 
    displayError, 
    graphType
    ):
    
    # select which data set to use
    passedData = aggregate if(displayMax) else data
    
    # select which display function to use
    if(graphType == 'scatter'):
        
        passedData = aggregate if(displayMax) else data
        displayFromDictsScatter(
            data = passedData, 
            yhigh = yHigh, 
            ylow = yLow, 
            namer = namer, 
            displayError = displayError, 
            colorCount = len(passedData)
            ) 
        
    elif(graphType == 'bar'):

        passedData = barAggregate if(displayMax) else barData
        displayFromDictsBar(
            data = passedData, 
            namer = namer, 
            colorCount = len(passedData)
            ) 
        
    else:
        print("invalid graph type")
    
##############################
# uses data sets in dicts to
# generate a bar graph
##############################
def displayFromDictsBar(
    data, 
    namer, 
    colorCount
):

    # create color map
    colormap = plt.get_cmap('gist_rainbow')

    # generate unique colors for all data points
    fig = plt.figure()
    ax = fig.add_subplot(111)
    ax.set_prop_cycle('color', plt.cm.Spectral(np.linspace(0,1,colorCount)))
    
    # initialize spacer and set bar width
    spacer = 0
    width = .05
    
    # display data points
    for sets in data: 
        
        # arrange data by total number of active channels
        sortedData = dict(sorted(data[sets].items(), key=lambda k: k[0][0]*k[0][1]))
        
        # prep x-axis for plotting
        xaxis = np.arange(len(sortedData))
                    
        # plot data with bars side by side and not overlapping
        plt.bar(xaxis+width*(spacer - len(data)/2), list(sortedData.values()), width = width, label = namer(sets))

        # increment spacer
        spacer +=1
    
        # label x-axis
        plt.xticks(np.arange(len(sortedData)), sortedData.keys())
                
##############################
# uses data sets in dicts to
# generate a scatter plot
##############################    
def displayFromDictsScatter(
    data, 
    yhigh,
    ylow,
    namer, 
    displayError,
    colorCount
):

    # create color map
    colormap = plt.get_cmap('gist_rainbow')

    # generate unique colors for all data points
    fig = plt.figure()
    ax = fig.add_subplot(111)
    ax.set_prop_cycle('color', plt.cm.Spectral(np.linspace(0,1,colorCount)))
    
    # display all data points
    for sets in data: 
        plt.plot(list(data[sets].keys()), list(data[sets].values()), 'o', linestyle = 'solid', label = namer(sets))

        # check if error needs to be displayed
        if(displayError):
            color = next(ax._get_lines.prop_cycler)['color']
            plt.plot(list(data[sets].keys()), list(yhigh[sets].values()), '1', markersize = 15, color = color)
            plt.plot(list(data[sets].keys()), list(ylow[sets].values()), '2', markersize = 15, color = color)
                    
##############################
# collects and prepares data
# from a SQLite3 database.
# X-axis is the log2(frameSize)
##############################
def collectDataVsFrameSize(
    rows, 
    dataIndex, 
    collectionFilter, 
    namer, 
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

        # determine indicies for data
        indexA = (rw[0], rw[1])
        indexB = math.log2(rw[2])

        # filter data
        if(collectionFilter(rw)):

            prepDicts(indexA,[data, tot, yhigh, ylow])
            
            # check if current row is an aggregate
            if(rw[9] == -1):
                tot[indexA][indexB] = rw[dataIndex]

            elif(dataIndex == 5):
                # store special error
                data[indexA][indexB] = calculateBandwidthError(rw[2], rw[4], rw[3])
                
            else:
                # store data
                data[indexA][indexB] = rw[dataIndex]
                
                yhigh[indexA][indexB] = rw[dataIndex+2]
                ylow[indexA][indexB] = rw[dataIndex+4]
                
                

    # display data 
    flowSelect(
        data = data, 
        aggregate = tot, 
        barData =barData, 
        barAggregate = barTot, 
        yHigh = yhigh, 
        yLow = ylow, 
        namer = namer, 
        displayMax = displayMax, 
        displayError= displayError, 
        graphType = graphType
        )

    # set x axis label
    plt.xlabel("frame size in words") 

##############################
# collects and prepares data
# from a SQLite3 database.
# X-axis is the number of
# active channels
##############################
def collectDataVsVc(
    rows, 
    dataIndex, 
    collectionFilter, 
    namer, 
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

        # determine indicies for data
        indexA = (int(math.log2(rw[2])))
        indexB = (rw[0], rw[1])
        indexC = rw[0]*rw[1]

        # filter data
        if(collectionFilter(rw)):

            prepDicts(indexA,[data, tot])
            prepDicts(indexA,[barData, barTot])

            # check if current row is an aggregate and collect data
            
            if(rw[9] == -1 and dataIndex != 5):
                barTot[indexA][indexB] = rw[dataIndex]
                tot[indexA][indexC] = rw[dataIndex]
                
            elif dataIndex == 5:
                    barData[indexA][indexB] = rw[4]/rw[3]
                    data[indexA][indexC] = rw[4]/rw[3]
                
            else:
                barData[indexA][indexB] = rw[dataIndex]
                data[indexA][indexC] = rw[dataIndex]
                
                #yhigh[index].append(rw[dataIndex+2])
                #ylow[index].append(rw[dataIndex+4])

    # display data
    flowSelect(
        data = data, 
        aggregate = tot, 
        barData = barData, 
        barAggregate = barTot, 
        yHigh = yhigh, 
        yLow = ylow, 
        namer = namer, 
        displayMax = displayMax, 
        displayError = displayError, 
        graphType = graphType
    )

    # set x axis label
    plt.xlabel("(Active Lanes, Active Channels)")

##############################
# reads data from SQLite3 data
# base file, plots the data,
# and prepares the plots for
# being displayed
##############################
def plotData(
    db_con, 
    funcSelect, 
    dataIndex, 
    displayAggregate, 
    collectionFilter = lambda row: True, 
    namer = lambda num: 2**(num+1), 
    legendTitle = 'Frame size in words',
    displayError = False,
    graphType = 'scatter',
    legendLoc = 'upper right'
):

    # query sql database
    rows = list(queryData(db_con))
    
    #for rw in range(len(rows)):
        #r = list(rows[rw])
        #r[1] = int(math.log2(r[1]))
        #rows[rw] = tuple(r)

    
    # collect and display data
    if(funcSelect == 1):
        collectDataVsVc(rows, dataIndex, collectionFilter, namer, displayAggregate, displayError, graphType)
    elif(funcSelect == 2):
        collectDataVsFrameSize(rows, dataIndex, collectionFilter, namer, displayAggregate, displayError, graphType)
    else:
        print("invalid function selection")
    
    # set y axis label
    if(dataIndex == 3):
        ylabel = "Bandwidth (Mbps)"
    elif(dataIndex == 4):
        ylabel = "Frame Rate (Hz)"
    else:
        ylabel = "Unknown"

    if(displayAggregate):
        ylabel = "Aggregate " + ylabel
    plt.ylabel(ylabel)
    
    # create legend
    legend = plt.legend(title = legendTitle, loc = legendLoc)