#!/bin/bash
if [ -d /software ] ;then
  cd /software
else
  mkdir /software && cd /software
fi

#is exist command ,if not,yum install
is_exist() {
  which $1
  if [ $? -ne 0 ] ;then
     yum -y install $1
  fi
}

#dolownad the mysql install package,if exist,check the md5sum,if correct,tar;else rm and download
if [ -f mysql-5.6.29.tar.gz ] ;then
  mysql_md5=`md5sum mysql-5.6.29.tar.gz | cut -d " " -f 1 `
  mysql_md5_true="aaa21c6450adee3a1894fd1710f02bf5"
  if [ "$mysql_md5" = "$mysql_md5_true" ] ;then
    tar -zxvf mysql-5.6.29.tar.gz
  else
    rm -rf mysql-5.6.29.tar.gz
　　　 rm -rf mysql-5.6.29
  fi
else
  is_exist wget
  wget http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.29.tar.gz
  tar -zxvf mysql-5.6.29.tar.gz
fi

#see the yum source is use
yum cleanup
yum makecache

#install the depend package
yum -y install gcc make cmake ncurses-devel libxml2-devel libtool-ltdl-devel gcc-c++ autoconf automake bison zlib-devel

#add mysql group and user
is_user_mysql=`cat /etc/passwd |awk -F ":" '{print $1}' |grep mysql`
is_group_mysql=`cat /etc/group |awk -F ":" '{print $1}' |grep mysql`

if [ "$is_group_mysql" != "mysql" ] ;then
  groupadd mysql
fi
if [ "$is_user_mysql" != "mysql" ] ;then
   useradd -r -s /sbin/nologin -g mysql mysql
fi

#compile and install
cd mysql-5.6.29
cmake .
make && make install

chown -R mysql.mysql /usr/local/mysql

#init database
/usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data

#copy the important file to /etc
#cp /usr/local/mysql/my.cnf /etc/my.cnf

sed -i 's/\# basedir \= ...../basedir \= \/usr\/local\/mysql/g' /usr/local/mysql/my.cnf
sed -i 's/\# port = ...../port = 3306/g' /usr/local/mysql/my.cnf
sed -i 's/\# datadir \= ...../datadir \= \/usr\/local\/mysql\/data/g' /usr/local/mysql/my.cnf
sed -i '/\[mysqld\]/a\log-error=\/usr\/local\/mysql\/log\/error.log' /usr/local/mysql/my.cnf
#sed -i '/\[mysqld\]/a\log=\/usr\/local\/mysql\/log\/log' /usr/local/mysql/my.cnf
#sed -i '/\[mysqld\]/a\log-slow-queries=\/usr\/local\/mysql\/log\/slowquery.log' /usr/local/mysql/my.cnf
sed -i '/\[mysqld\]/a\long_query_time=2' /usr/local/mysql/my.cnf
sed -i '/\[mysqld\]/a\pid-file=\/usr\/local\/mysql\/data\/mysql.pid' /usr/local/mysql/my.cnf
sed -i '/\[mysqld\]/a\character-set-server=utf8' /usr/local/mysql/my.cnf

echo "[client] " >> /usr/local/mysql/my.cnf
echo "socket = /var/lib/mysql/mysql.sock" >>/usr/local/mysql/my.cnf

/usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data
#use database
/usr/local/mysql/bin/mysqld_safe --user=mysql &

cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on

`ln -s /var/lib/mysql/mysql.sock /tmp/mysql.sock`
#start the service
service mysqld restart

#import environment
PATH=$PATH:/usr/local/mysql/bin
echo "export PATH=$PATH:/usr/local/mysql/bin >> /etc/profile"
source /etc/profile
`
