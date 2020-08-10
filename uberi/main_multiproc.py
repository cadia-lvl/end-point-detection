import multiprocessing
from multiprocessing import Queue
import speech_recognition as sr
import contextlib
import os
import sys
import logging

# Get rid of some of the microphone error messages on linux computers
@contextlib.contextmanager
def ignore_stderr():
    devnull = os.open(os.devnull, os.O_WRONLY)
    old_stderr = os.dup(2)
    sys.stderr.flush()
    os.dup2(devnull, 2)
    os.close(devnull)
    try:
        yield
    finally:
        os.dup2(old_stderr, 2)
        os.close(old_stderr)


def record_audio(m, r, q):
    '''Listen to audio, chunk it down and put in a queue'''
    try:
        while True:
            with ignore_stderr() as n, m as source:
                try:
                    audio = r.listen(source, timeout=.1)
                    q.put(audio)
                except sr.WaitTimeoutError:
                    logging.info("Timeout")
                    pass
    except KeyboardInterrupt:
        pass


def recognize_audio(r, q):
    '''Transcribe the audio chunks, using the chosen ASR. Here the google ASR should be switched out for an Icelandic one.'''
    #i=0
    while True:
        try:
            #i=i+1
            audio = q.get()
            #with open(f"audio_file_{i}.wav", "wb") as file:
            #    file.write(audio.get_wav_data())
            value = r.recognize_google(audio)
            print(value)
        except sr.UnknownValueError:
            print("Oops! Didn't catch that")
        except sr.RequestError as e:
            print(
                f"Uh oh! Couldn't request results from Google Speech Recognition service; {e}")
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    
    logging.basicConfig(filename='main_multiproc.log', level=logging.DEBUG)
    r = sr.Recognizer()
    m = sr.Microphone() # One can denote which mickrophone to use with device_index after listing the ones available
    

    print("A moment of silence, please...")
    with ignore_stderr() as n, m as source:
        r.adjust_for_ambient_noise(source)
    print(f"Set minimum energy threshold to {r.energy_threshold}")
    print("Say something!")

    # Put the recognizing in its own process to not disturb the listening of audio
    q = Queue()
    p1 = multiprocessing.Process(name="p1", target=recognize_audio, args=(r, q,))
    p1.start()
    record_audio(m,r,q)
    p1.join()
