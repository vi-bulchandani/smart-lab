import sys
import os
import urllib3
import requests
import httplib2
import json

from enum import Enum

class ThingSpeakClient:

    TimeScale = Enum(value="TimeScale", names= [
        ('M10',10),
        ('M15',15),
        ('M20',20),
        ('M30',30),
        ('M60',60),
        ('M240',240),
        ('M720',720),
        ('M1440',1440),
        ('DAILY',"daily")

    ])

    def __init__(self, channel: int, write_apiKey: str, read_apiKey=None):

        
        self._channel = channel
        self._write_apiKey = write_apiKey
        self._read_apiKey = read_apiKey
        self._fields = {
            "api_key": self._write_apiKey,
            "field1": None,
            "field2": None,
            "field3": None,
            "field4": None,
            "field5": None,
            "field6": None,
            "field7": None,
            "field8": None,
        }
    
    def resetFields(self):
        for i in range(1,9):
            self._fields["field{}".format(i)] = None



    @property
    def read_apiKey(self):
        return self._read_apiKey
    
    @read_apiKey.setter
    def read_apiKey(self,value):
        self._read_apiKey = value
    
    @property
    def channel(self):
        return self._channel
    
    @channel.setter
    def channel(self,value: int):
        self._channel = value
    
    @property
    def write_apiKey(self):
        return self._write_apiKey
    
    @write_apiKey.setter
    def write_apiKey(self,value: str):
        self._write_apiKey = value

    
    def setTSfield(self, number, value):
        self._fields["field{}".format(number)] = value
    
    def getTSfield(self, number):
        return self._fields["field{}".format(number)]

    
    def send_singleTSfield(self,number):
        data_json={}
        data_json['api_key']= self.write_apiKey
        data_json['field{}'.format(number)] = self.getTSfield(number)
        res = requests.post(url = "https://api.thingspeak.com/update.json",json=data_json)
        if(res.status_code==200):
            # self.resetFields()
            return True
            
        else:
            return False
        
    def send_multipleTSfields(self):
        res = requests.post(url = "https://api.thingspeak.com/update.json",json=self._fields)
        if(res.status_code==200):
            # self.resetFields()
            return True
        else:
            return False
    
    # def readallFields(self,results=None, days=1, minutes=1440, start=None, end=None, status=False, metadata=False, location = False, min=None, max=None,
    #                      round=None, timescale=None, sum=None, average=None, median=None):
    @staticmethod
    def filterNone(pair):
        key,value= pair
        return value is not None
    
    def readAllFields(self,**kwargs):
        
        params=dict(filter( ThingSpeakClient.filterNone, kwargs.items()))
        params['api_Key'] = self.read_apiKey
        # params['results']=results
        # params['days'] = days
        # params['minutes'] = minutes
        # params['start'] = start
        # params['end'] = end
        # params['status'] = status
        # params['metadata'] = metadata
        # params['location'] = location
        # params['min'] = min
        # params['max'] = max
        # params['round'] = round
        # params['timescale'] = timescale
        # params['sum'] = sum
        # params['average'] = average
        # params['median'] = median

        response = requests.get(url = "https://api.thingspeak.com/channels/{}/feeds.json".format(self.channel),
                                params=params)
        if(response.status_code==200):
            return json.loads(response.json())
        else: return {}

    
if __name__=="__main__":
    ts = ThingSpeakClient(channel=9, write_apiKey='PX70HD36BJ7MACXK', read_apiKey='E52AWRAV1RSXQQJW')
    print(ts.readAllFields(results=5))