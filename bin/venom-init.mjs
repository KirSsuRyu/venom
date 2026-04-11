#!/usr/bin/env node
// venom-init — Venom 하네스(.claude/, CLAUDE.md)를 임의 프로젝트에 설치/업데이트한다.
// 설계 원칙: 의존성 0, 파괴적 호출 금지, 모든 충돌은 백업 후 덮어쓰기.

import { argv, cwd, exit, stderr, stdout } from 'node:process';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve } from 'node:path';
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

const VERSION = '0.1.0';
const REPO_URL = 'https://github.com/KirSsuRyu/venom.git';
// 설치 대상 항목. 추가/삭제 시 README와 테스트도 함께 갱신할 것.
const ITEMS = ['CLAUDE.md', '.claude'];
// 사용자 로컬 파일 — 항상 보존하고 절대 덮어쓰지 않는다.
const PRESERVE_PATHS = [join('.claude', 'settings.local.json')];

const log = (msg = '') => stdout.write(msg + '\n');
const err = (msg = '') => stderr.write(msg + '\n');

function printHelp() {
  log(`venom-init v${VERSION}
사용법: venom-init [target-dir] [옵션]

옵션:
  --force          기존 파일을 백업 없이 덮어씁니다 (--no-backup과 함께 사용).
  --no-backup      충돌 시 백업하지 않습니다 (--force 없으면 중단).
  --from-git       동봉본 대신 ${REPO_URL} 에서 직접 가져옵니다.
  --ref <branch>   --from-git과 함께 사용 (기본 main).
  --dry-run        실제 변경 없이 계획만 출력합니다.
  -y, --yes        확인 프롬프트를 자동 승인합니다.
  -h, --help       이 도움말을 출력합니다.
  -v, --version    버전을 출력합니다.

기본 동작: 현재 디렉토리에 동봉된 Venom 하네스를 설치합니다.
충돌이 있으면 .venom-backup/<timestamp>/ 아래에 백업한 뒤 덮어씁니다.
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

function install(source, target, dryRun) {
  // 보존 대상 파일을 메모리에 스냅샷.
  const preserved = new Map();
  for (const rel of PRESERVE_PATHS) {
    const p = join(target, rel);
    if (existsSync(p)) preserved.set(rel, readFileSync(p));
  }

  for (const name of ITEMS) {
    const src = join(source, name);
    const dst = join(target, name);
    if (dryRun) {
      log(`[dry-run] 복사: ${name}`);
      continue;
    }
    if (existsSync(dst)) rmSync(dst, { recursive: true, force: true });
    cpSync(src, dst, { recursive: true, dereference: false });
  }

  // 소스에서 흘러 들어왔을 수 있는 보존 파일을 항상 제거.
  for (const rel of PRESERVE_PATHS) {
    const p = join(target, rel);
    if (dryRun) continue;
    if (existsSync(p)) rmSync(p, { force: true });
  }

  // 타깃에 원래 있었다면 그대로 복원 (덮어쓰지 않는다).
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

    install(source, opts.target, opts.dryRun);
    const giResult = ensureGitignore(opts.target, opts.dryRun);
    log(`.gitignore: ${giResult}`);

    log('');
    log('완료. 다음 단계:');
    log('  1) Claude Code 세션을 재시작하세요.');
    log('  2) 새 세션에서 /venom 을 실행하세요.');
  } finally {
    cleanup();
  }
}

main();
