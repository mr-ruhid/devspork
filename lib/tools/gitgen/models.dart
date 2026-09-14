enum GitDanger { safe, warning, danger }

extension GitDangerX on GitDanger {
  String get labelKey {
    switch (this) {
      case GitDanger.safe:
        return 'gitgen_danger_safe';
      case GitDanger.warning:
        return 'gitgen_danger_warning';
      case GitDanger.danger:
        return 'gitgen_danger_danger';
    }
  }
}

enum GitCategory { undo, branch, remote, stash, advanced, inspect }

extension GitCategoryX on GitCategory {
  String get labelKey {
    switch (this) {
      case GitCategory.undo:
        return 'gitgen_cat_undo';
      case GitCategory.branch:
        return 'gitgen_cat_branch';
      case GitCategory.remote:
        return 'gitgen_cat_remote';
      case GitCategory.stash:
        return 'gitgen_cat_stash';
      case GitCategory.advanced:
        return 'gitgen_cat_advanced';
      case GitCategory.inspect:
        return 'gitgen_cat_inspect';
    }
  }
}

class GitScenario {
  final String id;
  final GitCategory category;
  final GitDanger danger;
  final String titleKey;
  final String descriptionKey;
  final String command;
  final String explanationKey;
  final String? warningKey;
  final List<String> alternatives;

  const GitScenario({
    required this.id,
    required this.category,
    required this.danger,
    required this.titleKey,
    required this.descriptionKey,
    required this.command,
    required this.explanationKey,
    this.warningKey,
    this.alternatives = const <String>[],
  });
}

const List<GitScenario> kGitScenarios = <GitScenario>[
  // ============== UNDO / RESET ==============
  GitScenario(
    id: 'undo_commit_keep',
    category: GitCategory.undo,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_undo_commit_keep_title',
    descriptionKey: 'gitgen_s_undo_commit_keep_desc',
    command: 'git reset --soft HEAD~1',
    explanationKey: 'gitgen_s_undo_commit_keep_expl',
    alternatives: <String>[
      'git reset --soft HEAD~2   # son 2 commit',
    ],
  ),
  GitScenario(
    id: 'undo_commit_discard',
    category: GitCategory.undo,
    danger: GitDanger.danger,
    titleKey: 'gitgen_s_undo_commit_discard_title',
    descriptionKey: 'gitgen_s_undo_commit_discard_desc',
    command: 'git reset --hard HEAD~1',
    explanationKey: 'gitgen_s_undo_commit_discard_expl',
    warningKey: 'gitgen_warn_data_loss',
    alternatives: <String>[
      'git reset --hard HEAD~2   # son 2 commit',
    ],
  ),
  GitScenario(
    id: 'undo_commit_mixed',
    category: GitCategory.undo,
    danger: GitDanger.warning,
    titleKey: 'gitgen_s_undo_commit_mixed_title',
    descriptionKey: 'gitgen_s_undo_commit_mixed_desc',
    command: 'git reset HEAD~1',
    explanationKey: 'gitgen_s_undo_commit_mixed_expl',
  ),
  GitScenario(
    id: 'amend_last',
    category: GitCategory.undo,
    danger: GitDanger.warning,
    titleKey: 'gitgen_s_amend_title',
    descriptionKey: 'gitgen_s_amend_desc',
    command: 'git commit --amend',
    explanationKey: 'gitgen_s_amend_expl',
    warningKey: 'gitgen_warn_pushed',
    alternatives: <String>[
      'git commit --amend --no-edit    # mesajı dəyişmə',
      'git commit --amend -m "new message"',
    ],
  ),
  GitScenario(
    id: 'revert_commit',
    category: GitCategory.undo,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_revert_title',
    descriptionKey: 'gitgen_s_revert_desc',
    command: 'git revert <commit-hash>',
    explanationKey: 'gitgen_s_revert_expl',
    alternatives: <String>[
      'git revert HEAD              # son commit',
      'git revert --no-commit HEAD  # birləşdirmədən',
    ],
  ),
  GitScenario(
    id: 'discard_uncommitted',
    category: GitCategory.undo,
    danger: GitDanger.danger,
    titleKey: 'gitgen_s_discard_title',
    descriptionKey: 'gitgen_s_discard_desc',
    command: 'git checkout -- .',
    explanationKey: 'gitgen_s_discard_expl',
    warningKey: 'gitgen_warn_data_loss',
    alternatives: <String>[
      'git restore .              # yeni sintaksis',
      'git checkout -- file.txt   # tək fayl',
    ],
  ),
  GitScenario(
    id: 'unstage_file',
    category: GitCategory.undo,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_unstage_title',
    descriptionKey: 'gitgen_s_unstage_desc',
    command: 'git restore --staged <file>',
    explanationKey: 'gitgen_s_unstage_expl',
    alternatives: <String>[
      'git reset HEAD <file>      # köhnə sintaksis',
      'git reset HEAD .           # hamısı',
    ],
  ),
  GitScenario(
    id: 'recover_deleted_branch',
    category: GitCategory.undo,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_recover_branch_title',
    descriptionKey: 'gitgen_s_recover_branch_desc',
    command: 'git reflog\ngit checkout -b <branch> <hash>',
    explanationKey: 'gitgen_s_recover_branch_expl',
  ),

  // ============== BRANCH ==============
  GitScenario(
    id: 'create_branch',
    category: GitCategory.branch,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_create_branch_title',
    descriptionKey: 'gitgen_s_create_branch_desc',
    command: 'git checkout -b <branch-name>',
    explanationKey: 'gitgen_s_create_branch_expl',
    alternatives: <String>[
      'git switch -c <branch-name>  # yeni sintaksis',
    ],
  ),
  GitScenario(
    id: 'switch_branch',
    category: GitCategory.branch,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_switch_branch_title',
    descriptionKey: 'gitgen_s_switch_branch_desc',
    command: 'git switch <branch-name>',
    explanationKey: 'gitgen_s_switch_branch_expl',
    alternatives: <String>[
      'git checkout <branch-name>   # köhnə sintaksis',
    ],
  ),
  GitScenario(
    id: 'delete_branch',
    category: GitCategory.branch,
    danger: GitDanger.warning,
    titleKey: 'gitgen_s_delete_branch_title',
    descriptionKey: 'gitgen_s_delete_branch_desc',
    command: 'git branch -d <branch-name>',
    explanationKey: 'gitgen_s_delete_branch_expl',
    alternatives: <String>[
      'git branch -D <branch-name>  # məcburi silmə',
      'git push origin --delete <branch-name>',
    ],
  ),
  GitScenario(
    id: 'rename_branch',
    category: GitCategory.branch,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_rename_branch_title',
    descriptionKey: 'gitgen_s_rename_branch_desc',
    command: 'git branch -m <old-name> <new-name>',
    explanationKey: 'gitgen_s_rename_branch_expl',
  ),
  GitScenario(
    id: 'merge_branch',
    category: GitCategory.branch,
    danger: GitDanger.warning,
    titleKey: 'gitgen_s_merge_title',
    descriptionKey: 'gitgen_s_merge_desc',
    command: 'git checkout main\ngit merge <branch-name>',
    explanationKey: 'gitgen_s_merge_expl',
    alternatives: <String>[
      'git merge --no-ff <branch>   # merge commit',
      'git merge --squash <branch>   # tək commit',
    ],
  ),
  GitScenario(
    id: 'rebase_branch',
    category: GitCategory.branch,
    danger: GitDanger.warning,
    titleKey: 'gitgen_s_rebase_title',
    descriptionKey: 'gitgen_s_rebase_desc',
    command: 'git checkout <feature-branch>\ngit rebase main',
    explanationKey: 'gitgen_s_rebase_expl',
    warningKey: 'gitgen_warn_pushed',
    alternatives: <String>[
      'git rebase -i HEAD~3          # son 3 commit',
    ],
  ),
  GitScenario(
    id: 'squash_commits',
    category: GitCategory.branch,
    danger: GitDanger.warning,
    titleKey: 'gitgen_s_squash_title',
    descriptionKey: 'gitgen_s_squash_desc',
    command: 'git rebase -i HEAD~<n>',
    explanationKey: 'gitgen_s_squash_expl',
    warningKey: 'gitgen_warn_pushed',
    alternatives: <String>[
      '# Editor açılacaq: "pick" → "squash" (və ya "s")',
    ],
  ),
  GitScenario(
    id: 'cherry_pick',
    category: GitCategory.branch,
    danger: GitDanger.warning,
    titleKey: 'gitgen_s_cherry_title',
    descriptionKey: 'gitgen_s_cherry_desc',
    command: 'git cherry-pick <commit-hash>',
    explanationKey: 'gitgen_s_cherry_expl',
    alternatives: <String>[
      'git cherry-pick <hash1> <hash2>',
      'git cherry-pick <hash1>..<hash2>',
    ],
  ),

  // ============== REMOTE ==============
  GitScenario(
    id: 'push_new_branch',
    category: GitCategory.remote,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_push_new_title',
    descriptionKey: 'gitgen_s_push_new_desc',
    command: 'git push -u origin <branch-name>',
    explanationKey: 'gitgen_s_push_new_expl',
  ),
  GitScenario(
    id: 'force_push_safe',
    category: GitCategory.remote,
    danger: GitDanger.warning,
    titleKey: 'gitgen_s_force_push_safe_title',
    descriptionKey: 'gitgen_s_force_push_safe_desc',
    command: 'git push --force-with-lease',
    explanationKey: 'gitgen_s_force_push_safe_expl',
    warningKey: 'gitgen_warn_force_push',
    alternatives: <String>[
      'git push --force          # TƏHLÜKƏLİ, istifadə etmə',
    ],
  ),
  GitScenario(
    id: 'pull_rebase',
    category: GitCategory.remote,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_pull_rebase_title',
    descriptionKey: 'gitgen_s_pull_rebase_desc',
    command: 'git pull --rebase',
    explanationKey: 'gitgen_s_pull_rebase_expl',
  ),
  GitScenario(
    id: 'fetch_all',
    category: GitCategory.remote,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_fetch_all_title',
    descriptionKey: 'gitgen_s_fetch_all_desc',
    command: 'git fetch --all --prune',
    explanationKey: 'gitgen_s_fetch_all_expl',
  ),
  GitScenario(
    id: 'change_remote_url',
    category: GitCategory.remote,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_change_remote_title',
    descriptionKey: 'gitgen_s_change_remote_desc',
    command: 'git remote set-url origin <new-url>',
    explanationKey: 'gitgen_s_change_remote_expl',
  ),
  GitScenario(
    id: 'clone_specific_branch',
    category: GitCategory.remote,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_clone_branch_title',
    descriptionKey: 'gitgen_s_clone_branch_desc',
    command: 'git clone -b <branch> --single-branch <url>',
    explanationKey: 'gitgen_s_clone_branch_expl',
  ),

  // ============== STASH ==============
  GitScenario(
    id: 'stash_save',
    category: GitCategory.stash,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_stash_save_title',
    descriptionKey: 'gitgen_s_stash_save_desc',
    command: 'git stash push -m "message"',
    explanationKey: 'gitgen_s_stash_save_expl',
    alternatives: <String>[
      'git stash push -u          # untracked fayllar da',
      'git stash                  # qısa forma',
    ],
  ),
  GitScenario(
    id: 'stash_list',
    category: GitCategory.stash,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_stash_list_title',
    descriptionKey: 'gitgen_s_stash_list_desc',
    command: 'git stash list',
    explanationKey: 'gitgen_s_stash_list_expl',
  ),
  GitScenario(
    id: 'stash_apply',
    category: GitCategory.stash,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_stash_apply_title',
    descriptionKey: 'gitgen_s_stash_apply_desc',
    command: 'git stash apply stash@{0}',
    explanationKey: 'gitgen_s_stash_apply_expl',
    alternatives: <String>[
      'git stash pop             # apply + sil',
    ],
  ),
  GitScenario(
    id: 'stash_drop',
    category: GitCategory.stash,
    danger: GitDanger.warning,
    titleKey: 'gitgen_s_stash_drop_title',
    descriptionKey: 'gitgen_s_stash_drop_desc',
    command: 'git stash drop stash@{0}',
    explanationKey: 'gitgen_s_stash_drop_expl',
    alternatives: <String>[
      'git stash clear           # hamısını sil',
    ],
  ),

  // ============== INSPECT ==============
  GitScenario(
    id: 'log_pretty',
    category: GitCategory.inspect,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_log_pretty_title',
    descriptionKey: 'gitgen_s_log_pretty_desc',
    command:
    'git log --oneline --graph --decorate --all',
    explanationKey: 'gitgen_s_log_pretty_expl',
  ),
  GitScenario(
    id: 'log_file_history',
    category: GitCategory.inspect,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_log_file_title',
    descriptionKey: 'gitgen_s_log_file_desc',
    command: 'git log --follow -p <file>',
    explanationKey: 'gitgen_s_log_file_expl',
  ),
  GitScenario(
    id: 'blame_file',
    category: GitCategory.inspect,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_blame_title',
    descriptionKey: 'gitgen_s_blame_desc',
    command: 'git blame <file>',
    explanationKey: 'gitgen_s_blame_expl',
  ),
  GitScenario(
    id: 'diff_staged',
    category: GitCategory.inspect,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_diff_staged_title',
    descriptionKey: 'gitgen_s_diff_staged_desc',
    command: 'git diff --staged',
    explanationKey: 'gitgen_s_diff_staged_expl',
    alternatives: <String>[
      'git diff                  # işçi qovluq',
      'git diff HEAD             # hamısı',
    ],
  ),
  GitScenario(
    id: 'show_commit',
    category: GitCategory.inspect,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_show_title',
    descriptionKey: 'gitgen_s_show_desc',
    command: 'git show <commit-hash>',
    explanationKey: 'gitgen_s_show_expl',
  ),
  GitScenario(
    id: 'find_string_history',
    category: GitCategory.inspect,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_pickaxe_title',
    descriptionKey: 'gitgen_s_pickaxe_desc',
    command: 'git log -S "search-string" --oneline',
    explanationKey: 'gitgen_s_pickaxe_expl',
  ),

  // ============== ADVANCED ==============
  GitScenario(
    id: 'remove_untracked',
    category: GitCategory.advanced,
    danger: GitDanger.danger,
    titleKey: 'gitgen_s_clean_title',
    descriptionKey: 'gitgen_s_clean_desc',
    command: 'git clean -fd',
    explanationKey: 'gitgen_s_clean_expl',
    warningKey: 'gitgen_warn_data_loss',
    alternatives: <String>[
      'git clean -nd          # preview (dry-run)',
      'git clean -fdx         # .gitignore da sil',
    ],
  ),
  GitScenario(
    id: 'bisect',
    category: GitCategory.advanced,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_bisect_title',
    descriptionKey: 'gitgen_s_bisect_desc',
    command:
    'git bisect start\ngit bisect bad\ngit bisect good <hash>',
    explanationKey: 'gitgen_s_bisect_expl',
    alternatives: <String>[
      'git bisect reset       # bitirəndə',
    ],
  ),
  GitScenario(
    id: 'submodule_update',
    category: GitCategory.advanced,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_submodule_title',
    descriptionKey: 'gitgen_s_submodule_desc',
    command: 'git submodule update --init --recursive',
    explanationKey: 'gitgen_s_submodule_expl',
  ),
  GitScenario(
    id: 'config_user',
    category: GitCategory.advanced,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_config_title',
    descriptionKey: 'gitgen_s_config_desc',
    command:
    'git config --global user.name "Your Name"\n'
        'git config --global user.email "you@example.com"',
    explanationKey: 'gitgen_s_config_expl',
  ),
  GitScenario(
    id: 'merge_conflict_abort',
    category: GitCategory.advanced,
    danger: GitDanger.warning,
    titleKey: 'gitgen_s_abort_merge_title',
    descriptionKey: 'gitgen_s_abort_merge_desc',
    command: 'git merge --abort',
    explanationKey: 'gitgen_s_abort_merge_expl',
    alternatives: <String>[
      'git rebase --abort',
      'git cherry-pick --abort',
    ],
  ),
  GitScenario(
    id: 'create_tag',
    category: GitCategory.advanced,
    danger: GitDanger.safe,
    titleKey: 'gitgen_s_tag_title',
    descriptionKey: 'gitgen_s_tag_desc',
    command: 'git tag -a v1.0.0 -m "Version 1.0.0"',
    explanationKey: 'gitgen_s_tag_expl',
    alternatives: <String>[
      'git push origin v1.0.0',
      'git push origin --tags',
    ],
  ),
];