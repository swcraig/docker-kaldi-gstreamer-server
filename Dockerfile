FROM debian:9
MAINTAINER Eduardo Silva <zedudu@gmail.com>

RUN apt-get update && apt-get install -y  \
    procps \
    autoconf \
    automake \
    bzip2 \
    gfortran \
    g++ \
    git \
    gstreamer1.0-plugins-good \
    gstreamer1.0-tools \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-ugly  \
    libatlas3-base \
    libgstreamer1.0-dev \
    libtool-bin \
    make \
    python2.7 \
    python3 \
    python-pip \
    python-yaml \
    python-simplejson \
    python-gi \
    subversion \
    unzip \
    wget \
    build-essential \
    python-dev \
    sox \
    zlib1g-dev && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    pip install ws4py==0.3.2 && \
    pip install tornado && \
    pip install g2p_en && \
    ln -s /usr/bin/python2.7 /usr/bin/python ; ln -s -f bash /bin/sh

# install mkl
RUN apt update && apt install -y --force-yes apt-transport-https && \
  wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
  apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
  sh -c 'echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list' && \
  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install cpio intel-mkl-64bit-2018.3-051 && \
  (find /opt/intel -name "ia32*" -exec rm -rf {} \; || echo "removing ia32 binaries") ; \
  (find /opt/intel -name "examples" -type d -exec rm -rf {} \; || echo "removing examples") ; \
  (find /opt/intel -name "benchmarks" -exec rm -rf {} \; || echo "removing benchmarks") ; \
  (find /opt/intel -name "documentation*" -exec rm -rf {} \; || echo "removing documentation") ; \
  (rm -rf /opt/intel/mkl/interfaces ) ; \
  (rm -rf /opt/intel/mkl/lib/intel64/*.a ) ; \
  (rm -rf /opt/intel/mkl/lib/intel64/*mpi*.so ) ; \
  (rm -rf /opt/intel/mkl/lib/intel64/*tbb*.so ) ; \
  (rm -rf /opt/intel/mkl/lib/intel64/*pgi*.so ) ; \
  (rm -rf /opt/intel/mkl/lib/intel64/*mc*.so ) ; \
  (rm -rf /opt/intel/mkl/lib/intel64/*blacs*.so ) ; \
  (rm -rf /opt/intel/mkl/lib/intel64/*scalapack*.so ) ; \
  (rm -rf /opt/intel/mkl/lib/intel64/*gf*.so ) ; \
  (rm -rf /opt/intel/mkl/lib/intel64/*mic*.so ) ; \
  apt purge intel-tbb* intel-psxe* && \
  apt-get clean autoclean && \
  apt-get autoremove -y && \
  ln -s -f bash /bin/sh && \
  rm -rf /usr/share/doc && \
  echo "/opt/intel/mkl/lib/intel64" >> /etc/ld.so.conf.d/intel.conf && \
  ldconfig && \
  echo "source /opt/intel/mkl/bin/mklvars.sh intel64" >> /etc/bash.bashrc

RUN update-alternatives --install /usr/lib/x86_64-linux-gnu/libblas.so  \
    libblas.so-x86_64-linux-gnu      /opt/intel/mkl/lib/intel64/libmkl_rt.so 50 && \
  update-alternatives --install /usr/lib/x86_64-linux-gnu/libblas.so.3  \
    libblas.so.3-x86_64-linux-gnu    /opt/intel/mkl/lib/intel64/libmkl_rt.so 50 && \
  update-alternatives --install /usr/lib/x86_64-linux-gnu/liblapack.so   \
    liblapack.so-x86_64-linux-gnu    /opt/intel/mkl/lib/intel64/libmkl_rt.so 50 && \
  update-alternatives --install /usr/lib/x86_64-linux-gnu/liblapack.so.3 \
    liblapack.so.3-x86_64-linux-gnu  /opt/intel/mkl/lib/intel64/libmkl_rt.so 50 && \
  echo "/opt/intel/lib/intel64"     >  /etc/ld.so.conf.d/mkl.conf && \
  echo "/opt/intel/mkl/lib/intel64" >> /etc/ld.so.conf.d/mkl.conf && \
  ldconfig && \
  echo "MKL_THREADING_LAYER=GNU" >> /etc/environment

WORKDIR /opt

RUN wget http://www.digip.org/jansson/releases/jansson-2.7.tar.bz2 && \
    bunzip2 -c jansson-2.7.tar.bz2 | tar xf -  && \
    cd jansson-2.7 && \
    ./configure && make -j $(nproc) && make check &&  make install && \
    echo "/usr/local/lib" >> /etc/ld.so.conf.d/jansson.conf && ldconfig && \
    rm /opt/jansson-2.7.tar.bz2 && rm -rf /opt/jansson-2.7

RUN git clone https://github.com/kaldi-asr/kaldi && \
    cd /opt/kaldi/tools && \
    make -j $(nproc) && \
    ./install_portaudio.sh && \
    /opt/kaldi/tools/extras/install_mkl.sh && \
    cd /opt/kaldi/src && ./configure --shared && \
    sed -i '/-g # -O0 -DKALDI_PARANOID/c\-O3 -DNDEBUG' kaldi.mk && \
    make clean -j $(nproc) && make -j $(nproc) depend && make -j $(nproc) && \
    cd /opt/kaldi/src/online && make depend -j $(nproc) && make -j $(nproc) && \
    cd /opt/kaldi/src/gst-plugin && sed -i 's/-lmkl_p4n//g' Makefile && make depend -j $(nproc) && make -j $(nproc) && \
    cd /opt && \
    git clone https://github.com/alumae/gst-kaldi-nnet2-online.git && \
    cd /opt/gst-kaldi-nnet2-online/src && \
    sed -i '/KALDI_ROOT?=\/home\/tanel\/tools\/kaldi-trunk/c\KALDI_ROOT?=\/opt\/kaldi' Makefile && \
    make depend -j $(nproc) && make -j $(nproc) && \
    rm -rf /opt/gst-kaldi-nnet2-online/.git/ && \
    find /opt/gst-kaldi-nnet2-online/src/ -type f -not -name '*.so' -delete && \
    rm -rf /opt/kaldi/.git && \
    rm -rf /opt/kaldi/egs/ /opt/kaldi/windows/ /opt/kaldi/misc/ && \
    find /opt/kaldi/src/ -type f -not -name '*.so' -delete && \
    find /opt/kaldi/tools/ -type f \( -not -name '*.so' -and -not -name '*.so*' \) -delete && \
    cd /opt && git clone https://github.com/alumae/kaldi-gstreamer-server.git && \
    rm -rf /opt/kaldi-gstreamer-server/.git/ && \
    rm -rf /opt/kaldi-gstreamer-server/test/

COPY start.sh stop.sh /opt/

RUN chmod +x /opt/start.sh && \
    chmod +x /opt/stop.sh
