# Dockerfile
FROM postgres:16.3

LABEL maintainer="danilobrun"

# Variáveis do Oracle
ENV ORACLE_VERSION=23_7 \
    ORACLE_CLIENT_URL_BASE=https://download.oracle.com/otn_software/linux/instantclient/2370000 \
    LD_LIBRARY_PATH=/opt/oracle/instantclient \
    ORACLE_HOME=/opt/oracle/instantclient

# Instala dependências
RUN apt-get update && apt-get install -y \
  build-essential \
  libpq-dev \
  postgresql-server-dev-16 \
  postgresql-16-cron \
  git \
  unzip \
  wget \
  libaio1 \
  libxml2-dev \
  pkg-config \
  ca-certificates \
 && rm -rf /var/lib/apt/lists/*



# Cria diretórios Oracle
RUN mkdir -p /opt/oracle \
 && cd /opt/oracle \
 && wget --no-check-certificate --content-disposition \
      $ORACLE_CLIENT_URL_BASE/instantclient-basic-linux.x64-23.7.0.25.01.zip \
 && wget --no-check-certificate --content-disposition \
      $ORACLE_CLIENT_URL_BASE/instantclient-sdk-linux.x64-23.7.0.25.01.zip \
 && unzip -o instantclient-basic-linux.x64-23.7.0.25.01.zip \
 && unzip -o instantclient-sdk-linux.x64-23.7.0.25.01.zip \
 && ln -s instantclient_23_7 instantclient \
 && echo "$LD_LIBRARY_PATH" > /etc/ld.so.conf.d/oracle-instantclient.conf \
 && ldconfig

# Clona e compila o oracle_fdw
RUN cd /tmp \
 && git clone https://github.com/laurenz/oracle_fdw.git \
 && cd oracle_fdw \
 && make ORACLE_HOME=$ORACLE_HOME \
 && make install

# Ativa pg_cron
RUN echo "shared_preload_libraries = 'pg_cron'" >> /usr/share/postgresql/postgresql.conf.sample

# Expõe porta padrão
EXPOSE 5432
