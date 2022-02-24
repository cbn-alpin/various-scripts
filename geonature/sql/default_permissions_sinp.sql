INSERT INTO gn_permissions.cor_role_action_filter_module_object
    (
    id_role,
    id_action,
    id_filter,
    id_module,
    id_object
    )
VALUES
    -- Groupe Admin
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 1, 4, 0, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 2, 4, 0, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 3, 4, 0, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 4, 4, 0, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 5, 4, 0, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 6, 4, 0, 1),
    --Validateur général sur tout GeoNature
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Validateur'), 4, 4, 0, 1 ),
    --CRUVED du groupe en poste (id=7) sur tout GeoNature 
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 1, 4, 0, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 2, 3, 0, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 3, 2, 0, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 4, 1, 0, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 5, 3, 0, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 6, 2, 0, 1),
    -- Groupe admin a tous les droit dans METADATA
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 1, 4, 2, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 2, 4, 2, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 3, 4, 2, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 4, 4, 2, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 5, 4, 2, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 6, 4, 2, 1),
    -- Groupe en poste acces limité a dans METADATA
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 1, 1, 2, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 2, 3, 2, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 3, 1, 2, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 4, 1, 2, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 5, 3, 2, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 6, 1, 2, 1),
    -- Groupe en poste, n'a pas accès à l'admin
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 1, 1, 1, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 2, 1, 1, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 3, 1, 1, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 4, 1, 1, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 5, 1, 1, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_utilisateurs'), 6, 1, 1, 1),
    -- Groupe en admin a tous les droits sur l'admin
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 1, 4, 1, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 2, 4, 1, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 3, 4, 1, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 4, 4, 1, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 5, 4, 1, 1),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 6, 4, 1, 1),
    -- Groupe ADMIN peut gérer les permissions depuis le backoffice
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 1, 4, 1, 2),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 2, 4, 1, 2),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 3, 4, 1, 2),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 4, 4, 1, 2),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 5, 4, 1, 2),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 6, 4, 1, 2),
    -- Groupe ADMIN peut gérer les nomenclatures depuis le backoffice
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 1, 4, 1, 3),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 2, 4, 1, 3),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 3, 4, 1, 3),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 4, 4, 1, 3),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 5, 4, 1, 3),
    ((SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Grp_admin'), 6, 4, 1, 3)
;
