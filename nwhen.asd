;;;; nwhen.asd

(asdf:defsystem #:nwhen
  :description "A simple calendar program using a Lisp domain language."
  :author "Shunyao Liang <shunyao@shunyaoliang.xyz"
  :license  "BSD 2-Clause"
  :version "1.0.5"
  :serial t
  :components ((:file "package")
               (:file "nwhen")))
