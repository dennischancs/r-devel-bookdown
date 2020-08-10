## Emacs, make this -*- mode: sh; -*-

## start with the Docker 'base R' Debian-based image
FROM r-base:latest

## This handle reaches Carl and Dirk
LABEL maintainer="An unoffical MSG-book docker"

ARG PANDOC_VERSION=2.10.1
## Remain current
RUN apt-get update -qq \
    && apt-get dist-upgrade -y

## From the Build-Depends of the Debian R package, plus subversion
RUN apt-get update -qq \
    && apt-get install -t unstable -y --no-install-recommends \
        apt-utils \
        bash-completion \
        bison \
        curl \
        dialog \
        debhelper \
        default-jdk \
        g++ \
        gcc \
        gdb \
        gfortran \
        ghostscript \
        gnupg \
        groff-base \
        file \
        imagemagick \
        jags \
        unixodbc-dev \
        odbc-postgresql \
        libsqliteodbc \
        libblas-dev \
        libbz2-dev \
        libcairo2-dev/unstable \
        libcurl4-openssl-dev \
        libjpeg-dev \
        libgit2-dev \
        libglpk-dev \
        libgmp-dev \
        liblapack-dev \
        liblzma-dev \
        libncurses5-dev \
        libnlopt-dev \
        libnode-dev \
        libpango1.0-dev \
        libpcre3-dev \
        libpng-dev \
        libreadline-dev \
        libssl-dev \
        libtiff5-dev \
        libx11-dev \
        libxt-dev \
        libxaw7-dev \
        libxml2-dev \
        libxpm-dev \
        libmagick++-dev \
        libgeos-dev \
        libglu1-mesa-dev \
        libpoppler-cpp-dev \
        graphviz \
        ggobi \
        libgtk2.0-dev \
        libudunits2-dev \
        libproj-dev \
        libgdal-dev \
        libavfilter-dev \
        libfftw3-dev \
        cargo \
        mpack \
        optipng \
        qpdf \
        subversion \
        tcl8.6-dev \
        texinfo \
        tk8.6-dev \
        x11proto-core-dev \
        xauth \
        xdg-utils \
        xfonts-base \
        xvfb \
        zlib1g-dev \
        zip \
        unzip
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/*

RUN wget -q --no-check-certificate "https://travis-bin.yihui.name/texlive-local.deb" \
    && dpkg -i texlive-local.deb \
    && rm texlive-local.deb \
    && wget -qO- \
        "https://gitee.com/dennischan/CJupyterDocker/raw/master/cminimal-notebook/TinyTeX/install-unx.sh" | \
        sh -s - --admin --no-path \
    && ln -fs $(find /opt/TinyTeX/bin/x86_64-linux/* -executable) /usr/bin/ \
    && tlmgr install ae listings pdfcrop \
    && (tlmgr path add || true) \
    && chown -R root:staff /opt/TinyTeX \
    && chmod -R g+w /opt/TinyTeX \
    && chmod -R g+wx /opt/TinyTeX/bin

## Check out R-devel
RUN cd /tmp \
    && svn co https://svn.r-project.org/R/trunk R-devel

## Build and install according the standard 'recipe' I emailed/posted years ago
RUN cd /tmp/R-devel \
    && R_PAPERSIZE=letter \
        R_BATCHSAVE="--no-save --no-restore" \
        R_BROWSER=xdg-open \
        PAGER=/usr/bin/pager \
        PERL=/usr/bin/perl \
        R_UNZIPCMD=/usr/bin/unzip \
        R_ZIPCMD=/usr/bin/zip \
        R_PRINTCMD=/usr/bin/lpr \
        LIBnn=lib \
        AWK=/usr/bin/awk \
        CFLAGS=$(R CMD config CFLAGS) \
        CXXFLAGS=$(R CMD config CXXFLAGS) \
    ./configure --enable-R-shlib \
               --without-blas \
               --without-lapack \
               --with-readline \
               --without-recommended-packages \
               --program-suffix=dev \
    && make \
    && make install \
    && rm -rf /tmp/R-devel

## Set Renviron to get libs from base R install
RUN echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron

## Set default CRAN repo
RUN echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /usr/local/lib/R/etc/Rprofile.site \
# RUN echo 'options(repos = c(CRAN = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/"), download.file.method = "libcurl")' >> /usr/local/lib/R/etc/Rprofile.site \
    && Rscript -e "install.packages(c('littler', 'codetools', 'remotes'))" \
    && install.r docopt tinytex \
    && Rscript -e "tinytex::r_texmf()" \
    && mkdir -p /opt/pandoc \
    && url_prefix="https://github.com/jgm/pandoc/releases/download" \
    && wget -q --no-check-certificate $url_prefix/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz -P /opt/pandoc/ \
    && tar -xzf /opt/pandoc/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz -C /opt/pandoc \
    && ln -s /opt/pandoc/pandoc-${PANDOC_VERSION}/bin/pandoc /usr/local/bin \
    && ln -s /opt/pandoc/pandoc-${PANDOC_VERSION}/bin/pandoc-citeproc /usr/local/bin \
    && rm /opt/pandoc/pandoc-${PANDOC_VERSION}-linux-amd64.tar.gz

## Copy 'checkbashisms' (as a local copy from devscripts package)
COPY checkbashisms /usr/local/bin

RUN cd /usr/local/bin \
    && mv R Rdevel \
    && mv Rscript Rscriptdevel \
    && ln -s Rdevel RD \
    && ln -s Rscriptdevel RDscript

## R packages
RUN xvfb-run install2.r --error \
    animation \
    alphahull \
    bookdown \
    cowplot \
    corrplot \
    formatR \
    GGally \
    gWidgetsRGtk2 \
    hexbin \
    pdftools \
    plotrix \
    plot3D \
    scatterplot3d \
    magick \
    MSG \
    rgeos \
    rgl \
    RColorBrewer \
    showtext \
    sna \
    sp \
    maps \
    mapdata \
    mapproj \
    maptools \
    randomForest \
    rggobi \
    tikzDevice \
    vcd \
    mvtnorm \
    vioplot \
    TeachingDemos \
    aplpack \
    igraph \
    fun \
    svglite \
    av \
    gifski \
    gganimate \
    ggmap \
    ggraph \
    ggfortify \
    ggridges \
    leaflet \
    plotly \
    raster \
    rayshader \
    RgoogleMaps \
    sf \
    transformr \
    ggbeeswarm \
    ggpointdensity \
    heatmaply \
    quantreg \
    iplots \
    tuneR \
    odbc \
    glmmTMB \
    nimble \
    rstan \
	# add MSG-book new packages
	survminer \
    && installGithub.r \
    yihui/fun

## Install Adobe fonts
RUN curl -fLo Adobe-Fonts.zip https://github.com/XiangyunHuang/fonts/releases/download/v0.1/Adobe-Fonts.zip \
    && mkdir -p ~/.fonts \
    && unzip Adobe-Fonts.zip -d ~/.fonts/adobe \
    && fc-cache -fsv \
    && tlmgr install ctex xecjk courier courier-scaled savesym \
        colortbl dvipng dvisvgm environ fancyhdr jknapltx listings \
        makecell mathdesign metalogo microtype ms multirow parskip pdfcrop \
        pgf placeins preview psnfss realscripts relsize rsfs setspace soul \
        standalone subfig symbol tabu tex4ht threeparttable threeparttablex \
        titlesec tocbibind tocloft trimspaces ulem varwidth wrapfig xcolor \
        xltxtra zhnumber cancel titlepic mdwtools