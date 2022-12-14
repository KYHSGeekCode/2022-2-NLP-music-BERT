#!/bin/bash
# python ${PATH-TO-FAIRSEQ_ROOT}/fairseq_cli/train.py ${args}.
# bash train_genre.sh topmagd 13 0 checkpoints/checkpoint_last_musicbert_base.pt
# bash train_xai.sh xai 28 0 checkpoints/checkpoint_last_musicbert_base.pt
export CUDA_VISIBLE_DEVICES=0

# cd checkpoints
# wget https://msramllasc.blob.core.windows.net/modelrelease/checkpoint_last_musicbert_small.pt
# wget https://msramllasc.blob.core.windows.net/modelrelease/checkpoint_last_musicbert_base.pt
# cd -

TOTAL_NUM_UPDATES=7000
WARMUP_UPDATES=300
PEAK_LRS=(0.00001 0.000001 0.0001)
TOKENS_PER_SAMPLE=8192
MAX_POSITIONS=8192
BATCH_SIZE=32
MAX_SENTENCES=4
subset=xai
UPDATE_FREQ=$((${BATCH_SIZE} / ${MAX_SENTENCES} / 1))
HEAD_NAME=xai_head

SIZES=("base")
for size in "${SIZES[@]}"
do
    
    MUSICBERT_PATH=checkpoints/checkpoint_last_musicbert_${size}.pt

    for lr in "${PEAK_LRS[@]}"
        do
        CHECKPOINT_SUFFIX=xai_apex_M2PF_${lr}_${size}.pt
        fairseq-train processed/xai_data_bin_apex_reg_cls_base_split/0 --user-dir musicbert \
            --restore-file $MUSICBERT_PATH \
            --max-update $TOTAL_NUM_UPDATES \
            --batch-size $MAX_SENTENCES --update-freq $UPDATE_FREQ \
            --max-positions $MAX_POSITIONS \
            --max-tokens $((${TOKENS_PER_SAMPLE} * ${MAX_SENTENCES})) \
            --task xai \
            --reset-optimizer --reset-dataloader --reset-meters \
            --required-batch-size-multiple 1 \
            --num-workers 0 \
            --seed 7 \
            --init-token 0 --separator-token 2 \
            --arch musicbert_${size} \
            --criterion M2PF_xai \
            --classification-head-name $HEAD_NAME \
            --num-cls-classes 25 \
            --dropout 0.1 --attention-dropout 0.1 --weight-decay 0.01 \
            --optimizer adam --adam-betas "(0.9, 0.98)" --adam-eps 1e-6 --clip-norm 0.0 \
            --lr-scheduler polynomial_decay --lr $lr --total-num-update $TOTAL_NUM_UPDATES --warmup-updates $WARMUP_UPDATES \
            --log-format json --log-interval 100 \
            --tensorboard-logdir checkpoints_base_split/M2PF/board_apex_${lr}_${size} \
            --best-checkpoint-metric R2 \
            --shorten-method "truncate" \
            --save-dir checkpoints_base_split \
            --checkpoint-suffix _${CHECKPOINT_SUFFIX} \
            --no-epoch-checkpoints \
            --maximize-best-checkpoint-metric \
            --find-unused-parameters 
        done
done