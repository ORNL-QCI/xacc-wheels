# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]

DOCKER_IMAGE=xacc/manylinux1_x86_64

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
        brew install cmake boost curl 
    else
        yum -y install curl-devel openssl-devel
    fi
    cd $start_dir

}

function build_wheel {
    build_libs $PLAT
    build_pip_wheel $@
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    python --version
    python -c "import pyxacc, os; print(pyxacc.__file__); pyxacc.Initialize(['--internal-plugin-path',os.path.dirname(os.path.realpath(pyxacc.__file__))+'/lib'])"
}
