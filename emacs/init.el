;; Configure use-package to use system (nix) packages
;; inspired from https://www.srid.ca/vanilla-emacs-nixos.html
(require 'package)
(setq package-archives nil)
;;(package-initialize)
(require 'use-package)
;; Setup use package that must use system packages
(use-package use-package-ensure-system-package :ensure t)


;; Turn off some crufty defaults
(setq
   inhibit-startup-message t inhibit-startup-echo-area-message (user-login-name)
    initial-major-mode 'fundamental-mode initial-scratch-message nil
     fill-column 120
      locale-coding-system 'utf-8
       )

(setq-default
    tab-width 2
      indent-tabs-mode nil
        )

(defalias 'yes-or-no-p 'y-or-n-p)

(tool-bar-mode -1)
; emacs-nox does not have scroll bars
(if (boundp 'scroll-bar-mode) (scroll-bar-mode -1) nil)
(menu-bar-mode -1)
;(add-to-list 'default-frame-alist
;	       '(font . "Hack Nerd Font Mono-12"))
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(global-hl-line-mode t)
;;(set-fringe-mode 10) ; Give some breathing room

; notmuch
(setq mail-specify-envelope-from t) ; Settings to work with msmtp
(setq message-sendmail-envelope-from 'header)
(setq mail-envelope-from 'header)
(setq send-mail-function 'sendmail-send-it)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit) ;; Make ESC quit prompts

(use-package all-the-icons)
(use-package doom-themes
  :after all-the-icons
  :config
  (setq
    doom-themes-enable-bold t
    doom-themes-enable-italic t)
  (load-theme 'doom-vibrant t)
  ;(load-theme 'doom-solarized-light t)
  ;(load-theme 'doom-solarized-dark t)
  ;(if (boundp 'scroll-bar-mode)
  ;  (load-theme 'doom-solarized-dark t)
  ;  (load-theme 'doom-solarized-light t)
  ;  )
  (doom-themes-visual-bell-config)
  (setq doom-themes-treemacs-theme "doom-colors")
  (doom-themes-treemacs-config)

  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))


(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

;; Stop creating annoying files
(setq
 make-backup-files nil
 auto-save-default nil
 create-lockfiles nil
 )

;; Improved handling of clipboard in GNU/Linux and otherwise.
(setq
 select-enable-clipboard t
 select-enable-primary t
 save-interprogram-paste-before-kill t
 mouse-yank-at-point t
 )

(use-package evil
  :init ;; tweak evil's configuration before loading it
  (setq
       evil-search-module 'evil-search
       evil-vsplit-window-right t
       evil-split-window-below t
       evil-want-integration t
       evil-want-keybinding nil)
  :config ;; tweak evil after loading it
  (evil-mode)
  (evil-set-initial-state 'message-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal)
)

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3))

(use-package evil-leader
  :config
  (evil-leader/set-leader "<SPC>")
  (global-evil-leader-mode)
  (evil-leader/set-key
    "<SPC>" 'counsel-M-x
    "bd" 'kill-buffer
    "br" 'revert-buffer
    "qq" 'kill-buffers-kill-terminal
    "qs" 'save-buffers-kill-emacs
    "sa" 'counsel-ag
    "w" evil-window-map
    )
  )

(use-package direnv
  :config
  (direnv-mode))

(use-package evil-collection
  :after evil
  :ensure t
  :custom (evil-collection-setup-minibuffer t)
  :init (evil-collection-init)
  )

(use-package notmuch)

(use-package ivy
  :diminish
  :config
  (ivy-mode 1))

(use-package ivy-rich)

(use-package counsel
  :bind (("M-x" . counsel-M-x)
         ("C-x b" . counsel-ibuffer)
         ("C-x C-f" . counsel-find-file)
         :map minibuffer-local-map
         ("C-r" . 'counsel-minibuffer-history)))

(use-package helpful
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

(use-package general
  :config
  (general-create-definer rune/leader-keys
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")

  (rune/leader-keys
    "t"  '(:ignore t :which-key "toggles")
    "tt" '(counsel-load-theme :which-key "choose theme")))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;;; languages to execute/edit
(org-babel-do-load-languages
 'org-babel-load-languages
 '(;(ipython . t)
   ;(plantuml . t)
   (shell . t)
   (org . t)
   ;; other languages..
   ))
;;; execute block evaluation without confirmation
(setq org-confirm-babel-evaluate nil)

(use-package hydra)

(defhydra hydra-text-scale (:timeout 4)
  "scale text"
  ("j" text-scale-increase "in")
  ("k" text-scale-decrease "out")
  ("f" nil "finished" :exit t))

(rune/leader-keys
  "ts" '(hydra-text-scale/body :which-key "scale text"))

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :custom ((projectile-completion-system 'ivy))
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  ;; NOTE: Set this to the folder where you keep your Git repos!
  (when (file-directory-p "~/Projects/Code")
    (setq projectile-project-search-path '("~/Projects/Code")))
  (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
  :config (counsel-projectile-mode))

(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;;(setq tramp-shell-prompt-pattern "\\(?:^\\|\r\\)[^]#$%>\n]*#?[]#$%>].* *\\(^[\\[[0-9;]*[a-zA-Z] *\\)*")
;(setq tramp-default-method "sshx")
(customize-set-variable 'tramp-default-method "sshx" "")
;(setq tramp-verbose 10)
(customize-set-variable 'tramp-verbose 1 "Enable remote command traces")

(use-package org-download)

(add-hook 'org-mode-hook
          (lambda ()
            (define-key evil-normal-state-map (kbd "TAB") 'org-cycle)))

(defun efs/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1))

;; Org Mode Configuration ------------------------------------------------------

(defun efs/org-font-setup ()
  ;; Replace list hyphen with dot
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

;; Set faces for heading levels
(dolist (face '((org-level-1 . 1.2)
                (org-level-2 . 1.1)
                (org-level-3 . 1.05)
                (org-level-4 . 1.0)
                (org-level-5 . 1.1)
                (org-level-6 . 1.1)
                (org-level-7 . 1.1)
                (org-level-8 . 1.1)))
  (set-face-attribute (car face) nil :weight 'regular :height (cdr face)))

;; Ensure that anything that should be fixed-pitch in Org files appears that way
(set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
(set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
(set-face-attribute 'org-table nil   :inherit '(shadow fixed-pitch))
(set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
(set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
(set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
(set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch))

(use-package org
  :hook (org-mode . efs/org-mode-setup)
  :config
  (setq org-ellipsis " ▾")
  (efs/org-font-setup))

(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "►" "•")))

;(defun efs/org-mode-visual-fill ()
;  (setq visual-fill-column-width 100
;        visual-fill-column-center-text 0)
;  (visual-fill-column-mode 1))

(use-package visual-fill-column)
;  :hook (org-mode . efs/org-mode-visual-fill))

(use-package org-roam)
(use-package org-roam-bibtex
  :after org-roam
  :hook (org-roam-mode . org-roam-bibtex-mode)
  :config
  (require 'org-ref)) ; optional: if Org Ref is not loaded anywhere else, load it here

(use-package org-noter
  :after org
  :ensure t
  :config
  (require 'org-noter-pdftools))

(use-package org-pdftools
  :hook (org-mode . org-pdftools-setup-link))

(use-package org-noter-pdftools
  :after org-noter
  :config
  ;; Add a function to ensure precise note is inserted
  (defun org-noter-pdftools-insert-precise-note (&optional toggle-no-questions)
    (interactive "P")
    (org-noter--with-valid-session
     (let ((org-noter-insert-note-no-questions (if toggle-no-questions
                                                   (not org-noter-insert-note-no-questions)
                                                 org-noter-insert-note-no-questions))
           (org-pdftools-use-isearch-link t)
           (org-pdftools-use-freestyle-annot t))
       (org-noter-insert-note (org-noter--get-precise-info)))))

  ;; fix https://github.com/weirdNox/org-noter/pull/93/commits/f8349ae7575e599f375de1be6be2d0d5de4e6cbf
  (defun org-noter-set-start-location (&optional arg)
    "When opening a session with this document, go to the current location.
With a prefix ARG, remove start location."
    (interactive "P")
    (org-noter--with-valid-session
     (let ((inhibit-read-only t)
           (ast (org-noter--parse-root))
           (location (org-noter--doc-approx-location (when (called-interactively-p 'any) 'interactive))))
       (with-current-buffer (org-noter--session-notes-buffer session)
         (org-with-wide-buffer
          (goto-char (org-element-property :begin ast))
          (if arg
              (org-entry-delete nil org-noter-property-note-location)
            (org-entry-put nil org-noter-property-note-location
                           (org-noter--pretty-print-location location))))))))
  (with-eval-after-load 'pdf-annot
    (add-hook 'pdf-annot-activate-handler-functions #'org-noter-pdftools-jump-to-note)))

