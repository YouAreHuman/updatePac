#!/usr/bin/env bash

checkFile="$1"
# 将生成的新文件从 cfw 复制回仓库根目录 (或者你希望存放的位置)
# 假设你要覆盖根目录下的 "${checkFile}"
[ -f cfw/"${checkFile}" ] && cp cfw/"${checkFile}" ./"${checkFile}"
# 方法：检查 git status 是否有输出。
# git status --porcelain 会列出所有变更（包括新文件 M, A, D 等）。
# 如果没有任何输出，说明真的没变化。
# 如果有输出（例如 ?? "${checkFile}" 表示新文件），说明有变化。
# 初始化标记变量
HAS_CHANGES=false


# --- 第一步：检查已跟踪文件的内容差异 ---
# 如果文件已存在且被修改，git diff 会返回非零 (有差异)
# ! git diff --quiet 返回 true 表示有差异
if ! git diff --quiet HEAD -- "${checkFile}"; then
  echo "🔄 检测到 [内容修改]: "${checkFile}" 内容已更新"
  HAS_CHANGES=true
fi

# --- 第二步：检查是否为新文件 (未跟踪) ---
# 如果文件是新的 (Untracked)，git diff 上面那步会跳过，但这步能抓到
# git status --porcelain 输出非空表示有状态变化 (如 ?? "${checkFile}")
CHANGES_STATUS=$(git status --porcelain -- "${checkFile}")
if [ -n "$CHANGES_STATUS" ]; then
  # 避免重复打印，如果是新文件，上面 diff 没抓到，这里才打印
  if [ "$HAS_CHANGES" = false ]; then
    echo "🔄 检测到 [新文件]: "${checkFile}" 是新创建的"
  else
    # 如果上面已经打印了内容修改，这里可以补充说明，或者忽略
    echo "ℹ️ 同时检测到文件状态变化 (可能是新文件追踪或权限变动)"
  fi
  HAS_CHANGES=true
fi

# --- 第三步：根据标记执行操作 ---
if [ "$HAS_CHANGES" = true ]; then
  echo "🚀 准备提交并推送..."
 
  git add "${checkFile}"
  git commit -m "chore: auto update ${checkFile} nodes $(date '+%Y-%m-%d %H:%M:%S') UTC"
 
  # 推送到当前分支
  # git push origin HEAD:master
  echo "$checkFile" >> ready.txt
 
  # echo "✅ 推送成功！"
  echo "✅ ${checkFile}添加成功！"
else
  echo "⏭️ 无任何变化 (文件未修改且不是新文件)，跳过提交。"
fi

