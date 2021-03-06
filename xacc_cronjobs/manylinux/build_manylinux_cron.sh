#!/bin/bash
docker build --network=host -t xacc/build_manylinux_wheels . --no-cache
tmpid=$(docker run -d xacc/build_manylinux_wheels bash -c "mkdir extract; cd extract ; mv /xacc/wheelhouse/*.whl /extract ") && sleep 5 && docker cp $tmpid:/extract . && docker rm -v $tmpid
ls extract
