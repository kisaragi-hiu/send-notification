;;; send-notification.el --- Package Summary -*- lexical-binding: t -*-

;; Author: Kisaragi Hiu
;; Version: 0.1
;; Package-Requires: ((emacs "25.1") (s "1.12.0"))
;; Homepage: https://github.com/kisaragi-hiu/send-notification
;; Keywords: convenience desktop notifications


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; commentary

;;; Code:

(require 's)
(require 'cl-lib)

;; Although `notifications' exists, it only supports platforms with
;; dbus and, importantly (for me), doesn't support Termux.
(cl-defun send-notification
    (summary &key (body "") (app-name "Emacs") (icon "emacs"))
  "Send a desktop notification.

The notification ideally looks something like:

  <ICON> APP-NAME
  SUMMARY
  BODY

Supports:

- platforms with `notify-send',
- Termux (through `termux-notification')
- (untested) macOS (through `osascript'), and
- (untested) Windows 10/11 (through Powershell).

ICON is only supported with `notify-send'."
  (declare (indent 1))
  (cond ((executable-find "notify-send")
         (start-process "notify-send" nil
                        "notify-send"
                        "--icon" icon
                        "--app-name" app-name
                        summary
                        body))
        ((executable-find "termux-notification")
         (start-process "notify" nil
                        "termux-notification"
                        "--title" (format "%s: %s" app-name summary)
                        "--content" body))
        ((executable-find "osascript")
         (start-process
          "notify" nil
          "osascript" "-e"
          (format "display notification \"%s\" with title \"%s\" subtitle \"%s\""
                  body
                  app-name
                  summary)))
        ((executable-find "powershell.exe")
         ;; This is extracted from alert-toast.el. I have zero idea
         ;; how to write a powershell script, and it's all lifted from
         ;; there.
         (let ((process (make-process
                         :name "powershell"
                         :buffer " *powershell*"
                         :command (list
                                   "powershell.exe"
                                   "-noprofile" "-NoExit" "-NonInteractive"
                                   "-WindowStyle" "Hidden"
                                   "-Command" "-")
                         :noquery t
                         :connection-type 'pipe)))
           (unwind-protect
               (progn
                 (process-send-string
                  process
                  "
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml, ContentType=WindowsRuntime] > $null
")
                 (process-send-string
                  process
                  (s-lex-format "
$Xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$Xml.LoadXml('
<toast><visual>
  <binding template=\"ToastText02\">
    <text id=\"1\">${summary}</text>
    <text id=\"2\">${body}</text>
  </binding>
</visual></toast>
')

$Toast = [Windows.UI.Notifications.ToastNotification]::new($Xml)
$Toast.Tag = \"${app-name}\"
$Toast.Group = \"${app-name}\"
$Toast.Priority = [Windows.UI.Notifications.ToastNotificationPriority]::Default
$Toast.ExpirationTime = [DateTimeOffset]::Now.AddSeconds(5.000000)

$Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier(\"${app-name}\")
$Notifier.Show($Toast);
")))
             (delete-process process))))))

(defun send-notification--signal-startup-complete ()
  "Send a startup ready notification."
  (send-notification "Emacs is ready.")
  (send-notification-on-startup-mode -1))

;;;###autoload
(define-minor-mode send-notification-on-startup-mode
  "Send a notification after startup."
  :global t :lighter "" :group 'initialization
  (if send-notification-on-startup-mode
      (add-hook 'after-init-hook
                #'send-notification--signal-startup-complete)
    (remove-hook 'after-init-hook
                 #'send-notification--signal-startup-complete)))

(defun send-notification--on-magit-error-adv (func &rest args)
  "Advice around `magit-process-error-summary'.

FUNC: the original `magit-process-error-summary'
ARGS: arguments that are passed to `magit-process-error-summary'"
  (defvar magit-process-raise-error)
  (let ((msg (apply func args)))
    (unless (or magit-process-raise-error
                (not (stringp msg)) ; msg could be `suppressed'
                ;; If a Magit buffer is displayed, don't bother
                (cl-some
                 (lambda (w)
                   (provided-mode-derived-p
                    (buffer-local-value 'major-mode (window-buffer w))
                    'magit-mode))
                 (window-list)))
      (send-notification msg
        :app-name "Magit"))
    msg))

;;;###autoload
(define-minor-mode send-notification-on-magit-error-mode
  "If a Magit command errors out in the background, notify."
  :global t :lighter "" :group 'magit
  (unless (featurep 'magit)
    (error "Magit is not yet loaded!"))
  (if send-notification-on-magit-error-mode
      (advice-add 'magit-process-error-summary
                  :around #'send-notification--on-magit-error-adv)
    (advice-remove 'magit-process-error-summary
                   #'send-notification--on-magit-error-adv)))

(provide 'send-notification)

;;; send-notification.el ends here
