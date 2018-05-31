#!/bin/bash
docker build --network=host -t xacc/build_ibm_wheels . --no-cache
tmpid=$(docker run -d xacc/build_ibm_wheels bash -c "mkdir extract; cd extract ; mv /xacc-ibm/wheelhouse/*.whl /extract ") && sleep 5 && docker cp $tmpid:/extract . && docker rm -v $tmpid
ls extract
