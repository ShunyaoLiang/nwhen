;;;; nwhen.lisp

(defpackage #:nwhen
  (:use #:cl)
  (:export #:main))

(defparameter *nwhen-home*
  (uiop:native-namestring (if (uiop:getenv "NWHEN_HOME")
                              (uiop:getenv "NWHEN_HOME")
                              "~"))) 

(defparameter *unqualified-events* ())
(defparameter *time-span* ())  

(defparameter *scope-year* nil)
(defparameter *scope-month* nil)
(defparameter *scope-day* nil)

(defmacro year (v &body body)
  `(let ((*scope-year* ,v)) ,@body))
(defmacro month (v &body body)
  `(let ((*scope-month* ,v)) ,@body))
(defmacro day (v &body body)
  `(let ((*scope-day* ,v)) ,@body))

(defun get-current-date ()
  (multiple-value-bind (sec min hour day month year dow) (get-decoded-time)
    (declare (ignore sec min hour))
    (list :year year :month month :day day :dow dow)))

(defun month-index (month)
  (case month
    (:january 1) (:jan 1)
    (:february 2) (:feb 2)
    (:march 3) (:mar 3)
    (:april 4) (:apr 4)
    (:may 5) 
    (:june 6) (:jun 6)
    (:july 7) (:jul 7)
    (:august 8) (:aug 8)
    (:september 9) (:sep 9)
    (:october 10) (:oct 10)
    (:november 11) (:nov 11)
    (:december 12) (:dec 12)
    (otherwise month))) ; The case where it is nil or already an index.

(defvar *chinese-year-lookahead* 1)

(defun chinese-to-gregorian (year month day)
  (read-from-string (uiop:run-program (list "python"
                                            "lunisolar_to_gregorian.py"
                                            (write-to-string year)
                                            (write-to-string month)
                                            (write-to-string day))
                                      :output 'string)))

(defun event (desc &key (year *scope-year*) (month *scope-month*) (day *scope-day*) chinese)
  ;; Here, it is impossible to know how far the program must look ahead. In addition, the
  ;; gregorian equivalents of a Chinese calendar date differ every year. Hence, if year is nil,
  ;; instead, we calculate the dates for the next *chinese-year-lookahead* years, and add them all
  ;; to *unqualified-events*. Terrible hack.
  (if (and chinese (not year))
      (progn
        (setf year (getf (get-current-date) :year))
        (loop for i from 0 upto *chinese-year-lookahead*
              do (push (append (list :desc desc) (chinese-to-gregorian (+ year i) month day)) *unqualified-events*)))
      (push (list :desc desc :year year :month (month-index month) :day day) *unqualified-events*)))

(defun birthday (name &key month day chinese)
  (event (concatenate 'string name "'s Birthday") :month month :day day :chinese chinese))

(defun leap-p (year)
  (cond ((not (zerop (rem year 4))) nil)
        ((not (zerop (rem year 25))) t)
        ((not (zerop (rem year 16))) nil)
        (t t)))

(defun days-in-month (month year)
  (if (= month 2)
      (if (leap-p year) 29 28)
      (nth (1- month) '(31 28 31 30 31 30 31 31 30 31 30 31)))) 

(defun inc-date (date)
  (let ((year (getf date :year))
        (month (getf date :month))
        (day (getf date :day))
        (dow (rem (1+ (getf date :dow)) 7)))
    (if (> (1+ day) (days-in-month month year))
        (if (> (1+ month) 12)
            (list :year (1+ year) :month 1 :day 1 :dow dow)
            (list :year year :month (1+ month) :day 1 :dow dow))
        (list :year year :month month :day (1+ day) :dow dow)))) 

(defun wild-eq (a b)
  (or (not a) (= a b)))

(defun date-wild-eq (predicate date)
  (and (wild-eq (getf predicate :year) (getf date :year))
       (wild-eq (getf predicate :month) (getf date :month))
       (wild-eq (getf predicate :day) (getf date :day))))

(defun compare-events (a b)
  (< (encode-universal-time 0 0 0 (getf a :day) (getf a :month) (getf a :year))
     (encode-universal-time 0 0 0 (getf b :day) (getf b :month) (getf b :year))))

(defun include (pathname)
  (load (concatenate 'string *nwhen-home* "/" pathname)))

(defun make-time-span (length)
  (loop repeat length
        for date = (get-current-date) then (inc-date date)
        collect date))

(defun index-to-dow (index)
  (nth index '(:mon :tue :wed :thur :fri :sat :sun)))

(defun dow-eq (a b)
  (or (eq a b) (eq (index-to-dow a) b)))

(defun qualify-event (event date until)
  (list :desc (getf event :desc)
        :year (getf date :year)
        :month (getf date :month)
        :day (getf date :day)
        :dow (index-to-dow (getf date :dow))
        :until until))

(defun get-upcoming-events (time-span)
  (sort (loop for date in time-span
              for i from 0
              append (mapcar 
                       (lambda (event) (qualify-event event date i))
                       (remove-if-not
                         (lambda (event) (date-wild-eq event date))
                         *unqualified-events*))) 'compare-events))

(defun get-calendar-file () 
  (concatenate 'string *nwhen-home* "/calendar.nwhen"))

(defun main ()
  (let ((*time-span* (make-time-span 30)))
    (load (get-calendar-file) :if-does-not-exist nil)
    (print (list 'upcoming-events
                 (get-upcoming-events *time-span*)))))
