FROM ubuntu:16.04

# Create a base docker container that can execute the new version 2.1 of brainageR
# https://github.com/james-cole/brainageR
# Authors: Daniela Furlan and Ferran Prados
#
# Example usage:
#
#       docker run --rm -it -v ${PWD}/your_data:/data -w /data  \
#              docker.io/library/brainimage:latest brainageR \
#              -f sub-01_T1w_defaced.nii -o subj01_brain_predicted.age.csv
#
# Build the docker:
#
#	docker build . -f Dockerfile -t brainimage
#

# Install the needed basic packages
RUN apt-get update
RUN apt-get install -y --fix-missing \
        unzip\
        git \
        wget

# Install R-package
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		software-properties-common \
                dirmngr \
                ed \
		less \
		locales \
		vim-tiny \
		wget \
		ca-certificates \
        && add-apt-repository --enable-source --yes "ppa:marutter/rrutter4.0" \
        && add-apt-repository --enable-source --yes "ppa:c2d4u.team/c2d4u4.0+"

# Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# This was not needed before but we need it now
ENV DEBIAN_FRONTEND noninteractive

# Otherwise timedatectl will get called which leads to 'no systemd' inside Docker
ENV TZ UTC

# Now install R and littler, and create a link for littler in /usr/local/bin
# Default CRAN repo is now set by R itself, and littler knows about it too
# r-cran-docopt is not currently in c2d4u so we install from source
RUN apt-get update \
        && apt-get install -y --no-install-recommends \
                 littler \
 		 r-base \
 		 r-base-dev \
 		 r-recommended \
  	&& ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
 	&& ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
 	&& ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
 	&& ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
 	&& install.r docopt \
 	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
 	&& rm -rf /var/lib/apt/lists/*

# Install packages kernlab,RNifti and stringr
RUN R -e "install.packages('kernlab',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('RNifti',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('stringr',dependencies=TRUE, repos='http://cran.rstudio.com/')"

# Install SMP12 and Octave
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install \
     build-essential \
     curl \
     octave \
     liboctave-dev \
 && apt-get clean \
 && rm -rf \
     /tmp/hsperfdata* \
     /var/*/apt/*/partial \
     /var/lib/apt/lists/* \
     /var/log/apt/term*

RUN mkdir /opt/spm12 \
    && curl -SL https://github.com/spm/spm12/archive/refs/tags/r7219.tar.gz \
    | tar -xzC /opt/spm12 --strip-components 1 \
    && curl -SL https://raw.githubusercontent.com/spm/spm-docker/main/octave/spm12_r7771.patch 
    
 RUN  make -C /opt/spm12/src PLATFORM=octave distclean \
    && make -C /opt/spm12/src PLATFORM=octave \
    && make -C /opt/spm12/src PLATFORM=octave install \
    && ln -s /opt/spm12/bin/spm12-octave /usr/local/bin/spm12

# Install FSL
RUN apt-get update

# setup FSL using debian
ENV NDEB_URL http://neuro.debian.net/lists/xenial.us-ca.full
COPY neurodebian.gpg /root/.neurodebian.gpg

RUN apt-get install -y software-properties-common python-software-properties
RUN add-apt-repository universe
RUN apt-get update

RUN \
    curl -sSL $NDEB_URL >> /etc/apt/sources.list.d/neurodebian.sources.list && \
    apt-key add /root/.neurodebian.gpg && \
    (apt-key adv --refresh-keys --keyserver hkp://ha.pool.sks-keyservers.net 0xA5D32F012649A5A9 || true) && \
    apt-get update
RUN \
    apt-get update && \
    apt-get install -y \
        fsl-5.0-core \
        fsl-mni152-templates=5.0.7-2

# Configure environment
ENV \
    FSLDIR=/usr/share/fsl/5.0 \
    FSLOUTPUTTYPE=NIFTI_GZ \
    FSLMULTIFILEQUIT=TRUE \
    POSSUMDIR=/usr/share/fsl/5.0 \
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/fsl/5.0 \
    FSLTCLSH=/usr/bin/tclsh \
    FSLWISH=/usr/bin/wish

ENV PATH=$FSLDIR/bin:$PATH
ENV PATH=.:$PATH
ENV PATH=/opt/brainageR/software:$PATH

RUN \
    echo ". $FSLDIR/etc/fslconf/fsl.sh" >> ~/.bashrc && \
    echo "export FSLDIR PATH" >> ~/.bashrc

# Install brainageR
# Install brainageR zip v2.1 from github
RUN cd /opt && \
    wget https://github.com/james-cole/brainageR/archive/refs/tags/2.1.zip

# BrainageR directory
RUN cd /opt && \
    mkdir brainageR

# Unzip 2.1 in brainageR directory
RUN cd /opt && \
      unzip 2.1.zip  -d /opt/brainageR

# Rename unzipped 2.1 folder (brainageR-2.1)
RUN cd /opt/brainageR &&\
         mv brainageR-2.1 software

# Substituting brainageR script by a brainageR script with new software directories
# Edited variables: brainageR_dir, spm_dir, matlab_path,FSLDIR
ADD brainageR /opt/brainageR/software

# Data directory for input and output
RUN mkdir -p /data

# Download PCAs
# pca_center.rds
RUN cd /opt/brainageR/software &&\
      wget  https://github.com/james-cole/brainageR/releases/download/2.1/pca_center.rds

# pca_rotation.rds
RUN cd /opt/brainageR/software &&\
      wget  https://github.com/james-cole/brainageR/releases/download/2.1/pca_rotation.rds
# pca_scale.rds
RUN cd /opt/brainageR/software &&\
      wget  https://github.com/james-cole/brainageR/releases/download/2.1/pca_scale.rds

# Install the needed packages
RUN apt-get update
RUN apt-get install -y --fix-missing \
  cmake \
  gcc \
  g++ \
  git \
libeigen3-dev \
zlib1g-dev \
libpng-dev \
openssl* \
doxygen \
xvfb \
curl

# Install NiftyReg and NiftySeg from QNI bitbucket account
RUN cd /opt && \
git clone https://github.com/KCL-BMEIS/niftyreg.git niftyreg && \
cd niftyreg && \
mkdir build-reg && \
cd build-reg && \
cmake \
-D \
CMAKE_BUILD_TYPE=Release \
BUILD_SHARED_LIBS=ON \
BUILD_ALL_DEP=ON \
USE_OPENMP=ON \
/opt/niftyreg && \
make && \
make install && \
cd /opt && \
git clone https://github.com/KCL-BMEIS/niftyseg.git niftyseg && \
cd niftyseg && \
mkdir build-seg && \
cd build-seg && \
cmake \
-D \
CMAKE_BUILD_TYPE=Release \
BUILD_SHARED_LIBS=ON \
USE_OPENMP=ON \
/opt/niftyseg && \
make && \
make install

RUN chmod +x /opt/brainageR/software/brainageR
