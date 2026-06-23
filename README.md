<div align="center">

<h1>&#9883; UnitaryLab CLI User Manual</h1>

<p>
  <strong>A practical user manual for the UnitaryLab local command-line interface.</strong><br/>
  <strong>一个面向 UnitaryLab 本地命令行工具的完整使用指南。</strong>
</p>

<p>
  <img src="https://img.shields.io/badge/UnitaryLab-CLI-7c3aed?style=flat-square" alt="UnitaryLab CLI"/>
  <img src="https://img.shields.io/badge/Docs-Nextra_4-111827?style=flat-square" alt="Nextra 4"/>
  <img src="https://img.shields.io/badge/Next.js-16-000000?style=flat-square&logo=nextdotjs&logoColor=white" alt="Next.js 16"/>
  <img src="https://img.shields.io/badge/Language-English%20%7C%20中文-22c55e?style=flat-square" alt="English and Chinese"/>
  <img src="https://img.shields.io/badge/Manual-CLI_User_Guide-f59e0b?style=flat-square" alt="CLI User Guide"/>
</p>

<p>
  <a href="#english">English</a>
  &middot;
  <a href="#chinese">中文</a>
</p>

</div>

---

<h2 id="english">English</h2>

### What is this?

**UnitaryLab CLI User Manual** is a practical guide for the UnitaryLab local command-line interface. It explains how to install the CLI, configure model providers, sign in, start interactive sessions, manage workspaces, invoke built-in skills, and troubleshoot common issues.

After running `unitarylab` in a terminal, users enter an interactive REPL where the Agent can help with model conversations, file operations, workspace collaboration, quantum algorithms, PDE solving workflows, and other built-in capabilities.

---

### &#10024; Key Features

- **End-to-end onboarding** — Install the CLI, verify the command, configure models, and start the first session.
- **Account workflows** — Login, logout, inspect authentication state, and refresh credentials inside a session.
- **Multi-provider model setup** — Supports DashScope, OpenAI, and custom OpenAI-compatible services.
- **Interactive REPL** — Supports `agent`, `ask`, and `plan` modes with runtime switching.
- **Session and workspace binding** — Restore previous conversations together with their working directories.
- **Skill invocation** — Browse the skill tree with `/skills` and call built-in skills directly.
- **Troubleshooting guide** — Covers CLI startup, authentication, model configuration, command changes, and missing skills.

---

### &#128187; Supported Capabilities

| Capability | Description | Common Commands |
|------------|-------------|-----------------|
| **Start a session** | Enter the local interactive REPL | `unitarylab` / `unitarylab start` |
| **Model switching** | Change the active model during a session | `/model` |
| **Session switching** | Create or restore a conversation session | `/session` |
| **Workspace switching** | Change the working directory bound to the current session | `/cd <path>` |
| **Skill invocation** | Browse or call built-in skills | `/skills` / `/<skill-name>` |
| **Help and diagnostics** | Inspect available commands and current capabilities | `/help` |

---

### &#128640; Installation

**macOS / Linux:**

```bash
curl -fsSL https://assets.unitarylab.com/install.sh | bash
```

**macOS / Linux with Homebrew:**

```bash
brew install unitarylab/unitarylab-agent/unitarylab
```

**Windows PowerShell:**

```powershell
irm https://assets.unitarylab.com/install.ps1 | iex
```

After installation, verify the command:

```bash
unitarylab --help
```

If the output includes subcommands such as `configure`, `login`, `logout`, and `whoami`, the CLI has been added to PATH successfully.

---

### &#128161; Usage

For first-time use, run:

```bash
unitarylab
```

The startup wizard guides you through:

1. Configuring the LLM Provider, API Base, API Key, and model list.
2. Signing in to a UnitaryLab account.
3. Creating or selecting a session.
4. Selecting the current workspace directory.
5. Entering the interactive REPL.

Inside a session, the prompt usually looks like this:

```text
[agent│deepseek-v4-pro] ›
```

Here, `agent` is the current conversation mode, and `deepseek-v4-pro` is the active model.

---

### &#128295; Common Session Commands

| Command | Action |
|---------|--------|
| `/help` | Show available in-session commands |
| `/mode <agent\|ask\|plan>` | Switch conversation mode |
| `/model` | Switch the active model |
| `/models` | View or manage available models |
| `/config` or `/setup` | Reconfigure LLM settings inside the session |
| `/login` | Sign in again without leaving the session |
| `/whoami` | Show current authentication status |
| `/logout` | Clear local authentication state |
| `/session` | Switch or create a session |
| `/sessions` | List recent sessions |
| `/cd <path>` | Change the current workspace directory |
| `/pwd` | Show the current workspace path |
| `/files` | List files in the current workspace |
| `/skills` | Show the available skill tree |
| `/<skill-name>` | Invoke a specific skill directly |

---

### &#128736; Troubleshooting

When something goes wrong, check the basics first:

1. Confirm that the CLI command works:

```bash
unitarylab --help
```

2. Confirm that the authentication state is valid:

```bash
unitarylab whoami
```

3. Recheck model configuration:

```bash
unitarylab configure
```

4. Inspect in-session help:

```text
/help
```

5. Describe the issue to the Agent inside the session and let it inspect the current environment when tools are available.

---

### &#128221; Who is it for?

- Developers who prefer terminal-based AI conversations, file collaboration, and project assistance.
- Researchers who need local conversation history and workspace continuity.
- Engineers who want to embed UnitaryLab Agent into scripts, tools, or local workflows.
- Users working with quantum computing, PDE solving, algorithm demonstrations, and CLI-based workflows.

---

<h2 id="chinese">中文</h2>

### 这是什么？

**UnitaryLab CLI 用户手册** 是面向 UnitaryLab 本地终端命令行工具的中文使用文档。它覆盖从安装、首次配置、账号登录、交互式对话、会话管理到技能调用与故障排查的完整流程。

用户在终端执行 `unitarylab` 命令后，即可进入交互式对话环境。Agent 能协助用户完成模型对话、文件读写、工作目录协作，并调用量子算法、PDE 求解等内置技能。

---

### &#10024; 核心特性

- **完整启动流程** — 从安装 CLI、验证命令、配置模型到首次进入会话。
- **账号体系说明** — 覆盖登录、登出、查看登录态，以及会话内账号命令。
- **多模型配置** — 支持 DashScope、OpenAI 与任意 OpenAI 兼容服务。
- **交互式 REPL** — 支持 `agent`、`ask`、`plan` 三种对话模式，以及运行时切换。
- **会话与工作目录绑定** — 支持恢复历史会话，并自动恢复对应工作目录。
- **技能调用体系** — 可通过 `/skills` 查看技能树，并用 `/<技能名>` 直接调用内置能力。
- **排障路径清晰** — 提供 CLI、登录态、模型配置、命令变化、技能缺失等常见问题排查流程。

---

### &#128187; 支持能力

| 能力 | 说明 | 常用命令 |
|------|------|----------|
| **启动会话** | 进入本地交互式对话环境 | `unitarylab` / `unitarylab start` |
| **模式切换** | 在 `agent`、`ask`、`plan` 间切换 | `/mode <agent\|ask\|plan>` |
| **模型切换** | 在当前会话中切换可用模型 | `/model` |
| **会话切换** | 新建或恢复历史会话 | `/session` |
| **工作目录切换** | 切换当前会话绑定的工作目录 | `/cd <path>` |
| **技能调用** | 查看或调用内置技能 | `/skills` / `/<技能名>` |
| **帮助与排障** | 查看命令帮助与当前能力 | `/help` |

---

### &#128640; 安装 CLI

**macOS / Linux：**

```bash
curl -fsSL https://assets.unitarylab.com/install.sh | bash
```

**macOS / Linux（Homebrew）：**

```bash
brew install unitarylab/unitarylab-agent/unitarylab
```

**Windows（PowerShell）：**

```powershell
irm https://assets.unitarylab.com/install.ps1 | iex
```

安装完成后执行：

```bash
unitarylab --help
```

如果输出中包含 `configure`、`login`、`logout`、`whoami` 等子命令，说明 CLI 已正确加入 PATH。

---

### &#128161; 使用方法

首次使用时，直接执行：

```bash
unitarylab
```

CLI 会根据当前环境自动引导用户完成：

1. 配置 LLM Provider、API Base、API Key 与模型列表。
2. 登录 UnitaryLab 账号。
3. 选择或创建会话。
4. 选择当前工作目录。
5. 进入交互式对话环境。

进入会话后，提示符通常形如：

```text
[agent│deepseek-v4-pro] ›
```

其中 `agent` 表示当前对话模式，`deepseek-v4-pro` 表示当前使用的模型。

---

### &#128295; 常用会话命令

| 命令 | 作用 |
|------|------|
| `/help` | 查看会话内可用命令 |
| `/mode <agent\|ask\|plan>` | 切换对话模式 |
| `/model` | 切换当前模型 |
| `/models` | 查看或维护可用模型列表 |
| `/config` 或 `/setup` | 在会话中重新配置 LLM |
| `/login` | 在会话中重新登录 |
| `/whoami` | 查看当前登录态 |
| `/logout` | 清空本地登录态 |
| `/session` | 切换或新建会话 |
| `/sessions` | 查看最近会话 |
| `/cd <path>` | 切换当前工作目录 |
| `/pwd` | 查看当前工作目录 |
| `/files` | 查看当前工作目录文件 |
| `/skills` | 查看可用技能目录树 |
| `/<技能名>` | 直接调用指定技能 |

---

### &#128736; 排障建议

遇到异常时，建议按以下顺序检查：

1. 确认 CLI 命令可用：

```bash
unitarylab --help
```

2. 确认登录态有效：

```bash
unitarylab whoami
```

3. 重新检查模型配置：

```bash
unitarylab configure
```

4. 在会话中查看帮助：

```text
/help
```

5. 向 Agent 描述当前现象，让 Agent 基于当前环境进行自检。

---

### &#128221; 适用人群

- 希望在终端中完成日常 AI 对话、文件协作与项目辅助的开发者。
- 需要在本地保留对话历史与工作目录结构的研究人员。
- 希望将 UnitaryLab Agent 嵌入脚本、工具链或本地工作流的工程师。
- 对量子计算、PDE 求解、算法演示和 CLI 工具有需求的用户。

---

## License

This manual describes the UnitaryLab CLI documentation content. Please refer to the parent repository for project-level license and distribution terms.
