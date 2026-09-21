(:name "plugin-list"
 :description "--list-plugins prints the plug-ins found (the two alfe ships,
from the source tree or the installation), what each is, and the search
path, then exits 0."
 :classification :portable
 :argv ("--list-plugins")
 :expected-exit 0
 :expected-stdout-includes ("Installed plug-ins:" "epure " "epuree " "Search path:")
 :covers-options ("--list-plugins"))
