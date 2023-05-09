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
(add-to-list 'load-path (concat user-emacs-directory "site-lisp/"))
(add-to-list 'load-path "~/.emacs.private/site-lisp/")

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
  (add-to-list 'warning-suppress-types '(direnv))
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
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)
  ;; Don't use magit for interactive rebase
  ;; (has own entire key-map, doesn't allow text-file editing).
  (setq auto-mode-alist (rassq-delete-all #'git-rebase-mode auto-mode-alist))
  )

(use-package forge
  :ensure t
  :after magit)
;(require 'cl-lib)
;(setq auto-mode-alist
;      (cl-remove-if (lambda (x) (eq (cdr x) 'git-rebase-mode))
;                    auto-mode-alist))
;  ;; Don't use magit for interactive rebase
;  ;; (has own entire key-map, doesn't allow text-file editing).
;(while (rassoc 'git-rebase-mode auto-mode-alist)
;  (setq auto-mode-alist
;        (assq-delete-all (car (rassoc 'git-rebase-mode auto-mode-alist))
;                         auto-mode-alist)))

;(use-package tramp
;  :ensure t
;  :demand t
;  :init
  (autoload #'tramp-register-crypt-file-name-handler "tramp-crypt")
;  :config
;  ;;(setq tramp-verbose 6)
(setq tramp-default-method "sshx")
;;
  (setq vc-ignore-dir-regexp
        (format "\\(%s\\)\\|\\(%s\\)"
	        vc-ignore-dir-regexp
	        tramp-file-name-regexp))
;
  ;; Honor remote PATH.
  ; (add-to-list 'tramp-remote-path 'tramp-own-remote-path)

  (setq tramp-completion-reread-directory-timeout nil)
  (setq tramp-default-remote-shell "/bin/bash")
  (setq tramp-encoding-shell "/bin/bash")
;  ;; Allow ssh connections to persist.
;  ;;
;  ;; This seems to maybe cause tramp to hang a lot.
;  (customize-set-variable 'tramp-use-ssh-controlmaster-options nil)
;  )

;(require 'tramp)

;; Org Mode Configuration ------------------------------------------------------

(add-hook 'org-mode-hook
          (lambda ()
            (define-key evil-normal-state-map (kbd "TAB") 'org-cycle)))

(add-hook 'org-capture-prepare-finalize-hook 'org-id-get-create)

(defun my/org-add-ids-to-headlines-in-file ()
  "Add ID properties to all headlines in the current file which
do not already have one."
  (interactive)
  (org-map-entries 'org-id-get-create))

(add-hook 'org-mode-hook
          (lambda ()
            (add-hook 'before-save-hook 'my/org-add-ids-to-headlines-in-file nil 'local)))

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
; https://yannesposito.com/posts/0015-how-i-use-org-mode/index.html
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

  :bind
  (("\C-ca" . org-agenda)
   ("\C-cl" . org-store-link)
   ("\C-cc" . org-capture)
   )
  :config
  ;;(org-mode-config)
  (setq org-extend-today-until 4
        org-use-effective-time t)
  (setq org-todo-keywords
        '((sequence "TODO(t)"
                    "IN-PROGRESS(p)"
                    "|"
                    "DONE(d)"
                    "HOLD(h@/!)"
                    "CANCELED(c@/!)"
                    "HANDLED(l@/!)")
          (sequence "|" "PAUSE(p)" "CHAT(c)" "EMAIL(e)" "MEETING(m)" "REVIEW(r)" "GEEK(g)")))

  ;;; Look & Feel

  ;; I like to have something different than ellipsis because I often use them
  ;; myself.
  ;;(setq org-ellipsis " [+]")
  (custom-set-faces '(org-ellipsis ((t (:foreground "gray40" :underline nil)))))

  (defun my-org-settings ()
    (org-display-inline-images)
    (setq fill-column 75)
    (abbrev-mode)
    (org-indent-mode)
    nil)

  (add-hook 'org-mode-hook #'my-org-settings)

  (setq org-tags-column 69)

  ;; src block indentation / editing / syntax highlighting
  (setq org-src-fontify-natively t
        org-src-window-setup 'current-window ;; edit in current window
        org-src-preserve-indentation t ;; do not put two spaces on the left
        org-src-tab-acts-natively t)

  ;; *** Templates
  ;; the %a refer to the place you are in emacs when you make the capture
  ;; that's very neat when you do that in an email for example.
  (setq org-capture-templates
        '(("t" "todo"         entry (file "~/Documents/roam/inbox.org")
           "* TODO %?\n%U\n- ref :: %a\n")
          ;; time tracker (clocked tasks)
          ("g" "geek"         entry (file+olp+datetree "~/Documents/roam/tracker.org")
           "* GEEK %?         :perso:\n%U\n- ref :: %a\n"
           :prepend t :tree-type week :clock-in t :clock-keep t)
          ("c" "chat"         entry (file+olp+datetree "~/Documents/roam/tracker.org")
           "* CHAT %?         :work:chat:\n%U\n- ref :: %a\n"
           :prepend t :tree-type week :clock-in t :clock-keep t)
          ("e" "email"        entry (file+olp+datetree "~/Documents/roam/tracker.org")
           "* EMAIL %?        :work:email:\n%U\n- ref :: %a\n"
           :prepend t :tree-type week :clock-in t :clock-keep t)
          ("m" "meeting"      entry (file+olp+datetree "~/Documents/roam/tracker.org")
           "* MEETING %?      :work:meeting:\n%U\n- ref :: %a\n"
           :prepend t :tree-type week :clock-in t :clock-keep t)
          ("r" "review"       entry (file+olp+datetree "~/Documents/roam/tracker.org")
           "* REVIEW %?       :work:review:\n%U\n- ref :: %a\n"
           :prepend t :tree-type week :clock-in t :clock-keep t)
          ("w" "work"         entry (file+olp+datetree "~/Documents/roam/tracker.org")
           "* IN-PROGRESS %?  :work:\n%U\n- ref :: %a\n"
           :prepend t :tree-type week :clock-in t :clock-keep t)
          ("p" "pause"        entry (file+olp+datetree "~/Documents/roam/tracker.org")
           "* PAUSE %?        :pause:\n%U\n- ref :: %a\n"
           :prepend t :tree-type week :clock-in t :clock-keep t)
          ("i" "interruption" entry (file+olp+datetree "~/Documents/roam/tracker.org")
           "* IN-PROGRESS %?  :interruption:work:\n%U\n- ref :: %a\n"
           :prepend t :tree-type week :clock-in t :clock-keep t)
          ("s" "sport" entry (file+olp+datetree "~/Documents/roam/sport.org")
           "* %^T %?  :sport:%^g%^{TYPE}p%^{TIME}p%^{DISTANCE}p%^{HEARTRATE}p%^{MAXHEARRATE}p%^{PACE}p"
           :prepend t :tree-type month :jump-to-captured t)
          ("S" "sport (planned)" entry (file+olp+datetree "~/Documents/roam/sport.org")
           "* %^t %?  :sport:%^g%^{TIME}p%^{DISTANCE}p"
           :prepend t :tree-type month :jump-to-captured t)
          ("f" "chore"        entry (file "~/Documents/roam/inbox.org")
           "* IN-PROGRESS %?  :chore:\n%U\n"
           :clock-in t :clock-keep t)))

  ;; How to create default clocktable
  (setq org-clock-clocktable-default-properties
        '(:scope subtree :maxlevel 4 :timestamp t :link t :tags t :narrow 36! :match "work"))

  ;; How to display default clock report in agenda view
  (setq org-agenda-clockreport-parameter-plist
        '(:lang "en" :maxlevel 4 :fileskip0 t :link t :indent t :narrow 80!))

  ;; *** Projectile; default TODO file to create in your projects
  (setq org-projectile-file "inbox.org")

  (setq org-refile-targets
        '((nil :maxlevel . 5)
          (org-agenda-files :maxlevel . 5)))

  ;; *** Agenda
  (setq org-log-into-drawer t) ;; hide the log state change history a bit better
  (setq org-deadline-warning-days 7)
  (setq org-agenda-skip-scheduled-if-deadline-is-shown t)
  (setq org-habit-show-habits-only-for-today nil)
  (setq org-habit-graph-column 65)
  (setq org-duration-format 'h:mm) ;; show hours at max, not days
  (setq org-agenda-compact-blocks t)
  ;; default show today
  (setq org-agenda-span 'day)
  (setq org-agenda-start-day "-0d")
  (setq org-agenda-start-on-weekday nil)
  (setq org-agenda-custom-commands
        '(("d" "Done tasks" tags "/DONE|CANCELED")
          ("g" "Plan Today"
           ((agenda "" ((org-agenda-span 'day)))
            (org-agenda-skip-function '(org-agenda-skip-deadline-if-not-today))
            (org-agenda-entry-types '(:deadline))
            (org-agenda-overriding-header "Today's Deadlines ")))))
  (setq org-agenda-window-setup 'only-window)

  (setq org-agenda-prefix-format
        '((agenda . " %i %(vulpea-agenda-category 12)%?-12t% s")
          (todo . " %i %(vulpea-agenda-category 12) ")
          (tags . " %i %(vulpea-agenda-category 12) ")
          (search . " %i %(vulpea-agenda-category 12) ")))

  (defun vulpea-buffer-prop-get (name)
    "Get a buffer property called NAME as a string."
    (org-with-point-at 1
      (when (re-search-forward (concat "^#\\+" name ": \\(.*\\)")
                               (point-max) t)
        (buffer-substring-no-properties
         (match-beginning 1)
         (match-end 1)))))

  (defun vulpea-agenda-category (&optional len)
    "Get category of item at point for agenda.

Category is defined by one of the following items:

- CATEGORY property
- TITLE keyword
- TITLE property
- filename without directory and extension

When LEN is a number, resulting string is padded right with
spaces and then truncated with ... on the right if result is
longer than LEN.

Usage example:

  (setq org-agenda-prefix-format
        '((agenda . \" %(vulpea-agenda-category) %?-12t %12s\")))

Refer to `org-agenda-prefix-format' for more information."
    (let* ((file-name (when buffer-file-name
                        (file-name-sans-extension
                         (file-name-nondirectory buffer-file-name))))
           (title (vulpea-buffer-prop-get "title"))
           (category (org-get-category))
           (result
            (or (if (and
                     title
                     (string-equal category file-name))
                    title
                  category)
                "")))
      (if (numberp len)
          (s-truncate len (s-pad-right len " " result))
        result)))

  ;; ** Org Annotate

  ;; Ability to take annotate some files, can of double usage with org-capture.
  ;; Still, I keep that keyboard shortcut here.
  ;; (evil-leader/set-key "oa" 'org-annotate-file)
  (setq org-annotate-file-storage-file "~/Documents/roam/annotations.org")

  ;; ** Org colums
  ;; Can be nice sometime to have that column view
  ;; give a felling of Excel view
  (setq org-columns-default-format
        "%TODO %3PRIORITY %40ITEM(Task) %17Effort(Estimated Effort){:} %CLOCKSUM %8TAGS(TAG)")

  ;; Org Babel
  (org-babel-do-load-languages
   'org-babel-load-languages
   '(;; other Babel languages
     (shell . t)
     ;;(http . t) ; require ob-http
     (clojure . t)
     (haskell . t)
     (plantuml . t) ;; UML graphs
     (gnuplot . t)))
  (setq org-plantuml-jar-path "~/bin/plantuml.jar")

  (defun get-image-width (fname)
    "Returns the min of image width and window width, unless :width
is defined in an attr_org line."
    (let* ((link (save-match-data (org-element-context)))
           (paragraph (let ((e link))
                        (while (and (setq e (org-element-property
                                             :parent e))
                                    (not (eq (org-element-type e)
                                             'paragraph))))
                        e))
           (attr_org (org-element-property :attr_org paragraph))
           (pwidth (plist-get
                    (org-export-read-attribute :attr_org  paragraph) :width))
           (width (when pwidth (string-to-number pwidth)))
           open
           img-buf)

      (unless width
        (setq open (find-buffer-visiting fname)
              img-buf (or open (find-file-noselect fname))
              width (min (window-width nil :pixels)
                         (car (image-size (with-current-buffer img-buf (image-get-display-property)) :pixels))))

        (unless open (kill-buffer img-buf)))
      width))

  (defun around-image-display (orig-fun file width)
    (apply orig-fun (list file (get-image-width file))))

  (advice-add 'org--create-inline-image :around #'around-image-display)
)

(require 'org-tempo) ; for <s TAB to insert code block

;; *** Refile mapped to SPC y o r
;;(map! :leader :desc "org-refile" "y o r" #'org-refile)
;;(map! :leader "y o c" #'org-columns)
(rune/leader-keys
  "yor" #'org-refile
  "yoc" #'org-columns
  "X" #'org-capture
  ;X ;; capture a new task, write a description, the n C-c C-c, save that in tracker.org
  ;mco ;; stop clock on that task, if you capture a new time tracking tasks you don't need to clock-out
  "mco" #'org-clock-out
  ;no;; jump to current time tracked tasks
  "no" #'org-clock-goto
  ;q ;;add/remove tags to that task
  "yt" #'org-agenda-set-tags
  )

(use-package org-mime
  :ensure t)

(use-package org-download
  :ensure t)
(use-package ob-async
  :ensure t
  :config
  ;; 2022-10-22 cperl: A workaround for :async not working
  ;; sometimes as described at
  ;; https://github.com/astahlman/ob-async/issues/75
  (defun no-hide-overlays (orig-fun &rest args)
    (setq org-babel-hide-result-overlays nil))
  (advice-add 'ob-async-org-babel-execute-src-block :before #'no-hide-overlays))

(use-package org-super-agenda
  :ensure t
  :after org-agenda
  :custom (org-super-agenda-groups
           '( ;; Each group has an implicit boolean OR operator between its selectors.
             (:name "Overdue" :deadline past :order 0)
             (:name "Evening Habits" :and (:habit t :tag "evening") :order 8)
             (:name "Habits" :habit t :order 6)
             (:name "Today" ;; Optionally specify section name
              :time-grid t  ;; Items that appear on the time grid (scheduled/deadline with time)
              :order 3)     ;; capture the today first but show it in order 3
             (:name "Low Priority" :priority "C" :tag "maybe" :order 7)
             (:name "Due Today" :deadline today :order 1)
             (:name "Important"
              :and (:priority "A" :not (:todo ("DONE" "CANCELED")))
              :order 2)
             (:name "Due Soon" :deadline future :order 4)
             (:name "Todo" :not (:habit t) :order 5)
             (:name "Waiting" :todo ("WAITING" "HOLD") :order 9)))
  :config
  (setq org-super-agenda-header-map nil)
  (org-super-agenda-mode t))

(use-package ol-notmuch :ensure t)

(use-package org-contrib :ensure t)
(require 'org-collector)

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

(use-package pdf-tools :ensure t) ;; required for org-noter
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

;;;;;; Actually start using templates
;;(setq org-capture-templates
;;  '(("m" "Email Workflow")
;;    ("mf" "Follow Up" entry (file+olp "~/Documents/roam/Mail.org" "Follow Up")
;;     "* TODO Follow up with %:fromname on %:subject\nSCHEDULED:%t\n%a\n%i" :immediate-finish t)
;;    ("mr" "Read Later" entry (file+olp "~/Documents/roam/Mail.org" "Read Later")
;;     "* TODO Read %:subject\nSCHEDULED:%t\n%a\n\n%i" :immediate-finish t)
;;   ))
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

(use-package cmake-mode :ensure t)

(use-package all-the-icons :ensure t)

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

(use-package nix-mode
  :ensure t
	:mode "\\.nix\\'")

(use-package yaml-mode
  :ensure t)

(use-package shrface
  :ensure t
  :defer t
  :config
  (shrface-basic)
  (shrface-trial)
  (shrface-default-keybindings) ; setup default keybindings
  (setq shrface-href-versatile t))

(use-package eww
  :defer t
  :init
  (add-hook 'eww-after-render-hook #'shrface-mode)
  :config
  (require 'shrface))

(use-package request :ensure t)

(defun request-url-as-org (url)
  (interactive "sRequest url: ")
  (require 'shrface)
  (require 'request)
  (request url
    :parser 'buffer-string
    :headers '(("User-Agent" . "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.101 Safari/537.36"))
    :sync nil
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (let ((shrface-request-url url))
                  (shrface-html-export-as-org data))))))

(use-package denote
  :ensure t
  :config
  (setq
   denote-directory (expand-file-name "~/Documents/denotes/")
   denote-known-keywords '("project" "testing" "emacs" "denote")
   denote-file-type nil ;; default Org
   )
  (add-hook 'dired-mode-hook #'denote-dired-mode)
  (setq denote-infer-keywords t)
  (setq denote-sort-keywords t)
  (setq denote-file-type nil) ; Org is the default, set others here
  (setq denote-prompts '(title keywords))
  (setq denote-excluded-directories-regexp nil)
  (setq denote-excluded-keywords-regexp nil)

  ;; Pick dates, where relevant, with Org's advanced interface:
  (setq denote-date-prompt-use-org-read-date t)


  ;; Read this manual for how to specify `denote-templates'.  We do not
  ;; include an example here to avoid potential confusion.
  (setq denote-templates
      '((report . "* Some heading\n\n* Another heading")
        (project . "* Goals

* Tasks

** TODO add initial taks

* Dates

")
        ;(project . '(concat "* Goals"
        ;                 "\n\n%?\n\n"
        ;                 "* Tasks"
        ;                 "\n"
        ;                 "** TODO add initial tasks"
        ;                 "\n\n"
        ;                 "* Dates"
        ;                 "\n\n"
        ;                 )
        ;         )
        ))

;;;;  (org-roam-capture-templates
;;;;   '(("d" "default" plain
;;;;      "%?"
;;;;      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
;;;;      :unnarrowed t)
;;;;     ("p" "project" plain "* Goals\n\n%?\n\n* Tasks\n\n** TODO Add initial tasks\n\n* Dates\n\n"
;;;;      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+filetags: Project")
;;;;      :unnarrowed t)
;;;;     ("b" "book notes" plain (file "~/Documents/roam/templates/BookNoteTemplate.org")
;;;;      :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
;;;;       :unnarrowed t)
;;;;     ))
;;(defun my/org-roam-capture-inbox ()
;;  (interactive)
;;  (org-roam-capture- :node (org-roam-node-create)
;;                     :templates '(("i" "inbox" plain "* %?"
;;                                   :if-new (file+head "inbox.org" "#+title: Inbox\n")))))
;;
;;(defun my/org-roam-capture-task ()
;;  (interactive)
;;  ;; Add the project file to the agenda after capture is finished
;;  (add-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)
;;
;;  ;; Capture the new task, creating the project file if necessary
;;  (org-roam-capture- :node (org-roam-node-read
;;                            nil
;;                            (my/org-roam-filter-by-tag "Project"))
;;                     :templates '(("p" "project" plain "** TODO %?"
;;                                   :if-new (file+head+olp "%<%Y%m%d%H%M%S>-${slug}.org"
;;                                                          "#+title: ${title}\n#+category: ${title}\n#+filetags: Project"
;;                                                          ("Tasks"))))))



  ;; We allow multi-word keywords by default.  The author's personal
  ;; preference is for single-word keywords for a more rigid workflow.
  (setq denote-allow-multi-word-keywords t)

  (setq denote-date-format nil) ; read doc string

  ;; By default, we do not show the context of links.  We just display
  ;; file names.  This provides a more informative view.
  (setq denote-backlinks-show-context t)

  ;; Also see `denote-link-backlinks-display-buffer-action' which is a bit
  ;; advanced.

  ;; If you use Markdown or plain text files (Org renders links as buttons
  ;; right away)
  (add-hook 'find-file-hook #'denote-link-buttonize-buffer)

  ;; We use different ways to specify a path for demo purposes.
  (setq denote-dired-directories
        (list denote-directory
              (thread-last denote-directory (expand-file-name "attachments"))
              (expand-file-name "~/Documents/books")))

  ;; Generic (great if you rename files Denote-style in lots of places):
  ;; (add-hook 'dired-mode-hook #'denote-dired-mode)
  ;;
  ;; OR if only want it in `denote-dired-directories':
  (add-hook 'dired-mode-hook #'denote-dired-mode-in-directories)

  ;; Here is a custom, user-level command from one of the examples we
  ;; showed in this manual.  We define it here and add it to a key binding
  ;; below.
  (defun my-denote-journal ()
    "Create an entry tagged 'journal', while prompting for a title."
    (interactive)
    (denote
     (denote-title-prompt)
     '("journal")))

  ;; Denote DOES NOT define any key bindings.  This is for the user to
  ;; decide.  For example:
  :bind
  (:map global-map
    ("C-c n j" . my-denote-journal) ; our custom command
    ("C-c n n" . denote)
    ("C-c n N" . denote-type)
    ("C-c n d" . denote-date)
    ;("C-c n z" . denote-signature) ; "zettelkasten" mnemonic
    ("C-c n s" . denote-subdirectory)
    ("C-c n t" . denote-template)
    ;; If you intend to use Denote with a variety of file types, it is
    ;; easier to bind the link-related commands to the `global-map', as
    ;; shown here.  Otherwise follow the same pattern for `org-mode-map',
    ;; `markdown-mode-map', and/or `text-mode-map'.
    ("C-c n i" . denote-link) ; "insert" mnemonic
    ("C-c n I" . denote-link-add-links)
    ("C-c n b" . denote-link-backlinks)
    ("C-c n f f" . denote-link-find-file)
    ("C-c n f b" . denote-link-find-backlink)
    ;; Note that `denote-rename-file' can work from any context, not just
    ;; Dired bufffers.  That is why we bind it here to the `global-map'.
    ("C-c n r" . denote-rename-file)
    ("C-c n R" . denote-rename-file-using-front-matter)

  ;; Key bindings specifically for Dired.
   :map dired-mode-map
    ("C-c C-d C-i" . denote-link-dired-marked-notes)
    ("C-c C-d C-r" . denote-dired-rename-marked-files)
    ("C-c C-d C-R" . denote-dired-rename-marked-files-using-front-matter))
  )

(use-package citar
  :ensure t
  :custom
  (citar-bibliography '("~/Documents/denotes/references.bib"))
;;  (org-cite-global-bibliography '("~/Documents/denotes/references.bib"))
;;  (org-cite-insert-processor 'citar)
;;  (org-cite-follow-processor 'citar)
;;  (org-cite-activate-processor 'citar)
;;  (citar-bibliography org-cite-global-bibliography)
;;  ;; optional: org-cite-insert is also bound to C-c C-x C-@
;;  :bind
;;  (:map org-mode-map :package org ("C-c b" . #'org-cite-insert))
)

;; https://github.com/pprevos/citar-denote
(use-package citar-denote
  :ensure t
  :config
  (citar-denote-mode)
  :custom
  (citar-open-always-create-notes t)
  :bind
  ("C-c d c c" . citar-create-note)
  ("C-c d c o" . citar-denote-open-note)
  ("C-c d c d" . citar-denote-dwim)
  ("C-c d c a" . citar-denote-add-citekey)
  ("C-c d c k" . citar-denote-remove-citekey)
  ("C-c d c e" . citar-denote-open-reference-entry)
  ("C-c d c r" . citar-denote-find-reference)
  ("C-c d c f" . citar-denote-find-citation)
  ("C-c d c n" . citar-denote-cite-nocite)
  ("C-c d c m" . citar-denote-reference-nocite)
  )
