# startup-notification

Send a desktop notification after startup.

## Install

```elisp
(straight-use-package
 '(startup-notification
   :host github
   :repo "kisaragi-hiu/startup-notification"))
```

## Setup

```elisp
(when (daemonp)
  (startup-notification-mode))
```

## Acknowledgements

The (attempted) support for Windows is lifted from [alert-toast](https://github.com/gkowzan/alert-toast), © 2020, 2022 Grzegorz Kowzan.
