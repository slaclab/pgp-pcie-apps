##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'PGP PCIe APP DEV', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

# Setup environment
source /afs/slac/g/reseng/rogue/pre-release/setup_rogue.csh
#source /u/re/ruckman/projects/rogue/setup_env.csh


# Python Package directories
setenv SURF_DIR ${PWD}/../firmware/submodules/surf/python
setenv PCIE_DIR ${PWD}/../firmware/submodules/axi-pcie-core/python

# Setup python path
setenv PYTHONPATH ${PWD}/python:${SURF_DIR}:${PCIE_DIR}:${PYTHONPATH}
