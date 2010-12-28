;;; flymakemsg.el --- Show flymake compile errors in echo area
;;
;; Author: Lennart Borgman (lennart O borgman A gmail O com)
;; Created: 2009-11-21 Sat
;; Version: 0.5
;; Last-Updated: 2010-12-28 Tue
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   `backquote', `bytecomp', `warnings'.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; Show flymake error messages in minibuffer when point is on a
;; flymake error overlay.
;;
;; To use it just load this file. Put this in .emacs:
;;
;;   (require 'flymakemsg)
;;
;; This file run `defadvice' on some functions in `flymake-mode'.
;; This code started from an idea in a paste.
;;
;; Note: This code breaks Emacs conventions since it does the
;; defadvising when you just loads this file.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(eval-when-compile (require 'flymake))

;; Fix-me: move this into flymake.el and send a patch. It will anyway
;; not work without a patched flymake.

(defun flymakemsg-show-err-at-point ()
  "If point is on a flymake error, show it in echo area.
Protected to run in timers and hooks."
  (condition-case err
      (flymakemsg-show-err-at-point-1)
    (error (message "%s" err))))

(defvar flymakemsg-last-overlay nil)
(make-variable-buffer-local 'flymakemsg-last-overlay)

(defun flymakemsg-show-err-at-point-1 ()
  "If point is on a flymake error, show it in echo area."
  (interactive)
  (when flymake-mode
    (let ((flyovl (flymakemsg-get-overlay (point))))
      (unless (eq flyovl flymakemsg-last-overlay)
        (setq flymakemsg-last-overlay flyovl)
        (when flyovl
          (message "%s" (propertize (overlay-get flyovl 'help-echo)
                                    'face (overlay-get flyovl 'face))))))))

(defun flymakemsg-get-overlay (pos)
  (get-char-property pos 'flymake-overlay))

(defadvice flymake-mode (after
                         flymakemsg-ad-flymake-mode
                         activate compile)
  "Turn on showing of flymake errors then point is on them.
This shows the error in the echo area."
  (if flymake-mode
      (add-hook 'post-command-hook 'flymakemsg-post-command t t)
    (remove-hook 'post-command-hook 'flymakemsg-post-command t)))


(defcustom flymakemsg-delay 0.3
  "Delay after last command before showing flymake message.
This delay avoids that the messsage disappear if the user enters
into the overlay by for example holding down an arrow key."
  :type 'number
  :group 'flymake)

(defun flymakemsg-post-command ()
  ;; Wait to not disturb to much.
  (flymakemsg-start-msg-timer flymakemsg-delay))

(defvar flymakemsg-msg-timer nil)

(defun flymakemsg-cancel-msg-timer ()
  (when (timerp flymakemsg-msg-timer)
    (cancel-timer flymakemsg-msg-timer)))

(defun flymakemsg-start-msg-timer (delay)
  (flymakemsg-cancel-msg-timer)
  (run-with-idle-timer delay nil 'flymakemsg-show-err-at-point))


(provide 'flymakemsg)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; flymakemsg.el ends here
