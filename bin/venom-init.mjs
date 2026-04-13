#!/usr/bin/env node
// venom-init — Venom 하네스(.claude/, CLAUDE.md)를 임의 프로젝트에 설치/업데이트한다.
// 설계 원칙: 의존성 0, 파괴적 호출 금지.
//
// [업그레이드 동작]
// 파일을 두 종류로 구분하여 스마트 병합한다:
//   - 하네스 소유: hooks/, rules/00-59, 기본 스킬 → 항상 갱신
//   - 사용자 소유: rules/60+, memory/*.md, project-* 스킬 → 이미 있으면 보존
// 덕분에 /venom으로 생성한 프로젝트 특화 규칙·메모리·스킬이 업그레이드로 사라지지 않는다.

import { argv, cwd, exit, stderr, stdout } from 'node:process';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve, relative } from 'node:path';
import {
  existsSync,
  statSync,
  readFileSync,
  writeFileSync,
  mkdirSync,
  readdirSync,
  chmodSync,
  rmSync,
  cpSync,
} from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir, homedir } from 'node:os';
import { createRequire } from 'node:module';

const _require = createRequire(import.meta.url);
const VERSION = _require('../package.json').version;
const REPO_URL = 'https://github.com/KirSsuRyu/venom.git';
// 설치 대상 최상위 항목.
const ITEMS = ['CLAUDE.md', '.claude'];
// 사용자 로컬 파일 — 항상 보존하고 절대 덮어쓰지 않는다.
const PRESERVE_PATHS = [join('.claude', 'settings.local.json')];

// 하네스가 기본 제공하는 스킬 이름 목록.
// 이 목록에 없는 스킬(project-* 등)은 /venom이 생성한 사용자 소유로 간주한다.
const HARNESS_SKILLS = new Set([
  'code-review',
  'debug-loop',
  'evolve',
  'git-workflow',
  'mistake-recorder',
  'test-runner',
]);

const log = (msg = '') => stdout.write(msg + '\n');
const err = (msg = '') => stderr.write(msg + '\n');

function printHelp() {
  log(`venom-init v${VERSION}
사용법: venom-init [target-dir] [옵션]

옵션:
  --force          사용자 소유 파일도 포함해 모든 파일을 덮어씁니다.
  --no-backup      충돌 시 백업하지 않습니다 (--force 없으면 중단).
  --from-git       동봉본 대신 ${REPO_URL} 에서 직접 가져옵니다.
  --ref <branch>   --from-git과 함께 사용 (기본 main).
  --dry-run        실제 변경 없이 계획만 출력합니다.
  -y, --yes        확인 프롬프트를 자동 승인합니다.
  -h, --help       이 도움말을 출력합니다.
  -v, --version    버전을 출력합니다.

기본 동작 (업그레이드):
  하네스 소유 파일(hooks, rules/00-59, 기본 스킬)만 갱신합니다.
  사용자 소유 파일(rules/60+, memory/*.md, project-* 스킬)은 보존합니다.
  충돌이 있으면 .venom-backup/<timestamp>/ 아래에 백업한 뒤 갱신합니다.
  .claude/settings.local.json 은 항상 보존됩니다.`);
}

function parseArgs(rawArgv) {
  const opts = {
    target: null,
    force: false,
    noBackup: false,
    fromGit: false,
    ref: 'main',
    dryRun: false,
    yes: false,
  };
  const args = rawArgv.slice(2);
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    switch (a) {
      case '-h':
      case '--help':
        printHelp();
        exit(0);
        break;
      case '-v':
      case '--version':
        log(VERSION);
        exit(0);
        break;
      case '--force':
        opts.force = true;
        break;
      case '--no-backup':
        opts.noBackup = true;
        break;
      case '--from-git':
        opts.fromGit = true;
        break;
      case '--ref': {
        const v = args[++i];
        if (!v) {
          err('--ref 에는 브랜치/태그 이름이 필요합니다.');
          exit(1);
        }
        opts.ref = v;
        break;
      }
      case '--dry-run':
        opts.dryRun = true;
        break;
      case '-y':
      case '--yes':
        opts.yes = true;
        break;
      default:
        if (a.startsWith('-')) {
          err(`알 수 없는 옵션: ${a}`);
          exit(1);
        }
        if (opts.target) {
          err('target 디렉토리를 두 개 이상 지정할 수 없습니다.');
          exit(1);
        }
        opts.target = a;
    }
  }
  opts.target = resolve(opts.target ?? cwd());
  return opts;
}

// 시스템/홈 디렉토리 자체에 설치하는 사고를 방지한다.
function assertSafeTarget(target) {
  const forbidden = new Set(
    [
      '/',
      '/etc',
      '/usr',
      '/var',
      '/bin',
      '/sbin',
      '/System',
      '/Library',
      homedir(),
    ].map((p) => resolve(p)),
  );
  const normalized = resolve(target);
  if (forbidden.has(normalized)) {
    err(`보호된 경로에는 설치할 수 없습니다: ${normalized}`);
    exit(1);
  }
  if (!existsSync(normalized)) {
    err(`타깃 디렉토리가 존재하지 않습니다: ${normalized}`);
    exit(1);
  }
  if (!statSync(normalized).isDirectory()) {
    err(`타깃은 디렉토리여야 합니다: ${normalized}`);
    exit(1);
  }
}

// 패키지 안에 동봉된 CLAUDE.md / .claude 의 위치(= 패키지 루트)를 찾는다.
function findBundledSource() {
  const here = dirname(fileURLToPath(import.meta.url));
  const pkgRoot = resolve(here, '..');
  for (const item of ITEMS) {
    if (!existsSync(join(pkgRoot, item))) {
      err(`동봉 파일이 없습니다: ${item}. 패키지 설치가 손상되었을 수 있습니다.`);
      exit(1);
    }
  }
  return pkgRoot;
}

// --from-git: 임시 디렉토리에 얕은 클론.
function fetchFromGit(ref) {
  const dest = join(
    tmpdir(),
    `venom-init-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
  );
  mkdirSync(dest, { recursive: true });
  const r = spawnSync(
    'git',
    ['clone', '--depth=1', '--branch', ref, REPO_URL, dest],
    { stdio: 'inherit' },
  );
  if (r.status !== 0) {
    err(`git clone 실패 (ref=${ref}). git 설치와 네트워크를 확인하세요.`);
    exit(1);
  }
  for (const item of ITEMS) {
    if (!existsSync(join(dest, item))) {
      err(`클론된 저장소에 ${item} 가 없습니다. 잘못된 ref 일 수 있습니다.`);
      exit(1);
    }
  }
  return dest;
}

function detectConflicts(target) {
  return ITEMS.filter((name) => existsSync(join(target, name)));
}

function isoStamp() {
  return new Date().toISOString().replace(/[:.]/g, '-');
}

function backup(target, conflicts, dryRun) {
  const dir = join(target, '.venom-backup', isoStamp());
  if (dryRun) {
    log(`[dry-run] 백업 위치: ${dir}`);
    return dir;
  }
  mkdirSync(dir, { recursive: true });
  for (const name of conflicts) {
    const src = join(target, name);
    const dst = join(dir, name);
    cpSync(src, dst, { recursive: true, dereference: false });
  }
  return dir;
}

function ensureGitignore(target, dryRun) {
  const gi = join(target, '.gitignore');
  const line = '.venom-backup/';
  if (!existsSync(gi)) {
    if (!dryRun) writeFileSync(gi, `${line}\n`);
    return 'created';
  }
  const content = readFileSync(gi, 'utf8');
  if (content.split(/\r?\n/).some((l) => l.trim() === line)) return 'unchanged';
  if (!dryRun) {
    writeFileSync(gi, content + (content.endsWith('\n') ? '' : '\n') + `${line}\n`);
  }
  return 'appended';
}

// hooks 디렉토리의 스크립트는 실행 비트가 필요하다 (npm 패키징 후 손실 방지).
function ensureExecutable(claudeDir) {
  const hooksDir = join(claudeDir, 'hooks');
  if (!existsSync(hooksDir)) return;
  const walk = (d) => {
    for (const entry of readdirSync(d, { withFileTypes: true })) {
      const p = join(d, entry.name);
      if (entry.isDirectory()) {
        walk(p);
      } else if (entry.isFile() && /\.(sh|mjs|js|py)$/.test(entry.name)) {
        try {
          chmodSync(p, 0o755);
        } catch {
          /* 권한 부여 실패는 치명적이지 않다 */
        }
      }
    }
  };
  walk(hooksDir);
}

// 디렉토리를 재귀 순회하여 파일 상대 경로 목록을 반환한다.
function walkFiles(dir) {
  const result = [];
  const recurse = (cur) => {
    for (const entry of readdirSync(cur, { withFileTypes: true })) {
      const abs = join(cur, entry.name);
      if (entry.isDirectory()) recurse(abs);
      else if (entry.isFile()) result.push(relative(dir, abs));
    }
  };
  recurse(dir);
  return result;
}

// 파일 경로가 하네스 소유(업그레이드 시 항상 덮어씀)인지 판단한다.
// 사용자 소유(프로젝트 특화 또는 누적 데이터)이면 false → 타깃에 존재하면 건너뜀.
//
// 분류 기준:
//   하네스 소유: CLAUDE.md, settings.json, hooks/, commands/, rules/00-59, 기본 스킬 6개, memory/README.md
//   사용자 소유: rules/60+(/venom 생성), memory/*.md(누적 데이터), project-* 스킬
function isHarnessOwned(rel) {
  const p = rel.replace(/\\/g, '/');

  if (p === 'CLAUDE.md') return true;
  if (!p.startsWith('.claude/')) return true;

  if (p === '.claude/settings.json') return true;
  if (p === '.claude/settings.local.json') return false; // 항상 PRESERVE_PATHS로 처리
  if (p === '.claude/README.md') return true;
  if (p === '.claude/.npmignore') return true;

  // hooks/, commands/ 전체 → 하네스 소유
  if (p.startsWith('.claude/hooks/')) return true;
  if (p.startsWith('.claude/commands/')) return true;

  // rules/ → 00-59는 하네스 코어, 60+는 /venom이 생성하는 프로젝트 특화
  if (p.startsWith('.claude/rules/')) {
    const name = p.split('/').pop() ?? '';
    const num = parseInt(name, 10);
    if (!isNaN(num)) return num < 60;
    return true; // 번호 없는 rules 파일은 하네스 소유
  }

  // skills/ → HARNESS_SKILLS에 있는 것만 하네스 소유
  if (p.startsWith('.claude/skills/')) {
    const skillName = p.split('/')[2] ?? '';
    return HARNESS_SKILLS.has(skillName);
  }

  // memory/ → README.md만 하네스 소유, 나머지는 사용자 누적 데이터
  if (p.startsWith('.claude/memory/')) {
    return p === '.claude/memory/README.md';
  }

  return true;
}

// 스마트 병합 설치.
// 신규 설치: 모든 파일 복사.
// 업그레이드: 하네스 소유 파일만 갱신, 사용자 소유 파일은 보존.
// --force: 사용자 소유 파일도 모두 덮어씀.
function install(source, target, dryRun, force) {
  // 보존 대상 파일을 메모리에 스냅샷 (settings.local.json 등)
  const preserved = new Map();
  for (const rel of PRESERVE_PATHS) {
    const p = join(target, rel);
    if (existsSync(p)) preserved.set(rel, readFileSync(p));
  }

  const isUpgrade = ITEMS.some((name) => existsSync(join(target, name)));
  const stats = { updated: 0, added: 0, skipped: 0 };

  for (const item of ITEMS) {
    const srcItem = join(source, item);
    if (!existsSync(srcItem)) continue;

    if (statSync(srcItem).isFile()) {
      // 단일 파일 (CLAUDE.md 등)
      const dstItem = join(target, item);
      const owned = isHarnessOwned(item);
      const exists = existsSync(dstItem);
      const shouldCopy = !exists || owned || force;

      if (dryRun) {
        log(`[dry-run] ${!exists ? 'add' : shouldCopy ? 'update' : 'skip'}: ${item}`);
      } else if (shouldCopy) {
        cpSync(srcItem, dstItem);
      }
      if (!exists) stats.added++;
      else if (shouldCopy) stats.updated++;
      else stats.skipped++;
    } else {
      // 디렉토리 (.claude/) → 파일 단위 처리
      for (const relFile of walkFiles(srcItem)) {
        const relPath = join(item, relFile).replace(/\\/g, '/');
        const srcFile = join(srcItem, relFile);
        const dstFile = join(target, relPath);
        const owned = isHarnessOwned(relPath);
        const exists = existsSync(dstFile);
        const shouldCopy = !exists || owned || force;

        if (dryRun) {
          log(`[dry-run] ${!exists ? 'add' : shouldCopy ? 'update' : 'skip'}: ${relPath}`);
        } else if (shouldCopy) {
          mkdirSync(dirname(dstFile), { recursive: true });
          cpSync(srcFile, dstFile);
        }
        if (!exists) stats.added++;
        else if (shouldCopy) stats.updated++;
        else stats.skipped++;
      }
    }
  }

  // 보존 파일 복원 (소스에서 흘러 들어왔을 수 있으므로 항상 원본으로 덮어씀)
  for (const [rel, buf] of preserved) {
    const p = join(target, rel);
    if (dryRun) {
      log(`[dry-run] 보존 복원: ${rel}`);
      continue;
    }
    mkdirSync(dirname(p), { recursive: true });
    writeFileSync(p, buf);
  }

  if (!dryRun) ensureExecutable(join(target, '.claude'));

  return { ...stats, isUpgrade };
}

function main() {
  const opts = parseArgs(argv);
  assertSafeTarget(opts.target);

  log(`venom-init v${VERSION}`);
  log(`타깃: ${opts.target}`);
  if (opts.dryRun) log('(dry-run 모드: 파일시스템을 변경하지 않습니다)');

  let source;
  let cleanup = () => {};
  if (opts.fromGit) {
    log(`소스: git ${REPO_URL}#${opts.ref}`);
    source = fetchFromGit(opts.ref);
    cleanup = () => {
      try {
        rmSync(source, { recursive: true, force: true });
      } catch {
        /* 임시 디렉토리 정리 실패는 무시 */
      }
    };
  } else {
    source = findBundledSource();
    log('소스: 동봉본');
  }

  try {
    const conflicts = detectConflicts(opts.target);
    if (conflicts.length > 0) {
      log(`기존 항목 감지: ${conflicts.join(', ')}`);
      if (opts.noBackup && !opts.force) {
        err('--no-backup 모드에서 충돌이 발생했습니다. --force 와 함께 사용하거나 백업을 허용하세요.');
        exit(2);
      }
      if (!opts.noBackup) {
        const dir = backup(opts.target, conflicts, opts.dryRun);
        log(`백업: ${dir}`);
      } else {
        log('백업 생략 (--no-backup --force)');
      }
    } else {
      log('충돌 없음 — 깨끗한 설치');
    }

    const result = install(source, opts.target, opts.dryRun, opts.force);
    const giResult = ensureGitignore(opts.target, opts.dryRun);
    log(`.gitignore: ${giResult}`);
    log('');

    if (result.isUpgrade) {
      log(`업그레이드 완료: ${result.updated}개 갱신, ${result.added}개 신규, ${result.skipped}개 보존`);
      if (result.skipped > 0) {
        log('  보존된 파일: 프로젝트 특화 규칙(60+), 메모리 데이터, 커스텀 스킬');
        log('  모두 덮어쓰려면: --force 플래그 사용');
      }
    } else {
      log(`설치 완료: ${result.added}개 파일`);
    }

    log('');
    log('다음 단계:');
    log('  1) Claude Code 세션을 재시작하세요.');
    log('  2) 새 세션에서 /venom 을 실행하세요.');
  } finally {
    cleanup();
  }
}

main();
