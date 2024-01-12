;;; highlight-function-calls.el --- Highlight function/macro calls  -*- lexical-binding: t; -*-

;; Author: Adam Porter <adam@alphapapa.net>
;; Url: http://github.com/alphapapa/highlight-function-calls
;; Version: 0.2-pre
;; Package-Requires: ((emacs "24.4"))
;; Keywords: faces, highlighting

;;; Commentary:

;; This package highlights function symbols in function calls.  This
;; makes them stand out from other symbols, which makes it easy to see
;; where calls to other functions are.  Optionally, macros and special
;; forms can be highlighted as well.  Also, a list of symbols can be
;; excluded from highlighting; by default, ones like +/-, </>, error,
;; require, etc. are excluded.  Finally, the `not' function can be
;; highlighted specially.

;; Just run `highlight-function-calls-mode' to activate, or you can
;; add that to your `emacs-lisp-mode-hook' to do it automatically.

;;; License:

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

;;; Code:

(defgroup highlight-function-calls nil
  "Options for highlighting function/macro calls and special forms."
  :group 'faces)

(defface highlight-function-calls-face
  '((t (:underline t)))
  "Face for highlighting function calls."
  :group 'highlight-function-calls)

(defface highlight-function-calls--not-face
  '((t (:inherit font-lock-negation-char-face)))
  "Face for highlighting `not'."
  :group 'highlight-function-calls)

(defcustom highlight-function-calls-exclude-symbols
  '( = + - / * < > <= >=
     debug  ; Not intended as an interactive function
     error provide require signal throw user-error)
  "List of symbols to not highlight."
  :type '(repeat symbol))

(defcustom highlight-function-calls-macro-calls nil
  "Whether to highlight macro calls."
  :type 'boolean)

(defcustom highlight-function-calls-special-forms nil
  "Whether to highlight special-forms calls."
  :type 'boolean)

(defcustom highlight-function-calls-not nil
  "Whether to highlight `not'."
  :type 'boolean)

(defconst highlight-function-calls--keywords
  `((;; (MATCHER . ANCHORED-HIGHLIGHTER):

     ;; MATCHER
     ;; First we match an opening paren, which prevents matching
     ;; function names as arguments.  We also avoid matching opening
     ;; parens immediately after quotes (but we can't do the same for
     ;; deeper levels).
     ,(rx (or bol (one-or-more space) ",") "("
          (group symbol-start (1+ (not blank)) symbol-end))

     (;; ANCHORED-HIGHLIGHTER:
      ;; FUNCTION
      highlight-function-calls--matcher
      ;; PRE-FORM
      nil
      ;; POST-FORM
      nil
      ;; SUBEXP-HIGHLIGHTER
      (1 highlight-function-calls--face-name prepend)))
    (;; (MATCHER . ANCHORED-HIGHLIGHTER):
     ;; MATCHER
     ,(rx "#'" symbol-start (group (1+ (not blank))) symbol-end)
     ;; ANCHORED-HIGHLIGHTER:
     ;; FUNCTION
     highlight-function-calls--matcher
     ;; PRE-FORM
     nil
     ;; POST-FORM
     nil
     ;; SUBEXP-HIGHLIGHTER
     (0 highlight-function-calls--face-name prepend)))
  "Keywords argument for `font-lock-add-keywords'.")

(defvar highlight-function-calls--face-name nil)

(defun highlight-function-calls--matcher (end)
  "Match function symbols up to END.
The match function to be used by font lock mode."
  (catch 'highlight-function-calls--matcher
    (when (not (nth 5 (syntax-ppss)))
      (let ((match (intern-soft (match-string 1))))
        (when (and (or (functionp match)
                       (when highlight-function-calls-macro-calls
                         (macrop match))
                       (when highlight-function-calls-special-forms
                         (special-form-p match)))
                   (not (member match highlight-function-calls-exclude-symbols)))
          (setq highlight-function-calls--face-name
                (pcase match
                  ((and (or 'not 'null) (guard highlight-function-calls-not)) 'highlight-function-calls--not-face)
                  (_ 'highlight-function-calls-face)))
          (goto-char end)
          (throw 'highlight-function-calls--matcher t))))
    nil))

;;;###autoload
(define-minor-mode highlight-function-calls-mode
  "Highlight function calls.

Toggle highlighting of function calls on or off.

With a prefix argument ARG, enable if ARG is positive, and
disable it otherwise.  If called from Lisp, enable the mode if
ARG is omitted or nil, and toggle it if ARG is `toggle'."
  :init-value nil :lighter nil :keymap nil
  (let ((keywords highlight-function-calls--keywords))
    (font-lock-remove-keywords nil keywords)
    (when highlight-function-calls-mode
      (font-lock-add-keywords nil keywords 'append)))
  ;; Refresh font locking.
  (when font-lock-mode
    (if (fboundp 'font-lock-flush)
        (font-lock-flush)
      (with-no-warnings (font-lock-fontify-buffer)))))

(provide 'highlight-function-calls)

;;; highlight-function-calls.el ends here
