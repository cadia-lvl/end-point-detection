#!/bin/bash

stage=0
cmd=run.pl

. ./path.sh
. ./cmd.sh

if [ "$1" = "-h" ] || [ $# -lt 1 ]; then
    echo "This script takes in a Kaldi directory containing the files: wav.scp, pointing to the location of the audio files,"
    echo "and utt2spk and spk2utt, which connect speakers and audio files. It segments the audio input using energy based voice activity detection"
    echo "and stores the new segment time stamps in a file called segments, which is then used when transcribing the audio."
    echo "The parent directory this script must also contain path.sh and cmd.sh,"
    echo "a config directory with the files mfcc.conf and vad.conf and a symlink to steps and utils."
    echo "It is assumed that you are running this within a Kaldi example dir, otherwise change path.sh."
    echo ""
    echo "Usage: $0 <data-dir>"
    echo " e.g.: $0 kaldi/egs/isl-asr/s5/data"
    echo ""
    exit 1;
fi

datadir=$1

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