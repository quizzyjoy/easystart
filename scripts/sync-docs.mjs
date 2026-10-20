#!/usr/bin/env node
/**
 * sync-docs.mjs —— 把仓根 `教程/` 下的 Markdown 同步进各端 rawfile
 *
 * 用法（在仓根执行）：
 *   node scripts/sync-docs.mjs
 *
 * 做三件事：
 *   1. 复制 `教程/<专题>/<专题>.md` 与同目录 `图片/` 到 product/{entry,entry_pc,entry_tv} 的 rawfile/docs；
 *   2. 生成 `index.json`（id / title / summary / minutes / sections），学习 Tab 目录由它驱动；
 *   3. 校验 md 里引用的图片是否都存在 —— 缺一张就退出码 1，避免应用里裂图。
 *
 * 为什么要这个脚本：教程正文是唯一事实源（人在仓库里写 md），应用只消费副本，
 * 所以"文档更新 → 跑一次脚本 → 应用内同步"，不再手工维护第二份内容。
 */
import { copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const SRC = join(REPO, '教程');
const TARGETS = ['entry', 'entry_pc', 'entry_tv'].map((m) => join(REPO, 'hm_easystart', 'product', m, 'src', 'main', 'resources', 'rawfile', 'docs'));

const IMAGE_EXT = /\.(png|jpe?g|webp|gif|svg)$/i;

/** 递归收集 md 文件。 */
function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    const st = statSync(full);
    if (st.isDirectory()) {
      walk(full, out);
    } else if (name.toLowerCase().endsWith('.md')) {
      out.push(full);
    }
  }
  return out;
}

/** 去掉行内标记，用于摘要。 */
function plain(text) {
  return text
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/!\[[^\]]*\]\([^)]*\)/g, ' ')
    .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/[*_`>#|-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function parseDoc(file) {
  const raw = readFileSync(file, 'utf8');
  const lines = raw.split(/\r?\n/);
  const id = relative(SRC, file).replace(/\\/g, '/').replace(/\.md$/i, '');
  let title = id;
  let summary = '';
  const sections = [];
  for (const line of lines) {
    const h1 = /^#\s+(.*)$/.exec(line);
    if (h1 && title === id) {
      title = h1[1].trim();
      continue;
    }
    const h2 = /^##\s+(.*)$/.exec(line);
    if (h2) {
      sections.push(h2[1].trim());
      continue;
    }
    if (!summary && line.trim().length > 20 && !line.startsWith('!') && !line.startsWith('|') && !line.startsWith('-')) {
      summary = plain(line).slice(0, 60);
    }
  }
  const chars = plain(raw).length;
  return {
    id,
    title,
    summary: summary || '本工程实践记录',
    minutes: Math.max(3, Math.ceil(chars / 600)),
    sections,
    path: `docs/${id}.md`
  };
}

/** 校验 md 内图片引用是否指向真实文件。 */
function checkImages(file, raw) {
  const missing = [];
  const dir = dirname(file);
  // 代码块里的示例不是真实引用，扫描前先剔除
  const scannable = raw.replace(/```[\s\S]*?```/g, '');
  for (const m of scannable.matchAll(/!\[[^\]]*\]\(([^)]+)\)/g)) {
    const ref = m[1].trim();
    if (/^https?:/i.test(ref)) continue;
    const target = join(dir, ref.replace(/\//g, '\\'));
    if (!existsSync(target)) missing.push(ref);
  }
  return missing;
}

/**
 * 把 md 里的相对图片引用改写成库可识别的 `$rawfile("...")`。
 * 仓库里的 md 保持 `图片/x.png`（GitHub 能直接显示），应用副本才转成 rawfile 形式。
 */
function rewriteImages(raw, relDir) {
  return raw.replace(/!\[([^\]]*)\]\((?!https?:)([^)]+)\)/g, (_m, alt, src) => {
    const clean = src.trim().replace(/^\.\//, '');
    return `![${alt}]($rawfile(" docs/${relDir}/${clean}"))`.replace('(" docs', '("docs');
  });
}

function copyDir(from, to) {
  mkdirSync(to, { recursive: true });
  for (const name of readdirSync(from)) {
    const src = join(from, name);
    const dst = join(to, name);
    if (statSync(src).isDirectory()) copyDir(src, dst);
    else if (IMAGE_EXT.test(name)) copyFileSync(src, dst);
  }
}

// ---- 主流程 ----
if (!existsSync(SRC)) {
  console.error(`[sync-docs] 找不到教程目录：${SRC}`);
  process.exit(1);
}

/** 只收录「专题/专题.md」，目录索引与写作元信息不进应用。 */
function isTopicDoc(file) {
  const rel = relative(SRC, file).replace(/\\/g, '/');
  const parts = rel.split('/');
  if (parts.length !== 2) return false;
  return parts[1].replace(/\.md$/i, '') === parts[0];
}

const mdFiles = walk(SRC).filter(isTopicDoc).sort();
if (mdFiles.length === 0) {
  console.error('[sync-docs] 教程目录下没有 markdown 文件');
  process.exit(1);
}

const docs = [];
let broken = 0;
for (const file of mdFiles) {
  const raw = readFileSync(file, 'utf8');
  const missing = checkImages(file, raw);
  if (missing.length > 0) {
    broken += missing.length;
    console.error(`[sync-docs] 图片缺失：${relative(REPO, file)} -> ${missing.join(', ')}`);
  }
  docs.push(parseDoc(file));
}

if (broken > 0) {
  console.error(`[sync-docs] 共 ${broken} 处图片引用失效，已中止（先补齐图片再同步）`);
  process.exit(1);
}

const index = { generatedAt: new Date().toISOString(), docs };

for (const target of TARGETS) {
  rmSync(target, { recursive: true, force: true });
  mkdirSync(target, { recursive: true });
  for (const file of mdFiles) {
    const rel = relative(SRC, file);
    const relDir = dirname(rel).replace(/\\/g, '/');
    const dst = join(target, rel);
    mkdirSync(dirname(dst), { recursive: true });
    const raw = readFileSync(file, 'utf8');
    writeFileSync(dst, rewriteImages(raw, relDir), 'utf8');
    const imgDir = join(dirname(file), '图片');
    if (existsSync(imgDir)) copyDir(imgDir, join(dirname(dst), '图片'));
  }
  writeFileSync(join(target, 'index.json'), JSON.stringify(index, null, 2), 'utf8');
  console.log(`[sync-docs] 已同步 ${docs.length} 篇文档 -> ${relative(REPO, target)}`);
}

console.log(`[sync-docs] 完成：${docs.map((d) => `${d.id}（${d.minutes} 分钟，${d.sections.length} 节）`).join('；')}`);
