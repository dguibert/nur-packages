;; -*- lexical-binding: t; -*
;; Configure use-package to use system (nix) packages
;; inspired from https://www.srid.ca/vanilla-emacs-nixos.html
(require 'package)
(setq package-archives nil)
;;(package-initialize)
(require 'use-package)

(require 'org)
(org-babel-load-file (expand-file-name "emacs.org" user-emacs-directory))
;(org-babel-load-file (expand-file-name "emacs.org"))
