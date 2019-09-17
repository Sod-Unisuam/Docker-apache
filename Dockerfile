#Imagem do sistema operacional utilizado pelo servidor
FROM centos:7
#Pessoa que criou a iamgem
MAINTAINER Leonardo Costa Sabino leonardosabinoti@gmail.com
#Instalação

# -----------------------------------------------------------------------------
# Gerando argumentos
# -----------------------------------------------------------------------------
ARG gid=1000
ARG uid=1000
ARG PORTS_OPEN1=80
ARG PORTS_OPEN2=443

# -----------------------------------------------------------------------------
# Importando as chaves RPM GPG para os repositórios
# -----------------------------------------------------------------------------
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
	&& rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

# -----------------------------------------------------------------------------
# Instalação do apache e atualização do sistema
# -----------------------------------------------------------------------------
RUN yum update -y \
    && yum install -y httpd \
       httpd-tools

# -----------------------------------------------------------------------------
# Configurações globais apache
# -----------------------------------------------------------------------------

COPY apache/config/my-httpd.conf /etc/httpd/conf/httpd.conf

COPY apache/conf_modules/dav.conf /etc/httpd/conf.modules.d/00-dav.conf

COPY apache/conf_modules/lua.conf /etc/httpd/conf.modules.d/00-lua.conf

COPY apache/conf_modules/proxy.conf /etc/httpd/conf.modules.d/00-proxy.conf

COPY apache/conf_modules/base.conf /etc/httpd/conf.modules.d/00-base.conf

COPY apache/conf_modules/cgi.conf /etc/httpd/conf.modules.d/01-cgi.conf

# -----------------------------------------------------------------------------
# Configuração ssl
# -----------------------------------------------------------------------------

COPY apache/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf

# -----------------------------------------------------------------------------
# Configuração de segurança
# -----------------------------------------------------------------------------

COPY apache/security/limits.conf /etc/security/limits.conf

# -----------------------------------------------------------------------------
# Adicionar usuários padrões
# -----------------------------------------------------------------------------
RUN if ! grep -q ":${gid}:" /etc/group;then groupadd -g ${gid} app;fi
RUN useradd -u ${uid} -d /var/www/app -m -g ${gid} app \
	&& usermod -a -G ${gid} apache

RUN mkdir -p /var/www/app/{public_html,var/log,tmp}


# -----------------------------------------------------------------------------
# Setar permissões
# -----------------------------------------------------------------------------
RUN chown -R app:${gid} /var/www/app \
	&& chmod 770 /var/www/app \
	&& chmod -R g+w /var/www/app/var

# -----------------------------------------------------------------------------
# Remove packages
# -----------------------------------------------------------------------------
RUN yum -y remove \
	gcc \
	gcc-c++ \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

# -----------------------------------------------------------------------------
# Setando variaveis de ambiente para configuração do container
# -----------------------------------------------------------------------------
ENV APACHE_SERVER_ALIAS ""
ENV	APACHE_SERVER_NAME app-1.local
ENV	APP_HOME_DIR /var/www/app
ENV	DATE_TIMEZONE UTC
ENV	HTTPD /usr/sbin/httpd
ENV	TERM xterm

# -----------------------------------------------------------------------------
# Setando localização
# -----------------------------------------------------------------------------
RUN localedef -i pt_BR -f UTF-8 pt_BR.UTF-8
ENV LANG pt_BR.UTF-8

# -----------------------------------------------------------------------------
# Setando portas
# -----------------------------------------------------------------------------
EXPOSE ${PORTS_OPEN1} ${PORTS_OPEN2}

# -----------------------------------------------------------------------------
# Copiando todo o conteudo projeto para dentro do containter
# -----------------------------------------------------------------------------
COPY projeto /var/www/app

CMD ["/usr/sbin/httpd", "-DFOREGROUND"]