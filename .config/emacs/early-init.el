;;; early-init.el --- Strip the UI early
(setq package-enable-at-startup nil)
(setq inhibit-startup-screen t)

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; For Hyprland/Wayland transparency
(push '(alpha-background . 90) default-frame-alist)
