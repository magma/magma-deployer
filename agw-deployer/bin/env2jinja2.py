#!/usr/bin/env python
import sys, os
# from _abc import __name__
sys.path.append("../../lib")
from optparse import OptionParser
from pyutils import *
import jinja2
from jinja2 import Template


from dotenv import load_dotenv
from dotenv import dotenv_values

from simlogging import *


LOGNAME=__name__
TEMPLATEFILE="../files/hosts.yml.j2"
OUTFILE="../tmp/hosts.yml"
DOTENVDIR="../bootstrap"
cnf = {}

def main():
    global logger
    LOGFILE="env2jinja2.log"
    logger = configureLogging(LOGNAME=LOGNAME,LOGFILE=LOGFILE,coloron=False)

    try:
        mconsole("Starting {}".format(__file__))
        (options,_) = cmdOptions()
        kwargs = {**cnf, **options.__dict__.copy()}
        env = getEnv()
        renderTemplate(env)
    except KeyboardInterrupt:
        sys.exit(0)
        
def getEnv():
    envfn = os.path.join(DOTENVDIR,".env")
    if os.path.isfile(envfn):
        return dotenv_values(envfn)
    else:
        mconsole(f".env file ({envfn} does not exist")
    pass

def renderTemplate(data, templatefn = TEMPLATEFILE, outfile = OUTFILE):
    with open(templatefn) as f:
        rendered = Template(f.read()).render(data)
    with open(outfile,'w') as f:
        f.writelines(rendered)
    pass
    
def cmdOptions():
    parser = OptionParser(usage="usage: %prog [options]")
    parser.add_option("-d", "--debug",
                  action="store_true", dest="debug", default=False,
                  help="Debugging mode")
    return  parser.parse_args()

if __name__ == '__main__': main()
if __name__ == '_abc': main()