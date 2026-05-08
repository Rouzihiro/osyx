(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

(setq-default
 ad-redefinition-action 'accept                   ; Silence warnings
 cursor-type 'bar                                 ; Thin cursor
 indent-tabs-mode nil                             ; Spaces > Tabs
 tab-width 4                                      ; Match your shiftwidth
 window-divider-default-bottom-width 0            ; Clean splits
 window-divider-default-right-width 0)

(global-display-line-numbers-mode t)
(setq display-line-numbers-type 'relative)        ; set relativenumber
(delete-selection-mode 1)                         ; Visual mode overwrite
(save-place-mode 1)                               ; Remember where you were
(setq make-backup-files nil)                      ; No swap files cluttering

(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-vsplit-window-right t)
  (setq evil-split-window-below t)
  (setq evil-undo-system 'undo-redo)
  :config
  (evil-mode 1)
  (evil-set-leader 'motion (kbd ","))             ; let mapleader = ","

  (define-key evil-normal-state-map (kbd "C-h") 'evil-window-left)
  (define-key evil-normal-state-map (kbd "C-j") 'evil-window-down)
  (define-key evil-normal-state-map (kbd "C-k") 'evil-window-up)
  (define-key evil-normal-state-map (kbd "C-l") 'evil-window-right)

  (define-key evil-normal-state-map (kbd "C-s") 'save-buffer)
  (define-key evil-normal-state-map (kbd "C-q") 'kill-current-buffer))

(use-package evil-collection
  :after evil
  :config (evil-collection-init))

(use-package vertico
  :init (vertico-mode))

(use-package orderless
  :custom (completion-styles '(orderless basic)))

(use-package consult
  :bind (("C-p" . consult-buffer)                 ; Like <leader>bl
         ("M-f" . consult-line)                   ; Like /
         ("<leader> r" . consult-ripgrep)))      ; Like Telescope live_grep

(use-package eglot
  :hook ((python-mode . eglot-ensure)
         (rust-mode . eglot-ensure)
         (typescript-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs
               '(python-mode . ("ruff" "server"))))
(use-package magit)

(use-package catppuccin-theme
  :config
  (setq catppuccin-flavor 'mocha)
  (load-theme 'catppuccin t))

(setq mode-line-format nil)                       ; Kill the status bar
