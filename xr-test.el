;;; xr-test.el --- Tests for xr.el                   -*- lexical-binding: t -*-

;; Copyright (C) 2019 Free Software Foundation, Inc.

;; Author: Mattias Engdegård <mattiase@acm.org>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


(require 'xr)
(require 'ert)


(ert-deftest xr-basic ()
  (should (equal (xr "a\\$b\\\\c\\[\\]\\q")
                 "a$b\\c[]q"))
  (should (equal (xr "\\(?:ab\\|c*d\\)?")
                 '(opt (or "ab" (seq (zero-or-more "c") "d")))))
  (should (equal (xr ".+")
                 '(one-or-more nonl)))
  )

(ert-deftest xr-repeat ()
  (should (equal (xr "\\(?:x?y\\)\\{3\\}")
                 '(= 3 (opt "x") "y")))
  (should (equal (xr "\\(?:x?y\\)\\{3,8\\}")
                 '(repeat 3 8 (opt "x") "y")))
  (should (equal (xr "\\(?:x?y\\)\\{3,\\}")
                     '(>= 3 (opt "x") "y")))
  (should (equal (xr "\\(?:x?y\\)\\{,8\\}")
                 '(repeat 0 8 (opt "x") "y")))
  (should (equal (xr "\\(?:xy\\)\\{4,4\\}")
                 '(= 4 "xy")))
  (should (equal (xr "a\\{,\\}")
                 '(zero-or-more "a")))
  (should (equal (xr "a\\{0\\}")
                 '(repeat 0 0 "a")))
  (should (equal (xr "a\\{0,\\}")
                 '(zero-or-more "a")))
  (should (equal (xr "a\\{0,0\\}")
                 '(repeat 0 0 "a")))
  (should (equal (xr "a\\{\\}")
                 '(repeat 0 0 "a")))
  (should (equal (xr "a\\{,1\\}")
                 '(repeat 0 1 "a")))
  (should (equal (xr "a\\{1,\\}")
                 '(>= 1 "a")))
  (should-error (xr "a\\{3,2\\}"))
  )

(ert-deftest xr-backref ()
  (should (equal (xr "\\(ab\\)\\(?3:cd\\)\\1\\3")
                 '(seq (group "ab") (group-n 3 "cd") (backref 1) (backref 3))))
  (should (equal (xr "\\01")
                 "01"))
  (should-error (xr "\\(?abc\\)"))
  (should-error (xr "\\(?2\\)"))
  (should-error (xr "\\(?0:xy\\)"))
  (should (equal (xr "\\(?29:xy\\)")
                 '(group-n 29 "xy")))
  )

(ert-deftest xr-misc ()
  (should (equal (xr "^.\\w\\W\\`\\'\\=\\b\\B\\<\\>\\_<\\_>$")
                 '(seq bol nonl wordchar not-wordchar bos eos point
                       word-boundary not-word-boundary bow eow
                       symbol-start symbol-end eol)))
  (should-error (xr "\\_a"))
  )

(ert-deftest xr-syntax ()
  (should (equal (xr "\\s-\\s \\sw\\sW\\s_\\s.\\s(\\s)\\s\"")
                 '(seq (syntax whitespace) (syntax whitespace) (syntax word)
                       (syntax word)
                       (syntax symbol) (syntax punctuation)
                       (syntax open-parenthesis) (syntax close-parenthesis)
                       (syntax string-quote))))
  (should (equal (xr "\\s\\\\s/\\s$\\s'\\s<\\s>\\s!\\s|")
                 '(seq (syntax escape) (syntax character-quote)
                       (syntax paired-delimiter) (syntax expression-prefix)
                       (syntax comment-start) (syntax comment-end)
                       (syntax comment-delimiter) (syntax string-delimiter))))
  (should (equal (xr "\\S-\\S<")
                 '(seq (not (syntax whitespace))
                       (not (syntax comment-start)))))
  (should-error (xr "\\s"))
  (should-error (xr "\\S"))
  )

(ert-deftest xr-category ()
  (should (equal (xr "\\c0\\c1\\c2\\c3\\c4\\c5\\c6\\c7\\c8\\c9\\c<\\c>")
                 '(seq (category consonant) (category base-vowel)
                       (category upper-diacritical-mark)
                       (category lower-diacritical-mark)
                       (category tone-mark) (category symbol) (category digit)
                       (category vowel-modifying-diacritical-mark)
                       (category vowel-sign) (category semivowel-lower)
                       (category not-at-end-of-line)
                       (category not-at-beginning-of-line))))
  (should (equal (xr "\\cA\\cC\\cG\\cH\\cI\\cK\\cN\\cY\\c^")
          '(seq (category alpha-numeric-two-byte) (category chinese-two-byte)
                (category greek-two-byte) (category japanese-hiragana-two-byte)
                (category indian-two-byte)
                (category japanese-katakana-two-byte)
                (category korean-hangul-two-byte) (category cyrillic-two-byte)
                (category combining-diacritic))))
  (should (equal (xr "\\ca\\cb\\cc\\ce\\cg\\ch\\ci\\cj\\ck\\cl\\co\\cq\\cr")
          '(seq (category ascii) (category arabic) (category chinese)
                (category ethiopic) (category greek) (category korean)
                (category indian)  (category japanese)
                (category japanese-katakana) (category latin) (category lao)
                (category tibetan) (category japanese-roman))))
  (should (equal (xr "\\ct\\cv\\cw\\cy\\c|")
                 '(seq (category thai) (category vietnamese) (category hebrew)
                       (category cyrillic) (category can-break))))
  (should (equal (xr "\\C2\\C^")
                 '(seq (not (category upper-diacritical-mark))
                       (not (category combining-diacritic)))))
  (should (equal (xr "\\cR\\C.\\cL\\C ")
                 '(seq (category strong-right-to-left)
                       (not (category base)) (category strong-left-to-right)
                       (not (category space-for-indent)))))
  (should (equal (xr "\\c%\\C+")
                 '(seq (regexp "\\c%") (regexp "\\C+"))))
  (should-error (xr "\\c"))
  (should-error (xr "\\C"))
  )

(ert-deftest xr-lazy ()
  (should (equal (xr "\\(?:a.\\)*?")
                 '(*? "a" nonl)))
  (should (equal (xr "\\(?:a.\\)+?")
                 '(+? "a" nonl)))
  (should (equal (xr "\\(?:a.\\)??")
                 '(?? "a" nonl)))
  (should (equal (xr "\\(?:.\\(a+\\(?:b+?c*\\)?\\)??\\)*")
                 '(zero-or-more
                   nonl
                   (?? (group (one-or-more "a")
                              (opt (+? "b")
                                   (zero-or-more "c")))))))
  )

(ert-deftest xr-char-classes ()
  (should (equal (xr "[[:alnum:][:blank:]][[:alpha:]][[:cntrl:][:digit:]]")
                 '(seq (any alnum blank) alpha (any cntrl digit))))
  (should (equal (xr "[^[:lower:][:punct:]][^[:space:]]")
                 '(seq (not (any lower punct)) (not space))))
  (should (equal (xr "^[a-z]*")
                 '(seq bol (zero-or-more (any "a-z")))))
  (should (equal (xr "some[.]thing")
                 "some.thing"))
  (should (equal (xr "[^]-c]")
                 '(not (any "]-c"))))
  (should (equal (xr "[-^]")
                 '(any "^-")))
  (should (equal (xr "[a-z-+/*%0-4[:xdigit:]]")
                 '(any "0-4a-z" "%*+/-" xdigit)))
  (should (equal (xr "[^]A-Za-z-]*")
                 '(zero-or-more (not (any "A-Za-z" "]-")))))
  (should (equal (xr "[+*%A-Ka-k0-3${-}]")
                 '(any "0-3A-Ka-k{-}" "$%*+")))
  (should (equal (xr "[^\\\\o][A-\\\\][A-\\\\-a]")
                 '(seq (not (any "\\o")) (any "A-\\") (any "A-a"))))
  (should (equal (xr "[^A-FFGI-LI-Mb-da-eg-ki-ns-tz-v]")
                 '(not (any "A-FI-Ma-eg-ns-t" "G"))))
  (should (equal (xr "[z-a][^z-a]")
                 '(seq (any) anything)))
  (should (equal (xr "[[:alpha]]")
                 '(seq (any ":[ahlp") "]")))
  (should (equal (xr "[:alpha:]")
                 '(any ":ahlp")))
  (should (equal (xr "[[:digit:]-z]")
                 '(any "z-" digit)))
  (should (equal (xr "[A-[:digit:]]")
                 '(seq (any "A-[" ":dgit") "]")))
  (should-error (xr "[[::]]"))
  (should-error (xr "[[:=:]]"))
  (should-error (xr "[[:letter:]]"))
  )

(ert-deftest xr-empty ()
  (should (equal (xr "")
                 ""))
  (should (equal (xr "a\\|")
                 '(or "a" "")))
  (should (equal (xr "\\|a")
                 '(or "" "a")))
  (should (equal (xr "a\\|\\|b")
                 '(or "a" "" "b")))
  )

(ert-deftest xr-anything ()
  (should (equal (xr "\\(?:.\\|\n\\)?\\(\n\\|.\\)*")
                 '(seq (opt anything) (zero-or-more (group anything)))))
  )

(ert-deftest xr-real ()
  (should (equal (xr "\\*\\*\\* EOOH \\*\\*\\*\n")
                 "*** EOOH ***\n"))
  (should (equal (xr "\\<\\(catch\\|finally\\)\\>[^_]")
                 '(seq bow (group (or "catch" "finally")) eow
                       (not (any "_")))))
  (should (equal (xr "[ \t\n]*:\\([^:]+\\|$\\)")
                 '(seq (zero-or-more (any "\t\n ")) ":"
                       (group (or (one-or-more (not (any ":")))
                                  eol)))))
  )

(ert-deftest xr-edge-cases ()
  (should (equal (xr "^a^b\\(?:^c^\\|^d^\\|e^\\)^")
                 '(seq bol "a^b" (or (seq bol "c^") (seq bol "d^") "e^") "^")))
  (should (equal (xr "$a$b\\(?:$c$\\|$d$\\|$e$\\)$")
                 '(seq "$a$b" (or (seq "$c" eol) (seq "$d" eol) (seq "$e" eol))
                       eol)))
  (should (equal (xr "*a\\|*b\\(*c\\)")
                 '(or "*a" (seq "*b" (group "*c")))))
  (should (equal (xr "+a\\|+b\\(+c\\)")
                 '(or "+a" (seq "+b" (group "+c")))))
  (should (equal (xr "?a\\|?b\\(^?c\\)")
                 '(or "?a" (seq "?b" (group bol "?c")))))
  (should (equal (xr "^**")
                 '(seq bol (zero-or-more "*"))))
  (should (equal (xr "^+")
                 '(seq bol "+")))
  (should (equal (xr "^?")
                 '(seq bol "?")))
  (should (equal (xr "*?a\\|^??b")
                 '(or (seq (opt "*") "a") (seq bol (opt "?") "b"))))
  (should (equal (xr "^\\{xy")
                 '(seq bol "{xy")))
  (should (equal (xr "\\{2,3\\}")
                 "{2,3}"))
  (should (equal (xr "\\(?:^\\)*")
                 '(zero-or-more bol)))
  (should (equal (xr "\\(?:^\\)\\{3\\}")
                 '(= 3 bol)))
  (should (equal (xr "\\^+")
                 '(one-or-more "^")))
  (should (equal (xr "\\c^?")
                 '(opt (category combining-diacritic))))
  (should (equal (xr "a^*")
                 '(seq "a" (zero-or-more "^"))))
  (should (equal (xr "a^\\{2,7\\}")
                 '(seq "a" (repeat 2 7 "^"))))
  )

(ert-deftest xr-simplify ()
  (should (equal (xr "a\\(?:b?\\(?:c.\\)d*\\)e")
                 '(seq "a" (opt "b") "c" nonl (zero-or-more "d") "e")))
  (should (equal (xr "a\\(?:b\\(?:c.d\\)e\\)f")
                 '(seq "abc" nonl "def")))
  )

(ert-deftest xr-pretty ()
  (should (equal (xr-pp-rx-to-str "A\e\r\n\t\0 \x7f\x80\ B\xff\x02")
                 "\"A\\e\\r\\n\\t\\x00 \\x7f\\200B\\xff\\x02\"\n"))
  (should (equal (xr-pp-rx-to-str '(?? nonl))
                 "(?? nonl)\n"))
  (should (equal (xr-pp-rx-to-str '(repeat 1 63 "a"))
                 "(repeat 1 63 \"a\")\n"))
  (let ((indent-tabs-mode nil))
    (should (equal (xr-pp-rx-to-str
                    '(seq (1+ nonl
                              (or "a"
                                  (not (any space))))
                          (* (? (not cntrl)
                                blank
                                (| nonascii "abcdef")))))
                   (concat
                    "(seq (1+ nonl\n"
                    "         (or \"a\"\n"
                    "             (not (any space))))\n"
                    "     (* (? (not cntrl)\n"
                    "           blank\n"
                    "           (| nonascii \"abcdef\"))))\n"))))
  )

(ert-deftest xr-dialect ()
  (should (equal (xr "a*b+c?d\\{2,5\\}\\(e\\|f\\)[gh][^ij]" 'medium)
                 '(seq (zero-or-more "a") (one-or-more "b") (opt "c")
                       (repeat 2 5 "d") (group (or "e" "f"))
                       (any "gh") (not (any "ij")))))
  (should (equal (xr "a*b+c?d\\{2,5\\}\\(e\\|f\\)[gh][^ij]" 'verbose)
                 '(seq (zero-or-more "a") (one-or-more "b") (zero-or-one "c")
                       (repeat 2 5 "d") (group (or "e" "f"))
                       (any "gh") (not (any "ij")))))
  (should (equal (xr "a*b+c?d\\{2,5\\}\\(e\\|f\\)[gh][^ij]" 'brief)
                 '(seq (0+ "a") (1+ "b") (opt "c")
                       (repeat 2 5 "d") (group (or "e" "f"))
                       (any "gh") (not (any "ij")))))
  (should (equal (xr "a*b+c?d\\{2,5\\}\\(e\\|f\\)[gh][^ij]" 'terse)
                 '(: (* "a") (+ "b") (? "c")
                     (** 2 5 "d") (group (| "e" "f"))
                     (in "gh") (not (in "ij")))))
  (should (equal (xr "^\\`\\<.\\>\\'$" 'medium)
                 '(seq bol bos bow nonl eow eos eol)))
  (should (equal (xr "^\\`\\<.\\>\\'$" 'verbose)
                 '(seq line-start string-start word-start not-newline
                       word-end string-end line-end)))
  (should (equal (xr "^\\`\\<.\\>\\'$" 'brief)
                 '(seq bol bos bow nonl eow eos eol)))
  (should (equal (xr "^\\`\\<.\\>\\'$" 'terse)
                 '(: bol bos bow nonl eow eos eol)))
  )

(ert-deftest xr-lint ()
  (should (equal (xr-lint "^a*\\[\\?\\$\\(b\\{3\\}\\|c\\)[^]\\a-d^-]$")
                 nil))
  (should (equal (xr-lint "a^b$c")
                 '((1 . "Unescaped literal `^'")
                   (3 . "Unescaped literal `$'"))))
  (should (equal (xr-lint "^**$")
                 '((1 . "Unescaped literal `*'"))))
  (should (equal (xr-lint "a[\\\\[]")
                 '((3 . "Duplicated `\\' inside character alternative"))))
  (should (equal (xr-lint "\\{\\(+\\|?\\)\\[\\]\\}\\\t")
                 '((0  . "Escaped non-special character `{'")
                   (4  . "Unescaped literal `+'")
                   (7  . "Unescaped literal `?'")
                   (14 . "Escaped non-special character `}'")
                   (16 . "Escaped non-special character `\\t'"))))
  (should (equal (xr-lint "\\}\\w\\a\\b\\%")
                 '((0 . "Escaped non-special character `}'")
                   (4 . "Escaped non-special character `a'")
                   (8 . "Escaped non-special character `%'"))))
  (should (equal (xr-lint "a?+b+?\\(?:c?\\)*d\\{3\\}+e*?\\{2,5\\}")
                 '((2  . "Repetition of repetition")
                   (14 . "Repetition of repetition")
                   (25 . "Repetition of repetition"))))
  (should (equal (xr-lint "[]-Qa-fz-t]")
                 '((1 . "Reversed range `]-Q' matches nothing")
                   (7 . "Reversed range `z-t' matches nothing"))))
  (should (equal (xr-lint "[z-a][^z-a]")
                 nil))
  (should (equal (xr-lint "[^A-FFGI-LI-Mb-da-eg-ki-ns-t33-7]")
                 '((5  . "Character `F' included in range `A-F'")
                   (10 . "Ranges `I-L' and `I-M' overlap")
                   (16 . "Ranges `a-e' and `b-d' overlap")
                   (22 . "Ranges `g-k' and `i-n' overlap")
                   (25 . "Two-character range `s-t'")
                   (29 . "Character `3' included in range `3-7'"))))
  (should (equal (xr-lint "[a[:digit:]b[:punct:]c[:digit:]]")
                 '((22 . "Duplicated character class `[:digit:]'"))))
  (should (equal (xr-lint "a*\\|b+\\|\\(?:a\\)*")
                 '((8 . "Duplicated alternative branch"))))
  (should (equal (xr-lint "a\\{,\\}")
                 '((1 . "Uncounted repetition"))))
  (should (equal (xr-lint "a\\{\\}")
                 '((1 . "Implicit zero repetition"))))
  (should (equal (xr-lint "[0-9[|]*/]")
                 '((4 . "Suspect `[' in char alternative"))))
  (should (equal (xr-lint "[^][-].]")
                 nil))
  (should (equal (xr-lint "[0-1]")
                 nil))
  (should (equal (xr-lint "[^]-][]-^]")
                 '((6 . "Two-character range `]-^'"))))
  (should (equal
           (xr-lint "[-A-Z][A-Z-][A-Z-a][^-A-Z][]-a][A-Z---.]")
           '((16 . "Literal `-' not first or last in character alternative"))))
  (should (equal
           (xr-lint "\\(?:a*b?\\)*\\(c\\|d\\|\\)+\\(^\\|e\\)*\\(?:\\)*")
           '((10 . "Repetition of expression matching an empty string")
             (21 . "Repetition of expression matching an empty string"))))
  (should (equal (xr-lint "\\'*\\<?\\(?:$\\)+")
                 '((2 . "Repetition of zero-width assertion")
                   (5 . "Repetition of zero-width assertion")
                   (13 . "Repetition of zero-width assertion"))))
  )

(ert-deftest xr-skip-set ()
  (should (equal (xr-skip-set "0-9a-fA-F+*")
                 '(any "0-9a-fA-F" "+*")))
  (should (equal (xr-skip-set "^ab-ex-")
                 '(not (any "b-e" "ax-"))))
  (should (equal (xr-skip-set "-^][\\")
                 '(any "^][-")))
  (should (equal (xr-skip-set "\\^a\\-bc-\\fg")
                 '(any "c-f" "^abg-")))
  (should (equal (xr-skip-set "\\")
                 '(any)))
  (should (equal (xr-skip-set "--3^Q-\\")
                 '(any "--3Q-\\" "^")))
  (should (equal (xr-skip-set "^Q-\\c-\\n")
                 '(not (any "Q-c" "n-"))))
  (should (equal (xr-skip-set "\\\\A-")
                 '(any "\\A-")))
  (should (equal (xr-skip-set "[a-z]")
                 '(any "a-z" "[]")))
  (should (equal (xr-skip-set "[:ascii:]-[:digit:]")
                 '(any "-" ascii digit)))
  (should (equal (xr-skip-set "A-[:blank:]")
                 '(any "A-[" ":blank]")))
  (should (equal (xr-skip-set "\\[:xdigit:]-b")
                 '(any "]-b" "[:xdigt")))
  (should (equal (xr-skip-set "^a-z+" 'terse)
                 '(not (in "a-z" "+"))))
  (should-error (xr-skip-set "[::]"))
  (should-error (xr-skip-set "[:whitespace:]"))
  (should (equal (xr-skip-set ".")
                 "\\."))
  (should (equal (xr-skip-set "^")
                 'anything))
  (should (equal (xr-skip-set "^[:print:]")
                 '(not print)))
  )

(ert-deftest xr-skip-set-lint ()
  (should (equal (xr-skip-set-lint "A[:ascii:]B[:space:][:ascii:]")
                 '((20 . "Duplicated character class `[:ascii:]'"))))
  (should (equal (xr-skip-set-lint "a\\bF-AM-M\\")
                 '((1 . "Unnecessarily escaped `b'")
                   (3 . "Reversed range `F-A'")
                   (6 . "Single-element range `M-M'")
                   (9 . "Stray `\\' at end of string"))))
  (should (equal (xr-skip-set-lint "A-Fa-z3D-KM-N!3-7\\!b")
                 '((7 . "Ranges `A-F' and `D-K' overlap")
                   (10 . "Two-element range `M-N'")
                   (14 . "Range `3-7' includes character `3'")
                   (17 . "Duplicated character `!'")
                   (17 . "Unnecessarily escaped `!'")
                   (19 . "Character `b' included in range `a-z'"))))
  (should (equal (xr-skip-set-lint "!-\\$")
                 '((2 . "Unnecessarily escaped `$'"))))
  (should (equal (xr-skip-set-lint "[^a-z]")
                 '((0 . "Suspect skip set framed in `[...]'"))))
  (should (equal (xr-skip-set-lint "[0-9]+")
                 '((0 . "Suspect skip set framed in `[...]'"))))
  (should (equal (xr-skip-set-lint "[[:space:]].")
                 '((0 . "Suspect character class framed in `[...]'"))))
  (should (equal (xr-skip-set-lint "")
                 '((0 . "Empty set matches nothing"))))
  (should (equal (xr-skip-set-lint "^")
                 '((0 . "Negated empty set matches anything"))))
  (should (equal (xr-skip-set-lint "A-Z-")
                 nil))
  (should (equal (xr-skip-set-lint "-A-Z")
                 nil))
  (should (equal (xr-skip-set-lint "^-A-Z")
                 nil))
  (should (equal (xr-skip-set-lint "A-Z-z")
                 '((3 . "Literal `-' not first or last"))))
)

(provide 'xr-test)

;;; xr-test.el ends here
