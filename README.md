# send-notification

Send a desktop notification.

This serves as both a library for sending desktop notifications with zero config and a package of integrations.

## Install

```elisp
(straight-use-package
 '(startup-notification
   :host github
   :repo "kisaragi-hiu/send-notification"))
```

## Setup

```elisp
(when (daemonp)
  (send-notification-startup-mode))
```

## Acknowledgements

The (attempted) support for Windows is lifted from [alert-toast](https://github.com/gkowzan/alert-toast), © 2020, 2022 Grzegorz Kowzan.
