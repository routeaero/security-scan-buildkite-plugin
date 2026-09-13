# security-scan-buildkite-plugin

One step in every RouteAero pipeline. It runs [trivy](https://github.com/aquasecurity/trivy)
over the checkout and finds three things:

- **dependency vulnerabilities** in `go.mod` / `go.sum` and `package-lock.json`,
- **secrets** committed to the tree (keys, tokens, private keys),
- **misconfigurations** in `Dockerfile`, Kubernetes manifests and Terraform.

Every build gets a report: a table on the build page (Buildkite annotation,
context `security-scan`) and two artifacts, `security-report.json` (everything)
and `security-report.md` (the same table you see on the page).

## Use it

```yaml
  - label: ":shield: Security scan"
    key: "security"
    plugins:
      - routeaero/security-scan#v1.0.0: {}
```

Add `security` to the `depends_on` of the step that builds or promotes, so a red
scan stops the deploy the way `vuln` (govulncheck) already does. Go services
keep govulncheck: it is call-graph aware and finds Go issues trivy reports more
noisily; this plugin adds what govulncheck cannot see (npm, secrets, IaC).

Options (all optional):

| Option | Default | Meaning |
|---|---|---|
| `floor-file` | `.buildkite/security-floor` | the misconfiguration ratchet, see below |
| `skip-dirs` | `vendor,node_modules,.git,ios,android` | directories trivy does not walk |
| `image` | `aquasec/trivy@sha256:62b1e6…` (0.74.0) | the scanner, digest-pinned; roll forward on purpose, never by tag |

## The gate

| Finding | Result |
|---|---|
| any secret in the tree | **fail** |
| a CRITICAL or HIGH vulnerability **with a fix available** | **fail** |
| a vulnerability with no fix yet | reported, not failed |
| misconfigurations above the repo's floor | **fail** |
| misconfigurations at or below the floor | reported as a warning |

**The floor is a ratchet**, the same shape as the coverage floor. The repo's
`.buildkite/security-floor` holds the highest CRITICAL and HIGH misconfiguration
counts allowed:

```sh
floor_critical=0
floor_high=4
```

A build that finds more than that fails. When a fix lands, lower the floor in
the same PR. The floor never goes up. A missing file means `0 0`.

**An accepted risk is written down, with an expiry.** Put it in the repo's
`.trivyignore.yaml` (trivy's own format) and say why and until when:

```yaml
misconfigurations:
  - id: AWS-0098
    statement: "Secrets Manager with the AWS-managed key; a customer key is a prod decision (roadmap item 12)"
    expired_at: 2026-12-31
```

Trivy drops the ignore after the date, and the finding comes back. That is the
point: silence has a deadline.

## Why a plugin

The scan is the same everywhere, so its script lives once, here, and each
pipeline carries three lines. Changing the scanner version or the report is one
PR here and a tag bump in the pipelines that want it. The floor and the ignore
file stay in each repo, because they are that repo's state.

## Proven, not assumed

`tests/run.sh` is this plugin's canary (ADR-0004): it runs the hook against a
tree with a planted fake AWS key and requires the gate to **fail**, then against
a clean tree and requires it to **pass**. Its own pipeline runs that on every
push, with shellcheck and the Buildkite plugin linter.

## Releasing

Tags are immutable. Bump the version in the pipelines that consume it; never
move a tag.

```sh
git tag v1.x.y && git push origin v1.x.y
```
