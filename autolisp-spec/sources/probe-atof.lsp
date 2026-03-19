(defun autolisp-spec-run-atof-probes ()
  (autolisp-spec-capture "atof" "(atof \"3.5\")"
    (function (lambda () (atof "3.5"))))
  (autolisp-spec-capture "atof" "(atof \".5\")"
    (function (lambda () (atof ".5"))))
  (autolisp-spec-capture "atof" "(atof \"1.\")"
    (function (lambda () (atof "1."))))
  (autolisp-spec-capture "atof" "(atof \"1e3\")"
    (function (lambda () (atof "1e3"))))
  (autolisp-spec-capture "atof" "(atof \"017\")"
    (function (lambda () (atof "017"))))
  (autolisp-spec-capture "atof" "(atof \"0x1p4\")"
    (function (lambda () (atof "0x1p4"))))
  (autolisp-spec-capture "atof" "(atof \"3,5\")"
    (function (lambda () (atof "3,5"))))
  (autolisp-spec-capture "atof" "(atof \" 3.5\")"
    (function (lambda () (atof " 3.5")))))
