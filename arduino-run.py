import serial
import io
import json
import re
import thingspeak as ts
numre = r'-?\d+\.?\d*'
data={"MQ5": None, "CO": None, "Temperature": None, "Humidity": None}


if __name__ == "__main__":
    tsclient = ts.ThingSpeakClient(channel=2098172, write_apiKey='PX70HD36BJ7MACXK', read_apiKey='17J3EX7IDD6YMO9Y')

    with serial.Serial('/dev/ttyACM0', baudrate=9600, timeout=10) as ser:
        while True:
            line = ser.readline().decode().strip()
            print('{', line,'}')
            data['AQ']=None
            data['MQ5']=None
            if line.startswith('MQ5'):
                s= [float(s) for s in re.findall(numre, line)]
                if len(s)>0:
                    data["MQ5"]=s[1]
                    print(data["MQ5"])
                    tsclient.setTSfield(2, data["MQ5"])
            elif line.startswith('CO:'):
                s= [float(s) for s in re.findall(numre, line)]
                if len(s)>0:
                    data["CO"]=s[0]
                    print(data['CO'])
                    tsclient.setTSfield(1,data['CO'])
            elif line.startswith('Temperature:'):
                s= [float(s) for s in re.findall(numre, line)]
                if len(s)>0:
                    data["Temperature"]=s[0]
                    print(data['Temperature'])
                    tsclient.setTSfield(3,data['Temperature'])
            elif line.startswith('Humidity:'):
                s= [float(s) for s in re.findall(numre, line)]
                if len(s)>0:
                    data["Humidity"]=s[0]
                    print(data['Humidity'])
                    tsclient.setTSfield(4,data['Humidity'])
            print(tsclient.send_multipleTSfields())
            


            
    