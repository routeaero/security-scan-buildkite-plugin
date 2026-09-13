{{- /* Markdown report for a Buildkite annotation and artifact. One JSON in, one .md out. */ -}}
{{- $vc := 0 }}{{- $vh := 0 }}{{- $vfh := 0 }}{{- $vm := 0 }}{{- $vl := 0 }}{{- $vf := 0 }}
{{- $mc := 0 }}{{- $mh := 0 }}{{- $mm := 0 }}{{- $ml := 0 }}{{- $s := 0 }}
{{- range . }}
  {{- range .Vulnerabilities }}
    {{- if eq .Severity "CRITICAL" }}{{ $vc = add $vc 1 }}{{ else if eq .Severity "HIGH" }}{{ $vh = add $vh 1 }}{{ else if eq .Severity "MEDIUM" }}{{ $vm = add $vm 1 }}{{ else }}{{ $vl = add $vl 1 }}{{ end }}
    {{- if .FixedVersion }}{{ $vf = add $vf 1 }}{{ if or (eq .Severity "CRITICAL") (eq .Severity "HIGH") }}{{ $vfh = add $vfh 1 }}{{ end }}{{ end }}
  {{- end }}
  {{- range .Misconfigurations }}
    {{- if eq .Severity "CRITICAL" }}{{ $mc = add $mc 1 }}{{ else if eq .Severity "HIGH" }}{{ $mh = add $mh 1 }}{{ else if eq .Severity "MEDIUM" }}{{ $mm = add $mm 1 }}{{ else }}{{ $ml = add $ml 1 }}{{ end }}
  {{- end }}
  {{- range .Secrets }}{{ $s = add $s 1 }}{{ end }}
{{- end }}
## Security scan

| Class | Critical | High | Medium | Low | Note |
|---|---|---|---|---|---|
| Dependency vulnerabilities | {{ $vc }} | {{ $vh }} | {{ $vm }} | {{ $vl }} | {{ $vf }} with a fix available |
| Misconfigurations (Dockerfile, Kubernetes, Terraform) | {{ $mc }} | {{ $mh }} | {{ $mm }} | {{ $ml }} | ratchet: must not exceed `.buildkite/security-floor` |
| Secrets in the tree | {{ $s }} | | | | any secret fails the build |

SUMMARY vuln_critical={{ $vc }} vuln_high={{ $vh }} vuln_fixable={{ $vf }} vuln_fixable_high={{ $vfh }} misconf_critical={{ $mc }} misconf_high={{ $mh }} secrets={{ $s }}
{{- range . }}
{{- if .Vulnerabilities }}

### Vulnerabilities — `{{ .Target }}`

| ID | Severity | Package | Installed | Fixed | Title |
|---|---|---|---|---|---|
{{- range .Vulnerabilities }}
| {{ .VulnerabilityID }} | {{ .Severity }} | `{{ .PkgName }}` | {{ .InstalledVersion }} | {{ if .FixedVersion }}{{ .FixedVersion }}{{ else }}none yet{{ end }} | {{ .Title | abbrev 70 }} |
{{- end }}
{{- end }}
{{- if .Misconfigurations }}

### Misconfigurations — `{{ .Target }}`

| ID | Severity | Line | Finding | Fix |
|---|---|---|---|---|
{{- range .Misconfigurations }}
| {{ .ID }} | {{ .Severity }} | {{ if .CauseMetadata }}{{ .CauseMetadata.StartLine }}{{ end }} | {{ .Title | abbrev 70 }} | {{ .Resolution | abbrev 70 }} |
{{- end }}
{{- end }}
{{- if .Secrets }}

### Secrets — `{{ .Target }}`

| Rule | Severity | Line | What |
|---|---|---|---|
{{- range .Secrets }}
| {{ .RuleID }} | {{ .Severity }} | {{ .StartLine }} | {{ .Title }} |
{{- end }}
{{- end }}
{{- end }}
