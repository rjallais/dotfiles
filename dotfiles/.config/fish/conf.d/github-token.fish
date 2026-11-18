# Set GITHUB_TOKEN from gh CLI for aqua, topgrade, and other tools.
# This avoids GitHub API rate limit errors (403) on unauthenticated requests.
# gh manages its own token refresh via keyring; this runs on every shell start.
if command -q gh
    set -l _gh_token (gh auth token 2>/dev/null)
    if test -n "$_gh_token"
        set -gx GITHUB_TOKEN "$_gh_token"
    end
end
