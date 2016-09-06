FROM ubuntu:16.04
MAINTAINER Johnny T. <john@exogenesis.solutions>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y --install-recommends \
    build-essential \
    cmake \
    git \
    libtiff5-dev \
    libgeotiff-dev \
    libpng-dev \ 
    libjpeg-dev \
    zlib1g-dev  \
    libopenthreads-dev \
    libgeos++-dev \
    libgeos-dev \
    libpotrace-dev


ENV OSSIM_DEV_HOME=/usr/local/src/ossim

ENV OSSIM_BUILD_DIR=$OSSIM_DEV_HOME/build \
    OSSIM_DEPENDENCIES=/usr

RUN git clone https://github.com/ossimlabs/ossim.git $OSSIM_DEV_HOME && \
    cd $OSSIM_DEV_HOME && \
    git checkout master

RUN git clone https://github.com/ossimlabs/ossim-plugins.git $OSSIM_DEV_HOME/ossim-plugins && \
    cd $OSSIM_DEV_HOME/ossim-plugins && \
    git checkout master

RUN mkdir $OSSIM_BUILD_DIR
WORKDIR $OSSIM_BUILD_DIR

# Make and install ossim.

RUN cmake .. \
    -DOSSIM_LIBRARY=$OSSIM_BUILD_DIR/lib/libossim.so \
    -DOSSIM_INCLUDE_DIR=$OSSIM_DEV_HOME/include \
    -DBUILD_OSSIM_TESTS=OFF

RUN make && make install && ldconfig

# Make and install plugins.

RUN mkdir $OSSIM_DEV_HOME/ossim-plugins/build
WORKDIR $OSSIM_DEV_HOME/ossim-plugins/build

RUN cmake .. \
    -DOSSIM_INSTALL_PREFIX=/usr/local/ \
    -DCMAKE_MODULE_PATH=$OSSIM_DEV_HOME/cmake/CMakeModules/ \
    -DBUILD_GDAL_PLUGIN=OFF \
    -DBUILD_MRSID_PLUGIN=OFF \
    -DBUILD_PDAL_PLUGIN=OFF \
    -DBUILD_KAKADU_PLUGIN=OFF \
    -DBUILD_CNES_PLUGIN=OFF \
    -DBUILD_POTRACE_PLUGIN=ON

RUN make && make install

RUN useradd -ms /bin/bash ossimuser
USER ossimuser
WORKDIR /home/ossimuser

# Set up the preferences file
RUN echo 'plugin.file1: /usr/local/lib/ossim/plugins/libossim_potrace_plugin.so' > ~/ossim_preferences
ENV OSSIM_PREFS_FILE=/home/ossimuser/ossim_preferences
