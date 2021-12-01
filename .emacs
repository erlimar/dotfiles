;; Basic UI preferences
(setq inhibit-startup-message 1)
(setq display-line-numbers 'absolute)
(set-language-environment "UTF-8")
(global-display-line-numbers-mode t)
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

;; Enable NeoTree
(use-package neotree :ensure t)

;; Enable Company
(use-package company :ensure t)

;; Enable .NET Development
(use-package csharp-mode :ensure t)
(use-package cproj-mode :ensure t)

;; Enable Python Development
(use-package python-mode :ensure t)

;; Enable LSP
(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  :hook (
	 (csharp-mode . lsp)
	 (python-mode . lsp)
	 (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp
  :ensure t)

;; Custom KEYMAP
(global-set-key [f8] 'neotree-toggle)
