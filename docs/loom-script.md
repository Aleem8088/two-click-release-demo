# Loom Script: "Two-Click Release" (about 2 minutes)

Record only after the pipeline has actually run green in your own GitHub repo. Use your real screen. Do not show any employer or client information.

## Before recording
- [ ] Repo public with the README rendered
- [ ] Azure deployed once so staging and production URLs exist
- [ ] `production` environment has you as required reviewer
- [ ] A tiny prepared code change ready (for example, change the `service` name in `app/main.py`)
- [ ] Browser tabs open: repo → Actions, staging URL, production URL
- [ ] Close notifications, hide bookmarks and tabs unrelated to the demo

## Script

**0:00 Intro (15s)**
"Hi, I'm Mohammed. A lot of teams still release software by hand: days of prep, and someone staying up overnight. This is a small demo of the pipeline I build to replace that. A release becomes two clicks."

**0:15 The change (20s)**
Show the one-line code change. Commit and push to `main`.
"This is a normal commit. I'm not running anything manually."

**0:35 The pipeline (40s)**
Open Actions. Walk through each stage as it runs.
"First it lints and runs the tests. Then it builds a Docker image tagged with the commit. It deploys to staging, then runs a smoke test that checks staging is actually serving this exact commit, not an old version."

**1:15 Click one: approval (20s)**
Show the paused production job.
"Production waits here. Someone has to approve. This is the one human decision in the process."
Click Approve.

**1:35 Production and rollback (20s)**
Show the production job passing; open the production URL showing the new version.
"Production is live and verified. If something goes wrong, this rollback workflow redeploys a previous version in minutes."

**1:55 Close (10s)**
"The repo is linked below. If your team still deploys manually and you want this set up, send me a message with your stack."

## Tips
- Speak slowly. It's fine to cut and re-record.
- Add captions. Many viewers watch muted.
- If a stage takes long, speed that part up in the editor.
- Put the Loom link in the README, your Upwork portfolio and the Fiverr gig.
