Installation of TheSNPpit on Singularity
================

## Requirements and Problems

From the documenatation given in the user
\[guide\]<https://tsp-repo.thesnppit.net/resources/TheSNPpit-user-guide-latest.pdf>),
it is clear that TheSNPpit as it comes out of the box is a program that
is targetted towards running on a single machine. This means that there
is one instance of the database-server and one installation of the
client programs that accesses the data in the database. Different users
on the same machine can use the client programs which can all interact
with the given instance of the database on the same machine.

![](odg/base-installation-thesnppit.png)<!-- -->

It gets more complicated if we want to be able work with the same data
from different machines. This requires to get access to the
database-server from different clients running on different machines.
This requires a distributed setup over different machines.

![](odg/distributed-installation-thesnppit.png)<!-- -->

A further requirement for using the provided installation infrastructure
is that root access is available on the machine where TheSNPPit is to be
installed.

As a consequence of the points described above, the automatic
installation script given in the tarball from TheSNPpit cannot be used.

## Strategy

The problems described in the previous section are to be solved in
different steps.

1.  Installation of TheSNPpit on a single ZWS-machine given the
    restrictions of not having root access to the machine and only
    having a single user `zws`. The single machine installation requires
    to do all steps given in the installation section of the user guide
    separately.
2.  Try to expand the clients to be able to be used on different
    machines. The distributed usage of TheSNPpit includes the
    installation of the database server on one machine and the client
    part of the package on all machines where TheSNPpit should be used.
    All the clients must be able to connect to the single instance of
    the database server. Alternatively it would also be possible to
    setup a master-slave replication scheme between the machines where
    one machine has the database master and all the others run
    replication slave databases. But so far, this seams to be too
    complicated compared to the benefits that would result from this
    setup.

## Installation Resources

### User Guide

We are currently checking the user guide on
<https://tsp-repo.thesnppit.net/resources/TheSNPpit-user-guide-latest.pdf>
for hints on how to install. Chapter 6 of the user guide describes the
installation. The proposed way to install TheSNPpit is to download the
tar-ball from the website, to unpack the tarball and to run the script
`bin/install`. Since this requires root priviledges, this cannot be used
in a singularity container.

### Manual Installation

In section 6.3 of the user guide, a manual installation is described. In
Listing 57, the software required by TheSNPpit is described. The
installation procedure given there is based on system-wide
installations.

## Experiments

This section describes the trials and experiments with a local
installation. The experiments consist of the four steps given in section
6.3 of the user guide.

### System software installation

In a first experiment, the system software is added to the list of
software that is installed in the singularity container. The following
statement checks whether the required system software is already in the
singularity definition file.

``` bash
cd /home/quagadmin/simg/img/ubuntu1804lts
for p in perl gcc PostgreSQL PostgreSQL-contrib libecpg6 libecpg-dev libdbi-perl libinline-perl libmodern-perl-perl libcloog-ppl1 libcloog-ppl0 libfile-slurp-perl libdbd-pg-perl libjudy-dev
do
  echo " * Checking def for $p ..."
  grep "$p" ../../def/ubuntu1804lts/quagzws_ubuntu1804lts.def
  sleep 2
done
```

All packages that were indicated except for `perl` and `gcc` which are
installed in the container by default are added to the container
building definition file and a new image is built.

``` bash
cd /home/quagadmin/simg/img/thesnppit
../../shub/bash/build_simg.sh -d ../../def/thesnppit/quagzws_ubuntu1804lts.def -w /home/quagadmin/simg/img/thesnppit
```

The original aim was to have all system software including the postgres
database installed in the singularity container. But with such a
database installation, user `zws` cannot start a local database, as is
shown
    below

    zws@1-htz:~$ /var/lib/postgresql/10/main/bin/initdb -D /qualstorzws01/data_projekte/projekte/thesnppit/data -A trust -U zws
    bash: /var/lib/postgresql/10/main/bin/initdb: Permission denied

A first attempt to fix this problem is to change the directory
permissions using `chmod` for `/var/lib/postgresql/10/main` in the
singularity recipe file. This makes the directory visible, but the `bin`
directory with the program to init a DB is not included there. According
to
<https://superuser.com/questions/1320145/postgresql-10-does-not-start-under-ubuntu-18-04>,
the bin-directory is found in `/usr/lib/postgresql/10/bin`. Hence the
command to init a DB
    is

    /usr/lib/postgresql/10/bin/initdb -D /qualstorzws01/data_projekte/projekte/thesnppit/data -A trust -U zws
    The files belonging to this database system will be owned by user "zws".
    This user must also own the server process.
    
    The database cluster will be initialized with locale "en_US.UTF-8".
    The default database encoding has accordingly been set to "UTF8".
    The default text search configuration will be set to "english".
    
    Data page checksums are disabled.
    
    fixing permissions on existing directory /qualstorzws01/data_projekte/projekte/thesnppit/data ... ok
    creating subdirectories ... ok
    selecting default max_connections ... 100
    selecting default shared_buffers ... 128MB
    selecting dynamic shared memory implementation ... posix
    creating configuration files ... ok
    running bootstrap script ... ok
    performing post-bootstrap initialization ... ok
    syncing data to disk ... ok
    
    Success. You can now start the database server using:
    
        /usr/lib/postgresql/10/bin/pg_ctl -D /qualstorzws01/data_projekte/projekte/thesnppit/data -l logfile start

This created several configuration files of which the port setting in
postgresql.conf was
    changed.

    mv /qualstorzws01/data_projekte/projekte/thesnppit/data/postgresql.conf /qualstorzws01/data_projekte/projekte/thesnppit/data/postgresql.conf.org
    cat /qualstorzws01/data_projekte/projekte/thesnppit/data/postgresql.conf.org | sed -e "s/\#port = 5432/port = 5434/" > /qualstorzws01/data_projekte/projekte/thesnppit/data/postgresql.conf

The database server is then started with

    LOGDIR=/qualstorzws01/data_projekte/projekte/thesnppit/log
    LOGFILE=$LOGDIR/`date +"%Y%m%d%H%M%S"`_postgres.log
    if [ ! -d "$LOGDIR" ];then mkdir -p $LOGDIR;fi
    /usr/lib/postgresql/10/bin/pg_ctl -D /qualstorzws01/data_projekte/projekte/thesnppit/data -l $LOGFILE start
    waiting for server to start.... done
    server started

Try to get a connection using the
    client

    /usr/lib/postgresql/10/bin/createuser -h localhost -p 5434 zws # throws an error and hence might not be necessary.
    /usr/lib/postgresql/10/bin/createdb -h localhost -p 5434 -O zws zws
    /usr/lib/postgresql/10/bin/psql -h localhost -p 5434

Stopping the database
    server

    /usr/lib/postgresql/10/bin/pg_ctl -D /qualstorzws01/data_projekte/projekte/thesnppit/data stop

This concludes the system software installation part of the user guide.

### Database Configuration

## First Experiments with a local PostgreSQL Database

### Local pgsql

In a first attempt, we try to compile our own pgsql database.

``` bash
mkdir -p /home/zws/postgresql/9.5/main
cd source/postgres
wget https://ftp.postgresql.org/pub/source/v9.5.19/postgresql-9.5.19.tar.gz
tar -xvzf postgresql-9.5.19.tar.gz 
cd postgresql-9.5.19/
./configure --prefix=/home/zws/postgresql/9.5/main
make
make install
```

According to
<https://stackoverflow.com/questions/40644400/create-postgresql-database-without-root-privilege>,
we try to start a local db-cluster using the following
commands.

``` bash
./postgresql/9.5/main/bin/initdb -D /home/zws/postgresql/9.5/main/data -A trust -U zws
```

The above resulted in the following
    output

    The files belonging to this database system will be owned by user "zws".
    This user must also own the server process.
    
    The database cluster will be initialized with locale "en_US.UTF-8".
    The default database encoding has accordingly been set to "UTF8".
    The default text search configuration will be set to "english".
    
    Data page checksums are disabled.
    
    fixing permissions on existing directory /home/zws/postgresql/9.5/main/data ... ok
    creating subdirectories ... ok
    selecting default max_connections ... 100
    selecting default shared_buffers ... 128MB
    selecting default timezone ... Europe/Berlin
    selecting dynamic shared memory implementation ... posix
    creating configuration files ... ok
    creating template1 database in /home/zws/postgresql/9.5/main/data/base/1 ... ok
    initializing pg_authid ... ok
    initializing dependencies ... ok
    creating system views ... ok
    loading system objects' descriptions ... ok
    creating collations ... ok
    creating conversions ... ok
    creating dictionaries ... ok
    setting privileges on built-in objects ... ok
    creating information schema ... ok
    loading PL/pgSQL server-side language ... ok
    vacuuming database template1 ... ok
    copying template1 to template0 ... ok
    copying template1 to postgres ... ok
    syncing data to disk ... ok
    
    Success. You can now start the database server using:
    
        ./postgresql/9.5/main/bin/pg_ctl -D /home/zws/postgresql/9.5/main/data -l logfile start

The question about where the configuration is stored is answered by
<https://serverfault.com/questions/152942/location-of-postgresql-conf-and-pg-hba-conf-on-an-ubuntu-server>

The above start command requires an empty `data` directory. The
configuration files will all be placed into the data directory. In
`postgresql.conf` the port was changed to 5434 to not get in conflict
with any other running postgresql instances.

Connecting with the client to the running database required the
following steps according to
<https://stackoverflow.com/questions/16973018/createuser-could-not-connect-to-database-postgres-fatal-role-tom-does-not-e/16974197#16974197>

where the `createuser` statement threw an error at me, but the database
creation worked. Afterwards I was able to connect with the client to the
database.

``` bash
./postgresql/9.5/main/bin/createuser -h localhost -p 5434 zws
./postgresql/9.5/main/bin/createdb -h localhost -p 5434 -O zws zws
./postgresql/9.5/main/bin/psql -h localhost -p 5434
```
