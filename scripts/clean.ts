import ja from "@janush/ansi/sgr";
import { $ } from "bun";
import { existsSync } from "node:fs";
import { readdir, stat } from "node:fs/promises";
import path from "node:path";
import { performance } from "node:perf_hooks";

const targets = ["target"];

interface Stats {
	dirs: number;
	files: number;
	bytes: number;
}

const removed: string[] = [];

function formatBytes(bytes: number): string {
	if (bytes < 1024) return `${bytes} B`;
	const k = bytes / 1024;
	if (k < 1024) return `${k.toFixed(2)} KB`;
	const m = k / 1024;
	if (m < 1024) return `${m.toFixed(2)} MB`;
	return `${(m / 1024).toFixed(2)} GB`;
}

async function countContents(entry: string, stats: Stats): Promise<void> {
	try {
		const s = await stat(entry);
		if (s.isDirectory()) {
			stats.dirs++;
			const children = await readdir(entry);
			await Promise.all(
				children.map((child) => countContents(path.join(entry, child), stats)),
			);
		} else if (s.isFile()) {
			stats.files++;
			stats.bytes += s.size;
		}
	} catch {
		// Skip entries we can't stat
	}
}

async function main() {
	const start = performance.now();
	console.log(`${ja.bg.blue(ja.fmt.bold(" INFO "))} Starting process...`);

	const stats: Stats = { dirs: 0, files: 0, bytes: 0 };

	await Promise.all(
		targets.map(async (target) => {
			if (existsSync(target)) {
				await countContents(target, stats);
				await $`rm -rf ${target}`;
				removed.push(target);
			}
		}),
	);

	const duration = (performance.now() - start).toFixed(2);

	if (removed.length > 0) {
		console.log(
			`${ja.bg.green(ja.fmt.bold(" SUCCESS "))} Removed: ${removed.join(", ")}`,
		);
		console.log(
			`${ja.fg.cyan(
				`Deleted ${stats.files} file(s), ${stats.dirs} director${
					stats.dirs === 1 ? "y" : "ies"
				}`,
			)}`,
		);
		console.log(
			`${ja.fg.cyan(`Total size deleted: ${formatBytes(stats.bytes)}`)}`,
		);
		console.log(`${ja.fg.green(`Cleanup completed in ${duration}ms`)}`);
	} else {
		console.log(`${ja.bg.yellow(ja.fmt.bold(" WARNING "))} Nothing to clean`);
	}
}

main().catch((error) => {
	console.error(ja.bg.red(ja.fmt.bold(" ERROR ")), error);
	process.exit(1);
});
