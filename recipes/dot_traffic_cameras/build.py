import requests
import pandas as pd
import sys

user_agent = {'User-agent': 'Mozilla/5.0'}
r = requests.get('https://webcams.nyctmc.org/new-data.php?query=', headers = user_agent).json()
df = pd.DataFrame(r['markers'])
df['url'] = 'https://webcams.nyctmc.org/google_popup.php?cid=' + df.id

df.to_csv('raw.csv', 
    cols=['content', 'icon', 'id', 'latitude', 'longitude', 'title', 'url'], index=False)
