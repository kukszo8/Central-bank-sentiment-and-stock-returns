import json
from pprint import pprint as print

import requests
from bs4 import BeautifulSoup
from tqdm import tqdm

json_path = "https://www.federalreserve.gov/json/ne-speeches.json"

speeches_meta: list = requests.get(json_path).content.decode("utf-8-sig")

speeches_meta_list = json.loads(speeches_meta)

with open("data/fed_speeches_meta.jsonl", "w") as file:
    for meta in speeches_meta_list:
        file.write(json.dumps(meta) + "\n")


with open("data/fed_speeches_body.jsonl", "w") as file:
    for meta in tqdm(speeches_meta_list[0:7], desc="Downloading speeches", colour="green"):
        response = requests.get("https://www.federalreserve.gov" + meta.get("l"))
        if response.status_code == 200:
            soup = BeautifulSoup(response.content, "html.parser")
            paragraphs = [p.get_text() for p in soup.find_all("p")]
            content = "\n\n".join(paragraphs)
            file.write(json.dumps({"content": content}) + "\n")
        else:
            print(f"Failed to download {meta.get('l')}: {response.status_code}")
            file.write(json.dumps({"content": None}) + "\n")
