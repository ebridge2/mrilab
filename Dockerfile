FROM flashx/flashx
MAINTAINER Eric Bridgeford <ericwb95@gmail.com>

#--------Environment Variables-----------------------------------------------#
ENV NDMG_URL https://github.com/neurodata/ndmg.git
ENV ATLASES http://openconnecto.me/mrdata/share/eric_atlases/fmri_atlases.zip
ENV AFNI_URL https://afni.nimh.nih.gov/pub/dist/bin/linux_fedora_21_64/@update.afni.binaries
ENV LIBXP_URL http://mirrors.kernel.org/ubuntu/pool/main/libx/libxp/libxp6_1.0.2-2_amd64.deb


#--------Initial Configuration-----------------------------------------------#
# download/install basic dependencies, and set up python
RUN apt-get update
RUN apt-get install -y zip unzip vim git python-dev curl gsl-bin

RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py

RUN \
    apt-get install -y git libpng-dev libfreetype6-dev pkg-config \
    zlib1g-dev g++ vim r-base-core

#---------FSL INSTALL---------------------------------------------------------#
RUN apt-get install -y fsl-5.0-core

ENV FSLDIR=/usr/lib/fsl/5.0
ENV FSLOUTTYPE=NIFTI_GZ
ENV PATH=$PATH:$FSLDIR
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$FSLDIR

RUN echo ". /etc/fsl/5.0/fsl.sh" >> /root/.bashrc

#---------AFNI INSTALL--------------------------------------------------------#
# setup of AFNI, which provides robust modifications of many of neuroimaging
# algorithms
RUN \
    wget -c $LIBXP_URL && \
    dpkg -i `basename $LIBXP_URL` && \
    apt-get install -f && \
    curl -O $AFNI_URL && \
    chsh -s /usr/bin/tcsh && \
    tcsh @update.afni.binaries -package linux_openmp_64 -do_extras && \
    chsh -s /bin/bash && \
    cp /root/abin/AFNI.afnirc /root/.afnirc && \
    echo "PATH=$PATH:/root/abin" >> ~/.bashrc


#--------NDMG SETUP-----------------------------------------------------------#
# setup of python dependencies for ndmg itself, as well as file dependencies
RUN \
    pip install numpy==1.12.1 networkx>=1.11 nibabel>=2.0 dipy>=0.1 scipy \
    boto3 awscli matplotlib==1.5.3 plotly==1.12.1 nilearn>=0.2 sklearn>=0.0 \
    pandas

RUN a=a \
    git clone -b eric-dev-gkiar-fmri $NDMG_URL /ndmg && \
    cd /ndmg && \
    python setup.py install 

RUN \
    mkdir /ndmg_atlases && \
    cd /ndmg_atlases && \
    wget -rnH --cut-dirs=3 --no-parent -P /ndmg_atlases $ATLASES

ADD ./.vimrc ~/.vimrc

#--------Jupyter---------------------------------------------------------------#

USER root

RUN pip install setuptools==33.1.1
RUN apt-get -y install python2.7 python-pip python-dev
RUN apt-get -y install ipython ipython-notebook git &&\
		pip install --upgrade pip
RUN pip install jupyter

COPY jupyter_notebook_config.py ~/

EXPOSE 8888
CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0"]
