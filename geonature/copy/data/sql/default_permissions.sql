-- Add default permissions\n
BEGIN ;

\echo '----------------------------------------------------------------------------'
\echo 'Insert permissions'
-- To generate values of this query see:
-- https://wiki-intranet.cbn-alpin.fr/projets/feder-si/installation-geonature?rev=1709478679#requetes_post-installation
INSERT INTO gn_permissions.t_permissions
    ( id_role, id_action, id_module, id_object, scope_value )
VALUES
(
	utilisateurs.get_id_role_by_name('Grp_utilisateurs'), -- Grp_utilisateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_by_code('METADATA'),
	gn_permissions.get_id_object_by_code('ALL'),
	2
),

(
	utilisateurs.get_id_role_by_name('Grp_utilisateurs'), -- Grp_utilisateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_by_code('METADATA'),
	gn_permissions.get_id_object_by_code('ALL'),
	2
),

(
	utilisateurs.get_id_role_by_name('Grp_utilisateurs'), -- Grp_utilisateurs
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_by_code('SYNTHESE'),
	gn_permissions.get_id_object_by_code('ALL'),
	2
),

(
	utilisateurs.get_id_role_by_name('Grp_utilisateurs'), -- Grp_utilisateurs
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_by_code('SYNTHESE'),
	gn_permissions.get_id_object_by_code('ALL'),
	2
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('ADDITIONAL_FIELDS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('MOBILE_APPS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('PERMISSIONS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('NOMENCLATURES'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('NOTIFICATIONS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('NOTIFICATIONS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('NOMENCLATURES'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('MODULES'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('PERMISSIONS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('ADDITIONAL_FIELDS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('MOBILE_APPS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('MOBILE_APPS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('NOTIFICATIONS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('MODULES'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('NOMENCLATURES'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('ADDITIONAL_FIELDS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('PERMISSIONS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('NOTIFICATIONS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('PERMISSIONS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('NOMENCLATURES'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('MOBILE_APPS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('ADDITIONAL_FIELDS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('MODULES'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('ADDITIONAL_FIELDS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('PERMISSIONS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('NOMENCLATURES'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('NOTIFICATIONS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_by_code('ADMIN'),
	gn_permissions.get_id_object_by_code('MOBILE_APPS'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_by_code('METADATA'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_by_code('METADATA'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_by_code('METADATA'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_by_code('METADATA'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_by_code('METADATA'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_by_code('SYNTHESE'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_by_code('SYNTHESE'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('C'), -- Créer (C)
	gn_commons.get_id_module_by_code('OCCTAX'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('R'), -- Lire (R)
	gn_commons.get_id_module_by_code('OCCTAX'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
	gn_commons.get_id_module_by_code('OCCTAX'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
	gn_commons.get_id_module_by_code('OCCTAX'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
),

(
	utilisateurs.get_id_role_by_name('Grp_admin'), -- Grp_admin
	gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
	gn_commons.get_id_module_by_code('OCCTAX'),
	gn_permissions.get_id_object_by_code('ALL'),
	NULL
)
;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
