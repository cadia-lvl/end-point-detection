#!/bin/bash

# Copyright 2017  Reykjavik University (Author: Inga Rún Helgadóttir)
# Apache 2.0          # Isn't that ridiculous? These are a few commands from Kaldi

# This script takes in kaldi prepared data and splits the audio into smaller segments for transcription
# The datadir must contain the files spk2utt, utt2spk and wav.scp.
# The parent directory this script must also contain path.sh and cmd.sh,
# a config directory with the files mfcc.conf and vad.conf and at least a symlink to steps and utils
# ln -s $KALDI_ROOT/egs/wsj/s5/steps steps
# ln -s $KALDI_ROOT/egs/wsj/s5/utils utils

stage=0
cmd=run.pl

. ./path.sh
. ./cmd.sh

datadir=/work/inga/data/endpoint/h14_trimmed

utils/validate_data_dir.sh --no-feats ${datadir} || utils/fix_data_dir.sh ${datadir} || exit 1;

# Get the features
steps/make_mfcc.sh \
--nj 20 --mfcc-config conf/mfcc.conf \
--cmd "$train_cmd" \
$datadir ${datadir}/log ${datadir}/mfcc

# Get vad.scp
steps/compute_vad_decision.sh \
--vad-config conf/vad.conf \
--nj 20 --cmd "$train_cmd" \
$datadir ${datadir}/log ${datadir}/mfcc

# Segment the audio, method from callhome_diarization
local/vad_to_segments.sh \
--nj 20 --cmd "$train_cmd" \
--segmentation-opts "--silence-proportion 0.2 --max-segment-length 10" \
$datadir ${datadir}_segmented

utils/validate_data_dir.sh --no-text ${datadir}_segmented || utils/fix_data_dir.sh ${datadir}_segmented || exit 1;

exit 0;