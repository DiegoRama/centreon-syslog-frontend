#	Description:

Nom: Centreon-Syslog-Frontend
version: 1.5.x

#	Installation:

L'installation du module est enti�rement d�taill�e. Elle est dissponible sous forme de doccument PDF
accessible sur la forge du module � cette adresse http://forge.centreon.com/projects/centreon-syslog/documents

1. T�l�charger la derni�re version du module depuis la paage de t�l�chargement

Se rendre sur la page http://forge.centreon.com/projects/list_files/centreon-syslog

2. Lancer l'installation via le script d'installation situ� � la racine du dossier "centreon-syslog-frontend-2.x"

$> chmod +x install.sh
$> ./install.sh -u /etc/centreon

3. Se rendre sur l'interface de Centreon

Se rendre ensuite dans le menu 'Administration > Modules > Setup'.
Le module syslog doit figurer dans la liste des modules mais non install�.
Cliquer sur l'icone � droite pour lancer l'installation.

4. Se rendre dans le menu 'Administration > Modules > Syslog configuration'.

Remplir les champs afin que le module puisse acc�der � la base de donn�e.

5. Se rendre dans le menu 'Monitoring > Syslog > Monitoring'


#	FAQ

Q: Lors de l'acc�s � la page 'Monitoring > Syslog > Syslog reporting',
	un message d'erreur indique 'DB Error: connect failed' ou 'DB Error: insufficient permissions'

R: Soit les champs sont mal renseign�s, soit l'utilisateur renseign� n'a pas les droits suffisant pour
	acceder � la base de donn�es.




#	Liens utiles:

	Centreon-Syslog
	
Documentation:	http://forge.centreon.com/projects/centreon-syslog/documents
SVN:	http://syslog.modules.centreon.com/svn
Trac:	http://forge.centreon.com/projects/show/centreon-syslog
Forum:	http://forum.centreon.com/forumdisplay.php?f=26

	Centreon
	
Wiki:	http://doc.centreon.com/
SVN:	http://svn.centreon.com/
Trac:	http://forge.centreon.com/projects/show/centreon
Forum:	http://forum.centreon.com/