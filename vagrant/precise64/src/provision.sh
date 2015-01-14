echo "this shell script is going to setup a running ckan instance"

echo "switching the OS language"
locale-gen
export LC_ALL="en_US.UTF-8"
sudo locale-gen en_US.UTF-8

echo "updating the package manager"
sudo apt-get update

echo "installing dependencies available via apt-get"
sudo apt-get install python-dev postgresql libpq-dev python-pip python-virtualenv git-core solr-jetty openjdk-6-jdk vim -y

cd /usr/lib/ckan/default/src
if [[ ! -d ckan ]]; then
  echo "cloning ckan git repository"
  git clone -b ckan-2.2 https://github.com/ckan/ckan.git ckan
else
  echo "deleting *.pyc files"
  cd ckan
  find . -name "*.pyc" | xargs rm
fi

echo "installing the dependencies available via pip"
#sudo mkdir -p /usr/lib/ckan/default
sudo chown vagrant /usr/lib/ckan/default
virtualenv --no-site-packages /usr/lib/ckan/default
. /usr/lib/ckan/default/bin/activate
#pip install -e 'git+https://github.com/ckan/ckan.git@ckan-2.2#egg=ckan'
cd /usr/lib/ckan/default/src/ckan
pip install -e .
pip install -r /usr/lib/ckan/default/src/ckan/requirements.txt
deactivate
. /usr/lib/ckan/default/bin/activate

echo "editing postgresql configuration"
sudo cp /etc/postgresql/9.1/main/pg_hba.conf /etc/postgresql/9.1/main/pg_hba_org.conf
sudo sed -i -e "s/peer$/trust/g" /etc/postgresql/9.1/main/pg_hba.conf
sudo sed -i -e "s/md5$/trust/g" /etc/postgresql/9.1/main/pg_hba.conf
sudo sh -c "echo 'host    all             all             10.0.0.1/32            trust' >> /etc/postgresql/9.1/main/pg_hba.conf"
sudo cp /etc/postgresql/9.1/main/postgresql.conf /etc/postgresql/9.1/main/postgresql_org.conf
sudo sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.1/main/postgresql.conf
sudo service postgresql restart

echo "creating a postgres user and database"
sudo -u postgres createuser -S -D -R ckan_default
sudo -u postgres psql -c "ALTER USER ckan_default with password 'pass'"
sudo -u postgres createdb -O ckan_default ckan_default -E utf-8

echo "creating and editing configuration files"
sudo mkdir -p /etc/ckan/default
sudo chown -R vagrant /etc/ckan/
cd /usr/lib/ckan/default/src/ckan
paster make-config ckan /etc/ckan/default/development.ini
cp /etc/ckan/default/development.ini /etc/ckan/default/development_org.ini
sudo sed -i -e "s/#solr_url\s*=.*/solr_url = http:\/\/127.0.0.1:8983\/solr/g" /etc/ckan/default/development.ini

echo "editing jetty configuration"
sudo cp /etc/default/jetty /etc/default/jetty_org
sudo sed -i -e "s/NO_START=1/NO_START=0/g" /etc/default/jetty
sudo sed -i -e "s/#JETTY_HOST=.*/JETTY_HOST=127.0.0.1/g" /etc/default/jetty
sudo sed -i -e "s/#JETTY_PORT=.*/JETTY_PORT=8983/g" /etc/default/jetty
sudo sed -i -e "s/#JAVA_HOME=.*/JAVA_HOME=\/usr\/lib\/jvm\/java-6-openjdk-amd64\//g" /etc/default/jetty
sudo service jetty start

echo "linking the solr schema file"
sudo mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
sudo ln -s /usr/lib/ckan/default/src/ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml

echo "restarting jetty for the new configuration to kick-in"
sudo service jetty restart

echo "initialize the database for ckan"
cd /usr/lib/ckan/default/src/ckan
paster db init -c /etc/ckan/default/development.ini

echo "linking to who.ini"
ln -s /usr/lib/ckan/default/src/ckan/who.ini /etc/ckan/default/who.ini

#MEMO: "launch Paste development server"
#cd /usr/lib/ckan/default/src/ckan
#paster serve /etc/ckan/default/development.ini

echo "creating production.ini file"
cp /etc/ckan/default/development.ini /etc/ckan/default/production.ini

echo "installing deployment dependencies available via apt-get"
sudo apt-get install apache2 libapache2-mod-wsgi nginx -y

echo "defining apache2 server name"
echo "ServerName localhost" | sudo tee /etc/apache2/conf.d/fqdn

echo "copying wsgi script file"
cp /vagrant/vagrant/precise64/src/apache.wsgi /etc/ckan/default/apache.wsgi

echo "copying apache config file"
sudo cp /vagrant/vagrant/precise64/src/apache/ckan_default /etc/apache2/sites-available/ckan_default

echo "copying nginx config file"
sudo cp /vagrant/vagrant/precise64/src/nginx/ckan_default /etc/nginx/sites-available/ckan_default

echo "enabling the site"
sudo mv /etc/apache2/ports.conf /etc/apache2/ports_org.conf
echo "Listen 8080" | sudo tee /etc/apache2/ports.conf
sudo a2ensite ckan_default
sudo a2dissite 000-default
sudo ln -s /etc/nginx/sites-available/ckan_default /etc/nginx/sites-enabled/ckan_default
sudo service apache2 reload
sudo service nginx reload

echo "creating admin user"
cd /usr/lib/ckan/default/src/ckan
paster --plugin=ckan user add admin email=admin@email.org password=pass -c /etc/ckan/default/production.ini
paster --plugin=ckan sysadmin add admin -c /etc/ckan/default/production.ini

echo "loading test data"
paster --plugin=ckan create-test-data -c /etc/ckan/default/production.ini

deactivate

echo "you should now have a running instance on http://10.0.0.10:8080"
