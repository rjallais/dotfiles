# Set GITHUB_TOKEN from gh CLI for aqua, topgrade, and other tools.
# This avoids GitHub API rate limit errors (403) on unauthenticated requests.
# gh manages its own token refresh via keyring; this runs on every shell start.
if not set -q GITHUB_TOKEN; or test -z "$GITHUB_TOKEN"
    set -l _gh_bin (command -s gh 2>/dev/null)
    if test -z "$_gh_bin"; and test -x "$HOME/.local/share/mise/shims/gh"
        set _gh_bin "$HOME/.local/share/mise/shims/gh"
    end
    if test -n "$_gh_bin"
        set -l _gh_token ($_gh_bin auth token 2>/dev/null)
        if test -n "$_gh_token"
            set -gx GITHUB_TOKEN "$_gh_token"
        end
    end
end
