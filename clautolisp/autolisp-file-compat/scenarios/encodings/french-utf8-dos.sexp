(:name "french-utf8-dos"
 :description "Round-trip the French accented sentence in :utf-8 with dos (:crlf) line endings. The sentence is ISO-8859-1-safe (oe for the U+0153 ligature, ' for the U+2019 quote) so it encodes in both UTF-8 and ISO-8859-1; see test-file-encodings.issue. Non-LF variants assert via :expected-lines since the raw read-back retains the CR/CRLF terminator."
 :classification :portable
 :tags (:text :encoding :utf-8 :newline :crlf :french)
 :relative-path "artifacts/french-utf8-dos.txt"
 :external-format :utf-8
 :newline-mode :crlf
 :input-text "« À Noël, l'âgé Ægyr brûla du maïs rôti près d'un cañon où Foedor jugea déçu que l'île exiguë, bâtie sur du würmien, était trop naïve pour Zoë et Cécÿle. »
"
 :expected-lines ("« À Noël, l'âgé Ægyr brûla du maïs rôti près d'un cañon où Foedor jugea déçu que l'île exiguë, bâtie sur du würmien, était trop naïve pour Zoë et Cécÿle. »"))
