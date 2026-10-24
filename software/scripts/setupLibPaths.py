##############################################################################
## This file is part of 'PGP PCIe APP DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'PGP PCIe APP DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################
import pyrogue as pr
import os

# This file lives in <top_level>/software/scripts/
top_level = os.path.realpath(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', '..'))

pr.addLibraryPath(os.path.join(top_level, 'firmware/submodules/axi-pcie-core/python'))
pr.addLibraryPath(os.path.join(top_level, 'firmware/submodules/surf/python'))
pr.addLibraryPath(os.path.join(top_level, 'firmware/python'))
