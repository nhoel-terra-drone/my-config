;;; init.el --- minimal, tidy Emacs config for C/C++ & Rust + LSP

;; ---------------- Screen adjustment ----------------
;; Start Emacs Maximized
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Set default font size to 14pt (140)
(set-face-attribute 'default nil :height 140)

;; ---------------- gptel setup, API key definition----------------
(use-package gptel
  :ensure t
  :config
  (setq gptel-model 'gemini-2.5-flash)

  ;; System message configuration
  (setq gptel--system-message "You are a senior programmer, master of C++ and Python in the field of autonomous driving and robotics. Respond in detail and assume that I am a beginner C++ programmer.")

;  (setq gptel--system-message "You are a senior programmer, master of C++ and Python in the field of autonomous driving and robotics. Respond in detail and assume that I am a beginner C++ programmer but do not provide internal reasoning, thinking blocks, or self-explanations.")

  (setq gptel-backend
        (gptel-make-gemini "Gemini"
          :key (getenv "GEMINI_API_KEY")
          :stream t)))

(add-hook 'gptel-mode-hook
          (lambda ()
            (setq-local gptel-model 'gemini-2.5-flash)))

(add-hook 'gptel-mode-hook
          (lambda ()
            (setq-local gptel-backend gptel-backend)))

(setq gptel-model-fallbacks
      '(("gemini-2.5-flash"      . "gemini-2.5-flash-lite")
        ("gemini-2.5-flash-lite" . "gemini-2.0-flash")))

;; ---------------- gptel keymap ----------------
(define-prefix-command 'my/gptel-map)
(global-set-key (kbd "C-c g") 'my/gptel-map)

;(global-set-key (kbd "C-c RET") 'gptel-send) ;; Send the current prompt
(define-key my/gptel-map (kbd "s") #'gptel-send)        ;; Send prompt / region
(define-key my/gptel-map (kbd "g") #'gptel)             ;; Open gptel buffer
(define-key my/gptel-map (kbd "k") #'gptel-abort)       ;; Abort streaming
(define-key my/gptel-map (kbd "c") #'gptel-clear-buffer) ;; Clear conversation
(define-key my/gptel-map (kbd "n") #'rename-buffer)     ;; Rename buffer

;; ---------------- UI / quality of life ----------------
(global-set-key (kbd "<C-up>") 'shrink-window)
(global-set-key (kbd "<C-down>") 'enlarge-window)
(global-set-key (kbd "<C-left>") 'shrink-window-horizontally)
(global-set-key (kbd "<C-right>") 'enlarge-window-horizontally)
(global-set-key (kbd "<C-right>") 'enlarge-window-horizontally)
(scroll-bar-mode -1)       ; hide scroll bar
(tool-bar-mode -1)         ; hide tool bar
(electric-pair-mode 1)     ; auto insert matching parens/brackets
(show-paren-mode 1)        ; highlight matching paren
(delete-selection-mode 1)  ; typing replaces active selection
(setq visible-bell t)      ; no beeps
(load-theme 'wombat t)

(when (version<= "26.0.50" emacs-version)
  (global-display-line-numbers-mode))

;; Ido (lightweight buffer/file switching)
(setq ido-everywhere t
      ido-enable-flex-matching t)
(ido-mode 1)

;; ---------------- Keybindings ----------------
(global-set-key (kbd "C-;") (kbd "<RET>"))                  ; C-; => RET
(global-set-key (kbd "C-:") #'delete-backward-char)         ; C-: => backspace
(global-set-key (kbd "M-:") #'backward-kill-word)           ; M-: => delete word
(global-set-key (kbd "M-]") #'eval-expression)              ; M-: => delete word
(global-set-key (kbd "C-.") #'ido-switch-buffer)            ; switch buffer
(global-set-key (kbd "C-,") #'other-window)                 ; switch window
(global-set-key (kbd "C-c c") #'recompile)                  ; quick rebuild

;; ---------------- Forward to word ----------------
(require 'misc)
(global-set-key (kbd "M-f") #'forward-to-word)


;; ---------------- copy-sexp-at-point ----------------
(defun copy-sexp-at-point ()
  "Copy the s-expression at point to the kill ring without moving the cursor."
  (interactive)
  (save-excursion
    (let ((start (point)))
      (forward-sexp)
      (copy-region-as-kill start (point))
      (message "S-exp copied to kill ring"))))

(global-set-key (kbd "C-0") #'copy-sexp-at-point)
(global-set-key (kbd "C-9") #'dabbrev-expand)        ; C-9 simple completion

;; ---------------- Indentation / tabs ----------------
(setq-default tab-width 2
              indent-tabs-mode nil) ; use spaces, not hard tabs
(setq tab-stop-list (number-sequence 2 200 2))
(setq indent-line-function 'insert-tab)
(setq c-default-style "linux"
      c-basic-offset 2)
(setq lsp-enable-on-type-formatting nil)

;; ---------------- Packages / use-package -------------
(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")
        ("org"   . "https://orgmode.org/elpa/")))
(unless package--initialized (package-initialize))
(unless package-archive-contents (package-refresh-contents))
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(eval-when-compile (require 'use-package))
(setq use-package-always-ensure t)

;; ---------------- Magit -------------
(global-set-key (kbd "C-x g") 'magit-status)
(use-package magit
  :ensure t
  :bind (("C-x g" . magit-status)))

;; ---------------- Perf knobs for LSP ----------------
(setq gc-cons-threshold       (* 100 1024 1024)  ; 100MB GC threshold
      read-process-output-max (* 1 1024 1024))   ; 1MB from language servers

;; ---------------- Company (completion UI) ----------
(use-package company
  :hook ((c-mode . company-mode)
         (c++-mode . company-mode)
         (rustic-mode . company-mode))
  :custom
  (company-idle-delay 0.0)
  (company-minimum-prefix-length 1))

;; ---------------- Snippets (for LSP completions) ---
(use-package yasnippet
  :config (yas-global-mode 1))

;; ---------------- LSP core (clangd & rust-analyzer) -
(use-package lsp-mode
  :commands lsp
  :hook ((c-mode . lsp)
         (c++-mode . lsp)
         (rustic-mode . lsp)
         ;; Emacs 29 tree-sitter modes (if present):
         (c-ts-mode . lsp)
         (c++-ts-mode . lsp))
  :init
  (setq lsp-completion-provider :capf)        ; feed completions to company
  :custom
  ;; quiet signatures; keep diagnostics simple
  (lsp-signature-auto-activate nil)
  (lsp-signature-render-documentation nil)
  (lsp-diagnostics-provider :auto)
  ;; clangd setup
  (lsp-clients-clangd-executable "clangd")
  (lsp-clients-clangd-args
   '("--background-index"
     "--clang-tidy"
     "--completion-style=detailed"
     "--header-insertion=never"
     "--compile-commands-dir=build"
     "--query-driver=/usr/bin/g++,/usr/bin/c++"))
  ;; If your compile_commands.json lives in ./build/, uncomment:
  ;; (lsp-clients-clangd-args
  ;;  '("--background-index" "--clang-tidy"
  ;;  "--completion-style=detailed" "--header-insertion=never"
  ;;  "--query-driver=/usr/bin/g++"
  ;;  "--compile-commands-dir=build"))
  )

(with-eval-after-load 'lsp-clangd
  (setq lsp-clients-clangd-executable "clangd")
  (setq lsp-clients-clangd-args
        '("--background-index"
          "--clang-tidy"
          "--completion-style=detailed"
          "--header-insertion=never"
          "--compile-commands-dir=build"
          "--query-driver=/usr/bin/g++,/usr/bin/c++")))

;; bulletproff wrapper
(require 'lsp-clangd)
(setq lsp-clients-clangd-executable (expand-file-name "~/bin/clangd-wrapper.sh"))
(setq lsp-clients-clangd-args nil)


;; Optional UI sugar for LSP (kept minimal/off)
(use-package lsp-ui
  :commands lsp-ui-mode
  :custom
  (lsp-ui-doc-enable nil)
  (lsp-ui-sideline-enable nil))

;; ---------------- Rust ------------------------------
(use-package rustic
  :mode ("\\.rs\\'" . rustic-mode)
  :config
  ;; small QoL defaults
  (setq rustic-format-on-save t)
  ;; lsp-mode handles rust-analyzer automatically; a couple of nice tweaks:
  (with-eval-after-load 'lsp-mode
    (setq lsp-rust-analyzer-completion-add-call-parenthesis t
          lsp-rust-analyzer-completion-add-call-argument-snippets nil)))

;; ---------------- Flycheck (optional global checks) -
(use-package flycheck
  :init (global-flycheck-mode))

;; ---------------- Compilation buffer behavior -------
(setq compilation-scroll-output t)

;; ---------------- Treat .h as C++ -------------------
(when (fboundp 'c++-ts-mode)
  (add-to-list 'auto-mode-alist
               '("\\.\\(h\\|hh\\|hpp\\|hxx\\|ipp\\|tpp\\)\\'" . c++-ts-mode)))
(unless (fboundp 'c++-ts-mode)
  (add-to-list 'auto-mode-alist
               '("\\.\\(h\\|hh\\|hpp\\|hxx\\|ipp\\|tpp\\)\\'" . c++-mode)))

;; ---------- Python: built-in mode + LSP (pyright) + DAP + venv ----------

(use-package python
  :ensure nil
  :hook (python-mode . lsp-deferred))

;; Tell lsp-mode to use pylsp for Python
(with-eval-after-load 'lsp-mode
  (setq lsp-disabled-clients '(pyls))   ;; disable the old 'pyls'
  (add-to-list 'lsp-enabled-clients 'pylsp))

;; Debugger (DAP) + Python adapter; requires pip install debugpy in venv
(use-package dap-mode
  :after lsp-mode
  :config
  (dap-auto-configure-mode)
  (with-eval-after-load 'dap-mode
    (require 'dap-python))        ;; only after dap-mode is loaded
  ;; If system python is named python3, uncomment:
  ;; (setq dap-python-executable "python3")
  (setq dap-python-debugger 'debugpy))

;; Keep flake8, but ignore specific codes
(with-eval-after-load 'flycheck
  (setq flycheck-flake8-args '("--ignore=D100,D107,F401")))

;; Disable Flycheck for Python (rely on LSP only)
(add-hook 'python-mode-hook (lambda () (flycheck-mode -1)))

;; Virtualenv integration
(use-package pyvenv
  :defer t
  :init (pyvenv-mode 1))

;; Allow all lsp clients
(with-eval-after-load 'lsp-mode
  (setq lsp-enabled-clients nil)      ;; allow all registered clients
  (setq lsp-disabled-clients '(pyls)) ;; optional: disable the *old* pyls only
)

(provide 'init)
;;; init.el ends here
