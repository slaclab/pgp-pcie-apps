# pgp-pcie-apps


<!--- ########################################################################################### -->

# Before you clone the GIT repository

1) Create a github account:
> https://github.com/

2) On the Linux machine that you will clone the github from, generate a SSH key (if not already done)
> https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

3) Add a new SSH key to your GitHub account
> https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/

4) Setup for large filesystems on github

```
$ git lfs install
```

5) Verify that you have git version 2.13.0 (or later) installed 

```
$ git version
git version 2.13.0
```

6) Verify that you have git-lfs version 2.1.1 (or later) installed 

```
$ git-lfs version
git-lfs/2.1.1
```

<!--- ########################################################################################### -->

# Clone the GIT repository
> $ git clone --recursive git@github.com:slaclab/pgp-pcie-apps

<!--- ########################################################################################### -->

# Example of How to build the firmware

In this example, we will build the pseudorandom binary sequence (PRBS) data generator on a Xilinx KCU1500 PCIe card.

1) Setup your Xilinx Vivado:

> If you are on the SLAC AFS network:

```
$ pgp-pcie-apps/firmware/setup_env_slac.csh
```

> Else you will need to install Vivado and install the Xilinx Licensing

2) Go to the firmware's target directory:

```
$ cd pgp-pcie-apps/firmware/targets/XilinxKcu1500PrbsTester
```

3) Build the firmware (two options available)

```
# Option#1: Build the firmware in batch mode
$ make

# Option#2: Build the firmware in GUI mode
$ make gui
```

Note: For more information about the firmware build system:

https://confluence.slac.stanford.edu/x/n4-jCg

<!--- ########################################################################################### -->
