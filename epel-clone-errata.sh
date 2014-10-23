#!/bin/bash
# Processes EPEL Errata and imports it into Spacewalk

# IMPORTANT: read through this script, it's more of a guidance than something fixed in stone
# also: if you're using the commandline options for usernames and passwords, comment out the
# line that says ". ./ya-errata-import.cfg"

# set fixed locale
export LC_ALL=C
export LANG=C

# Set your spacewalk server
SPACEWALK=127.0.0.1

# the EPEL version and architecture we're handling
EPEL_VERSION=6
EPEL_ARCH=x86_64

# create and/or cleanup the errata dir
ERRATADIR=/tmp/epel-errata
mkdir $ERRATADIR >/dev/null 2>&1
rm -f $ERRATADIR/* >/dev/null 2>&1

(
   cd $ERRATADIR
   # wget needs a proxy? Then set these
   export http_proxy=
   export https_proxy=

   # now download the errata, in this example we do it for EPEL-6-x86_64
   # EPEL changed repomd format
   # wget -q --no-cache http://dl.fedoraproject.org/pub/epel/$EPEL_VERSION/x86_64/repodata/updateinfo.xml.gz
   repomd=`wget -q -O - --no-cache http://dl.fedoraproject.org/pub/epel/$EPEL_VERSION/$EPEL_ARCH/repodata/repomd.xml`
   # we use perl minimal matching
   updateinfo_location=`echo $repomd | perl -pe 's/.*href="(.*?updateinfo.xml.gz).*/$1/;'`
   wget -q --no-cache -O updateinfo.xml.gz http://dl.fedoraproject.org/pub/epel/$EPEL_VERSION/$EPEL_ARCH/$updateinfo_location
   gunzip updateinfo.xml.gz
)

# Set usernames and passwords. You have some options here:
# 1) Either define the environment variables here:
# export SPACEWALK_USER=my_username
# export SPACEWALK_PASS=my_passwd
# export RHN_USER=my_rhn_username
# export RHN_PASS=my_rhn_password
# 2) Set them on the commandline (but I don't recommend it)
# 3) Set them in a separate cfg file and source it (like done below)
. ./ya-errata-import.cfg

# upload the errata to spacewalk, e.g. for a channel used by redhat servers:
/sbin/ya-errata-import.pl --epel_errata $ERRATADIR/updateinfo.xml --server $SPACEWALK --channel rhel-x86_64-server-6-epel --os-version 6 --publish --redhat --startfromprevious twoweeks --quiet
# upload the errata to spacewalk, e.g. for a channel used by centos servers:
/sbin/ya-errata-import.pl --epel_errata $ERRATADIR/updateinfo.xml --server $SPACEWALK --channel centos-x86_64-server-6-epel --os-version 6 --publish --startfromprevious twoweeks --quiet

rm -f $ERRATADIR/*
