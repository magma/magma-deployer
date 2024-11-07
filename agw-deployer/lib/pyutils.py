#!/usr/bin/env python3
import json
import os
import sys
from tqdm import tqdm
import shlex, subprocess
import time, datetime
from subprocess import PIPE
import logging, logging.config


def wait_bar(seconds):
    wait_range = tqdm(range(seconds)) 
    for ii in wait_range:
        wait_range.refresh()
        time.sleep(1)
    wait_range.write("DONE", file=None, end='\n', nolock=False)
    wait_range.close()
    print()

def cd(path):
    os.chdir(path)

def oscmd(cmdstr): # Prints out to console and returns exit status
    return os.system(cmdstr)

def cmd(cmdstr,removeblank=False): # Returns the output of the command as a list
    output = os.popen(cmdstr).read().split("\n")
    if len(output) > 0 and removeblank:
        output = [ln for ln in output if ln != ""]
    return output

def cmd0(cmdstr): # Returns first line of output as a string
    retlst = cmd(cmdstr)
    return retlst[0].strip()

def cmds(cmdstr): # Returns all output  of the command as a string
    output = os.popen(cmdstr).read()
    return output

def cmd_subp(cmdstr):
    args = shlex.split(cmdstr)
    procdata = subprocess.Popen(args)
    return procdata

def prtlines(lines):
    devnull = [print(line) for line in lines]
    
def cmd_all(cmdstr,output=False):
    args = shlex.split(cmdstr)
    procdata = subprocess.run(args,stdout=PIPE,stderr=PIPE)
    stdout = procdata.stdout.decode('utf-8').split('\n')
    stderr = procdata.stderr.decode('utf-8').split('\n')    
    stderr = [line for line in stderr if line != ""]
    
    if output:
        print("STDOUT")
        prtlines(stdout)
        print("STDERR")
        prtlines(stderr)
    return {'stdout':stdout,'stderr':stderr }

def humandate(unixtime):
    retstr = datetime.datetime.fromtimestamp(unixtime).strftime('%Y-%m-%d-%H-%M-%S-%f')
    return retstr

def humandatenow():
    retstr = datetime.datetime.now().strftime('%Y-%m-%d-%H-%M-%S-%f')
    return retstr

def printhumandatenow(prstr=""): print(humandatenow(),prstr)

def getFreeMem(): return int(cmd("free -m")[1].split(" ")[-1])

def getMemUsage(dirlst):
    # needs to be called with getMemUsage(dir())
    # These are the usual ipython objects, including this one you are creating
    ipython_vars = ['In', 'Out', 'exit', 'quit', 'get_ipython', 'ipython_vars']
    # Get a sorted list of the objects and their sizes
    retlst = sorted([(x, sys.getsizeof(globals().get(x))) for x in dirlst if not x.startswith('_') and \
            x not in sys.modules and x not in ipython_vars], key=lambda x: x[1], reverse=True)
    return retlst

def getLastLine(fn): # Faster than running a commandline
    with open(fn,'rb') as f:
        f.seek(-2, os.SEEK_END)
        while f.read(1) != b'\n':
            f.seek(-2,os.SEEK_CUR)
        last_line = f.readline().decode()
#         print(last_line)
    return last_line

from timeit import timeit
def timefunc(func,*args,nexp=10,**kwargs):
    ''' time a function with *args and **kwargs '''
    def wrapper(func, *args, **kwargs):
        def wrapped():
            return func(*args, **kwargs)
        return wrapped
    wrapped = wrapper(func,*args,**kwargs)
    timeret = timeit(wrapped,number=nexp)
    return timeret

''' JSON '''
def readJSON(fn):
    retdict = {}
    if os.path.isfile(fn):
        with open(fn,"r") as f:
            retdict = json.load(f)
    else:
        writeJSON(fn,retdict)
    return retdict

def writeJSON(fn,injson):
    with open(fn,"w") as f:
        json.dump(injson,f,indent=4)

''' ZIP '''
def dunzip(zipfilefull,dstdir="."): # Unzip file to destination directory -- works as pandas.series.apply
    with zipfile.ZipFile(zipfilefull,"r") as zipd:
        zipcontents = zipd.namelist()
        for zipitem in zipcontents:
            zipdstfile = os.path.join(dstdir,zipitem)
            if not os.path.exists(zipdstfile):
                print("Extracting %s from %s to %s" % (zipitem,zipfilefull,dstdir))
                zipd.extract(zipitem, dstdir)
    return zipitem # Assumes only one item

