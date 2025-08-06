# Serveur_mattin_b

Voici un template de Serveur GTA RP sous la framework ESX. Ce serveur contient uniquement des ressources Open-Source les fxmanifest ne sont pas modifié et contiennent donc les crédits de toutes les personnes ayant développé les différents scripts

Ce template est mis à disposition de tous, si vous ne souhaitez pas vous prendre la tête a configurer les ressources une à une.

# Configuration

Pour configurer la base il vous manquera un fichier que vous devrez créé, server_secret.cfg.
Dans ce fichier vous devez ajouté ces lignes :


sv_licenseKey ""
sv_maxclients 48
endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"
set steam_webApiKey "none"
set resources_useSystemChat true

set mysql_connection_string "mysql://NomUtilisateur:MotDePasse@localhost/NomBaseDeDonnée?waitForConnections=true&charset=utf8mb4"
set mysql_ui true

## Add system admins
add_ace group.admin command allow # allow all commands
add_ace group.admin command.quit deny # but don't allow quit
add_principal identifier.fivem:IdentifiantFiveM group.admin #Mettre son ID
add_principal identifier.discord:IdentifiantDisord group.admin #Mettre son ID
