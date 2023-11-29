{
  stdenvNoCC,
  runCommand,
  git,
  git-annex,
  fetchurl,
  isHydra ? true,
}: {
  file ? builtins.baseNameOf url,
  repo ? "${builtins.getEnv "HOME"}/nur-packages/downloads",
  name ? builtins.baseNameOf url,
  recursiveHash ? false,
  sha256,
  url,
}:
/*
  if isHydra then
runCommand name ({
  nativeBuildInputs = [ git git-annex ];

  outputHashAlgo = "sha256";
  outputHash = sha256;
  outputHashMode = if recursiveHash then "recursive" else "flat";

  preferLocalBuild = true;

}) ''
(
    set -eufx -o pipefail
    if test -d ${repo}; then
      ( cd ${repo}
        git annex get ${file}
        cp ${file} $out
      )
    fi
)
''
#else
*/
fetchurl {inherit name recursiveHash sha256 url;}
