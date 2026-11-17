# 本机开发约定

这是一台 Apple Silicon Mac，使用 zsh、Homebrew 和 chezmoi。以下是本机默认做法；进入具体项目后，优先采用该仓库的 `AGENTS.md`、锁文件和 CI 命令。默认用中文沟通，命令、路径和报错保留原文。

## 定位项目

- 接手续做的 Git 任务时，在目标仓库运行 `git handoff`，一次确认工作树、分支、HEAD、提交作者和未提交改动。需要核对目标仓库时用 `git remote -v`。如果缺少该助手，用 `git rev-parse --show-toplevel` 和 `git status --short --branch`。
- 交互终端中，`ws` 进入 `~/Workspace`。其下 `w1` 到 `w5` 依次对应 `projects`（正式项目）、`lab`（实验）、`data`（数据）、`archive`（归档）、`vault`（私有文件，权限 `700`）。自动化命令直接使用路径，例如 `git -C "$HOME/Workspace/projects/项目名" status`。搜索限定在当前项目；涉及私有文件时只处理用户指定的路径。
- 维护个人 dotfiles 时用 `git -C "$(chezmoi source-path)" rev-parse --show-toplevel` 找到仓库根。本机仓库在 `~/.local/share/chezmoi`，托管源文件在其 `home/` 下，远端为 `iwnbha/dotfiles`。可用 `chezmoi source-path ~/.config/ghostty/config` 定位 Ghostty 的源文件。改完用 `chezmoi diff -- <目标路径>` 预览；任务包含本机部署时，用 `chezmoi apply -- <目标路径>` 定向应用。此机 14 英寸内屏已选定 `MonoLisaCode` 17.5 pt。

## 选择工具和验证命令

| 项目线索 | 本机做法 |
| --- | --- |
| Python，有 `uv.lock` | 从项目根运行 `uv run --locked` 加项目声明的命令，例如已配置 pytest 的项目用 `uv run --locked pytest`。 |
| Rust，有 `Cargo.toml` | 编译器由 rustup 管理。沿用项目 toolchain 和 features，先运行相关的 `cargo test`；已有 `Cargo.lock` 时可加 `--locked`。 |
| C/C++，有 `CMakePresets.json` | 先用 `cmake --list-presets=all` 查看已有配置，按项目的 workflow 或 build/test preset 验证。此机已有 CMake、Ninja 和 Homebrew LLVM。 |
| Go、Zig、Node.js | Go 模块按改动运行 `go test`，Zig 项目有 test 步骤时用 `zig build test`；Node.js 按 `packageManager`、锁文件和 `package.json` scripts 选择命令。 |

定位工具问题先查 `command -v <工具>` 和 `brew --prefix`（本机为 `/opt/homebrew`）。在非交互 Shell 做 dotfiles 环境诊断时，可直接运行 `bash "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/scripts/doctor.sh"`，对应终端里的 `devdoctor`。改动验证优先选能复现问题的最小测试，再按仓库要求扩大范围。

本机运行 CodeLLDB 如果报 `could not find 'debugserver'`，Apple Command Line Tools 提供的可执行文件在 `/Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.framework/Versions/A/Resources/debugserver`。用 `test -x` 核实后，可仅为该调试命令设置 `LLDB_DEBUGSERVER_PATH` 为此路径。

## Git 签名和 CI

- 个人 GitHub 账户为 `iwnbha`；工作项目使用各自的作者和远端配置。个人提交由 Proton Pass SSH Agent 签名，签名公钥为 `~/.ssh/keys/git_signing.pub`。签名失败时，先用 `git config --show-origin --get user.signingkey` 查实际配置，再用 `SSH_AUTH_SOCK="$HOME/.ssh/proton-pass-ssh-agent.sock" ssh-add -l` 查 Agent 提供的指纹。需要解锁时由用户在 Proton Pass 桌面端完成。提交后用 `git verify-commit HEAD` 验签。
- 排查 GitHub Actions 时，先用 `gh run list --commit "$(git rev-parse HEAD)"` 找到本次提交的运行，再用 `gh run view <运行ID> --log-failed` 读取失败步骤。交付要求 CI 通过时，用 `gh run watch <运行ID> --exit-status` 跟到结束，并在回复中给出结果链接。
