import configparser
ip=""
with open("public-ip","r") as public_ip:
    ip=public_ip.readline()

with open('../../client/src/files/config.ini', 'w') as configfile:
    config = configparser.ConfigParser()
    config["DEFAULT"]["master"]=ip
    config.write(configfile)
