FROM alpine:3.8
RUN apk --update add build-base zlib-dev git perl

# Install STAR
WORKDIR /
RUN git clone https://github.com/alexdobin/STAR && cd STAR && git checkout 2.5.2b

# Install RSEM
WORKDIR /
RUN git clone --single-branch -b STARNoSharedMemory https://github.com/inutano/RSEM
RUN cd RSEM && make && make install

CMD ["sh"]
