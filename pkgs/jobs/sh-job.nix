{ stdenvNoCC, lib, writeScript, runCommand }:
{ name
, script ? ""
, buildInputs ? []
, scratch ? null
, ...
}@args: let
  define_job_basename_sh = name: ''job_out=$(basename $out); job_basename=${name}-''${job_out:0:12}'';
  job = writeScript "${name}.sh" ''
    #!${stdenvNoCC.shell}

    source ${stdenvNoCC}/setup
    set -ue -o pipefail
    runHook jobSetup
    set -x
    ${script}
    set +x
    runHook jobDone
    echo 'done'
  '';
  extraArgs = removeAttrs args ["name" "buildInputs" "outputs" "script" "scratch"];
in builtins.trace extraArgs
  runCommand name (extraArgs // {
         inherit buildInputs;
         outputs = [ "out" ]
           ++ lib.optional (scratch !=null) "scratch";
  }) ''
  failureHooks+=(_benchFail)
  _benchFail() {
    cat $out/job
  }
  set -xuef -o pipefail
  mkdir $out
  ${define_job_basename_sh name}
  ${lib.optionalString (scratch !=null) ''
    echo "${scratch}/$job_basename" > $scratch
    scratch_=$(cat $scratch)
    mkdir -p $scratch_; cd $scratch_
  ''}
  ${job} 2>&1 | tee $out/job
  echo "job has run"
  set +x
''

