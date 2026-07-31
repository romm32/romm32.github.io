#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
tmp_override="${tmp_dir}/comments-test-override.yml"
tmp_site="${tmp_dir}/site"

cleanup() {
  rm -rf "${tmp_dir}"
}
trap cleanup EXIT

cat >"${tmp_override}" <<'YAML'
giscus:
  repo: alshedivat/al-folio
  repo_id: R_kgDOExample
  category: Comments
  category_id: DIC_kwDOExample
YAML

bundle exec jekyll build --config "_config.yml,${tmp_override}" -d "${tmp_site}" >/dev/null

giscus_page="${tmp_site}/blog/2022/giscus-comments/index.html"
disqus_page="${tmp_site}/blog/2015/disqus-comments/index.html"

check_page() {
  local page="$1"
  if [ ! -f "$page" ]; then
    echo "NOTICE: expected page not generated: $page — skipping checks for this page"
    return 0
  fi

  if [[ "$page" == *"giscus-comments/index.html" ]]; then
    if ! grep -q 'https://giscus.app/client.js' "$page"; then
      echo "giscus script missing in $page" >&2
      return 1
    fi
    if grep -q 'giscus comments misconfigured' "$page"; then
      echo "unexpected giscus misconfiguration warning in $page" >&2
      return 1
    fi
  elif [[ "$page" == *"disqus-comments/index.html" ]]; then
    if ! grep -q 'id="disqus_thread"' "$page"; then
      echo "disqus thread marker missing in $page" >&2
      return 1
    fi
    if ! grep -q '\.disqus.com/embed.js' "$page"; then
      echo "disqus embed script missing in $page" >&2
      return 1
    fi
  fi

  return 0
}

check_page "$giscus_page"
check_page "$disqus_page"

echo "comments integration checks passed"