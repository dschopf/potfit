############################################################################
#
# potfit -- The ITAP Force Matching Program
#
# Copyright 2002-2010 Institute for Theoretical and Applied Physics,
# University of Stuttgart, D-70550 Stuttgart
#
############################################################################
#
#   This file is part of potfit.
#
#   potfit is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   potfit is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with potfit; if not, see http://www.gnu.org/licenses/.
#
############################################################################
#
# Beware: This Makefile works only with GNU make (gmake)!
#
# Usage:  make <target>
#
# <target> has the form
#
#    potfit[_<parallel>][_<option>[_<option>...]]
#
# The parallelization method <parallel> can be one of:
#
#    mpi   compile for parallel execution, using MPI
#    omp   compile for parallel execution, using OpenMP
#    ompi  compile for parallel execution, using OpenMP and MPI
#
###########################################################################
#
# Customizing this Makefile
#
# As potfit supports a large number of compile options, you will have to
# compile potfit freqently. Before doing so, however, you must check whether
# the settings in this Makefile fit your needs. You possibly have to
# customize these setttings. Before you can do that, we have to explain
# a bit how the compilation process works.
#
# The compilation process requires the environment variable IMDSYS to
# be set to a recognized value. It specifies what system you have, and
# what compiler you are using. The flags for the compiler and the linker
# are then selected as a function of this variable. It is also possible
# to pass the value of IMDSYS on the command line, e.g.:
#
#   make IMDSYS=x86_64-icc potfit_mpi_eam
#
# Another important ingredient is the parallelization method, which is
# determined from the make target. The parallelization method is stored
# in the variable PARALLEL, which takes as value one of SERIAL, MPI,
# OMP, OMPI, or PACX.
#
# Depending on the value of ${IMDSYS}, a number of variables must be
# set, from which everything else is constructed.
#
# CC_${PARALLEL} defines the compiler to be used for parallelization
# method ${PARALLEL}. If not defined, the parallelization method
# ${PARALLEL} is not available.
#
# BIN_DIR defines the directory where the potfit binary is put. Note that
# this directory must exist.
#
# MV defines the program used to move the potfit binary to ${BIN_DIR}.
# The default is mv, which is usually ok.
#
# The compilation options are stored in the variable CFLAGS.
# The initial value of CFLAGS is set to the variable FLAGS,
# which can be given on the command line as explained above for
# IMDSYS, although this is usually not necessary.
#
# If the option debug was specified, ${DEBUG_FLAGS} is then appended
# to ${CFLAGS}, otherwise ${OPT_FLAGS}. If the option prof was specified
# (for profiling), ${PROF_FLAGS} is also appended to ${CFLAGS}. However,
# before appending ${OPT_FLAGS} or ${DEBUG_FLAGS} to ${CFLAGS}, some
# parallelization specific flags are appended to them:
#
#   OPT_FLAGS   += ${${PARALLEL}_FLAGS} ${OPT_${PARALLEL}_FLAGS}
#   DEBUG_FLAGS += ${${PARALLEL}_FLAGS} ${DEBUG_${PARALLEL}_FLAGS}
#
# If any of these variables is not defined, it is assumed to be empty.
# This setup should provide sufficient flexibility to set one's favorite
# flags, depending on parallelization, profiling, and optimization/debugging.
#
# Similarly, the link libraries are stored in the variable LIBS,
# to which ${${PARALLEL}_LIBS} and possibly ${PROF_LIBS} (for profiling)
# is appended.
#
# You may have to change the setting for an existing value of IMDSYS.
# or you have to add support for a new value of IMDSYS. The latter is
# best done by using the folloing template for IMDSYS=sys-cc:
#
# ifeq (sys-cc,${IMDSYS})
#   CC_SERIAL		= serial-compiler
#   CC_OMP		= OpenMP-compiler
#   CC_MPI		= MPI-compiler
#   CC_OMPI		= OpenMP+MPI-compiler
#   OPT_FLAGS		+= generic flags for optimization
#   OPT_MPI_FLAGS	+= MPI-specific flags for optimization
#                          similar variables for other parallelizations
#   MPI_FLAGS		+= MPI-specific flags
#                          similar variables for other parallelizations
#   DEBUG_FLAGS		+= generic flags for debugging
#   DEBUG_MPI_FLAGS	+= MPI-specific flags for debugging
#                          similar variables for other parallelizations
#   PROF_FLAGS		+= flags for profiling
#   LIBS		+= generically needed libraries
#   MPI_LIBS		+= MPI-specific libraries
#                          similar variables for other parallelizations
#   PROF_LIBS		+= libraries for profiling
# endif
#
# Variables remaining empty need not be mentioned.

###########################################################################
#
#  Adjust these variables to your system
#
###########################################################################

# Currently the following systems are available:
# x86_64-icc  	64bit Intel Compiler
# x86_64-gcc    64bit GNU Compiler
# i386-icc 	32bit Intel Compiler
# i386-icc  	32bit GNU Compiler
SYSTEM 		= x86_64-icc

# This is the directory where the potfit binary will be moved to
BIN_DIR 	= ${HOME}/bin

# Base directory of your installation of the MKL
MKLDIR          = /common/linux/paket/intel/compiler-11.0/cc/mkl

###########################################################################
#
#  Defaults for some variables
#
###########################################################################

MV		= $(shell basename `which mv`)
STRIP 		= $(shell basename `which strip`)
LIBS		+= -lm
MPI_FLAGS	+= -DMPI
OMP_FLAGS	+= -DOMP
OMPI_FLAGS	+= -DMPI -DOMP
DEBUG_FLAGS	+= -DDEBUG
MKLPATH         = ${MKLDIR}/lib

###########################################################################
#
#  flags for 64bit
#
###########################################################################

ifeq (x86_64-icc,${SYSTEM})
  CC_SERIAL     = icc
  CC_MPI        = mpicc
  CC_OMP        = mpicc
  CC_OMPI       = mpicc
  MPICH_CC      = icc
  MPICH_CLINKER = icc
  OPT_FLAGS     += -fast
  MPI_FLAGS     +=
  OMP_FLAGS     += -openmp
  OMPI_FLAGS    += -openmp
  DEBUG_FLAGS   += -g -Wall -wd981 -wd1572
  PROF_FLAGS    += -prof_gen
  MPI_LIBS      +=
  LFLAGS        += -L${MKLPATH} ${MKLPATH}/libmkl_solver_lp64_sequential.a -Wl,--start-group 
  LFLAGS 	+= -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -Wl,--end-group -lpthread
# acml
#   ACMLPATH      = /common/linux/paket/acml3.5.0/gnu64
#   CINCLUDE     += -I$(ACMLPATH)/include
#   LD_LIBRARY_PATH +=':$(ACMLPATH)/lib:'
#   LIBS		:= $(ACMLPATH)/lib/libacml.a \
# 		   -L${ACMLPATH}/lib -lpthread -lacml -lg2c
# intel mkl
  MKLPATH       = ${MKLDIR}/lib/em64t/
  CINCLUDE      =  -I${MKLDIR}/include/
  export        MPICH_CC MPICH_CLINKER
endif


ifeq (x86_64-gcc,${SYSTEM})
  CC_SERIAL     = gcc
  CC_MPI        = mpicc
  CC_OMPI       = mpicc
  OMPI_CC 	= gcc
  MPICH_CLINKER = gcc
  OPT_FLAGS     += -O3 -march=native -Wno-unused -pipe
  DEBUG_FLAGS   += -g -O -Wall
  PROF_FLAGS    += -pg -g
  PROF_LIBS    += -pg -g
#  LFLAGS        +=  -static
#  ACMLPATH      = /common/linux/paket/acml4.2.0/gfortran64_mp
  MKLPATH       = ${MKLDIR}/lib/em64t/
#  CINCLUDE     += -I$(ACMLPATH)/include
  CINCLUDE      = -I${MKLDIR}/include
#   LD_LIBRARY_PATH +=':$(ACMLPATH)/lib:'
#  export        OMPI_MPICC # MPICH_CLINKER
#  export        LD_LIBRARY_PATH
# acml
#  LIBS		:= $(ACMLPATH)/lib/libacml_mp.a \
		   -L${ACMLPATH}/lib -lpthread -lacml_mp -lgfortran
# intel mkl
   LFLAGS        += -L${MKLPATH} ${MKLPATH}/libmkl_solver_ilp64_sequential.a -Wl,--start-group -lmkl_intel_lp64 -lmkl_sequential -lmkl_core -Wl,--end-group -lpthread
  #LIBS		+= ${MKLPATH}/libmkl_lapack.a ${MKLPATH}/libmkl_em64t.a \
		   -L${MKLPATH} -lguide -lpthread
  export        OMPI_CC MPICH_CLINKER
endif


###########################################################################
#
#  flags for 32bit
#
###########################################################################

ifeq (i386-icc,${SYSTEM})
  CC_SERIAL	= icc
  CC_OMP	= icc
  CC_MPI	= mpicc
  CC_OMPI	= mpicc
  MPICH_CC      = icc
  MPICH_CLINKER = icc
  OPT_FLAGS	+= -O -ip -tpp7 # -static
  OMP_FLAGS	+= -openmp
  OMPI_FLAGS	+= -openmp
  DEBUG_FLAGS	+= -g
  PROF_FLAGS	+= -prof_gen
  LIBS		+= ${MKLPATH}/libmkl_lapack.a ${MKLPATH}/libmkl_ia32.a \
		   -L${MKLPATH} -lguide -lpthread
  export        MPICH_CC MPICH_CLINKER
endif


ifeq (i386-gcc3,${SYSTEM})
  CC_SERIAL	= gcc
  CC_MPI	= mpicc
  MPICH_CC      = gcc
  MPICH_CLINKER = gcc
  OPT_FLAGS	+= -O -march=pentium4 # -static
  DEBUG_FLAGS	+= -g
  PROF_FLAGS	+= -g3 -pg
  LIBS		+= ${MKLPATH}/libmkl_lapack.a ${MKLPATH}/libmkl_ia32.a \
		   -L${MKLPATH} -lguide -lpthread
  export        MPICH_CC # MPICH_CLINKER
endif


###########################################################################
#
#  Parallelization method
#
###########################################################################

# default is serial
PARALLEL = SERIAL
# MPI
ifneq (,$(strip $(findstring mpi,${MAKETARGET})))
PARALLEL = MPI
endif
# OpenMP
ifneq (,$(strip $(findstring omp,${MAKETARGET})))
PARALLEL = OMP
endif
# MPI + OpenMP
ifneq (,$(strip $(findstring ompi,${MAKETARGET})))
PARALLEL = OMPI
endif


###########################################################################
#
#  Compiler, flags, libraries
#
###########################################################################

# compiler; if empty, we issue an error later
CC = ${CC_${PARALLEL}}

# optimization flags
OPT_FLAGS   += ${${PARALLEL}_FLAGS} ${OPT_${PARALLEL}_FLAGS}
DEBUG_FLAGS += ${${PARALLEL}_FLAGS} ${DEBUG_${PARALLEL}_FLAGS}

# libraries
LIBS += ${${PARALLEL}_LIBS}

# optimization or debug
CFLAGS := ${FLAGS}
ifneq (,$(findstring debug,${MAKETARGET}))
CFLAGS += ${DEBUG_FLAGS}
else
CFLAGS += ${OPT_FLAGS}
endif

# profiling support
ifneq (,$(findstring prof,${MAKETARGET}))
CFLAGS += ${PROF_FLAGS}
LIBS   += ${PROF_LIBS}
endif


###########################################################################
#
# potfit sources
#
###########################################################################

POTFITHDR   	= potfit.h powell_lsq.h utils.h
POTFITSRC 	= utils.c bracket.c powell_lsq.c brent.c \
		  linmin.c config.c param.c potential.c \
		  potfit.c splines.c simann.c random.c

ifneq (,$(strip $(findstring pair,${MAKETARGET})))
POTFITSRC      += force_pair.c
endif

ifneq (,$(strip $(findstring eam,${MAKETARGET})))
POTFITSRC      += force_eam.c rescale.c
endif

ifneq (,$(strip $(findstring adp,${MAKETARGET})))
POTFITSRC      += force_adp.c
endif

ifneq (,$(strip $(findstring apot,${MAKETARGET})))
POTFITSRC      += functions.c chempot.c
endif

ifneq (,$(strip $(findstring evo,${MAKETARGET})))
POTFITSRC      += diff_evo.c
endif

MPISRC          = mpi_utils.c

#########################################################
#
# potfit Configuration rules
#
#########################################################

HEADERS := ${POTFITHDR}

# serial or mpi
ifneq (,$(strip $(findstring mpi,${MAKETARGET})))
SOURCES	:= ${POTFITSRC} ${MPISRC}
else
SOURCES	:= ${POTFITSRC}
endif

###  INTERACTIONS  #######################################

INTERACTION = 0

# PAIR
ifneq (,$(findstring pair,${MAKETARGET}))
CFLAGS += -DPAIR
INTERACTION = 1
endif

# EAM
ifneq (,$(strip $(findstring eam,${MAKETARGET})))
  ifneq (,$(findstring 1,${INTERACTION}))
  ERROR += More than one potential model specified
  endif
CFLAGS  += -DEAM
INTERACTION = 1
endif

# ADP
ifneq (,$(strip $(findstring adp,${MAKETARGET})))
  ifneq (,$(findstring 1,${INTERACTION}))
  ERROR += More than one potential model specified
  endif
  ifeq (,$(strip $(findstring apot,${MAKETARGET})))
    ERROR += ADP does not support tabulated potentials (yet)
  endif
  CFLAGS  += -DADP
INTERACTION = 1
endif

ifneq (,$(findstring 0,${INTERACTION}))
ERROR += No interaction model specified
endif

# EVO - for differential evolution
ifneq (,$(findstring evo,${MAKETARGET}))
CFLAGS += -DEVO
endif

# APOT - for analytic potentials
ifneq (,$(findstring apot,${MAKETARGET}))
CFLAGS += -DAPOT -DNORESCALE
endif

# Forces (only used for debugging)
ifneq (,$(findstring forces,${MAKETARGET}))
CFLAGS += -DFORCES
endif

# Stress
ifneq (,$(findstring stress,${MAKETARGET}))
CFLAGS += -DSTRESS
endif

# Disable gauge punishments for EAM/ADP
ifneq (,$(findstring nopunish,${MAKETARGET}))
CFLAGS += -DNOPUNISH
endif

ifneq (,$(findstring limit,${MAKETARGET}))
WARNING += "limit is now mandatory -- "
endif

ifneq (,$(findstring parab,${MAKETARGET}))
CFLAGS += -DPARABEL
endif

ifneq (,$(findstring wzero,${MAKETARGET}))
CFLAGS += -DWZERO
endif

ifneq (,$(findstring dist,${MAKETARGET}))
ifeq (,$(findstring MPI,${PARALLEL}))
CFLAGS += -DPDIST
else
ERROR += "dist is not mpi parallelized -- "
endif
endif

ifneq (,$(findstring newscale,${MAKETARGET}))
ifeq (,$(findstring MPI,${PARALLEL}))
CFLAGS += -DNEWSCALE
else
ERROR += "newscale is not mpi parallelized -- "
endif
endif

ifneq (,$(findstring fweight,${MAKETARGET}))
CFLAGS += -DFWEIGHT
endif

ifneq (,$(findstring acml,${MAKETARGET}))
CFLAGS += -DACML
endif

ifneq (,$(findstring noresc,${MAKETARGET}))
CFLAGS += -DNORESCALE
endif

# Substitute .o for .c to get the names of the object files
OBJECTS := $(subst .c,.o,${SOURCES})

###########################################################################
#
# 	Check for bzr binary
#
###########################################################################

ifeq (Found,$(shell if `which bzr >& /dev/null`; then echo Found; fi))
	BAZAAR = 1
else
	BAZAAR = 0
endif

###########################################################################
#
#	 Rules
#
###########################################################################

# all objects depend on headers
${OBJECTS}: ${HEADERS}

# How to compile *.c files
# special rules for force computation
powell_lsq.o: powell_lsq.c
	${CC} ${CFLAGS} ${CINCLUDE} -c powell_lsq.c

# special rules for function evaluation
functions.o: functions.c
	${CC} ${CFLAGS} ${CINCLUDE} -c functions.c

# generic compilation rule
.c.o:
	${CC} ${CFLAGS} -c $<

# How to link
${MAKETARGET}: ${OBJECTS}
	${CC} ${LFLAGS} -o $@ ${OBJECTS} ${LIBS}
ifneq (,${STRIP})
ifeq (,$(findstring debug,${MAKETARGET}))
	${STRIP} --strip-unneeded $@
endif
endif
	${MV} $@ ${BIN_DIR}; rm -f $@

# First recursion only set the MAKETARGET Variable
.DEFAULT:
ifneq (,${CC})
	${MAKE} MAKETARGET='$@' STAGE2
else
	@echo "There is no compiler defined for this option."
	@echo -e "Please adjust the Makefile.\n"
	@exit
endif

potfit:
	@echo -e "\nError:\tYou cannot compile potfit without any options."
	@echo -e "\tAt least an interaction is required.\n"

# Second recursion sets MAKETARGET variable and compiles
# An empty MAKETARGET variable would create an infinite recursion, so we check
STAGE2:
ifneq (,${ERROR})
	@echo -e "\nError: ${ERROR}\n"
else
ifneq (,${MAKETARGET})
	@echo "${WARNING}"
ifeq (1,${BAZAAR})
	@echo -e "Writing bazaar data to version.h\n"
	@rm -f version.h
	@bzr version-info --custom \
	--template="#define VERSION_INFO \"potfit-{branch_nick} (r{revno})\"\n" > version.h
	@bzr version-info --custom \
	--template="#define VERSION_DATE \"{build_date}\"\n" >> version.h
else
	@echo -e "Writing fake bazaar data to version.h\n"
	@rm -f version.h
	@echo -e "#define VERSION_INFO \"potfit-`basename ${PWD}` (r ???)\"" > version.h
	@echo -e "#define VERSION_DATE \"`date +%Y-%m-%d\ %H:%M:%S\ %z`\"" >> version.h
endif
	${MAKE} MAKETARGET='${MAKETARGET}' ${MAKETARGET}
else
	@echo 'No TARGET specified.'
endif
endif
###########################################################################
#
#	 Misc. TARGETs
#
###########################################################################

clean:
	rm -f *.o *.u *~ \#* *.V *.T *.O *.il

help:
	@echo "Usage: make potfit[_<parallel>][_<option>[_<option>...]]"

