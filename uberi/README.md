The script main_multiproc.py uses the multiprocessing python library to be able to both record audio and recognize in parallel without disturbing the recording process. 
It should work in situations where we want immediate recognition of continuous speech, e.g. to put subtitles to lectures.

Inga Run Helgadottir wrote this script to work with Uberi's Speech Recognition package: https://github.com/Uberi/speech_recognition
Read the requirements on the github page and install then the package with pip install SpeechRecognition
