#!/usr/bin/env node
"use strict";

// Benchmark gzip and Brotli compression of the *actual exported* Godot PCK.
// Compression is NOT wired into production by this script.
// Usage: node tools/benchmark_noxsum_pack_compression.cjs [builds/web/index.pck]

const fs = require("node:fs");
const zlib = require("node:zlib");
const path = require("node:path");
const { performance } = require("node:perf_hooks");
const input = path.resolve(process.argv[2] || "builds/web/index.pck");
const original = fs.readFileSync(input);
const options = [
  {name: "gzip-6", suffix: ".gz", method: () => zlib.gzipSync(original, {level: 6, mtime: 0})},
  {name: "brotli-5", suffix: ".br", method: () => zlib.brotliCompressSync(original, {params: {[zlib.constants.BROTLI_PARAM_QUALITY]: 5}})},
  {name: "brotli-9", suffix: ".br9", method: () => zlib.brotliCompressSync(original, {params: {[zlib.constants.BROTLI_PARAM_QUALITY]: 9}})}
];
const results = [];
console.log("SOURCE_PCK_BYTES=" + original.length);
for (const item of options) {
  const t0 = performance.now();
  const packed = item.method();
  const durationMs = Math.round(performance.now() - t0);
  const percent = Math.round(10000 * (1 - packed.length / original.length)) / 100;
  const result = { method: item.name, bytes: packed.length, savedPercent: percent, durationMs };
  results.push(result);
  console.log("PACK_RESULT=" + JSON.stringify(result));
  // Verify byte-for-byte decompression before suggesting any use for game delivery.
  const unpacked = item.name.startsWith("gzip") ? zlib.gunzipSync(packed) : zlib.brotliDecompressSync(packed);
  if (!original.equals(unpacked)) throw new Error(item.name + ": decompressed bytes differ");
  console.log("PACK_ROUNDTRIP_OK=" + item.name);
  if (item.name === "gzip-6") {
    fs.writeFileSync(input + ".gz", packed); // Only exported artifact directory, not committed.
  }
}
console.log("PACK_SUMMARY=" + JSON.stringify({originalBytes: original.length, results}));
