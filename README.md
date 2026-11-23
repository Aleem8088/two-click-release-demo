# Two-Click Release: CI/CD Pipeline Demo

A small, working example of the release pipeline I build for teams that still deploy by hand.

**The idea:** a code change is tested, built into a Docker image, deployed to staging and verified automatically. Shipping to production then takes **one approval click**.

> This is a demo built from scratch with a sample app. It contains no client code. It reflects a pattern I use professionally: replacing a release that needed days of preparation and an overnight deployment with a pipeline where a release is two clicks.

## How it works

```
 pull request ──► lint + tests
                      │
 merge to main ──► lint + tests ──► build Docker image ──► push to registry (GHCR)
                                                               │
                                                               ▼
                                         deploy to STAGING ──► smoke test
                                                               │   (must report this exact commit)
                                                               ▼
                                         ⏸  waits for approval (click 1)
                                                               ▼
                                         deploy to PRODUCTION ──► smoke test
```

- **Tests gate everything.** Ruff and pytest run on every PR and every merge.
- **Immutable images.** Each image is tagged with the short commit SHA, and the full SHA is baked in as `APP_VERSION`.
- **Verified deploys.** After each deploy, `scripts/smoke-test.sh` polls `/health` until it reports the commit being deployed, so a stale or failed revision can't pass.
- **Approval gate.** The `production` job uses a GitHub Environment with a required reviewer. The run pauses until someone approves.
- **No stored cloud secrets.** GitHub signs in to Azure with OIDC federation, so there is no long-lived client secret in the repo.
- **Rollback.** The `rollback` workflow redeploys any previous image tag to production.

## Repo layout

| Path | Purpose |
|---|---|
| `app/main.py` | Tiny Flask service with `/` and `/health` |
| `tests/` | pytest tests |
| `Dockerfile` | Non-root image running gunicorn |
| `.github/workflows/ci-cd.yml` | Test → build → staging → approval → production |
| `.github/workflows/rollback.yml` | Manual rollback to a previous image tag |
| `scripts/smoke-test.sh` | Post-deploy check against `/health` |
| `infra/setup-azure.sh` | One-time Azure setup (Container Apps + OIDC identity) |

## Run it locally

```bash
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
ruff check . && pytest -q

# optional: run the container
docker build -t two-click-demo --build-arg APP_VERSION=local .
docker run --rm -p 8000:8000 two-click-demo
curl http://localhost:8000/health
```

## Use it as a template

1. Fork or copy this repo to your own GitHub account.
2. **Out of the box** the pipeline runs tests, builds the image and pushes it to GitHub Container Registry. The deploy jobs are skipped until you enable them, so the pipeline stays green.
3. **To enable deployment to Azure Container Apps:**
   1. Log in with `az login` to a subscription you own.
   2. Run `GITHUB_REPO=<owner>/<repo> bash infra/setup-azure.sh`.
   3. Add the repository variables the script prints (including `AZURE_DEPLOY=true`).
   4. In GitHub → Settings → Environments, create `staging` and `production`. On `production`, enable **Required reviewers** and add yourself.
   5. Make the GHCR package public (Packages → your image → visibility) so Container Apps can pull it. For private images, use Azure Container Registry with a managed identity instead.
4. Push to `main`, watch staging deploy, then approve production.

## Cost and cleanup
Azure Container Apps can scale to zero and this demo uses one small replica at most, so cost should be minimal. Check current pricing for your region. Delete everything when you're done:

```bash
az group delete --name rg-two-click-demo --yes
```

## Status of this demo
- ✅ Lint and unit tests pass, locally and in GitHub Actions.
- ✅ Docker image builds and is pushed to GHCR by the pipeline (see the Actions tab).
- ⏳ The staging/production deploy jobs are written but not yet exercised against a live Azure subscription; they are skipped until `AZURE_DEPLOY=true`.
- The Azure setup script follows the Azure CLI docs but should be read before you run it.

## What I'd adapt for your project
The same pattern works for Node/Next.js, other Python apps, or other targets (AWS, a VPS, Kubernetes), with extra stages such as security scans, database migrations or approvals per environment. If you want this set up for your repo, message me with your stack and where it deploys.
