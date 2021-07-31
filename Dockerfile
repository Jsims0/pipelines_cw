
FROM ubuntu:latest
WORKDIR /tmp


RUN apt-get --assume-yes update && apt-get --assume-yes install samtools
RUN apt-get install unzip
RUN apt-get install -y trimmomatic
RUN apt-get install -y bwa
RUN apt-get --assume-yes install picard

#Install gatk
RUN apt-get install -y python3
RUN apt-cache show python-is-python3
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN apt-get install wget
RUN wget https://github.com/broadinstitute/gatk/releases/download/4.2.0.0/gatk-4.2.0.0.zip -O gatk-4.2.0.0.zip \
	&& unzip /tmp/gatk-4.2.0.0.zip -d /opt/ \
	&& rm /tmp/gatk-4.2.0.0.zip -f \
	&& cd /opt/gatk-4.2.0.0 \
	&& ./gatk --list

#Install java
RUN apt-get install -y openjdk-8-jre && \
	rm -rf /var/lib/apt/lists/*

#Install R 3.6
RUN apt-get update && apt-get install -y gnupg
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN apt-get install -y lsb-release && apt-get clean all
RUN apt-get --assume-yes install software-properties-common
RUN apt-get update

#RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
RUN add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/'
#RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran35/"
RUN apt update && apt-get install --assume-yes r-base

#Install Bioconductor packages required by Qualimap

RUN Rscript -e "install.packages('optparse')"
RUN Rscript -e "install.packages('BiocManager', repos = 'http://cran.us.r-project.org')"
RUN Rscript -e "BiocManager::install(c('NOISeq', 'Repitools', 'Rsamtools', 'GenomicFeatures', 'rtracklayer'))"

#Install Qualimap
RUN Rscript --version
RUN apt-get update
RUN apt-get install libxml2-dev

RUN apt-get install libcurl4-openssl-dev

RUN cd /opt && wget https://bitbucket.org/kokonech/qualimap/downloads/qualimap_v2.2.1.zip
RUN cd /opt && unzip qualimap_v2.2.1.zip && rm qualimap_v2.2.1.zip
#RUN Rscript /opt/qualimap_v2.2.1/scripts/installDependencies.r

RUN apt-get install -y bcftools

RUN apt-get install -y freebayes

RUN wget https://bootstrap.pypa.io/get-pip.py
RUN apt-get install --assume-yes python3-distutils

RUN apt-get install --assume-yes python3-apt

RUN python get-pip.py
RUN pip install snakemake

WORKDIR /bin
RUN wget https://raw.githubusercontent.com/ekg/interleave-fastq/master/interleave-fastq

# Get Demo Data
WORKDIR /Data

RUN wget http://ftp.sra.ebi.ac.uk/vol1/fastq/SRR151/001/SRR1518011/SRR1518011_1.fastq.gz
RUN wget http://ftp.sra.ebi.ac.uk/vol1/fastq/SRR151/001/SRR1518011/SRR1518011_2.fastq.gz

COPY primer_adapters.fa /Data
COPY Homo_sapiens.GRCh38.dna.chromosome.10.fa /Data

ENV PATH="/opt/qualimap_v2.2.1:/bin/interleave-fastq:/opt/gatk-4.1.4.1/:$PATH"
RUN apt-get install -y vcftools

WORKDIR /
COPY snakefile snakefile
