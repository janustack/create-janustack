#!/usr/bin/env node

import { normalize, parse, relative } from "node:path";
import { argv, cwd, env } from "node:process";

import { run } from "../index.js"; 

const [bin, script, ...args] = argv;
const binStem = parse(bin).name.toLowerCase();

let binName;

if (binStem.match(/(nodejs|node|bun)-*([0-9]*)*$/g)) {
	const managerStem = env.npm_execpath
		? parse(env.npm_execpath).name.toLowerCase()
		: null;

	if (managerStem) {
		let manager;
		switch (managerStem) {
			// Only supported package manager that has a different filename is npm.
			case "npm-cli":
				manager = "npm";
				break;

			// Bun and pnpm have the same stem name as their bin.
			// We assume all unknown package managers do as well.
			default:
				manager = managerStem;
				break;
		}

		binName = `${manager} run ${env.npm_lifecycle_event}`;
	} else {
		// Assume running NodeJS if we didn't detect a manager from the env.
		// We normalize the path to prevent the script's absolute path being used.
		const scriptNormal = normalize(relative(cwd(), script));
		binName = `${binStem} ${scriptNormal}`;
	}
} else {
	args.unshift(bin);
}

function pkgManagerFromUserAgent(userAgent) {
	if (!userAgent) return undefined;
	return userAgent.split(" ")[0]?.split("/")[0];
}

const pkgManager = pkgManagerFromUserAgent(env.npm_config_user_agent);

run(args, binName, pkgManager);
