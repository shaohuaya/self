import requests
import json
url='http://apiproxy/v3/ondemand/createVM'
data={"ua":"13700002000","pw":"12qwaszx","ct":12}

r=requests.post(url,data=json.dumps(data))
print (r.text)
