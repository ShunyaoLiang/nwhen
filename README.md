# nwhen

`nwhen` is a simple calendar program that introduces a domain-specific
language written in Lisp for its calendar files. The name is inspired by
Ben Crowell's `when` program, as `nvim` is to `vim`.

```lisp
; Specify events like this:
(event "Lunch with Ben" :year 2021 :month january :day 5)
; You can specify the date in any order.
(event "Save the world" :month july :day 4 :year 2025)
; If you leave out a date field, the event will repeat.
(event "Amelia's Birthday" :day 5 :month august) ; This repeats every August 5
; There is a shortcut function for birthdays.
(birthday "Thomas" :day 29 :month november)

; To avoid repetition, you can create 'scopes' like the following
(year 2021
  (month january
    (event "Canoeing" :day 5)          ; Implies 2021-01-05
    (event "Hiking with Mum" :day 14)) ; Implies 2021-01-14
  (month february
    (event "Physics Exam" :day 2)))    ; Implies 2021-02-02

; You can separate your calendar amongst multiple files with the include
; function.
(include "birthdays")
(include "$HOME/calendar/exams.nwhen")
```

By default, `nwhen` tries to open `$HOME/calendar` as the calendar file.
This behaviour can be configured by setting the `NWHEN_HOME` environment
variable.

This is my first significant Lisp program, so code review is appreicated.

## Arbitrary Code Execution

The contents of the calendar file are executed as a Common Lisp program,
enabling calendar entries that have dates that must be algorithmically
calculated each year. I hope to illustrate this with the following example
of Mother's Day. In most countries that celebrate Mother's Day, it occurs
on the second Sunday of May.

```lisp
(let ((mothers-day (nth 1 (remove-if-not (lambda (date)
                                           (and (eq (getf date :month) :may)
                                                (dow-eq (getf date :dow) :sun)))
                                         *time-span*))))
  (when mothers-day
    (push (append mothers-day '(:desc "Mother's Day")) *unqualified-events*)))
```

## Chinese Lunisolar Calendar Dates

`nwhen` has limited support for Chinese lunisolar calendar dates,
currently in a very unoptimal way. It must call a Python script that
depends upon Wei Yen's lunisolar library. **This feature is not
well-tested in the slightest, and is likely flawed! Please do not use this
in production.**

```lisp
(birthday "Grandpa" :month 5 :day 12 chinese t)
```

## License

`nwhen` is licensed under the BSD 2-Clause "Simplified" License.
