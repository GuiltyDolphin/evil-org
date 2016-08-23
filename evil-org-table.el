;;; evil-org-table.el --- evil-org table table manipulation.

;; Copyright (C) 2016 Ben Moon
;; Author: Ben Moon <guiltydolphin@gmail.com>

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;;
;;; Defines Evil functionality for working with tables in Org-mode.
;;;
;;; Code:

(require 'dash)
(require 'emaps)
(require 'evil)
(require 'hook)

(evil-define-state org-table
  "org-table-state
State for working in org tables."
  :tag " <O-T> "
  :enable (normal))

(defun evil-org-table-insert-row-above ()
  "Insert a new row above the current row."
  (interactive)
  (org-table-insert-row))

(defun evil-org-table-insert-row-below ()
  "Insert a new row below the current row."
  (interactive)
  (org-table-insert-row t))

(evil-define-motion evil-org-table-goto-column (n)
  "Go to the Nth field in the current row.
By default the next field."
  :type exclusive
  (if n (org-table-goto-column n) (org-table-next-field))
  (point))

(evil-define-motion evil-org-table-forward-field (count)
  "Move COUNT fields forwards.
Default COUNT is 1."
  (let ((count (or count 1)))
    (if (< count 0) (evil-org-table-backward-field (abs count))
      (--dotimes count (org-table-next-field)))))

(evil-define-motion evil-org-table-backward-field (count)
  "Move COUNT fields backwards.
Default COUNT is 1."
  (let ((count (or count 1)))
    (if (< count 0) (evil-org-table-forward-field (abs count))
      (--dotimes count (org-table-previous-field)))))

(evil-define-motion evil-org-table-end-of-field (count)
  "Go to the end of the current field, move forward COUNT fields if specified."
  :type exclusive
  (evil-org-table-forward-field count)
  (let ((current-field (org-table-current-column)))
    (org-table-goto-column current-field)
    (let ((beg-point (point)))
      (org-table-end-of-field 0)
      (if (= (org-table-current-column) current-field)
          (point)
        (goto-char beg-point)))))

(evil-define-motion evil-org-table-beginning-of-field (count)
  "Go to the end of the current field, move backwards COUNT fields if specified."
  :type exclusive
  (evil-org-table-backward-field count)
  (let ((current-field (org-table-current-column)))
    (org-table-goto-column current-field)
    (let ((beg-point (point)))
      (org-table-beginning-of-field 0)
      (if (= (org-table-current-column) current-field)
          (point)
        (goto-char beg-point)))))

(evil-define-text-object evil-org-table-field (count &optional beg end type)
  "Select a field."
  (list (save-excursion (evil-org-table-beginning-of-field (1- count)))
        (save-excursion (evil-org-table-end-of-field (1- count)))))

(evil-define-operator evil-org-table-kill-row
  (beg end type register yank-handler)
  "Delete whole current table row."
  :motion nil
  (interactive "<R><x>")
  (let ((col (org-table-current-column)))
    (org-table-kill-row)
    (org-table-goto-column col)))

(evil-define-motion evil-org-table-next-row (count)
  "Move the cursor COUNT rows down."
  :type line
  (let (line-move-visual)
    (dotimes (n (or count 1)) (org-table-next-row))))

(emaps-define-key evil-org-table-state-map
  "D" 'evil-org-table-kill-row
  "o" 'evil-org-table-insert-row-below
  "O" 'evil-org-table-insert-row-above)

(defun evil-org-table--check-table ()
  "Check if we are in a table and switch to `evil-org-table-state' if so."
  (if (org-at-table-p)
      (progn
        (evil-org-table-mode 1)
        (when (and (evil-normal-state-p) (not (evil-org-table-state-p)))
          (evil-org-table-state)))
    (progn
      (when (evil-org-table-state-p) (evil-normal-state))
      (when evil-org-table-mode (evil-org-table-mode -1)))))

(define-minor-mode evil-org-table-mode
  "Minor mode for additional table bindings in evil-org."
  :keymap (make-sparse-keymap))

(evil-define-key 'motion evil-org-table-mode-map
  "|" 'evil-org-table-goto-column)

(evil-define-key 'visual evil-org-table-mode-map
  "i|" 'evil-org-table-field)

(hook--monitor-expression-value '(point) 'evil-org-table--check-table 'org-mode t)

(provide 'evil-org-table)
;;; evil-org-table.el ends here
