BootStrap: debootstrap
OSVersion: bionic
MirrorURL: http://archive.ubuntu.com/ubuntu/

%post
# the following causes multiple entries in /etc/apt/sources.list
#  sed -i 's/main/main restricted universe/g' /etc/apt/sources.list
#  apt update

  # install software properties commons for add-apt-repository
  apt install -y software-properties-common apt-utils
  apt update
  apt upgrade -y

  # Install system software for TheSNPpit
  apt install -y gcc perl make wget vim less screen curl locales time rsync gawk tzdata git dos2unix sshpass htop
  apt install -y libdbd-pg-perl libecpg6 libecpg-dev libdbi-perl libinline-perl libmodern-perl-perl libcloog-ppl1 libcloog-ppl-dev libfile-slurp-perl libpq5 libjudy-dev
  apt update -y
  echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list
  wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | apt-key add -
  apt install -y postgresql postgresql-contrib
  apt update -y
  apt upgrade -y
  apt clean
  
  # Install additional perl-modules for TheSNPPit
  curl -sSL "https://raw.githubusercontent.com/pvrqualitasag/quagtsp-sidef/master/etc/needed_perl_modules_tsp" > needed_perl_modules_tsp
  curl -sSL "https://raw.githubusercontent.com/pvrqualitasag/quagtsp-sidef/master/bash/install_perlmd_tsp.pl" > install_perlmd_tsp.pl
  perl -w install_perlmd_tsp.pl --install
  rm -rf install_perlmd_tsp.pl needed_perl_modules_tsp

  # install OpenJDK 8 (LTS) from https://adoptopenjdk.net
  curl -sSL "https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u222-b10/OpenJDK8U-jdk_x64_linux_hotspot_8u222b10.tar.gz" > openjdk8.tar.gz
  mkdir -p /opt/openjdk
  tar -C /opt/openjdk -xf openjdk8.tar.gz
  rm -f openjdk8.tar.gz

  # permissions for postgres
  chmod -R 755 /var/lib/postgresql/10/main
  chmod -R 777 /var/run/postgresql

  # dconf problem
  mkdir -p /run/user/501
  chmod -R 777 /run/user
  
  # locales
  locale-gen en_US.UTF-8
  locale-gen de_CH.UTF-8

  # timezone
  echo 'Europe/Berlin' > /etc/timezone

  # hostname
  echo '1-htz.quagzws.com' > /etc/hostname

%environment
  export PATH=${PATH}:/opt/openjdk/jdk8u222-b10/bin:/qualstorzws01/data_projekte/linuxBin
  export TZ=$(cat /etc/timezone)

