#!/bin/bash

# Copyright 2020  Reykjavik University (Author: Inga Rún Helgadóttir)
# Apache 2.0

set -o pipefail

stage=0
cmd=run.pl

. ./path.sh
. ./cmd.sh

if [ "$1" = "-h" ] || [ $# -lt 2 ]; then
    echo "This script takes in an audio file and returns a kaldi directory containing the following files:"
    echo "wav.scp, pointing to the location of the audio files,"
    echo "utt2spk and spk2utt, which connect speakers and audio files, and the new segment file, which stores the new segment time stamps."
    echo "The segments are found using energy based voice activity detection, and used when transcribing the audio."
    echo "The parent directory of this script must contain path.sh and cmd.sh,"
    echo "a config directory with the files mfcc.conf and vad.conf and a symlink to steps and utils."
    echo "It is assumed that you are running this within a Kaldi example dir, otherwise change path.sh."
    echo ""
    echo "Usage: $0 [options] <audiofile> <outputdir>"
    echo " e.g.: $0 audio/radXXX.mp3 output/radXXX"
    echo ""
    exit 1;
fi

speechfile=$1
speechname=$(basename "$speechfile")
extension="${speechname##*.}"
speechname="${speechname%.*}"

dir=$2
outdir=$dir/${speechname}
tmp=$outdir/tmp
mkdir -p $outdir $tmp

# Create a dummy speaker file
echo -e "unknown",$speechname > $tmp/${speechname}_meta.tmp
speakerfile=$tmp/${speechname}_meta.tmp

length=$(soxi -D $speechfile) || error 1 "$speechfile is not an audio file"

if [ ${length%.*} -lt 1 ]; then
    echo "The audio file is empty"
    exit 1;
fi

# SoX converts all audio files to an internal uncompressed format before performing any audio processing
samplerate=16000
wav_cmd="sox -t$extension - -c1 -esigned -r$samplerate -G -twav - "

IFS=$'\n' # Split on new line

if [ $stage -le 0 ]; then
    
    # Extract the speaker info
    grep "$speechname" $speakerfile | tr "," "\t" > $tmp/spkname_speechname.tmp
    spkID=$(cut -f1 $tmp/spkname_speechname.tmp | perl -pe 's/[ \.]//g')
    
    echo "a) utt2spk" # Connect each speech ID to a speaker ID.
    printf "%s %s\n" ${spkID}-${speechname} ${spkID} | tr -d $'\r' > $tmp/utt2spk
    
    # Make a helper file with mapping between the speechnames and uttID
    echo -e ${speechname} ${spkID}-${speechname} | tr -d $'\r' | LC_ALL=C sort -n > $tmp/speechname_uttID.tmp
    
    echo "b) wav.scp" # Connect every speech ID with an audio file location.
    echo -e ${spkID}-${speechname} $wav_cmd" < "$(readlink -f ${speechfile})" |" | tr -d $'\r' > $tmp/wav.scp
    
    echo "c) spk2utt"
    utils/utt2spk_to_spk2utt.pl < $tmp/utt2spk > $tmp/spk2utt
fi

if [ $stage -le 1 ]; then
    echo "Extracting features"
    steps/make_mfcc.sh \
    --nj 1 \
    --mfcc-config conf/mfcc.conf \
    --cmd "$train_cmd"           \
    $tmp || exit 1;
    
    echo "Computing cmvn stats"
    steps/compute_cmvn_stats.sh $tmp || exit 1;
fi

if [ $stage -le 2 ]; then
    echo "Get vad.scp"
    steps/compute_vad_decision.sh \
    --vad-config conf/vad.conf \
    --nj 1 --cmd "$train_cmd" \
    $tmp $tmp/log $tmp/mfcc
fi

if [ $stage -le 3 ]; then
    echo "Segment the audio" # method from callhome_diarization
    local/vad_to_segments.sh \
    --nj 1 --cmd "$train_cmd" \
    --segmentation-opts "--silence-proportion 0.2 --max-segment-length 10" \
    $tmp ${outdir}
fi

if [ $stage -le 4 ]; then
    
    echo "Make sure all files are created and that everything is sorted"
    utils/validate_data_dir.sh --no-text ${outdir} || utils/fix_data_dir.sh ${outdir}
fi

IFS=$' \t\n'
exit 0;
