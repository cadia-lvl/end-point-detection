# End-point-detection
Example scripts for end-point detection (EPD) in audio recordings or online audio. End-point detection is necessary in longer auido recordings to chunk it down into smaller units for ASR decoding. It is a necessary first step before using any ASR.

## Table of Contents
  * Installation
  * Running
  * Licence
  * Authors/Credit
  * Acknowledgements

## Installation

* The onine EPD script works with Uberi's Speech recognition library, https://github.com/Uberi/speech_recognition.
  * The Speech recognition package need PyAudio. I had to install it like this:
      `sudo apt-get install portaudio19-dev python-all-dev python3-all-dev` and then `pip install pyaudio`
* The offline EPD scripts are intended to work within Kaldi, https://github.com/kaldi-asr/kaldi.
* Follow the installation instructions from there and nothing else is needed.

## Running
Both online and offline scripts are not supposed to be whole recipies. This in only one part of what it needed when transcribing audio with an ASR, so running these parts doesn't give any final output. The code is supposed to help someone along with using an ASR. The online EPD script needs to be changed according to which ASR you plug in. The offline EPD can be put as a first step in a run script which applies a Kaldi ASR.

For the offline script to work one need to have a Kaldi directory properly set up with symlinks to steps and utils in the Wall street journal recipe:
`ln -s $KALDI_ROOT/egs/wsj/s5/steps steps`
`ln -s $KALDI_ROOT/egs/wsj/s5/utils utils`

The offline EPD script can be run like this:
`bash segment_single_raw_audio.sh audio/audiofile1.mp3 output/audiofile1`

The outputdir audiofile1 will be a typical Kaldi directory, but not it containd the new file: segments

The online script can be run like this:
`python run.py`

It will continue recording and recognizing till you kill it with ctrl-C. Since I don't know the future use case for this I let this part wait. One can decide whether to save the audio to a file or not.

## License
MIT License

Copyright (c) 2020 Language and Voice Lab

## Acknowledgements
This project was funded by the Language Technology Programme for Icelandic 2019-2023. The programme, which is managed and coordinated by [Almannarómur](https://almannaromur.is/), is funded by the Icelandic Ministry of Education, Science and Culture.
