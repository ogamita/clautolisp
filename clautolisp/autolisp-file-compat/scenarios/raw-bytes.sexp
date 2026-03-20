(:name "raw-bytes"
 :description "Capture a raw byte payload without decoding-sensitive assumptions."
 :classification :implementation-sensitive
 :tags (:bytes :binary)
 :relative-path "artifacts/raw-bytes.bin"
 :input-bytes (0 1 2 3 255)
 :expected-bytes (0 1 2 3 255))
