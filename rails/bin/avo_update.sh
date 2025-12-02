#!/bin/bash
echo "🔄 Mise à jour automatique des resources Avo…"
cd /app || exit 1  # dans le conteneur rails, /app est le dossier du projet

for file in app/models/*.rb; do
  model=$(basename "$file" .rb)
  # ignore ApplicationRecord
  if [[ "$model" == "application_record" ]]; then
    continue
  fi
  class_name=$(echo "$model" | awk -F'_' '{for(i=1;i<=NF;i++){printf toupper(substr($i,1,1)) substr($i,2)} print ""}')
  echo "🧩 Regénération de la resource Avo pour $class_name"
  rails generate avo:resource "$class_name" --force >/dev/null 2>&1
done

echo "✅ Mise à jour Avo terminée."
