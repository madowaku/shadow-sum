#!/usr/bin/env node
"use strict";

// Mock only the Godot Web shell boundary. This is NOT a real browser/Web export test.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const shell = fs.readFileSync(path.join(__dirname, "..", "web", "noxsum_web_shell.html"), "utf8");
assert.match(shell, /id="noxsum-loading"/);
assert.match(shell, /role="progressbar"/);
const match = shell.match(/<script>\s*([\s\S]*?)<\/script>/);
assert.ok(match, "inline Web startup script must exist");
const script = match[1].replace("$GODOT_CONFIG", "{}");

function mockElement() {
    const classes = new Set();
    const attributes = {};
    return {
        classes,
        attributes,
        style: {},
        textContent: "",
        removed: false,
        classList: {
            add: (name) => classes.add(name),
            remove: (name) => classes.delete(name),
            contains: (name) => classes.has(name),
        },
        setAttribute: (name, value) => { attributes[name] = value; },
        removeAttribute: (name) => { delete attributes[name]; },
        remove() { this.removed = true; },
    };
}

function createScenario() {
    const loading = mockElement();
    const track = mockElement();
    const fill = mockElement();
    const percent = mockElement();
    loading.querySelector = (selector) => ({
        ".loading-track": track,
        ".loading-fill": fill,
        ".loading-percent": percent,
    })[selector];
    const canvas = {
        width: 720, height: 900,
        style: { width: "720px", height: "900px" },
        getBoundingClientRect: () => ({ width: 720, height: 900 }),
    };
    const document = {
        title: "",
        getElementById: (id) => (id === "canvas" ? canvas : loading),
    };
    const errors = [];
    const window = {
        visualViewport: null,
        innerWidth: 720,
        innerHeight: 900,
        devicePixelRatio: 1,
        ResizeObserver: null,
        addEventListener: () => {},
        setTimeout: (fn) => fn(),
    };
    let callbacks;
    let resolveStart;
    let rejectStart;
    class Engine {
        startGame(options) {
            callbacks = options;
            return new Promise((resolve, reject) => {
                resolveStart = resolve;
                rejectStart = reject;
            });
        }
    }
    vm.runInNewContext(script, {
        Engine, document, window,
        console: { info: () => {}, error: (...args) => errors.push(args) },
    }, { timeout: 2000 });
    assert.equal(typeof callbacks.onProgress, "function");
    return { callbacks, loading, track, fill, percent, document, errors, resolveStart, rejectStart };
}

async function main() {
    const ok = createScenario();
    ok.callbacks.onProgress(25, 100);
    assert.equal(ok.percent.textContent, "25%");
    assert.equal(ok.fill.style.width, "25%");
    assert.equal(ok.track.attributes["aria-valuenow"], "25");
    ok.callbacks.onProgress(10, 0);
    assert.equal(ok.percent.textContent, "Loading…");
    assert.ok(ok.loading.classes.has("indeterminate"));
    assert.equal(ok.track.attributes["aria-valuenow"], undefined);
    ok.callbacks.onProgress(100, 100);
    assert.equal(ok.percent.textContent, "100%");
    assert.ok(!ok.loading.classes.has("indeterminate"));
    ok.resolveStart();
    await new Promise(setImmediate);
    assert.ok(ok.loading.classes.has("ready"));
    assert.ok(ok.loading.removed);
    assert.equal(ok.document.title, "NOXSUM");

    const bad = createScenario();
    bad.rejectStart(new Error("mock offline failure"));
    await new Promise(setImmediate);
    assert.match(bad.percent.textContent, /Load failed/);
    assert.ok(!bad.loading.removed);
    assert.equal(bad.errors.length, 1);
    console.log("PASS: progress, unknown total, successful startup, failure UI");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
