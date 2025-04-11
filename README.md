# postgres_pgcron_oraclefdw

Show! Bora instalar o oracle_fdw dentro do seu container PostgreSQL.

Mas antes, só um spoiler: instalar o oracle_fdw não é tão direto quanto um apt install simples, porque ele depende de:

Bibliotecas do Oracle Instant Client

Headers do PostgreSQL (já estão lá no container, provavelmente)

E precisa compilar o oracle_fdw a partir do código-fonte

✅ Passo a passo para instalar oracle_fdw dentro do container
📦 Requisitos:
Oracle Instant Client (Basic e SDK)

oracle_fdw (código-fonte do GitHub)

Ferramentas de build (make, gcc, git, etc.)

⚙️ 1. Instalar dependências
Dentro do container:

bash
Copy
Edit
apt-get update
apt-get install -y build-essential git libpq-dev unzip curl
apt-get update && apt-get install -y wget
📥 2. Baixar e instalar o Oracle Instant Client
1. Crie uma pasta para o Oracle Client:

bash
Copy
Edit
mkdir -p /opt/oracle
cd /opt/oracle
2. Baixe os arquivos ZIP da Oracle (Instant Client Basic + SDK)

Infelizmente, a Oracle exige login para download, então você precisa:

Fazer o download manualmente no site da Oracle

E copiar os dois arquivos .zip pro container (ou para o host e montar como volume)

Site: https://www.oracle.com/database/technologies/instant-client/linux-x86-64-downloads.html

Exemplo de arquivos:
Basic Package (ZIP)	
instantclient-basic-linux.x64-21.13.0.0.0dbru.zip

wget -v https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-basic-linux.x64-23.7.0.25.01.zip

SDK Package (ZIP)	
instantclient-sdk-linux.x64-21.13.0.0.0dbru.zip

wget -v https://download.oracle.com/otn_software/linux/instantclient/2370000/instantclient-sdk-linux.x64-23.7.0.25.01.zip

Depois, dentro do container:
Os aquivos zip contém a mesma pasta chamada instantclient_xx_yy versão ai no unzip ele reclama e pede para digitar A para aceitar mesclar o mesmo conteúdo para 
✅ Solução: usar yes A | unzip ...
Esse comando simula digitar "A" automaticamente para 
ou ou unzip -o instantclient-sdk-linux*.zip
bash
Copy
Edit
unzip instantclient-basic-linux*.zip
yes A | unzip instantclient-sdk-linux*.zip

Crie o link simbólico:

bash
Copy
Edit
cd /opt/oracle
ln -s instantclient_23_7 instantclient
E exporte as variáveis necessárias:

bash
Copy
Edit
echo "/opt/oracle/instantclient" > /etc/ld.so.conf.d/oracle-instantclient.conf
ldconfig
export LD_LIBRARY_PATH=/opt/oracle/instantclient
🛠️ 3. Clonar e compilar o oracle_fdw
bash
Copy
Edit
cd /tmp
git clone https://github.com/laurenz/oracle_fdw.git
cd oracle_fdw
1. Descubra onde está o oci.h
find /opt/oracle -name oci.h
o camingo que ele esta é 
/opt/oracle/instantclient_23_7/sdk/include/oci.h

✅ Passo a passo pra compilar o oracle_fdw com o caminho correto
1. Exportar variáveis de ambiente
Dentro do container, rode:

bash
Copy
Edit
export ORACLE_HOME=/opt/oracle/instantclient_23_7
export LD_LIBRARY_PATH=$ORACLE_HOME
export PATH=$ORACLE_HOME:$PATH
2. Rodar make com os includes e libs corretos
bash
Copy
Edit
make \
  INCLUDES="-I$ORACLE_HOME/sdk/include -I$ORACLE_HOME" \
  LDFLAGS="-L$ORACLE_HOME"
Isso diz explicitamente onde estão os headers e as libs da Oracle.

3. Se compilar com sucesso, instale com:
bash
Copy
Edit
make install

4. Instalar a biblioteca libaio1
apt-get update && apt-get install -y libaio1
🧪 Teste: Criar a extensão no PostgreSQL
Depois que compilar e instalar, reincie o postgres, você pode rodar:
🔄 4. Reinicie o container (ou PostgreSQL)
Se usou shared_preload_libraries, pode só reiniciar o PostgreSQL dentro do container:

bash
Copy
Edit
psql -U postgres
pg_ctl restart
Dentro do psql:

sql
Copy
Edit
CREATE EXTENSION oracle_fdw;


