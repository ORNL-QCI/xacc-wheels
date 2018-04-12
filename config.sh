# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

function dot_per_line {
    # http://unix.stackexchange.com/questions/117501/in-bash-script-how-to-capture-stdout-line-by-line
    while IFS= read -r line; do
        printf .
    done
    echo
}

function build_libs {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    local start_dir=$PWD
    if [ -n "$IS_OSX" ]; then
        brew install cmake openssl zlib
    else
	wget https://github.com/squeaky-pl/centos-devtools/releases/download/7.1/gcc-7.1.0-binutils-2.28-x86_64.tar.bz2
	yum install -y zlib-devel
	wget https://www.openssl.org/source/openssl-1.0.2n.tar.gz
	tar -xvzf openssl-1.0.2n.tar.gz
	cd openssl-1.0.2n
	CFLAGS=-fPIC ./config shared
	make
	make install
	cd $start_dir
	wget https://cmake.org/files/v3.6/cmake-3.6.2.tar.gz
	tar -xzvf cmake-3.6.2.tar.gz
	cd cmake-3.6.2
	./bootstrap --prefix=/usr/local
	make -j4 install
        ln -sf $(which cmake) /usr/bin/cmake
	cd $start_dir
    fi
    curl -LO https://downloads.sourceforge.net/project/boost/boost/1.61.0/boost_1_61_0.tar.gz
    echo Done downloading
    tar zxf boost_1_61_0.tar.gz
    echo Done unpacking
    cd boost_1_61_0
    ./bootstrap.sh --prefix=/usr/local --without-libraries=python,mpi
    # Reduce verbosity by showing dots for continuing stdout lines
    ./b2
    ./b2 install
    cd $start_dir

}

function build_wheel {
    build_libs $PLAT
    build_pip_wheel $@
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    python --version
    python -c "import pyxacc; print(pyxacc.__file__)"
}
