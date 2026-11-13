"""Custom HTML shell for the Web export: the "Knitting your sweater" scarf loader (style guide §7).

Run from the project root:  python art_src/tools/make_web_shell.py   ->  web/shell.html
(export_presets.cfg: html/custom_html_shell = "res://web/shell.html").
The knit tile, Fair Isle band and title font are inlined (base64) so the loader shows with the first paint.
Background = boot_splash/bg_color = the intro's first frame (knit red), so page -> engine -> intro never flashes.
Sizes use the game's canvas scale (min(w/1280, h/720)) so the bands line up with the intro scene's bands.
Built from Godot 4.7's default shell (same $GODOT_* placeholders and startGame/onProgress flow).
"""
import base64
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def b64(path: str) -> str:
    with open(os.path.join(ROOT, path), "rb") as f:
        return base64.b64encode(f.read()).decode()


TEMPLATE = r"""<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0">
		<title>$GODOT_PROJECT_NAME</title>
		<style>
@font-face { font-family: "New Rocker"; src: url(data:font/woff2;base64,__FONT__) format("woff2"); font-display: block; }
html, body, #canvas { margin: 0; padding: 0; border: 0; }
body { color: #FFF8EE; background-color: #8E1F2E; overflow: hidden; touch-action: none; --s: 1; }
#canvas { display: block; }
#canvas:focus { outline: none; }
#status {
	position: absolute; inset: 0; z-index: 2; visibility: hidden; transition: opacity .35s ease;
	background: #8E1F2E url(data:image/png;base64,__KNIT__) 0 0 / calc(14px * var(--s)) calc(16px * var(--s));
	image-rendering: pixelated;
}
#status.done { opacity: 0; }
.cc-band { position: absolute; left: 0; right: 0; height: calc(30px * var(--s));
	background: url(data:image/png;base64,__BAND__) 0 0 / auto 100% repeat-x; image-rendering: pixelated; }
#cc-band-top { top: calc(26px * var(--s)); }
#cc-band-bottom { bottom: calc(26px * var(--s)); }
#cc-label { position: absolute; left: 0; right: 0; top: calc(50% - 90px * var(--s)); text-align: center;
	font: calc(36px * var(--s)) / 1 "New Rocker", serif;
	text-shadow: 0 calc(3px * var(--s)) 0 #0D1322, 2px 0 0 #0D1322, -2px 0 0 #0D1322, 0 -2px 0 #0D1322, 0 2px 0 #0D1322; }
#cc-label small { display: block; margin-top: calc(10px * var(--s)); font: calc(14px * var(--s)) / 1 ui-monospace, Consolas, monospace;
	color: #F2C9B8; text-shadow: none; }
#cc-scarf { position: absolute; left: 0; top: calc(50% - 10px * var(--s)); height: calc(76px * var(--s)); width: 0;
	background: url(data:image/png;base64,__BAND__) 0 calc(23px * var(--s)) / auto calc(30px * var(--s)) repeat-x,
		url(data:image/png;base64,__KNITO__) 0 0 / calc(14px * var(--s)) calc(16px * var(--s)), #1F5A43;
	box-shadow: 0 calc(8px * var(--s)) 0 rgba(13, 19, 34, .35); outline: 2px dashed rgba(255, 248, 238, .45); outline-offset: -8px;
	transition: width .25s ease-out; image-rendering: pixelated; }
#cc-ball { position: absolute; top: calc(50% - 10px * var(--s)); left: 0; width: calc(76px * var(--s)); height: calc(76px * var(--s));
	border-radius: 50%; background: repeating-linear-gradient(60deg, #F4E6D4 0 4px, #D9C3A8 4px 7px);
	box-shadow: 0 calc(6px * var(--s)) 0 rgba(13, 19, 34, .3); transition: left .25s ease-out; }
#status-notice { display: none; position: absolute; left: 2rem; right: 2rem; bottom: 18%; padding: 1rem; text-align: center;
	background: #1A2438; border: 3px solid #0D1322; box-shadow: inset 0 0 0 2px #5C77AB; color: #F4F8FF;
	font-family: ui-monospace, Consolas, monospace; line-height: 1.4; }
@media (prefers-reduced-motion: reduce) { #cc-scarf, #cc-ball, #status { transition: none; } }
		</style>
		$GODOT_HEAD_INCLUDE
	</head>
	<body>
		<canvas id="canvas">Your browser does not support the canvas tag.</canvas>
		<noscript>Your browser does not support JavaScript.</noscript>
		<div id="status">
			<div class="cc-band" id="cc-band-top"></div>
			<div class="cc-band" id="cc-band-bottom"></div>
			<div id="cc-label">Knitting your sweater <span id="cc-pct"></span><small id="cc-mb">&nbsp;</small></div>
			<div id="cc-scarf"></div>
			<div id="cc-ball"></div>
			<div id="status-notice"></div>
		</div>
		<script src="$GODOT_URL"></script>
		<script>
const GODOT_CONFIG = $GODOT_CONFIG;
const GODOT_THREADS_ENABLED = $GODOT_THREADS_ENABLED;
const engine = new Engine(GODOT_CONFIG);

(function () {
	const statusOverlay = document.getElementById('status');
	const statusNotice = document.getElementById('status-notice');
	const scarf = document.getElementById('cc-scarf');
	const ball = document.getElementById('cc-ball');
	const pct = document.getElementById('cc-pct');
	const mb = document.getElementById('cc-mb');
	let initializing = true;

	// The game's canvas scale (stretch canvas_items, aspect expand), so sizes match the intro scene.
	function fit() {
		document.body.style.setProperty('--s', Math.min(window.innerWidth / 1280, window.innerHeight / 720));
	}
	window.addEventListener('resize', fit);
	fit();

	function setProgress(current, total) {
		if (!(current > 0 && total > 0)) {
			pct.textContent = '';
			return;
		}
		const p = Math.min(1, current / total);
		const span = window.innerWidth * 0.92;
		scarf.style.width = (p * span) + 'px';
		ball.style.left = (p * span - ball.offsetWidth * 0.15) + 'px';
		pct.textContent = Math.round(p * 100) + '%';
		mb.textContent = (current / 1048576).toFixed(1) + ' / ' + (total / 1048576).toFixed(1) + ' MB';
	}

	function finish() {
		// Fade into the canvas: the engine's boot colour and the intro's first frame are the same knit red.
		statusOverlay.classList.add('done');
		setTimeout(() => statusOverlay.remove(), 400);
		initializing = false;
	}

	function displayFailureNotice(err) {
		console.error(err);
		statusNotice.textContent = (err instanceof Error) ? err.message : (typeof err === 'string' ? err : 'An unknown error occurred.');
		statusNotice.style.display = 'block';
		initializing = false;
	}

	const missing = Engine.getMissingFeatures({ threads: GODOT_THREADS_ENABLED });
	statusOverlay.style.visibility = 'visible';
	if (missing.length !== 0) {
		if (GODOT_CONFIG['serviceWorker'] && GODOT_CONFIG['ensureCrossOriginIsolationHeaders'] && 'serviceWorker' in navigator) {
			let registration;
			try {
				registration = navigator.serviceWorker.getRegistration();
			} catch (err) {
				registration = Promise.reject(new Error('Service worker registration failed.'));
			}
			Promise.race([
				registration.then((r) => (r != null ? Promise.reject(new Error('Service worker already exists.')) : r))
					.then(() => engine.installServiceWorker()),
				new Promise((resolve) => setTimeout(() => resolve(), 2000)),
			]).then(() => window.location.reload()).catch((err) => console.error('Error while registering service worker:', err));
		} else {
			displayFailureNotice('Error\nThe following features required to run Godot projects on the Web are missing:\n' + missing.join('\n'));
		}
	} else {
		engine.startGame({ 'onProgress': setProgress }).then(finish, displayFailureNotice);
	}
}());
		</script>
	</body>
</html>
"""


if __name__ == "__main__":
    html = (TEMPLATE.replace("__FONT__", b64("art_src/web/NewRocker-latin.woff2"))
            .replace("__KNITO__", b64("assets/ui/tin/knit_overlay.png"))  # transparent knit over the pine scarf
            .replace("__KNIT__", b64("assets/ui/tin/knit_red.png"))
            .replace("__BAND__", b64("assets/ui/tin/fair_isle_big.png")))
    out = os.path.join(ROOT, "web", "shell.html")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(html)
    print("wrote", out, len(html) // 1024, "KB")
