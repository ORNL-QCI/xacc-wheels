#!/bin/bash

set -e

mkdir -p $HOME/wheelhouse
mkdir -p $HOME/wheelhouse/xacc
mkdir -p $HOME/wheelhouse/rigetti
mkdir -p $HOME/wheelhouse/ibm
mkdir -p $HOME/wheelhouse/tnqvm
mkdir -p $HOME/wheelhouse/vqe

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

function updateCprPath {
	install_name_tool -change $1/tmp_build/lib/libcpr.dylib @rpath/libcpr.dylib $2
}

function updateBoostLibs {
        install_name_tool -change libboost_system.dylib @rpath/libboost_system.dylib $1 
        install_name_tool -change libboost_unit_test_framework.dylib @rpath/libboost_unit_test_framework.dylib $1 
        install_name_tool -change libboost_filesystem.dylib @rpath/libboost_filesystem.dylib $1 
        install_name_tool -change libboost_program_options.dylib @rpath/libboost_program_options.dylib $1 
        install_name_tool -change libboost_regex.dylib @rpath/libboost_regex.dylib $1 
        install_name_tool -change libboost_chrono.dylib @rpath/libboost_chrono.dylib $1 
        install_name_tool -change libboost_graph.dylib @rpath/libboost_graph.dylib $1 
}

function clone {
	git clone https://github.com/ornl-qci/$1
}

#git clone --recursive https://github.com/eclipse/xacc
#clone xacc-rigetti
clone xacc-ibm
clone xacc-vqe
clone tnqvm 

for version in 2.7.14 3.3.7 3.4.7 3.5.4 3.6.4
do
	pyenv virtualenv $version xacc-$version
	pyenv activate xacc-$version
	python --version
 	python -m pip install --upgrade pip
	python -m pip install wheel
	export libPath=$(python -c "import distutils.util; print(distutils.util.get_platform())")
	echo $libPath
	cd xacc
	export ver=`case $version in "3.6.4") echo 3.6 ;; "3.5.4") echo 3.5 ;; "3.5.0") echo 3.5 ;; "3.4.7") echo 3.4 ;; "3.3.7") echo 3.3 ;; "2.7.14") echo 2.7 ;; *) echo "invalid";; esac`
        export verstr=`case $ver in "3.6") echo "cp36-cp36m" ;; "3.5") echo "cp35-cp35m" ;; "3.4") echo "cp34-cp34m" ;; "3.3") echo "cp33-cp33m" ;; "2.7") echo "cp27-cp27mu" ;; *) echo "invalid";; esac`

	# ------------------- XACC BUILD ------------------#
	python setup.py build -t tmp_build --executable="/usr/bin/env python"
	export buildPath=build/lib.$libPath-$ver
	echo "./xacc" >> build/lib.$libPath-$ver/xacc.pth

	install_name_tool -change libcpr.dylib @rpath/libcpr.dylib $buildPath/xacc/lib/libxacc.dylib
	install_name_tool -add_rpath "@loader_path" $buildPath/xacc/lib/libboost_regex.dylib
	install_name_tool -add_rpath "@loader_path" $buildPath/xacc/lib/libboost_chrono.dylib
	install_name_tool -add_rpath "@loader_path" $buildPath/xacc/lib/libboost_filesystem.dylib
	install_name_tool -add_rpath "@loader_path" $buildPath/xacc/lib/libboost_graph.dylib
	install_name_tool -change libboost_system.dylib @rpath/libboost_system.dylib $buildPath/xacc/lib/libboost_filesystem.dylib
	install_name_tool -change libboost_system.dylib @rpath/libboost_system.dylib $buildPath/xacc/lib/libboost_chrono.dylib
	install_name_tool -change libboost_regex.dylib @rpath/libboost_regex.dylib $buildPath/xacc/lib/libboost_graph.dylib

	updateCprPath $PWD $buildPath/xacc/pyxacc.so
	updateBoostLibs $buildPath/xacc/lib/libxacc-quantum-gate.dylib
	updateBoostLibs $buildPath/xacc/lib/libxacc-quantum-aqc.dylib
	updateBoostLibs $buildPath/xacc/pyxacc.so

	python setup.py bdist_wheel --skip-build
	mv dist/*.whl $HOME/wheelhouse/xacc
	
        export prefix="build\/lib."
        export suffix="-$ver"
        export arch=$(echo $libPath | sed -e "s/^$prefix//" -e "s/$suffix$//" | sed -e 's/-/_/g' | sed -e 's/\./_/g')
        echo $arch
	echo $verstr
	which python

	export xaccdir=$(pwd)

	# ---------------- RIGETTI BUILD -------------------#
	cd ../xacc-rigetti
        PYTHONPATH=../xacc/$buildPath/xacc python setup.py build -t tmp_build --executable="/usr/bin/env python"
	updateCprPath $xaccdir $buildPath/xacc/plugins/libxacc-rigetti-quilcompiler.dylib 
	updateCprPath $xaccdir $buildPath/xacc/plugins/libxacc-rigetti-accelerator.dylib 
	updateBoostLibs $buildPath/xacc/plugins/libxacc-rigetti-quilcompiler.dylib
	updateBoostLibs $buildPath/xacc/plugins/libxacc-rigetti-accelerator.dylib

	python setup.py bdist_wheel --skip-build
	mv dist/*.whl $HOME/wheelhouse/rigetti

	# ---------------- IBM BUILD -------------------#
	cd ../xacc-ibm

        PYTHONPATH=../xacc/$buildPath/xacc python setup.py build -t tmp_build --executable="/usr/bin/env python"

	updateCprPath $xaccdir $buildPath/xacc/plugins/libxacc-ibm-accelerator.dylib 
	updateBoostLibs $buildPath/xacc/plugins/libxacc-ibm-accelerator.dylib

	python setup.py bdist_wheel --skip-build
	mv dist/*.whl $HOME/wheelhouse/ibm

	# ---------------- TNQVM BUILD -------------------#
	cd ../tnqvm

        PYTHONPATH=../xacc/$buildPath/xacc python setup.py build -t tmp_build --executable="/usr/bin/env python"

	updateCprPath $xaccdir $buildPath/xacc/plugins/libtnqvm.dylib 
	updateCprPath $xaccdir $buildPath/xacc/plugins/libtnqvm-itensor.dylib 
	updateBoostLibs $buildPath/xacc/plugins/libtnqvm.dylib
	updateBoostLibs $buildPath/xacc/plugins/libtnqvm-itensor.dylib

	python setup.py bdist_wheel --skip-build
	mv dist/*.whl $HOME/wheelhouse/tnqvm

	# ---------------- VQE BUILD -------------------#
	cd ../xacc-vqe

        PYTHONPATH=../xacc/$buildPath/xacc python setup.py build -t tmp_build --executable="/usr/bin/env python"

	updateCprPath $xaccdir $buildPath/xacc/pyxaccvqe.so 
	updateCprPath $xaccdir $buildPath/xacc/plugins/libxacc-vqe-fermion-compiler.dylib 
	updateCprPath $xaccdir $buildPath/xacc/plugins/libxacc-vqe-fermion-compiler.dylib 
	updateCprPath $xaccdir $buildPath/xacc/plugins/libxacc-vqe-ir.dylib 
	updateCprPath $xaccdir $buildPath/xacc/plugins/libxacc-vqe-tasks.dylib 
	updateCprPath $xaccdir $buildPath/xacc/plugins/libxacc-vqe-irtransformations.dylib 
	updateCprPath $xaccdir $buildPath/xacc/plugins/libxacc-vqe-no-mpi.dylib 

	updateBoostLibs $buildPath/xacc/pyxaccvqe.so
	updateBoostLibs $buildPath/xacc/plugins/libxacc-vqe-fermion-compiler.dylib
	updateBoostLibs $buildPath/xacc/plugins/libxacc-vqe-ir.dylib
	updateBoostLibs $buildPath/xacc/plugins/libxacc-vqe-tasks.dylib
	updateBoostLibs $buildPath/xacc/plugins/libxacc-vqe-irtransformations.dylib
	updateBoostLibs $buildPath/xacc/plugins/libxacc-vqe-no-mpi.dylib

	python setup.py bdist_wheel --skip-build
	mv dist/*.whl $HOME/wheelhouse/vqe

	cd ..
	python -m pip uninstall -y xacc

	source deactivate
done

