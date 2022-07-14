from mpl_toolkits import mplot3d

import numpy as np
import matplotlib.pyplot as plt
import sqlite3
import os
import argparse
import random

from pathlib import Path



def plot3D(x, y, z):

    fig = plt.figure() 
    ax = plt.axes(projection='3d')

    ax.scatter3D(x, y, z, c=z, cmap='Greens')

    ax.set_xlabel('Rate')
    ax.set_ylabel('Packet Length')
    ax.set_zlabel('Bandwidth')

def plot2D(x, y, args):
    ax = plt.subplots(20)

    print(len(x))
    print(len(y))
    print(len(ax))

    for dist in range(args.lowerBound, args.upperBound):
        print(dist)
        ax[dist][0].plot(x[dist], y[dist], 'o', color = 'black')
        ax[dist][0].set_title(f'set length: {(2**(dist))}')
            
        

    plt.plot(x, y, 'o', color = 'black')

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
xdata = [[]]*20
ydata = [[]]*20
x = []
y = []

db_con = sqlite3.connect("test3")
cur = db_con.cursor()
statement = '''SELECT set_num_lanes, set_rate, set_packet_length, tx_bandwidth, tx_frame_rate FROM raw_data'''

cur.execute(statement)
rows = cur.fetchall()

for rw in rows:
    if(rw[1]==19):
        print(rw)
        xdata[rw[2]].append(rw[0])
        ydata[rw[2]].append(random.randint(0,100))
        if rw[2] == 19:
            x.append(random.randrange(0,100))
            y.append(rw[4])
        zdata.append(rw[2])
print(xdata)
print(ydata)

plot2D(xdata, ydata, args)
#plt.plot(x, y, 'o', color = 'black')
plt.show()