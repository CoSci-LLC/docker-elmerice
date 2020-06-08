FROM ubuntu:19.10 AS base

RUN apt update; apt install -y \
    git \
    cmake \
    gfortran \
    g++ \
    libblas-dev \
    liblapack-dev \
    libmetis-dev \
    libparmetis-dev \
    libmumps-dev \
    libnetcdf-dev \
    libnetcdff-dev \ 
    netcdf-bin \
    wget 

FROM base as mpiBuild

RUN wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.3.tar.gz
RUN tar zxvf openmpi-4.0.3.tar.gz
RUN cd openmpi-4.0.3/ && ./configure --prefix=/opt/mpi/
RUN cd openmpi-4.0.3/ && make install -j 4


FROM mpiBuild as mmgBuild

COPY --from=mpiBuild /opt/mpi/ /usr/local/

RUN mkdir /usr/local/mmg
RUN git clone https://github.com/MmgTools/mmg /usr/local/src/mmg
RUN mkdir /usr/local/src/mmg/build
RUN echo 'SET(CMAKE_C_FLAGS "-fPIC" CACHE STRING "")\nSET(CMAKE_CXX_FLAGS "-fPIC" CACHE STRING "")\nSET(CMAKE_Fortran_FLAGS "-fPIC" CACHE STRING "")' > /tmp/mmg.cache
RUN cd /usr/local/src/mmg/build && cmake -C /tmp/mmg.cache -DLIBMMG2D_SHARED=ON -DLIBMMG3D_SHARED=ON -DLIBMMGS_SHARED=ON -DLIBMMG_SHARED=ON -DUSE_SCOTCH=OFF ..
RUN cd /usr/local/src/mmg/build && make install -j 4

FROM base AS mmgBase
COPY --from=mmgBuild /usr/local/include/mmg/ /usr/local/include/mmg/
COPY --from=mmgBuild /usr/local/lib/libmmg* /usr/local/lib/

FROM mmgBase AS elmerBuild

ARG gitCommit=latest
RUN git clone https://www.github.com/ElmerCSC/elmerfem -b elmerice /usr/local/src/elmer/elmerfem
RUN cd /usr/local/src/elmer/elmerfem && git reset --hard $gitCommit
RUN mkdir /usr/local/src/elmer/build
RUN cd /usr/local/src/elmer/build && cmake -DWITH_ElmerIce:BOOL=TRUE -DWITH_ELMERGUI:BOOL=FALSE -DWITH_MPI:BOOL=TRUE -DWITH_Mumps:BOOL=TRUE -DWITH_LUA:BOOL=TRUE -DMMG_INCLUDE_DIR=/usr/local/include/mmg -DMMG_LIBRARY=/usr/local/lib/libmmg.so -DCMAKE_INSTALL_PREFIX=/usr/local/ ../elmerfem/
RUN cd /usr/local/src/elmer/build && make install -j 4

FROM mmgBase
COPY --from=elmerBuild /usr/local/bin /usr/local/bin
COPY --from=elmerBuild /usr/local/lib /usr/local/lib
COPY --from=elmerBuild /usr/local/share /usr/local/share
