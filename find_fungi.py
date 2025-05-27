import requests
from tqdm import tqdm

# Path to your species.txt file
file_path = ".../species.txt"

# Read the first column of each line, skipping the header
proteome_ids = []
with open(file_path, 'r') as file:
    next(file)  # Skip header line
    for line in file:
        line = line.strip()
        if line:
            proteome_id = line.split()[0]
            proteome_ids.append(proteome_id)

# List to store fungal Proteome IDs
fungi_proteomes = []

# Check each ID via UniProt API
for pid in tqdm(proteome_ids, desc="Checking Proteome IDs"):
    url = f"https://rest.uniprot.org/proteomes/{pid}"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        lineage = data.get("taxonLineage", [])
        if any(taxon.get("scientificName") == "Fungi" for taxon in lineage):
            fungi_proteomes.append(pid)
    else:
        print(f"Failed to retrieve data for {pid}, status code: {response.status_code}")

# Save fungal Proteome IDs to fungi_list.txt
output_path = ".../fungi_list.txt"
with open(output_path, 'w') as outfile:
    for pid in fungi_proteomes:
        outfile.write(f"{pid}\n")

print(f"\nSaved {len(fungi_proteomes)} fungal Proteome IDs to {output_path}")