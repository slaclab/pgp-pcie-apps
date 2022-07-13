from mpl_toolkits import mplot3d

import numpy as np
import matplotlib.pyplot as plt
import sqlite3
import os

from pathlib import Path

fig = plt.figure() 
ax = plt.axes(projection='3d')

zdata = 15 * np.random.random(100)
xdata = np.sin(zdata) + 0.1 * np.random.randn(100)
ydata = np.cos(zdata) + 0.1 * np.random.randn(100)
ax.scatter3D(xdata, ydata, zdata, c=zdata, cmap='Greens');


db_con = sqlite3.connect("~/pgp-pcie-apps/software/scripts/test3")
cur = db_con.cursor()
statement = '''SELECT * FROM raw_data'''

cur.execute(statement)
rows = cur.fetchall()
print(rows[0:5])
plt.show()