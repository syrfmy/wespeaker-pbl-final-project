#!/bin/bash
# Copyright 2021 Hongji Wang

stage=-1
stop_stage=-1

config=conf/XVEC.yaml
exp_dir=exp/XVEC
num_avg=10
gpus="[0,1]"

. tools/parse_options.sh || exit 1;

# TODO: local/prepare_data.sh
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    echo "Preparing datasets..."
    
    for folder in vox2_dev vox1 musan rirs_noises; do
        mkdir -p data/$folder
        echo "Making wav.scp utt2spk .."
    done
fi


if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    echo "Start training ..."
    num_gpus=$(echo $gpus | awk -F ',' '{print NF}')
    torchrun --standalone --nnodes=1 --nproc_per_node=$num_gpus \
        wenet_speaker/bin/train.py --config $config \
                                    --exp_dir ${exp_dir} \
                                    --seed 42 \
                                    --gpus $gpus \
                                    --num_avg ${num_avg}
fi

if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    echo "Do model average ..."
    python wenet_speaker/bin/average_model.py \
        --dst_model $exp_dir/models/avg_model.pt \
        --src_path $exp_dir/models  \
        --num ${num_average}
    
    echo "Extract embeddings ..."
    local/extract_vox.sh --exp_dir $exp_dir
fi

# TODO: wenet_speaker/bin/score.py
if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    echo "Python scoring ..."
    #python wenet_speaker/bin/score.py \
    #    --config $dir/config.yaml \
    #    --test_data data/test/data.list \
    #    --batch_size 256 \
    #    --checkpoint $score_checkpoint \
    #    --score_file $result_dir/score.txt \
    #    --num_workers 8
fi

