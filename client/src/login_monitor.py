import os
import inotify.adapters
import requests, socket
from configparser import ConfigParser

def _init():
    global HOSTNAME
    global MASTER
    global CURRENT_COUNT
    parser = ConfigParser()
    parser.read('files/config.ini')
    # INITIALIZE THE GLOBAL SETTINGS
    HOSTNAME = socket.gethostname().strip()
    MASTER=parser['DEFAULT']['master']
    CURRENT_COUNT=_get_login_counts()

def _get_login_counts():
    data=os.popen("utmpdump /var/log/wtmp | grep '\[[7]\]' | wc -l").read().strip()
    return data

def _update_login_count(count):
    global MASTER
    global HOSTNAME
    url = MASTER+"/add"
    data = {"hostname": HOSTNAME, "count": int(count)}
    x = requests.post(url, json=data)

def _main():
    global CURRENT_COUNT
    i = inotify.adapters.Inotify()

    i.add_watch('/var/log/wtmp')

    for event in i.event_gen(yield_nones=False):
        login_count=_get_login_counts()
        if not CURRENT_COUNT == login_count:
            _update_login_count(login_count)
            CURRENT_COUNT = login_count

if __name__ == '__main__':
    _init()
    _main()
