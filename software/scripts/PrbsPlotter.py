from pickle import FALSE
from mpl_toolkits import mplot3d

import numpy as np
import matplotlib.pyplot as plt
import sqlite3
import os
import argparse
import random
import math

from pathlib import Path

def plot3D(x, y, z):

    fig = plt.figure() 
    ax = plt.axes(projection='3d')

    ax.scatter3D(x, y, z, c=z, cmap='Greens')

    ax.set_xlabel('Rate')
    ax.set_ylabel('Packet Length')
    ax.set_zlabel('Bandwidth')

def plotHzVsNumVc(db_con, args):
    #fig, ax = plt.subplots(args.upperBound-args.lowerBound)

    # prep data base for query
    cur = db_con.cursor()
    statement = '''SELECT set_num_lanes, set_rate, set_packet_length, tx_bandwidth, tx_frame_rate FROM raw_data'''

    # get data from data base
    cur.execute(statement)
    rows = cur.fetchall()

    # initialize arrays
    xdata = [[]*20 for i in range(20)]
    ydata = [[]*20 for i in range(20)]
    ytotal = [[]*7 for i in range(20)]
    bwtot = [[]*7 for i in range(20)]
    #yexpected = [[0]*7 for i in range(20)]
    xtotals = [1.1, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1]

    # collect data
    for rw in rows:
        if(rw[1]==19):
            if(rw[6] == -1):
                ytotal[rw[2]].append(rw[4])
                bwtot[rw[2]].append(rw[3])
            else:
                print(rw)
                xdata[rw[2]].append(rw[0])
                ydata[rw[2]].append(rw[4])
            
           # yexpected[rw[2]][rw[0]-1] += 48e9/((2**rw[2])*rw[0])

    for sets in range(20):
        skip = False
        for bw in range(len(bwtot[sets])):
            
            if(bwtot[sets][bw] > 48000):
                skip = True

        if(not skip):
            plt.plot(xdata[sets], ydata[sets], 'o', linestyle = 'solid', label = (sets+1))
            plt.plot(xtotals, ytotal[sets], 'o', color = 'red', linestyle = 'dashed', label = (sets+1))
        else:
            print("skipping:\n")
            print(ydata[sets])
            print("because bandwidth = ")
            print(bwtot[sets])
        #plt.plot(xtotals, yexpected[sets], 'o', color = 'blue', linestyle = 'dashed', label = (sets+1))
    legend = plt.legend(loc = 'best')

    # plot data
    for dist in range(args.lowerBound, args.upperBound):
        print(xdata[dist])
        print(ydata[dist])
        print("")
        #ax[dist-args.lowerBound].set_xlabel('Active # of VC')
        #ax[dist-args.lowerBound].set_ylabel('Hz')
        #ax[dist-args.lowerBound].plot(xdata[dist], ydata[dist], 'o', color = 'black', linestyle = 'solid')
        #ax[dist-args.lowerBound].set_title(f'set length: {(2**(dist))}')
        #ax[dist-args.lowerBound].plot(xtotals, ytotal[dist], 'o', color = 'red', linestyle = 'solid')
        

def plotBwVsNumVc(db_con, args):
    #fig, ax = plt.subplots(args.upperBound-args.lowerBound)

    # prep data base for query
    cur = db_con.cursor()
    statement = '''SELECT set_num_lanes, set_rate, set_packet_length, tx_bandwidth, tx_frame_rate, iteration_num, lane FROM raw_data'''

    # get data from data base
    cur.execute(statement)
    rows = cur.fetchall()

    # initialize arrays
    xdata = [[]*20 for i in range(20)]
    ydata = [[]*20 for i in range(20)]
    bwtot = [[]*7 for i in range(20)]
    xtotals = [1.1, 2.1, 3.1, 4.1, 5.1, 6.1, 7.1, 8.1]

    # collect data
    for rw in rows:
        if(rw[1]==19):
            if(rw[6] == -1):
                bwtot[math.log2(rw[2])].append(rw[3])
            else:
                print(rw)
                xdata[math.log2(rw[2])].append(rw[0])
                ydata[math.log2(rw[2])].append(rw[3])
                

    for sets in range(20):
        plt.plot(xdata[sets], ydata[sets], 'o', linestyle = 'solid', label = (sets+1))
        plt.plot(xtotals, bwtot[sets], 'o', color = 'red', linestyle = 'dashed', label = (sets+1))
        #plt.plot(xtotals, yexpected[sets], 'o', color = 'blue', linestyle = 'dashed', label = (sets+1))
    legend = plt.legend(loc = 'best')

    # plot data
    for dist in range(args.lowerBound, args.upperBound):
        print(xdata[dist])
        print(ydata[dist])
        print("")

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

# Get the arguments
args = parser.parse_args()

zdata = []

db_con = sqlite3.connect("test5")

plotBwVsNumVc(db_con, args)

plt.show()