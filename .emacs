;; Basic UI preferences
(setq inhibit-startup-message 1)
(setq display-line-numbers 'absolute)
(setq neo-theme (if (display-graphic-p) 'icons 'arrow))
(set-language-environment "UTF-8")
(global-display-line-numbers-mode t)
(set-default 'truncate-lines t)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; Enable MELPA
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-initialize)

;; Enable Use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; Enable Magit
(use-package magit :ensure t)

;; Enable NeoTree and All The Icons
;; Install fonts (https://github.com/domtronn/all-the-icons.el/tree/master/fonts)
(use-package neotree :ensure t)
(use-package all-the-icons :ensure t)

;; Enable Company
(use-package company :ensure t)

;; Enable .NET Development
(use-package csharp-mode :ensure t)
(use-package csproj-mode :ensure t)

;; Enable Python Development
(use-package python-mode :ensure t)

;; Enable LSP
(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  :hook ((csharp-mode . lsp)
	 (python-mode . lsp))
  :commands lsp
  :ensure t)

;; Enable Dracula Theme
(use-package dracula-theme :ensure t)
(load-theme 'dracula t)

;; Custom KEYMAP
(global-set-key [f8] 'neotree-toggle)
