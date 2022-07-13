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
    fig, ax = plt.subplots(5, 1)

    

    for dist in range(4):
        plt.subplot(4,1, dist+1)
        plt.plot(x[15+dist], y[15+dist], 'o', color = 'black')
        #plt.set_title(f'set length: {(2**(15+dist))}')

            
        

    plt.plot(x, y, 'o', color = 'black')

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
    if(rw[1]==19 and rw[2]==19):
        print(rw)
        xdata[rw[2]].append(rw[0])
        ydata[rw[2]].append(rw[4])
        if rw[2] == 19:
            x.append(rw[0])
            y.append(rw[4])
        zdata.append(rw[2])
print(xdata)
print(ydata)

plot2D(xdata, ydata, zdata)
#plt.plot(x, y, 'o', color = 'black')
plt.show()