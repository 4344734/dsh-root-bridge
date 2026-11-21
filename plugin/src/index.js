/**
 * dsh-root-bridge — model-facing tool that runs commands as real root on the
 * Android side, through the companion KernelSU module of the same name.
 *
 * The bridge listens on 127.0.0.1:47913, authenticated by the token in
 * `$DSH_HOME/rootd/token`; the module restores that token file and the listener.
 * This package only speaks that loopback protocol; it never escalates anything.
 */
import net from 'node:net';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { defineTool } from '@deepseek-ai/dsh-tools';

export const name = 'root-bridge';

/** Only the tool registry is needed; the bridge is a plain loopback socket. */
export const inject = ['tools'];

const MARK = '__RC__';
const DEFAULT_PORT = 47913;
const DEFAULT_TIMEOUT_MS = 60_000;
const MAX_TIMEOUT_MS = 600_000;

function dshHome() {
	const env = process.env.DSH_HOME;
	if (typeof env === 'string' && env.length > 0) return env;
	return path.join(os.homedir(), '.dsh');
}

function bridgePort() {
	try {
		const text = fs.readFileSync(path.join(dshHome(), 'rootd', 'port'), 'utf8').trim();
		const port = Number.parseInt(text, 10);
		if (Number.isInteger(port) && port > 0 && port < 65536) return port;
	} catch {
		// Fall through to the default the module uses.
	}
	return DEFAULT_PORT;
}

function bridgeToken() {
	const file = path.join(dshHome(), 'rootd', 'token');
	try {
		const token = fs.readFileSync(file, 'utf8').trim();
		if (token.length > 0) return token;
	} catch {
		// Reported by the caller with the installation hint.
	}
	throw new Error(
		`找不到 root 桥的 token（${file}）。请先在手机上安装 dsh-root-bridge 的 KernelSU 模块并重启，` +
		'然后运行 dsh-root --status 确认桥在线。',
	);
}

function parseReply(buffer) {
	const at = buffer.indexOf(MARK);
	if (at < 0) throw new Error('root 桥没有回执（连接被提前关闭或 token 不匹配）');
	const output = buffer.slice(0, at);
	const code = Number.parseInt(buffer.slice(at + MARK.length).trim(), 10);
	return { output, exitCode: Number.isInteger(code) ? code : 1 };
}

/** Send one authenticated command to the bridge and collect its reply. */
export function runRoot(command, timeoutMs = DEFAULT_TIMEOUT_MS) {
	const timeout = Math.min(Math.max(1, Math.trunc(timeoutMs) || DEFAULT_TIMEOUT_MS), MAX_TIMEOUT_MS);
	const token = bridgeToken();
	const port = bridgePort();
	return new Promise((resolve, reject) => {
		let buffer = '';
		let settled = false;
		const socket = net.createConnection({ host: '127.0.0.1', port });
		const timer = setTimeout(() => {
			finish(new Error(`命令超过 ${timeout}ms 仍未结束`));
		}, timeout);

		function finish(error, value) {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			socket.destroy();
			if (error) reject(error);
			else resolve(value);
		}

		socket.setEncoding('utf8');
		socket.on('connect', () => {
			socket.write(`${token}\n${command}`);
			socket.end();
		});
		socket.on('data', (chunk) => {
			buffer += chunk;
			if (buffer.includes(MARK)) {
				try {
					finish(undefined, parseReply(buffer));
				} catch (error) {
					finish(error);
				}
			}
		});
		socket.on('error', (error) => {
			const hint = error && error.code === 'ECONNREFUSED'
				? 'root 桥没在跑：确认 KernelSU 模块 dsh-root-bridge 已启用，或运行 dsh-root --status 检查。'
				: String(error && error.message ? error.message : error);
			finish(new Error(hint));
		});
		socket.on('close', () => {
			if (!settled) finish(new Error('root 桥在回执前关闭了连接'));
		});
	});
}

export function apply(ctx) {
	ctx.tools.register(defineTool({
		name: 'root_exec',
		description: '在 Android 系统侧以真正的 root 执行一条命令（绕过 DSH 的 proot 容器），返回合并后的输出与退出码。'
			+ '需要手机上已安装 dsh-root-bridge 的 KernelSU 模块；容器里普通的 bash 工具仍然是 proot 的假 root。'
			+ '注意：pm / am / settings / input 等 Android 框架命令在 ColorOS 上会被 binder 限制挡住，返回 Failed transaction；'
			+ '文件、系统、dumpsys、screencap、iptables 等正常。',
		parameters: {
			command: {
				type: 'string',
				required: true,
				description: '交给 Android 侧 /system/bin/sh -c 执行的命令。',
			},
			timeoutMs: {
				type: 'integer',
				description: '超时毫秒数，默认 60000，最大 600000。',
			},
		},
		output: {
			schema: {
				type: 'object',
				additionalProperties: false,
				properties: {
					output: { type: 'string', required: true },
					exitCode: { type: 'integer', required: true },
				},
			},
			render: (_args, value) => [{
				type: 'text',
				text: `exit ${value.exitCode}\n${value.output}`,
			}],
		},
		async execute(args) {
			return runRoot(args.command, args.timeoutMs);
		},
	}));
}
