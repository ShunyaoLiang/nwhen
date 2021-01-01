all:
	sbcl --eval "(load \"nwhen.lisp\")" --eval "(sb-ext:save-lisp-and-die \"nwhen\" :toplevel #'main :executable t)"
