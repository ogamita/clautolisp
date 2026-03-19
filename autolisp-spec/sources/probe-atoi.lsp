(defun autolisp-spec-run-atoi-probes ()
  (autolisp-spec-capture "atoi" "(atoi \"17\")"
    (function (lambda () (atoi "17"))))
  (autolisp-spec-capture "atoi" "(atoi \"017\")"
    (function (lambda () (atoi "017"))))
  (autolisp-spec-capture "atoi" "(atoi \"0xbabe\")"
    (function (lambda () (atoi "0xbabe"))))
  (autolisp-spec-capture "atoi" "(atoi \"+17\")"
    (function (lambda () (atoi "+17"))))
  (autolisp-spec-capture "atoi" "(atoi \"-17\")"
    (function (lambda () (atoi "-17"))))
  (autolisp-spec-capture "atoi" "(atoi \"17x\")"
    (function (lambda () (atoi "17x"))))
  (autolisp-spec-capture "atoi" "(atoi \" 17\")"
    (function (lambda () (atoi " 17"))))
  (autolisp-spec-capture "atoi" "(atoi \"3.9\")"
    (function (lambda () (atoi "3.9")))))
