import sys, os
import logging, logging.config

# https://docs.python.org/3/library/logging.config.html#configuration-dictionary-schema
# https://stackoverflow.com/questions/7507825/where-is-a-complete-example-of-logging-config-dictconfig

def configureLogging(LOGNAME=__name__,LOGFILE='out.log', loglev = logging.DEBUG, coloron=True):
    fmt = "%(asctime)s [%(levelname)s] %(message)s"
    class CustomFormatter(logging.Formatter):
        """Logging Formatter to add colors and count warning / errors"""
        grey = "\033[37;40m"
        bold_yellow = "\033[33;1m"
        red = "\033[31;40m"
        bold_red = "\033[31;1m"
        bold_green = "\033[32;1m"
        reset = "\033[0m"
    
        FORMATS = {
            logging.DEBUG: grey + fmt + reset,
            logging.INFO: bold_green + fmt + reset,
            logging.WARNING: bold_yellow + fmt + reset,
            logging.ERROR: bold_red + fmt + reset,
            logging.CRITICAL: bold_red + fmt + reset
        }
        def format(self, record):
            log_fmt = self.FORMATS.get(record.levelno)
            formatter = logging.Formatter(log_fmt)
            return formatter.format(record)
    logging.config.dictConfig({'version':1,'disable_existing_loggers':True,'propagate':False})
    selflogger = logging.getLogger(LOGNAME)
    # selflogger.propagate = False
    fh = logging.FileHandler(LOGFILE)
    fh.setLevel(loglev)
    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(loglev)
    formatter = logging.Formatter(fmt)
    fh.setFormatter(formatter)
    if coloron: ch.setFormatter(CustomFormatter())
    else: ch.setFormatter(formatter)
    selflogger.addHandler(fh)
    selflogger.addHandler(ch)
    selflogger.setLevel(loglev)
    return selflogger

def getLogger(): return logging.getLogger("__main__")

def mconsole(msg,level='INFO'):
    tmplogger = getLogger()
    if level == 'DEBUG': getLogger().debug(msg)
    elif level == 'ERROR': getLogger().error(msg) 
    elif level == 'WARNING': getLogger().warning(msg)    
    else: getLogger().info(msg)
    
def batch_console(batchfile=None,batchlist=None,level="INFO"):
    if batchfile is not None and os.path.isfile(batchfile):
        with open(batchfile,"r") as f:
            batchlist = f.readlines()
    if batchlist is not None:
        for line in batchlist:
            mconsole(line.strip('\n'),level=level)
    else:
        mconsole("No file or list specified",level="ERROR")
    
LOGNAME=__name__
LOGFILE="main.log"