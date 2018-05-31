#!/bin/bash
docker build --network=host -t xacc/build_vqe_wheels . --no-cache
tmpid=$(docker run -d xacc/build_vqe_wheels bash -c "mkdir extract; cd extract ; mv /xacc-vqe/wheelhouse/*.whl /extract ") && sleep 5 && docker cp $tmpid:/extract . && docker rm -v $tmpid
ls extract
