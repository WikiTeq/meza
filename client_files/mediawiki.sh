#!/bin/bash
#
# Setup MediaWiki
#
# Example:
#   bash mediawiki.sh
#
#   This script will prompt the user for several parameters
#

print_title "Starting script mediawiki.sh"


#
# Prompt for parameters
#
while [ -z "$mysql_root_pass" ]
do
echo -e "\n\nEnter MySQL root password and press [ENTER]: "
read -s mysql_root_pass
done

while [ -z "$mediawiki_git_install" ]
do
echo -e "\nInstall MediaWiki with git? (y/n) [ENTER]: "
read mediawiki_git_install
done


#
# Install Composer
#
cd ~/sources
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer


#
# Download MediaWiki
#
cd "$m_htdocs"

if [ "$mediawiki_git_install" = "y" ]; then
	# git clone https://github.com/wikimedia/mediawiki.git wiki
	cmd_profile "START mediawiki git clone"
	git clone https://gerrit.wikimedia.org/r/p/mediawiki/core.git mediawiki
	cd mediawiki

	# Checkout latest released version
	git checkout tags/1.25.1
	cmd_profile "END mediawiki git clone"
else
	cmd_profile "START mediawiki get from tarball"
	wget http://releases.wikimedia.org/mediawiki/1.25/mediawiki-core-1.25.1.tar.gz

	mkdir mediawiki
	tar xpvf mediawiki-core-1.25.1.tar.gz -C ./mediawiki --strip-components 1
	cd mediawiki
	cmd_profile "END mediawiki get from tarball"
fi


#
# Update Composer dependencies
#
# @FIXME: This may be able to be deferred until composer-extensions
cmd_profile "START mediawiki core composer update"
composer update
cmd_profile "END mediawiki core composer update"


#
# Download Vector skin
#
cd skins

if [ "$mediawiki_git_install" = "y" ]; then
	# git clone https://github.com/wikimedia/mediawiki-skins-Vector.git Vector
	git clone https://gerrit.wikimedia.org/r/p/mediawiki/skins/Vector.git Vector
	cd Vector
	git checkout REL1_25
	cd ..
else
	wget https://github.com/wikimedia/mediawiki-skins-Vector/archive/REL1_25.tar.gz
	mkdir Vector
	tar xpvf REL1_25.tar.gz -C ./Vector --strip-components 1
fi

#
# Copy in LocalSettings.php
#
cp "$m_meza/client_files/config/LocalSettings.php" "$m_htdocs/mediawiki/LocalSettings.php"


#
# Create common database credentials
#
echo -e "<?php\n\$wgDBuser = \"root\";\n\$wgDBpassword = \"$mysql_root_pass\";\n" > "$m_htdocs/__common/dbUserPass.php"


#
# Install Demo MW: create wiki directory, setup basic settings, create database
#
bash "$m_meza/client_files/create_wiki.sh" "demo" "Demo Wiki" "$mysql_root_pass"


#
# Modify LocalSettings.php, set $wgEnableUploads = true;
# Evidently must also set $wgMaxUploadSize = 1024*1024*100; to get over 40MB
#
# sed -r -i 's/\$wgEnableUploads\s*=\s*false;/$wgEnableUploads = true;\n$wgMaxUploadSize = 1024*1024*100; \/\/ 100 MB/g;' ./LocalSettings.php


# end of script
echo -e "\n\nMediaWiki has been installed"
