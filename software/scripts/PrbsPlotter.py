from mpl_toolkits import mplot3d

import numpy as np
import matplotlib.pyplot as plt
import sqlite3
import os

from pathlib import Path

fig = plt.figure() 
ax = plt.axes(projection='3d')

zdata = []
xdata = []
ydata = []

db_con = sqlite3.connect("test3")
cur = db_con.cursor()
statement = '''SELECT set_num_lanes, set_rate, set_packet_length, tx_bandwidth FROM raw_data'''

cur.execute(statement)
rows = cur.fetchall()

for rw in rows:
    if(rw[0]==1):
        print(rw)
        xdata.append(rw[1]*5000)
        ydata.append(2**rw[2])
        zdata.append(rw[3])


ax.scatter3D(xdata, ydata, zdata, c=zdata, cmap='Greens');

ax.set_xlabel('Rate')
ax.set_ylabel('Packet Length')
ax.set_zlabel('Bandwidth')

plt.show()