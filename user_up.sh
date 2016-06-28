# user_up.sh
# OurCIO(r)
if test $1 = "-h" || test $1 = "--help"; then
    # Give them help
    echo "user_up.sh usage and  syntax:"
    echo " user_up.sh -h | --help "
    echo "    displays this help text"
    echo " user_up.sh <username> (<password>)"
    echo "   Will create a username with the password supplied or default password"
    echo "   It sets the user to have the default unsecure vagrant ssh key"
    echo "   These users are intended for testing ONLY."  
    echo "   You need at least one test user for each vmname machine for rsyncvmshare"
    echo "   to work properly."
    echo "   Default password is Password1!"
  else
    # perform the work
    sudo useradd  -p "*" -U -m $1 -G sudo
    if [[ ! -z "$2" ]]; then  
        echo "$1:$2" | sudo chpasswd
      else
        echo "$1:Password1!" | sudo chpass
    fi
    sudo cp -r /home/core/.ssh/authorized_keys.d/ /home/$1/.ssh/authorized_keys.d
    sudo update-ssh-keys -u $1 $1.pem
fi
