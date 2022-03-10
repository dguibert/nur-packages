;; -*- lexical-binding: t; -*
;; Configure use-package to use system (nix) packages
;; inspired from https://www.srid.ca/vanilla-emacs-nixos.html
(require 'package)
(setq package-archives nil)
;;(package-initialize)
(require 'use-package)
;; Setup use package that must use system packages
(use-package use-package-ensure-system-package :ensure t)

(setq gc-cons-threshold most-positive-fixnum
      load-prefer-newer t)
(add-to-list 'load-path "~/.emacs.private/site-lisp/")
(add-to-list 'load-path (concat user-emacs-directory "site-lisp/"))

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
; https://emacs.stackexchange.com/questions/3912/force-using-fixed-width-font-in-org-mode
(setq solarized-use-variable-pitch nil
      solarized-scale-org-headlines nil)


(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(global-hl-line-mode t)
;;(set-fringe-mode 10) ; Give some breathing room

(global-set-key (kbd "<escape>") 'keyboard-escape-quit) ;; Make ESC quit prompts

(require 'server)
(unless (server-running-p)
    (server-start))

(use-package all-the-icons :ensure t)
(use-package doom-themes
  :ensure t
  :after all-the-icons
  :config
  (setq
   doom-themes-enable-bold t
   doom-themes-enable-italic t)
  ;(load-theme 'doom-vibrant t)
  ;(load-theme 'doom-solarized-light t)
  (load-theme 'doom-solarized-dark t)
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
  :ensure t
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
  :ensure t
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3))

(use-package evil-leader
  :ensure t
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
  :ensure t
  :config
  (direnv-mode))

(use-package evil-collection
  :after evil
  :ensure t
  :custom (evil-collection-setup-minibuffer t)
  :init (evil-collection-init)
  )

(use-package notmuch-agenda
  :defer t
  :commands notmuch-agenda-insert-part)

(use-package org-mime
  :ensure t)

(use-package general
  :ensure t
  :config
  (general-create-definer rune/leader-keys
    :keymaps '(normal insert visual emacs)
    :prefix "SPC"
    :global-prefix "C-SPC")

  (rune/leader-keys
    "t"  '(:ignore t :which-key "toggles")
    "tt" '(counsel-load-theme :which-key "choose theme")))

(use-package hydra
  :ensure t)

(defhydra hydra-text-scale (:timeout 4)
  "scale text"
  ("j" text-scale-increase "in")
  ("k" text-scale-decrease "out")
  ("f" nil "finished" :exit t))

(rune/leader-keys
  "ts" '(hydra-text-scale/body :which-key "scale text"))

(use-package notmuch
  :ensure t
  :init
  ;(setq message-directory "~/Maildir")
  (setq send-mail-function 'sendmail-send-it)
  ;; Send from correct email account
  (setq message-sendmail-f-is-eval 't)
  ; sendmail: cannot use both --from and --read-envelope-from
  ;(setq message-sendmail-extra-arguments '("--read-envelope-from"))
  (setq mail-specify-envelope-from 't)
  (setq mail-envelope-from 'header)
  (setq message-sendmail-envelope-from 'header)
  ;; Setting proper from, fixes i-did-not-set--mail-host-address--so-tickle-me
  (setq mail-host-address "orsin.net")
  (setq user-full-name "David Guibert")
  :bind
  (:map notmuch-search-mode-map
   ("d" . notmuch-delete)
   ("u" . notmuch-mark-read)
   ("i" . notmuch-mark-inbox)
   ("g" . notmuch-refresh-this-buffer)
   ("@" . notmuch-search-person)
   :map notmuch-show-mode-map
   ("d" . notmuch-delete)
   ("U" . notmuch-mark-read)
   ("u" . notmuch-skip-to-unread)
   )
  :custom
  (notmuch-search-oldest-first nil)
  (notmuch-saved-searches
   '((:name "unread" :query "tag:inbox and tag:unread")
     (:name "inbox" :query "tag:inbox" :key "i")
     (:name "flagged" :query "tag:flagged" :key "f")
     (:name "drafts" :query "tag:draft" :key "d")
     (:name "all mail" :query "*" :key "a")
     (:name "recent"
            :query "date:\"this week\""
            :key "r"
            )))
  ;(notmuch-identities
  ; '("David Guibert <david.guibert@gmail.com>"))
  (notmuch-fcc-dirs
   '(("david.guibert@gmail.com" . "david.guibert@gmail.com/mail -unread +sent")))
  ;(notmuch-draft-folders
  ; '(("david\\.guibert@gmail\\.com" . "david.guibert/mail +draft")))

  (notmuch-address-selection-function
   (lambda
     (prompt collection initial-input)
     (completing-read prompt collection nil nil nil
                      (quote notmuch-address-history))))
  :config
  (setq notmuch-show-logo nil)
  ;; Writing email
  ;;(setq message-default-mail-headers "Cc: \nBcc: \n") ;; Always show BCC
  (setq notmuch-always-prompt-for-sender 't)
  ;; postponed message is put in the following draft directory
  (setq message-auto-save-directory "~/Maildir/draft")
  (setq message-kill-buffer-on-exit t)
  ;; change the directory to store the sent mail
  ;(setq message-directory "~/mail/")
  ;;; PGP Encryption
  ;(add-hook 'message-setup-hook 'mml-secure-sign-pgpmime)
  ;(setq notmuch-crypto-process-mime t)
  ;; Saving sent mail in folders depending on from
  (require 'org-mime)

  (defun notmuch-mark-read ()
    (interactive)
    (notmuch-toggle-tag '("unread") t))

  (defun notmuch-search-person ()
    (interactive)
    (let* ((options (notmuch-address-options ""))
           (choice (ivy-completing-read
                    "Person: "
                    options
                    nil
                    nil
                    ;; (plist-get  :authors)
                    "" ;; TODO get author email addresses here? or stick them at the start?
                    )))
      (when choice
        (notmuch-search (format "from: %s or to:%s" choice choice)))))

  (defun notmuch-toggle-tag (tags advance)
    (let* ((cur-tags
            (cl-case major-mode
              (notmuch-search-mode
               (notmuch-search-get-tags))

              (notmuch-show-mode
               (notmuch-show-get-tags))))
           (action (if (cl-intersection cur-tags tags :test 'string=) "-" "+"))
	   (arg (mapcar (lambda (x) (concat action x)) tags)))

      (cl-case major-mode
        (notmuch-search-mode
         (notmuch-search-tag arg)
         (when advance (notmuch-search-next-thread)))
        (notmuch-show-mode
         (notmuch-show-tag arg)
         (when advance (notmuch-show-next-matching-message))))))

  (defun notmuch-mark-inbox ()
    (interactive)
    (notmuch-toggle-tag '("inbox") t))

  (defun notmuch-mark-read ()
    (interactive)
    (notmuch-toggle-tag '("unread") t))

  (defun notmuch-expand-calendar-parts (o msg part depth &optional hide)
    (funcall o
             msg part depth (and hide
                                 (not (string= (downcase (plist-get part :content-type))
                                               "text/calendar")))))

  (advice-add 'notmuch-show-insert-bodypart :around #'notmuch-expand-calendar-parts)

  (require 'notmuch-switch-identity)
  (fset 'notmuch-show-insert-part-text/calendar #'notmuch-agenda-insert-part)



)
;(define-key notmuch-show-mode-map "d"
;  (lambda ()
;    "toggle deleted tag for message"
;    (interactive)
;    (if (member "deleted" (notmuch-show-get-tags))
;        (notmuch-show-tag (list "-deleted -inbox"))
;      (notmuch-show-tag (list "+deleted")))))

(use-package ivy
  :ensure t
  :diminish
  :config
  (ivy-mode 1))

(use-package ivy-rich
  :ensure t)

(use-package counsel
  :ensure t
  :bind (("M-x" . counsel-M-x)
         ("C-x b" . counsel-ibuffer)
         ("C-x C-f" . counsel-find-file)
         :map minibuffer-local-map
         ("C-r" . 'counsel-minibuffer-history)))

(use-package helpful
  :ensure t
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))

(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package gnuplot
  :ensure t)

(use-package projectile
  :ensure t
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
  :ensure t
  :config (counsel-projectile-mode))

(use-package magit
  :ensure t
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;;(setq tramp-shell-prompt-pattern "\\(?:^\\|\r\\)[^]#$%>\n]*#?[]#$%>].* *\\(^[\\[[0-9;]*[a-zA-Z] *\\)*")
;(setq tramp-default-method "sshx")
(customize-set-variable 'tramp-default-method "sshx" "")
;(setq tramp-verbose 10)
(customize-set-variable 'tramp-verbose 1 "Enable remote command traces")

(use-package org-download
  :ensure t)
(use-package ob-async
  :ensure t)

;; Org Mode Configuration ------------------------------------------------------

(add-hook 'org-mode-hook
          (lambda ()
            (define-key evil-normal-state-map (kbd "TAB") 'org-cycle)))

(defun efs/org-mode-setup ()
  (org-indent-mode)
  (variable-pitch-mode 1)
  (visual-line-mode 1))

; https://emacs.stackexchange.com/a/63562
(defun ek/babel-ansi ()
  (when-let ((beg (org-babel-where-is-src-block-result nil nil)))
    (save-excursion
      (goto-char beg)
      (when (looking-at org-babel-result-regexp)
        (let ((end (org-babel-result-end))
              (ansi-color-context-region nil))
          (ansi-color-apply-on-region beg end))))))

(add-hook 'org-babel-after-execute-hook 'ek/babel-ansi)

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

(use-package org :ensure t
  :hook (org-mode . efs/org-mode-setup)
  :init
  ;; Proper code blocks
  (setq org-src-fontify-natively t)
  (setq org-src-tab-acts-natively t)
  ;; Babel languages
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((python  . t)
     (shell   . t)
     ;(C       . t)
     ;(C++     . t)
     ;(fortran . t)
     ;(awk     . t)
     (gnuplot . t)
     (latex   . t)
     (emacs-lisp . t)))
  ;;; execute block evaluation without confirmation
  (setq org-latex-listings t)
  ;(setq org-confirm-babel-evaluate nil)
  (setq org-ellipsis " ▾")
  ;; Agenda
  (setq org-agenda-start-with-log-mode t)
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)
  ;; Encoding
  (setq org-export-coding-system 'utf-8)
  (prefer-coding-system 'utf-8)
  (set-charset-priority 'unicode)
  (setq default-process-coding-system '(utf-8-unix . utf-8-unix))
  ;; Don't allow editing of folded regions
  (setq org-catch-invisible-edits 'error)
  ;; Start agenda on Monday
  (setq org-agenda-start-on-weekday 1)
  ;; Enable indentation view, does not effect file
  (setq org-startup-indented t)
  ;; Attachments
  (setq org-id-method (quote uuidgen))
  (setq org-attach-directory "attach/")
  (efs/org-font-setup)

  (setq org-agenda-files
        '(("~/Documents/org/notes.org")
          ))
  :bind
  (("\C-ca" . org-agenda)
   ("\C-cl" . org-store-link))
)

(use-package ol-notmuch :ensure t)

(use-package org-bullets
  :ensure t
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "►" "•")))

;(defun efs/org-mode-visual-fill ()
;  (setq visual-fill-column-width 100
;        visual-fill-column-center-text 0)
;  (visual-fill-column-mode 1))

(use-package visual-fill-column :ensure t)
;  :hook (org-mode . efs/org-mode-visual-fill))

; https://rgoswami.me/posts/org-note-workflow/
; https://lucidmanager.org/productivity/taking-notes-with-emacs-org-mode-and-org-roam/
(use-package org-roam
  :ensure t
  :demand t  ;; Ensure org-roam is loaded by default
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-directory "~/Documents/roam")
  (org-roam-completion-everywhere t)
  (org-roam-dailies-capture-templates
   '(("d" "default" entry "* %<%I:%M %p>: %?"
             :if-new (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n"))))
  (org-roam-capture-templates
   '(("d" "default" plain
      "%?"
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
      :unnarrowed t)
     ("p" "project" plain "* Goals\n\n%?\n\n* Tasks\n\n** TODO Add initial tasks\n\n* Dates\n\n"
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: Project")
      :unnarrowed t)
     ("b" "book notes" plain (file "~/Documents/roam/templates/BookNoteTemplate.org")
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
       :unnarrowed t)
     ))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n I" . org-roam-node-insert-immediate)
         ("C-c n p" . my/org-roam-find-project)
         ("C-c n t" . my/org-roam-capture-task)
         ("C-c n b" . my/org-roam-capture-inbox)
         :map org-mode-map
         ("C-M-i" . completion-at-point)
         :map org-roam-dailies-map
         ("Y" . org-roam-dailies-capture-yesterday)
         ("T" . org-roam-dailies-capture-tomorrow))
  :bind-keymap
  ("C-c n d" . org-roam-dailies-map)
  :config
  (setq org-roam-verbose nil  ; https://youtu.be/fn4jIlFwuLU
        org-roam-buffer-no-delete-other-windows t ; make org-roam buffer sticky
        )
  (require 'org-roam-dailies) ;; Ensure the keymap is available
                                        ;(org-roam-db-autosync-mode)
  (org-roam-setup))

(defun org-roam-node-insert-immediate (arg &rest args)
  (interactive "P")
  (let ((args (push arg args))
        (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                  '(:immediate-finish t)))))
    (apply #'org-roam-node-insert args)))

(defun my/org-roam-filter-by-tag (tag-name)
  (lambda (node)
    (member tag-name (org-roam-node-tags node))))

(defun my/org-roam-list-notes-by-tag (tag-name)
  (mapcar #'org-roam-node-file
          (seq-filter
           (my/org-roam-filter-by-tag tag-name)
           (org-roam-node-list))))

(defun my/org-roam-refresh-agenda-list ()
  (interactive)
  (setq org-agenda-files
        (delq nil (delete-dups
                   (my/org-roam-list-notes-by-tag "Project")))))

;; Build the agenda list the first time for the session
(my/org-roam-refresh-agenda-list)

(defun my/org-roam-project-finalize-hook ()
  "Adds the captured project file to `org-agenda-files' if the
capture was not aborted."
  ;; Remove the hook since it was added temporarily
  (remove-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)

  ;; Add project file to the agenda list if the capture was confirmed
  (unless org-note-abort
    (with-current-buffer (org-capture-get :buffer)
      (add-to-list 'org-agenda-files (buffer-file-name)))))

(defun my/org-roam-find-project ()
  (interactive)
  ;; Add the project file to the agenda after capture is finished
  (add-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)

  ;; Select a project file to open, creating it if necessary
  (org-roam-node-find
   nil
   nil
   (my/org-roam-filter-by-tag "Project")
   :templates
   '(("p" "project" plain "* Goals\n\n%?\n\n* Tasks\n\n** TODO Add initial tasks\n\n* Dates\n\n"
      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+category: ${title}\n#+filetags: Project")
      :unnarrowed t))))

(defun my/org-roam-capture-inbox ()
  (interactive)
  (org-roam-capture- :node (org-roam-node-create)
                     :templates '(("i" "inbox" plain "* %?"
                                   :if-new (file+head "Inbox.org" "#+title: Inbox\n")))))

(defun my/org-roam-capture-task ()
  (interactive)
  ;; Add the project file to the agenda after capture is finished
  (add-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)

  ;; Capture the new task, creating the project file if necessary
  (org-roam-capture- :node (org-roam-node-read
                            nil
                            (my/org-roam-filter-by-tag "Project"))
                     :templates '(("p" "project" plain "** TODO %?"
                                   :if-new (file+head+olp "%<%Y%m%d%H%M%S>-${slug}.org"
                                                          "#+title: ${title}\n#+category: ${title}\n#+filetags: Project"
                                                          ("Tasks"))))))

(defun my/org-roam-copy-todo-to-today ()
  (interactive)
  (let ((org-refile-keep t) ;; Set this to nil to delete the original!
        (org-roam-dailies-capture-templates
         '(("t" "tasks" entry "%?"
            :if-new (file+head+olp "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n" ("Tasks")))))
        (org-after-refile-insert-hook #'save-buffer)
        today-file
        pos)
    (save-window-excursion
      (org-roam-dailies--capture (current-time) t)
      (setq today-file (buffer-file-name))
      (setq pos (point)))

    ;; Only refile if the target file is different than the current file
    (unless (equal (file-truename today-file)
                   (file-truename (buffer-file-name)))
      (org-refile nil nil (list "Tasks" today-file nil pos)))))

(add-to-list 'org-after-todo-state-change-hook
             (lambda ()
               (when (equal org-state "DONE")
                 (my/org-roam-copy-todo-to-today))))

(use-package org-roam-bibtex
  :ensure t
  :after (org-roam)
  :hook (org-roam-mode . org-roam-bibtex-mode)
  :config
  (setq org-roam-bibtex-preformat-keywords
        '("=key=" "title" "url" "file" "author-or-editor" "keywords"))
  (setq orb-templates
        '(("r" "ref" plain (function org-roam-capture--get-point)
           ""
           :file-name "${slug}"
           :head "#+TITLE: ${=key=}: ${title}\n#+ROAM_KEY: ${ref}

- tags ::
- keywords :: ${keywords}

\n* ${title}\n  :PROPERTIES:\n  :Custom_ID: ${=key=}\n  :URL: ${url}\n  :AUTHOR: ${author-or-editor}\n  :NOTER_DOCUMENT: %(orb-process-file-field \"${=key=}\")\n  :NOTER_PAGE: \n  :END:\n\n"

           :unnarrowed t))))

(use-package org-noter
  :ensure t
  :after (:any org pdf-view)
  :config
  (setq
   ;; The WM can handle splits
   org-noter-notes-window-location 'other-frame
   ;; Please stop opening frames
   org-noter-always-create-frame nil
   ;; I want to see the whole file
   org-noter-hide-other nil
   ;; Everything is relative to the main notes file
   ;org-noter-notes-search-path (list org_notes)
   )
  )

;;;; Actually start using templates
(setq org-capture-templates
  '(("m" "Email Workflow")
    ("mf" "Follow Up" entry (file+olp "~/Documents/roam/Mail.org" "Follow Up")
     "* TODO Follow up with %:fromname on %:subject\nSCHEDULED:%t\n%a\n%i" :immediate-finish t)
    ("mr" "Read Later" entry (file+olp "~/Documents/roam/Mail.org" "Read Later")
     "* TODO Read %:subject\nSCHEDULED:%t\n%a\n\n%i" :immediate-finish t)
   ))
;;        ;; Firefox and Chrome
;;                     '("P" "Protocol" entry ; key, name, type
;;                       (file+headline +org-capture-notes-file "Inbox") ; target
;;                       "* %^{Title}\nSource: %u, %c\n #+BEGIN_QUOTE\n%i\n#+END_QUOTE\n\n\n%?"
;;                       :prepend t ; properties
;;                       :kill-buffer t))
;;        (add-to-list 'org-capture-templates
;;                     '("L" "Protocol Link" entry
;;                       (file+headline +org-capture-notes-file "Inbox")
;;                       "* %? [[%:link][%(transform-square-brackets-to-round-ones \"%:description\")]]\n"
;;                       :prepend t
;;                       :kill-buffer t))

(use-package org-ref
  :ensure t
  :config
  (setq
   org-ref-completion-library 'org-ref-ivy-cite
   org-ref-get-pdf-filename-function 'org-ref-get-pdf-filename-helm-bibtex
   org-ref-default-bibliography (list "/home/dguibert/Documents/bib.bib")
   org-ref-bibliography-notes "/home/dguibert/Documents/notes/bibnotes.org"
   org-ref-note-title-format "* TODO %y - %t\n :PROPERTIES:\n  :Custom_ID: %k\n  :NOTER_DOCUMENT: %F\n :ROAM_KEY: cite:%k\n  :AUTHOR: %9a\n  :JOURNAL: %j\n  :YEAR: %y\n  :VOLUME: %v\n  :PAGES: %p\n  :DOI: %D\n  :URL: %U\n :END:\n\n"
   org-ref-notes-directory "/home/dguibert/Documents/notes"
   org-ref-notes-function 'orb-edit-notes
   ))


(use-package cmake-mode :ensure t)

(use-package all-the-icons :ensure t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(helm-minibuffer-history-key "M-p")
)

;; support multiple email accounts (required in private.el)
(autoload 'gnus-alias-determine-identity "gnus-alias" "" t)
(require 'private nil t) ;; t=no signaling an error

(savehist-mode 1)
(setq savehist-additional-variables '(kill-ring search-ring regexp-search-ring))

(use-package org-tree-slide
  :ensure t
  :custom
  (org-image-actual-width nil))

(setq ediff-diff-options "-w")
(setq ediff-split-window-function 'split-window-horizontally)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

(use-package auctex
  :defer t
  :ensure t
  :config
  (setq TeX-PDF-mode t))

;; move customization variables to a separate file and load it
(setq custom-file (expand-file-name "custom-vars.el" user-emacs-directory))
(load custom-file 'noerror 'nomessage)

;; revert buffers when the underlying file has changed
(global-auto-revert-mode 1)
;; revert dired and other buffers
(setq golbal-auto-revert-non-file-buffers t)

