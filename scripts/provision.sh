#!/usr/bin/env bash


yum_prepare() {

    # To add the CentOS 7 EPEL repository, open terminal and use the following command:
    yum -y install epel-release
    yum -y install yum-priorities yum-utils yum-plugin-versionlock yum-plugin-show-leaves yum-plugin-upgrade-helper

    # ensure build tools are installed.
    yum -y group install 'Development Tools'

    # nodes repo
    curl --silent --location https://rpm.nodesource.com/setup_5.x | bash -

    yum -y update
}

yum_install() {
    yum -y install autoconf make automake sendmail sendmail-cf m4

    yum -y install vim mlocate curl htop wget dos2unix tree
    yum -y install ntp nmap nc whois libnotify inotify-tools telnet ngrep
}

install_node5() {
    # https://nodejs.org/en/download/package-manager/#enterprise-linux-and-fedora

    yum install -y nodejs
    /usr/bin/npm install -g gulp
    /usr/bin/npm install -g bower
}

install_git2() {
    # http://tecadmin.net/install-git-2-0-on-centos-rhel-fedora/
    v=2.5.4
    yum install -y perl-Tk-devel curl-devel expat-devel gettext-devel openssl-devel zlib-devel
    yum remove -y git
    pushd /usr/src
    wget "https://www.kernel.org/pub/software/scm/git/git-$v.tar.gz"
    tar -xvf "git-$v.tar.gz"
    pushd "git-$v"
    make prefix=/usr/local/git all
    make prefix=/usr/local/git install
    echo "export PATH=\$PATH:/usr/local/git/bin" >> /etc/bashrc

    echo "Installation of git-$v complete"
}

install_nginx() {
    # https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-centos-7
    yum install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx

    firewall-cmd --permanent --zone=public --add-service=http
    firewall-cmd --permanent --zone=public --add-service=https
    # firewall-cmd --reload

    # Server Block Configuration

    # Any additional server blocks, known as Virtual Hosts in Apache, can be added by creating new configuration files in /etc/nginx/conf.d.
    # Files that end with .conf in that directory will be loaded when Nginx is started.

    # Nginx Global Configuration

    # The main Nginx configuration file is located at /etc/nginx/nginx.conf.
    # This is where you can change settings like the user that runs the Nginx daemon processes,
    # and the number of worker processes that get spawned when Nginx is running, among other things.
}

install_supervisor() {

    # install supervisor
    # http://vicendominguez.blogspot.com.au/2015/02/supervisord-in-centos-7-systemd-version.html
    # http://www.alphadevx.com/a/455-Installing-Supervisor-and-Superlance-on-CentOS
    yum install -y python-setuptools python-pip
    easy_install supervisor
    mkdir -p /etc/supervisor
    echo_supervisord_conf > /etc/supervisor/supervisord.conf

    cat << SUPERVISOR_EOF > "/usr/lib/systemd/system/supervisord.service"
[Unit]
Description=supervisord - Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
ExecReload=/usr/bin/supervisorctl reload
ExecStop=/usr/bin/supervisorctl shutdown
User=root

[Install]
WantedBy=multi-user.target
SUPERVISOR_EOF

    chmod 755 /usr/lib/systemd/system/supervisord.service
    systemctl enable supervisord
}

install_sqlite() {
    yum -y install sqlite-devel sqlite
}

install_postgresql95() {
    # http://tecadmin.net/install-postgresql-9-5-on-centos/
    rpm -Uvh http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-centos95-9.5-2.noarch.rpm

    yum -y install postgresql95-server postgresql95 postgresql95-contrib
    /usr/pgsql-9.5/bin/postgresql95-setup initdb

    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/9.5/data/postgresql.conf

    sed -ir "s/local[[:space:]]*all[[:space:]]*all[[:space:]]*peer/#local     all       all       peer/g"  /var/lib/pgsql/9.5/data/pg_hba.conf

    echo "local   all        all                                trust" | tee -a /var/lib/pgsql/9.5/data/pg_hba.conf
    echo "host    all        all        10.0.2.2/32             md5" | tee -a /var/lib/pgsql/9.5/data/pg_hba.conf
    echo "host    all        all        10.20.1.0/2             md5" | tee -a /var/lib/pgsql/9.5/data/pg_hba.conf
    echo "host    all        all        10.20.0.0/24            trust" | tee -a /var/lib/pgsql/9.5/data/pg_hba.conf
    echo "host    all        all        10.0.2.2/32             trust" | tee -a /var/lib/pgsql/9.5/data/pg_hba.conf
    echo "host    all        all        127.0.0.1/32            trust" | tee -a /var/lib/pgsql/9.5/data/pg_hba.conf

    systemctl start postgresql-9.5
    systemctl enable postgresql-9.5

    sudo -u postgres psql -c "CREATE ROLE homestead LOGIN UNENCRYPTED PASSWORD 'secret' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"
    sudo -u postgres /usr/bin/createdb --echo --owner=homestead homestead

    systemctl restart postgresql-9.5
}

install_postgresql95_bdr() {
    echo "TODO look at bdr extension for pg95"
}

install_other() {
    # http://tecadmin.net/install-postgresql-9-5-on-centos/
    yum -y install redis

    systemctl start redis.service
    systemctl enable redis.service
    systemctl restart redis.service

    # install memcache
    yum -y install memcached

    systemctl enable memcached.service
    systemctl start memcached.service
    systemctl restart memcached.service


    # install beanstalk
    yum -y install beanstalkd

    systemctl enable beanstalkd.service
    systemctl start beanstalkd.service
    systemctl restart beanstalkd.service

}

install_php_remi() {
    # https://www.cloudinsidr.com/content/how-to-install-php-7-on-centos-7-red-hat-rhel-7-fedora/

    #rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm

    yum-config-manager --enable remi-php70

    yum -y install \
        php70-php \
        php70-php-cli \
        php70-php-common \
        php70-php-intl \
        php70-php-fpm \
        php70-php-xml \
        php70-php-xmlrpc \
        php70-php-pdo \
        php70-php-gmp \
        php70-php-process \
        php70-php-devel \
        php70-php-mbstring \
        php70-php-mcrypt \
        php70-php-gd \
        php70-php-readline \
        php70-php-pecl-imagick \
        php70-php-opcache \
        php70-php-memcached \
        php70-php-pecl-apcu \
        php70-php-imap \
        php70-php-pecl-jsond \
        php70-php-pecl-jsond-devel \
        php70-php-pecl-xdebug \
        php70-php-bcmath \
        php70-php-mysqlnd \
        php70-php-pgsql \
        php70-php-imap \
        php70-php-pear

    systemctl enable php70-php-fpm

    systemctl start php70-php-fpm

    ln -s /usr/bin/php70 /usr/bin/php

    # Set Some PHP CLI Settings

    sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/opt/remi/php70/php.ini
    sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/opt/remi/php70/php.ini
    sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/opt/remi/php70/php.ini
    sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/opt/remi/php70/php.ini


    # Setup Some PHP-FPM Options

    sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini
    sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini
    sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.0/fpm/php.ini
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.0/fpm/php.ini
    sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.0/fpm/php.ini
    sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/fpm/php.ini


    # Set The Nginx & PHP-FPM User

    sed -i "s/user www-data;/user vagrant;/" /etc/nginx/nginx.conf
    sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

    sed -i "s/user = www-data/user = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
    sed -i "s/group = www-data/group = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf

    sed -i "s/listen\.owner.*/listen.owner = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
    sed -i "s/listen\.group.*/listen.group = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
    sed -i "s/;listen\.mode.*/listen.mode = 0666/" /etc/php/7.0/fpm/pool.d/www.conf

    service nginx restart
    service php7.0-fpm restart

}

install_php_webtatic() {
    #rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

    yum -y install \
        php70w \
        php70w-cli \
        php70w-common \
        php70w-intl \
        php70w-fpm \
        php70w-xml \
        php70w-pdo \
        php70w-devel \
        php70w-xmlrpc \
        php70w-gd \
        php70w-pecl-imagick
        php70w-opcache \
        php70w-pecl-apcu \
        php70w-imap \
        php70w-mysql \
        php70w-curl \
        php70w-memcached \
        php70w-readline \
        php70w-pecl-xdebug
}

install_composer() {
    # Install Composer

    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer

     # Install Laravel Envoy & Installer
    sudo su - vagrant <<'EOF'
    /usr/local/bin/composer global require "laravel/envoy=~1.0"
    /usr/local/bin/composer global require "laravel/installer=~1.1"
    /usr/local/bin/composer global require "phing/phing=~2.9.0"

    # Add Composer Global Bin To Path
    printf "\nPATH=\"~/.config/composer/vendor/bin/:\$PATH\"\n" | tee -a ~/.bash_profile
EOF

     # Install Laravel Envoy & Installer
    /usr/local/bin/composer global require "laravel/envoy=~1.0"
    /usr/local/bin/composer global require "laravel/installer=~1.1"
    /usr/local/bin/composer global require "phing/phing=~2.9.0"

    # Add Composer Global Bin To Path
    printf "\nPATH=\"~/.config/composer/vendor/bin/:\$PATH\"\n" | tee -a ~/.bash_profile
}

install_mysql() {

    # http://www.tecmint.com/install-latest-mysql-on-rhel-centos-and-fedora/
    wget http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
    yum -y localinstall mysql57-community-release-el7-7.noarch.rpm

    # check repos installed.
    yum repolist enabled | grep "mysql.*-community.*"

    yum -y install mysql-community-server

    systemctl enable mysqld.service
    systemctl start mysqld.service

    # Configure Centos Mysql 5.7+

    # http://blog.astaz3l.com/2015/03/03/mysql-install-on-centos/
    echo "default_password_lifetime = 0" >> /etc/mysql/my.cnf
    echo "bind-address = 0.0.0.0" >> /etc/my.cnf
    echo "validate_password_policy=LOW;" >> /etc/my.cnf
    echo "validate_password_length=6" >> /etc/my.cnf
    systemctl restart mysqld.service

    # find temporary password
    mysql_password=`sudo grep 'temporary password' /var/log/mysqld.log | sed 's/.*localhost: //'`
    mysqladmin -u root -p"$mysql_password" password secret
    mysqladmin -u root -psecret variables | grep validate_password

    mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
    systemctl restart mysqld.service

    mysql --user="root" --password="secret" -e "CREATE USER 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret';"
    mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
    mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'homestead'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
    mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"
    mysql --user="root" --password="secret" -e "CREATE DATABASE homestead;"
    systemctl restart mysqld.service
}

yum_prepare
yum_install
install_supervisor
install_nginx
install_git2
install_node5
install_sqlite
install_postgresql95
install_mysql
install_other
install_php_remi
install_composer

