Top demais! Vamos empacotar tudo isso num setup bonitinho com:

Dockerfile com:

PostgreSQL 16.3

pg_cron

oracle_fdw compilado

Oracle Instant Client (basic + sdk)

docker-compose.yml que roda tudo em um comando.

🐳 Dockerfile
dockerfile
Copy
Edit
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
🔧 docker-compose.yml
yaml
Copy
Edit
version: "3.8"

services:
  postgres:
    build: .
    container_name: postgres_pgcron_oraclefdw
    environment:
      POSTGRES_PASSWORD: suasenha
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  pgdata:
▶️ Como usar
Salve os arquivos como Dockerfile e docker-compose.yml na mesma pasta (ex: postgres-oraclefdw/)

No terminal, vá até essa pasta e rode:

bash
Copy
Edit
docker compose up --build -d
Depois de subir, você pode acessar o container com:

bash
Copy
Edit
docker exec -it postgres_pgcron_oraclefdw bash
E dentro do psql:

bash
Copy
Edit
psql -U postgres
CREATE EXTENSION oracle_fdw;