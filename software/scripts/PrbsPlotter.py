from mpl_toolkits import mplot3d

import numpy as np
import matplotlib.pyplot as plt
import sqlite3
import os

from pathlib import Path



def plot3D(x, y, z):

    fig = plt.figure() 
    ax = plt.axes(projection='3d')

    ax.scatter3D(x, y, z, c=z, cmap='Greens')

    ax.set_xlabel('Rate')
    ax.set_ylabel('Packet Length')
    ax.set_zlabel('Bandwidth')

def plot2D(x, y, labels):
    fig = plt.figure() 
    fig, ax = plt.subplots(len(x))

    for dist in range(4):
        ax[dist].plot(x[dist], y[dist], 'o', color = 'black')
        ax[dist].set_title(f'set length: {(2**labels[dist])}')

            
        

    plt.plot(x, y, 'o', color = 'black')

zdata = []
xdata = [[]]*20
ydata = [[]]*20


db_con = sqlite3.connect("test3")
cur = db_con.cursor()
statement = '''SELECT set_num_lanes, set_rate, set_packet_length, tx_bandwidth, tx_frame_rate FROM raw_data'''

cur.execute(statement)
rows = cur.fetchall()

for rw in rows:
    if(True):
        print(rw)
        xdata[rw[2]].append(rw[0])
        ydata[rw[2]].append(rw[4])
        zdata.append(rw[2])


plot2D(xdata, ydata, zdata)

plt.show()