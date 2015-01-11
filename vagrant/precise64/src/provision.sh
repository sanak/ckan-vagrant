echo "this shell script is going to setup a running ckan instance"

echo "switching the OS language"
locale-gen
export LC_ALL="en_US.UTF-8"
sudo locale-gen en_US.UTF-8

echo "updating the package manager"
sudo apt-get update

echo "installing dependencies available via apt-get"
sudo apt-get install python-dev postgresql libpq-dev python-pip python-virtualenv git-core solr-jetty openjdk-6-jdk vim -y

cd /vagrant/src
if [[ ! -d ckan ]]; then
  echo "cloning ckan git repository"
  git clone -b ckan-2.2 https://github.com/ckan/ckan.git ckan
fi

echo "installing the dependencies available via pip"
sudo mkdir -p /usr/lib/ckan/default
sudo chown vagrant /usr/lib/ckan/default
virtualenv --no-site-packages /usr/lib/ckan/default
. /usr/lib/ckan/default/bin/activate
#pip install -e 'git+https://github.com/ckan/ckan.git@ckan-2.2#egg=ckan'
mkdir -p /usr/lib/ckan/default/src
cp -R /vagrant/src/ckan /usr/lib/ckan/default/src/
cd /usr/lib/ckan/default/src/ckan
pip install -e .
pip install -r /usr/lib/ckan/default/src/ckan/requirements.txt
deactivate
. /usr/lib/ckan/default/bin/activate

echo "creating a postgres user and database"
sudo -u postgres createuser -S -D -R ckan_default
sudo -u postgres psql -c "ALTER USER ckan_default with password 'pass'"
sudo -u postgres createdb -O ckan_default ckan_default -E utf-8

echo "copying configuration files"
sudo mkdir -p /etc/ckan/default
sudo chown -R vagrant /etc/ckan/
#cd /usr/lib/ckan/default/src/ckan
#paster make-config ckan /etc/ckan/default/development.ini
cd /etc/ckan/default/
cp /vagrant/vagrant/precise64/src/development.ini development.ini

echo "copying jetty configuration"
sudo cp /vagrant/vagrant/precise64/jetty /etc/default/jetty
sudo service jetty restart

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

echo "you should now have a running instance on http://localhost:8080"
