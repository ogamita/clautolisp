(:name "plugin-help"
 :description "--help lists the plug-in options of every installed plug-in,
generated from what they registered, after alfe's own."
 :classification :portable
 :argv ("--help")
 :expected-exit 0
 :expected-stdout-includes ("--plugin NAME" "--plugin-path DIR" "--no-plugins"
                            "--list-plugins" "--compile-plugin FILE"
                            "Plug-in options" "--epure-profile NAME"
                            "--epuree-path DIR")
 :covers-options ("--help"))
