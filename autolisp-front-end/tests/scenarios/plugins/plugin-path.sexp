(:name "plugin-path"
 :description "--plugin-path DIR puts DIR first on the plug-in search path;
--list-plugins shows it, and marks it when it does not exist."
 :classification :portable
 :argv ("--plugin-path" "no-such-plugin-root" "--list-plugins")
 :expected-exit 0
 :expected-stdout-includes ("Search path:" "no-such-plugin-root" "(missing)")
 :covers-options ("--plugin-path" "--list-plugins"))
