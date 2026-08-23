# fnm is not installed on this machine; guard so fish does not error at startup.
command -q fnm && fnm env --use-on-cd --shell fish | source
