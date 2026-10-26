# NOXSUM release lineage and verification gates (2026-10-26)

This is a **source-to-distribution audit**, not a new build or a deployment. It records what the existing repository says about the two different public destinations, and what has **not** been independently verified. It does not supersede [NOXSUM_WEB_EXPORT.md](NOXSUM_WEB_EXPORT.md) or [GRANT_SUBMISSION_2026.md](GRANT_SUBMISSION_2026.md).

## Source-of-truth references

| Reference | Exact revision | Meaning |
| --- | --- | --- |
| `main` at audit time | `12655b88f8937698f832e9572fdfb8a4912358b7` | Older development line, **not** the published Grant36 source. |
| Annotated tag `grant-submission-2026` | target commit `10520036a2ce207d43900c4bdf614172c4bb133f` | Immutable source snapshot for the September 27 Grant submission. The annotated tag object itself is `aabd633e932a2b65ccba35b935d2e19948a7a831`. |
| Afterimage change | `708b0209a33ddb89239e48e8f0da39a3915cf736` | 0.25-second placement hold and 0.40-second afterimage fade, after the submission snapshot. |
| `release/noxsum-grant36-final` at audit time | `22242890dfd704e27d88224af784583b43e33f9c` | Later release branch tip containing deployment documentation; **not** proof that a matching binary is currently live. |
| Draft PR #11 | `1aea94406e81121f6cc834ccab1674510bd58092` | Fixes legacy experiment plate orientation only; targets the release branch. **Not deployed or merged** as of this audit. |

GitHub compare at audit time: `main...release/noxsum-grant36-final` was **73 commits ahead / 0 behind**. Do not assume that rebuilding from `main`, the release tip, or PR #11 will reproduce either September 27 package.

## Distribution ledger

| Destination | Source / artifact recorded in repository | SHA-256 / deployment identifier | What is verified |
| --- | --- | --- | --- |
| [itch.io Grant submission](https://madowaku.itch.io/noxsum) | `builds/NOXSUM_Grant_Itchio_2026-09-27.zip`, submitted September 27, from the Grant36 submission line with GR03 variant B | ZIP SHA-256: `B6F3712B211D9F1A53246DF0786769B7FF4CF09A408B9F2D7A3FC351CBE02DFE` | Packaging checks and upload are **documented** in `NOXSUM_WEB_EXPORT.md`. This audit did **not** download the currently hosted itch.io payload to recompute its hash. |
| Local Afterimage itch.io package | `builds/NOXSUM_Grant_Itchio_2026-09-27_Afterimage.zip`, produced after `708b0209` | ZIP SHA-256: `6F9EBAF07611842960D7DADA95D003C47B4265E0ED563A4A9ACD530E6BEC6C73` | Local ZIP checks and Chromium smoke are **documented**. The repository explicitly says this ZIP was **not uploaded to itch.io**. |
| [Netlify Web production](https://noxsum.netlify.app) | `builds/web/` Afterimage Web export, manually deployed September 27; **not the itch.io ZIP** | Deploy ID: `6ab90b8f7189d8f6a34df68b`; [immutable deploy URL](https://6ab90b8f7189d8f6a34df68b--noxsum.netlify.app) | Deployment readiness and HTTP 200 checks were **documented at deploy time**. This audit did **not** verify the currently served bytes or the current production alias. A ZIP hash must not be treated as the hash of the Netlify directory. |

The Grant36 puzzle-data SHA-256 recorded in the submission snapshot is `d7db564e4bf74cd4bc180c2212bd065b75ab2f6dc1a9e88fd8b917c330d6808f`. It is a **data-file hash**, not a ZIP or Web-build hash.

## Release gates before another upload, rebuild, or merge

1. **Recover the exact artifacts** from their existing local/archived location. The paths under `builds/` are historical records, not evidence that the binaries are checked into GitHub. If an artifact is missing, mark it **UNKNOWN**; do not silently regenerate it from a different commit.
2. **Hash the actual ZIPs** and compare the *full* SHA-256 values above (e.g. PowerShell: `Get-FileHash -Algorithm SHA256 <path>`). For itch.io, verify the downloadable/hosted payload separately where possible. The uploaded package may not be publicly downloadable without publisher access.
3. **Verify Netlify independently**: confirm the production alias points to deploy `6ab90b8f7189d8f6a34df68b` in the authorized deployment history, then compare the immutable deploy's served runtime assets with the preserved `builds/web/` manifest or files. HTTP 200 and the title alone are insufficient for byte identity.
4. **Keep the streams separate**: submission tag `10520036` is the Grant snapshot; Afterimage `708b0209` is later; release tip `22242890` adds records; Draft PR #11 fixes legacy experiments. Do not promote experiment fixes into a public build without separate regression and release acceptance.
5. **Before shipping**: rerun the appropriate Godot 4.7 export, stage validation, packaging checks, browser smoke at 720×900 and 360×800, and human play acceptance. Confirm license notices in the actual distribution archive. Record the exact source commit, export preset, artifact hash, deployment ID, and date in a new release entry.

## CI and remaining uncertainty

The release branch's September 27 Godot smoke and Jev Review jobs were **failing** for legacy experiment plate orientation. Draft [PR #11](https://github.com/madowaku/shadow-sum/pull/11) has a narrow fix with successful CI reported on that PR, but it has not been merged into the release branch. Do not mistake a green PR check for a green current release-branch check.

**Audit scope:** GitHub branch/tag references, GitHub PR metadata, and existing documentation were checked on October 26. No local ZIP, itch.io-hosted binary, Netlify deployment account, physical device, or human gameplay was accessed. Therefore **current live binary equivalence is UNKNOWN**. This document authorizes no merge, publication, deployment, or overwrite.
