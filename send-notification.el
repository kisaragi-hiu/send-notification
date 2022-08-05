;;; send-notification.el --- Package Summary -*- lexical-binding: t -*-

;; Author: Kisaragi Hiu
;; Version: 0.1
;; Package-Requires: ((emacs "25.1") (s "1.12.0"))
;; Homepage: https://github.com/kisaragi-hiu/send-notification
;; Keywords: convenience


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

Supports `notify-send', `termux-notification', and `osascript'."
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
                        "--title" app-name
                        "--content"
                        (if (equal "" body)
                            summary
                          (format "%s\n\n%s"
                                  summary
                                  body))))
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
  (send-notification "Emacs is ready."))

;;;###autoload
(define-minor-mode send-notification-startup-mode
  "Send a notification after startup."
  :global t :lighter "" :group 'initialization
  (if send-notification-startup-mode
      (add-hook 'after-init-hook
                #'send-notification--signal-startup-complete)
    (remove-hook 'after-init-hook
                 #'send-notification--signal-startup-complete)))

(provide 'send-notification)

;;; send-notification.el ends here
