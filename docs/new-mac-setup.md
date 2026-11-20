# 新个人 Mac 从零部署

适用于全新的 Apple Silicon Mac 和个人 GitHub 账户。日常浏览器使用 Chrome，密码、通行密钥及个人 SSH 私钥由 Proton Pass 管理。完成后，GitHub SSH 认证和 Git 提交签名使用 Proton Pass 中的个人密钥，新终端会加载工作区快捷方式，Neovim 会加载仓库配色。所有命令都在**新 Mac** 上运行。

## 1. 安装命令行工具和 Homebrew

用个人账户完成开机设置，按 `⌘ Space` 搜索并打开「终端」，运行：

```sh
xcode-select --install
```

在弹窗中确认，等安装完成。打开 [Homebrew 官网](https://brew.sh/)，下载并运行 macOS 的 `.pkg` 安装包。回到终端，运行以下命令，并保留这个窗口直到第 4 步结束：

```sh
eval "$(/opt/homebrew/bin/brew shellenv)"
export XDG_CONFIG_HOME="$HOME/.config"

brew install chezmoi
brew install --cask proton-pass
open -a "Proton Pass"
```

## 2. 准备 Proton Pass 里的个人 SSH 密钥

在桌面应用登录并解锁个人账户。如果保险库里已经有打算用于个人 GitHub 的 SSH 密钥，选中它。如果还没有，可在手机的 Proton Pass 中选择 **+ → Other → SSH Key → Public key → Generate SSH key**，生成 Ed25519 密钥，命名为 `Personal Mac GitHub` 并保存。等该条目同步到 Mac。[Proton SSH Agent 指南](https://proton.me/support/ssh-agent)

在 **Mac 桌面版 Proton Pass → Settings → General → SSH Agent** 勾选 **Use Proton Pass as SSH agent**。首次保存公钥时，在终端运行下面两行。如果提示文件已存在，直接比较下一段的指纹。

```sh
install -d -m 700 ~/.ssh ~/.ssh/keys
(set -C; cat > ~/.ssh/keys/git_signing.pub)
```

当终端等待输入时，回到 Proton Pass，复制该条目的 **Public key**。回终端按 `⌘V` 粘贴，按一次 `Return`，再按 `Ctrl+D` 保存。Ed25519 公钥是一行以 `ssh-ed25519` 开头的文本。私钥留在 Proton Pass 中。

```sh
ssh-keygen -lf ~/.ssh/keys/git_signing.pub
SSH_AUTH_SOCK="$HOME/.ssh/proton-pass-ssh-agent.sock" ssh-add -l
```

**看到第一条命令的 `SHA256:…` 指纹出现在第二条的列表中，再继续。** 如果无法连接，先确认桌面应用已解锁并启用了 SSH Agent。如果列表里有其他指纹，回到所选密钥条目核对公钥。

## 3. 在个人 GitHub 登记公钥

将刚验证过的公钥复制到剪贴板：

```sh
pbcopy < ~/.ssh/keys/git_signing.pub
```

登录个人账户，打开 [GitHub → Settings → SSH and GPG keys](https://github.com/settings/keys)。点击 **New SSH key**，按下表登记同一行公钥。已有相应用途时，只补缺少的那项。[GitHub 公钥登记说明](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

| Key type | Title 示例 | 用途 |
| --- | --- | --- |
| Authentication Key | Personal Mac SSH | 通过 SSH 拉取或推送仓库 |
| Signing Key | Personal Mac Git Signing | 让 GitHub 验证提交签名 |

## 4. 预览并完整部署 dotfiles

```sh
chezmoi init https://github.com/iwnbha/dotfiles
```

按提示填写**个人 Git 姓名**与**已在个人 GitHub 账户验证的邮箱**。先预览，再执行完整部署：

```sh
chezmoi diff --no-pager
```

```sh
chezmoi apply
```

这一步会安装工作站工具（包括 Chrome 和 Proton Pass），部署 Shell、Ghostty、Neovim、Git 与 SSH 配置，并应用 Finder、Dock、键盘和截图等 macOS 偏好。还会写入 Chrome 的 Proton Pass 扩展安装声明；首次启用、登录和密码管理开关按第 6 步完成。如果部署提示 Agent 或公钥缺失，回到第 2 步，确认指纹匹配后重新运行 `chezmoi apply`。成功后**打开一个新的终端窗口**，在新窗口完成下面的检查。[部署范围与维护手册](operations.md#初始化)

## 5. 验证 GitHub、默认签名和日用配置

先确认 GitHub 识别的是你的个人账户：

```sh
ssh -T git@github.com
```

首次连接若询问是否信任主机，先核对 [GitHub 官方主机指纹](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)。认证成功会显示 `Hi 你的用户名! You've successfully authenticated…`。这条 GitHub 探测命令在成功认证时也会以状态码 1 退出。[GitHub 测试说明](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)

接着在临时仓库创建一条普通提交，验证默认签名已经生效：

```sh
check_dir="$(mktemp -d)"
git -C "$check_dir" init -q
git -C "$check_dir" commit --allow-empty -m "Verify personal Mac signing"
git -C "$check_dir" verify-commit HEAD
```

最后一条应显示 `Good "git" signature` 和你的个人邮箱。若 SSH 认证成功但签名失败，按[签名配置排查步骤](operations.md#ssh-与提交签名)检查生效的签名程序和公钥。

`chezmoi apply` 会在 `~/Workspace` 下创建下表中的五个目录，并将 `vault` 的权限设为 `700`。在新终端里用 `w1` 进入项目目录。

```zsh
w1
pwd
nvim
```

`pwd` 应显示以 `/Workspace/projects` 结尾的路径。

| 命令 | 进入的目录 |
| --- | --- |
| `ws` | `~/Workspace` |
| `w1` | `~/Workspace/projects` |
| `w2` | `~/Workspace/lab` |
| `w3` | `~/Workspace/data` |
| `w4` | `~/Workspace/archive` |
| `w5` | `~/Workspace/vault` |

让 Neovim 完成首次插件安装，即可使用仓库配色。个人项目按需 clone 到 `~/Workspace/projects`。

### 验证 Codex 全局说明

macOS 工作站执行第 4 步的 `chezmoi apply` 时会创建 `~/.codex/AGENTS.md`，权限为 `600`。安装 Codex 后，在任意本地项目新开会话即可加载这份说明。项目自己的 `AGENTS.md` 仍可补充或覆盖全局约定。

```sh
chezmoi source-path ~/.codex/AGENTS.md
stat -f '%Sp %N' ~/.codex/AGENTS.md
chezmoi diff -- ~/.codex/AGENTS.md
```

源文件路径应以 `home/private_dot_codex/private_AGENTS.md` 结尾，权限应显示 `-rw-------`。部署内容一致时，最后一条命令没有输出。以后修改全局说明，编辑该源文件，再运行 `chezmoi apply -- ~/.codex/AGENTS.md`。

## 6. 统一使用 Proton Pass 管理密码

### 自动部署与首次确认

macOS `workstation` 的 `chezmoi apply` 自动完成：

| 项目 | 部署结果 |
| --- | --- |
| Chrome、Proton Pass 桌面应用 | 由 Homebrew workstation profile 安装 |
| Proton Pass Chrome 扩展安装声明 | 创建 `~/Library/Application Support/Google/Chrome/External Extensions/ghmbeldphafepmbegfdlkpapadhbakde.json`，更新源为 Chrome Web Store |
| Git 与 SSH | 使用第 2 步准备的 Proton SSH Agent 和公钥，按第 5 步验收 |

扩展声明不包含账户或保险库数据。Chrome 启动后会读取它，但仍需要本人确认启用扩展。账户登录、解锁、扩展内部设置、Chrome 每个配置文件的密码开关和 Apple 自动填充由下面的首次确认步骤完成；`chezmoi apply` 不会代替这些操作，也不导入或删除密码。[Chrome 外部扩展安装机制](https://developer.chrome.com/docs/extensions/how-to/distribute/install-extensions)

1. 打开 Chrome，在 `chrome://extensions` 确认启用 **Proton Pass**，发布者为 **Proton AG**，扩展 ID 为 `ghmbeldphafepmbegfdlkpapadhbakde`。若 Chrome 已在运行，保存工作后退出并重新打开。若未出现安装提示，或此前曾拒绝/移除此扩展，直接从 [Proton Pass 官方商店页面](https://chromewebstore.google.com/detail/proton-pass-free-password/ghmbeldphafepmbegfdlkpapadhbakde) 安装。[Proton 安装说明](https://proton.me/support/pass-setup)
2. 在扩展中登录与桌面应用相同的个人 Proton 账户，确认保险库同步完成，将扩展固定到工具栏。桌面应用已登录不代表 Chrome 扩展已经登录。
3. 打开 **Proton Pass 扩展 → Settings → General**，确认以下开关开启：

   | 开关 | 用途 |
   | --- | --- |
   | Use Proton Pass as your browser's default password manager | 由 Proton 接管浏览器密码保存入口 |
   | Login autofill | 填充登录信息 |
   | Prompt for auto-save | 提示保存或更新密码 |
   | Save passkeys | 将新通行密钥保存到 Proton |
   | Authenticate with passkeys | 使用 Proton 中的通行密钥认证 |

4. 打开 `chrome://password-manager/settings`，确认「提供保存密码和通行密钥」「自动登录」「自动创建通行密钥（Automatically create a passkey to sign in faster）」均关闭。第一项可能显示由 Proton Pass 扩展控制。旧版本没有第三项时，更新 Chrome 后再确认。每个日用 Chrome 配置文件都检查一次。[Chrome 密码设置说明](https://support.google.com/chrome/answer/95606)
5. 在 `chrome://extensions` 停用已安装的 **iCloud Passwords** 及其他密码管理扩展，保留 Proton Pass 作为日用入口。
6. 打开 **系统设置 → 通用 → 自动填充与密码（AutoFill & Passwords）**，关闭 **自动填充密码和通行密钥（AutoFill Passwords and Passkeys）**。macOS 系统钥匙串继续用于系统和应用凭据；这一步不删除 Apple Passwords 中的记录，也不关闭 iCloud 或系统钥匙串。此配置以 Chrome 为日用浏览器；日后使用 Safari 时需另外配置其填充方式。

### 已有记录：先核对，保留旧副本

新 Mac 登录 Google 账户后可能同步回旧记录。先在 Proton 中按网站、用户名和密码逐条核对；完整一致的记录无需重复导入。仅迁入缺失项，密码不同的同名条目先核实，不覆盖已有记录。

确需迁移时，按 [Proton 导入指南](https://proton.me/support/pass-import) 使用 Chrome 导出和 Proton 导入界面，在本机完成系统身份验证。导出的 CSV 是明文，临时放在权限为 `700` 的 `~/Workspace/vault` 下；确认导入和登录成功后删除临时导出文件。不要把 CSV、密码、通行密钥或私钥加入 dotfiles。密码 CSV 不等同于通行密钥迁移，已有通行密钥保留并按各网站支持的方式单独处理。

**Chrome 和 Apple 中的原记录先保留，清理副本另行决定。** 关闭保存或自动登录不会删除旧记录，Chrome 仍可能提供已有密码供填充；保留副本期间不宣称浏览器中已没有凭据。

### 验收

```sh
chrome_pass_manifest="$HOME/Library/Application Support/Google/Chrome/External Extensions/ghmbeldphafepmbegfdlkpapadhbakde.json"
chezmoi diff -- "$chrome_pass_manifest"
cat "$chrome_pass_manifest"
```

第一条应无差异，第二条只显示 Chrome Web Store 更新地址。它只证明安装声明已部署；继续在 `chrome://extensions` 确认扩展已启用并登录，重新打开扩展设置核对开关。打开已有登录记录的网站，确认 Proton 能填充；下次注册或更新密码、创建通行密钥时，确认保存目标是 Proton。最后重做第 5 步的 SSH 和签名检查。

2026-11-20 的本机核对中，4 条 Chrome 密码记录均在 Proton 中存在完整副本，Chrome 原记录保留。这个数量仅作为本次迁移记录，新 Mac 按同步后的实际条目核对。
