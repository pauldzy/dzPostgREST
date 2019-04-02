FROM haskell:8.6.3 AS builder

LABEL maintainer="Paul Dziemiela <Paul@Dziemiela.com>"

ENV POSTGREST_VERSION 5.2.0

ARG DEBIAN_FRONTEND=noninteractive

RUN printf "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d &&\
    apt-get update                                     &&\
    apt-get install -y --no-install-recommends           \
       vim                                               \
       build-essential                                   \
       pkg-config                                        \
       clang                                             \
       zip                                               \
       unzip                                             \
       wget                                              \
       libpq-dev                                       &&\
    rm -rf /var/lib/apt/lists/*

RUN cd /tmp                                            &&\
    wget -nv https://github.com/begriffs/pg_listen/archive/master.zip &&\
    unzip -q master.zip                                &&\
    cd /tmp/pg_listen-master                           &&\
    make                                               &&\
    mv pg_listen /usr/local/bin                        &&\
    chmod 755 /usr/local/bin/pg_listen                 &&\
    rm -Rf /tmp/pg_listen-master
    
RUN cd /tmp                                            &&\
    wget -nv https://github.com/PostgREST/postgrest/archive/v${POSTGREST_VERSION}.tar.gz &&\
    tar -xf v${POSTGREST_VERSION}.tar.gz

RUN cd /tmp/postgrest-${POSTGREST_VERSION}/src/PostgREST  &&\
    sed -i.bak -e 's/ActionInvoke{isReadOnly=True} -> HT.Read/ActionInvoke{isReadOnly=True} -> HT.Write/' App.hs
    
RUN cd /tmp/postgrest-${POSTGREST_VERSION}             &&\
    stack build                                          \
       --install-ghc                                     \
       --copy-bins                                       \
       --local-bin-path /usr/local/bin                   \
       --verbosity info                                &&\
    rm -Rf /tmp/postgrest-${POSTGREST_VERSION}
              
FROM debian:stretch

RUN apt-get update                                     &&\
    apt-get install -y --no-install-recommends           \
       apt-utils                                         \
       dos2unix                                          \
       psmisc                                            \
       supervisor                                        \
       libpq-dev                                       &&\
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/pg_listen /usr/local/bin
COPY --from=builder /usr/local/bin/postgrest /usr/local/bin

EXPOSE 3000

