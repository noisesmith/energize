;; Roughly the strategy is to find whether the current line is part of a table,
;; a "body" special form call, a regular function call, or none of the above.
;; Each of these are indented differently.
;;
;; Examples:
;;
;; (local table-type {:a 1
;;                    :b 2
;;                    :c 3})
;;
;; (when body-type?
;;   (print "This form is indented in body type."))
;;
;; (local regular-call (this-is indented-as
;;                              a-regular "function call"))
;;
;; "this is none of the above."

(fn identify-line [line pos stack]
  "For the given line, identify the kind of form it opens, if any.
Returns nil if the given line doesn't open any form; in that case the caller
should continue looking to previous lines."
  (let [closers {")" "(" "]" "[" "}" "{" "\"" "\""}
        char (line:sub pos pos)
        looking-for (. stack (# stack))
        continue #(identify-line line (- pos 1) stack)]
    (if (= 0 pos) nil
        ;; TODO: backslashed delimiters aren't consistently handled
        (= (line:sub (- pos 1) (- pos 1)) :\ ) (continue)
        ;; if we find the delimiter we're looking for, stop looking
        (= looking-for char) (do (table.remove stack) (continue))
        ;; if we find a new form, start looking for the delimiter that begins it
        (and (. closers char)
             ;; (unless we're already in a string)
             (not= looking-for "\"")) (do (table.insert stack (. closers char))
                                        (continue))
        ;; if we're looking for a delimiter, skip everything till we find it
        looking-for (continue)
        ;; if we hit an opening table char, we're in a table!
        (or (= "[" char) (= "{" char)) (values :table pos)
        ;; if we hit an open paren, we're in a call!
        (= "(" char) (values :call pos line)
        :else (continue))))

(fn symbol-at [line pos]
  (: (line:sub pos) :match "[^%s]+"))

;; Some special forms have their own indentation rules, but specials which
;; aren't on this list are indented like normal function calls.
(local body-specials {"let" true "fn" true "lambda" true "λ" true "when" true
                      "do" true "eval-compiler" true "for" true "each" true
                      "while" true "macro" true "match" true "doto" true})

(fn remove-comment [line in-string? pos]
  (if (< (# line) pos) line
      (= (line:sub pos pos) "\"")
      (remove-comment line (not in-string?) (+ pos 1))
      (and (= (line:sub pos pos) ";") (not in-string?))
      (line:sub 1 (- pos 1)) ; could hit false positives in multi-line strings
      (remove-comment line in-string? (+ pos 1))))

(fn identify-indent-type [lines last stack]
  "Distinguish between forms that are part of a table vs a function call.
This function iterates backwards thru a table of lines to find where the current
form begins. Also returns details about the position in the line."
  (let [line (remove-comment (or (. lines last) "") false 1)]
    (match (identify-line line (# line) stack)
      (:table pos) (values :table pos)
      (:call pos line) (let [function-name (symbol-at line (+ pos 1))]
                         (if (. body-specials function-name)
                             (values :body-special (- pos 1))
                             (values :call (- pos 1) function-name)))
      (_ ? (< 1 last)) (identify-indent-type lines (- last 1) stack))))

(fn indentation [lines prev-line-num]
  "Return indentation for a line, given a table of lines and a number offset.
The prev-line-num indicates the line previous to the current line, which will be
looked up in the table of lines. Returns the column number to indent to."
  (match (identify-indent-type lines prev-line-num [])
    ;; three kinds of indentation:
    (:table opening) opening
    (:body-special prev-indent) (+ prev-indent 2)
    (:call prev-indent function-name) (+ prev-indent (# function-name) 2)
    _ 0))

(fn indent [line lines prev-line-num]
  (let [without-indentation (line:match "[^%s]+.*")]
    (if without-indentation
        (.. (: " " :rep (indentation lines prev-line-num)) without-indentation)
        "")))

(fn fmt [code]
  "Reformat an entire block of code."
  (let [lines []]
    (each [line (code:gmatch "([^\n]*)\n")]
      (table.insert lines (indent line lines (# lines))))
    (table.concat lines "\n")))

{:fmt fmt :indentation indentation}
