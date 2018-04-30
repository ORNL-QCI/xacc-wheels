
tmpid=$(docker run -d xacc/build_tnqvm_wheels bash -c "mkdir extract; cd extract ; mv /tnqvm/dist/*.whl /extract ") && sleep 5 && docker cp $tmpid:/extract . && docker rm -v $tmpid
