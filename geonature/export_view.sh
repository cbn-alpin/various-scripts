#!/bin/bash
old_dataset_uuid="8eaa8dd4-cb9c-4223-8c25-a7307e2dfdd6"
new_dataset_uuid="840efa00-6115-479f-b408-5192410fdd69"
old_source_code="CEN_PACA_EXPORT|CBNA_EXPORT"
new_source_code="TDB_TEST"

# Replace insert to "v_synthese_for_tests" by "synthese"

sed -i --follow-symlinks "s/v_synthese_for_tests/synthese/" "${1}"

# Supprime les quotes autours des fonctions d'un export de la synthese GeoNature v2.3.1
sed -i --follow-symlinks "s/'gn_synthese\.get_id_source(''\([^']*\)'')'/gn_synthese.get_id_source('\1')/" "${1}"
sed -i --follow-symlinks "s/'gn_meta\.get_id_dataset(''\([^']*\)'')'/gn_meta.get_id_dataset('\1')/" "${1}"
sed -i --follow-symlinks "s/'gn_commons\.get_id_module(''\([^']*\)'')'/gn_commons.get_id_module('\1')/" "${1}"
sed -i --follow-symlinks "s/'ref_nomenclatures\.get_id_nomenclature(''\([^']*\)'', ''\([^']*\)'')'/ref_nomenclatures.get_id_nomenclature('\1', '\2')/g" "${1}"

# Dataset
sed -i --follow-symlinks -E "s/${old_dataset_uuid}/${new_dataset_uuid}/" "${1}"
# Source
sed -i --follow-symlinks -E "s/${old_source_code}/${new_source_code}/" "${1}"
