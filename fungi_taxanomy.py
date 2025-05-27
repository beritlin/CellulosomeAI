import requests
from tqdm import tqdm

# Path to your species.txt file
file_path = ".../species.txt"

# Read the first column of each line, skipping the header
proteome_ids = []
with open(file_path, 'r') as file:
    next(file)  # Skip header
    for line in file:
        line = line.strip()
        if line:
            proteome_id = line.split()[0]
            proteome_ids.append(proteome_id)

# For results
fungi_info = []

# Query each Proteome ID
for pid in tqdm(proteome_ids, desc="Checking Proteome IDs"):
    url = f"https://rest.uniprot.org/proteomes/{pid}"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        lineage = data.get("taxonLineage", [])

        # Find index of "Fungi" in lineage
        fungi_index = next((i for i, taxon in enumerate(lineage) if taxon.get("scientificName") == "Fungi"), None)
        
        if fungi_index is not None:
            # Extract classification after "Fungi"
            after_fungi = [taxon["scientificName"] for taxon in lineage[fungi_index + 1:]]
            fungi_info.append((pid, after_fungi))
    else:
        print(f"Failed to retrieve data for {pid}, status code: {response.status_code}")

# Output to screen and file
output_path = ".../fungi_taxanomy.txt"
with open(output_path, 'w') as f:
    for pid, classification in fungi_info:
        print(f"{pid} ➜ {' > '.join(classification)}")
        f.write(f"{pid}\t{' > '.join(classification)}\n")

print(f"\n✅ Saved {len(fungi_info)} fungal Proteome IDs and their classification to {output_path}")