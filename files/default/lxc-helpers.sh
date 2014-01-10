alias xcl='lxc-ls --fancy'

export GOLDEN_CONTAINER=g-ubuntu-precise-chef-client

function xcg {
    [[ -n $1 ]] && GOLDEN_CONTAINER=$1
    echo "Golden Container is '$GOLDEN_CONTAINER'"
}
function xcw {
    [[ -n $1 ]] && WORKING_CONTAINER=$1
    echo "Working Container is '$WORKING_CONTAINER'"
}
function xcr {
    echo "Running command in '$WORKING_CONTAINER'"
    lxc-attach -n $WORKING_CONTAINER --clear-env -- $@
}
function xc-chroot {
    echo "Running command in '$WORKING_CONTAINER' chroot"
    chroot "/var/lib/lxc/$WORKING_CONTAINER/rootfs" $@
}
function xci {
    if [[ -n $1 ]]; then
	local CHEF_VERSION="-v $1"
    fi
    echo "Installing Chef $1 on '$WORKING_CONTAINER'"
    curl -L https://www.opscode.com/chef/install.sh | chroot /var/lib/lxc/$WORKING_CONTAINER/rootfs/ bash -s -- $CHEF_VERSION
}
function xcz {
    echo "Configuring Chef's client.rb in '$WORKING_CONTAINER'"
    if chroot /var/lib/lxc/$WORKING_CONTAINER/rootfs [ ! -a /root/chef-zero.pem ]; then
	chroot /var/lib/lxc/$WORKING_CONTAINER/rootfs ssh-keygen -t rsa -f /root/chef-zero.pem
    fi
    if chroot /var/lib/lxc/$WORKING_CONTAINER/rootfs [ ! -d /etc/chef ]; then
	chroot /var/lib/lxc/$WORKING_CONTAINER/rootfs mkdir /etc/chef
    fi
    echo "chef_server_url 'http://33.33.34.1:8889'" | chroot /var/lib/lxc/$WORKING_CONTAINER/rootfs tee /etc/chef/client.rb
    echo "client_key '/root/chef-zero.pem'" | chroot /var/lib/lxc/$WORKING_CONTAINER/rootfs tee -a /etc/chef/client.rb
}
function xcs {
    if [[ -n $1 ]]; then
	if [[ -n $2 ]]; then
	    echo "Setting GOLDEN_CONTAINER=$1"
	    GOLDEN_CONTAINER=$1
	    echo "Setting WORKING_CONTAINER=$2"
	    WORKING_CONTAINER=$2
	else
	    echo "Setting WORKING_CONTAINER=$1"
	    WORKING_CONTAINER=$1
	fi
    fi
    if ! lxc-info -n $WORKING_CONTAINER &> /dev/null; then
	echo "Cloning '$GOLDEN_CONTAINER' into '$WORKING_CONTAINER'"
	lxc-clone -s -o $GOLDEN_CONTAINER -n $WORKING_CONTAINER
    fi
    echo "Starting '$WORKING_CONTAINER'"
    lxc-start -d -n $WORKING_CONTAINER
    echo "Waiting for '$WORKING_CONTAINER' to be RUNNING"
    lxc-wait -t 10 -n $WORKING_CONTAINER -s RUNNING
}
function xck {
    if [[ -n $1 ]]; then
	echo "Setting WORKING_CONTAINER=$1"
	WORKING_CONTAINER=$1
    fi
    echo "Stopping '$WORKING_CONTAINER'"
    lxc-stop -n $WORKING_CONTAINER
}
function xcd {
    if [[ -n $1 ]]; then
	echo "Setting WORKING_CONTAINER=$1"
	WORKING_CONTAINER=$1
    fi
    echo "Killing '$WORKING_CONTAINER'"
    lxc-kill -n $WORKING_CONTAINER
    echo "Waiting for '$WORKING_CONTAINER' to be STOPPED"
    lxc-wait -t 10 -n $WORKING_CONTAINER -s STOPPED
    echo "Destroying '$WORKING_CONTAINER'"
    lxc-destroy -n $WORKING_CONTAINER
}