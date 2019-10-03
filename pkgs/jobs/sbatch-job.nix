{ stdenvNoCC, lib, writeScript, runCommand, scontrol_show }:
{ name
, script ? ""
, buildInputs ? []
, scratch ? null
, ...
}@args: let
  define_job_basename_sh = name: ''job_out=$(basename $out); job_basename=${name}-''${job_out:0:12}'';

  args_names = builtins.attrNames args;
  options_args = builtins.filter (x: (builtins.match "^sbatch-.*" x) !=null) args_names;

  job = writeScript "${name}.sbatch" ''
    #!${stdenvNoCC.shell}
    ${lib.concatMapStrings (n: let
        n_ = builtins.head (builtins.match "^sbatch-(.*)" n);
      in if lib.isBool args.${n} then
         lib.optionalString args.${n} "#SBATCH --${n_}\n"
    else "#SBATCH --${n_}=${args.${n}}\n") (options_args)}

    source ${stdenvNoCC}/setup
    set -ue -o pipefail
    runHook jobSetup
    set -x
    ${script}
    set +x
    runHook jobDone
    echo 'done'
  '';
  extraArgs = removeAttrs args (["name" "buildInputs" "outputs" "script" "scratch"] ++ options_args);
in builtins.trace extraArgs
   runCommand name (extraArgs // {
         inherit buildInputs;
         outputs = [ "out" ] ++ lib.optional (scratch !=null) "scratch";
         impureEnvVars = [ "KRB5CCNAME" ];
  }) ''
  failureHooks+=(_benchFail)
  _benchFail() {
    cat $out/job
    exit 0
  }
  set -xuef -o pipefail
  mkdir $out
  ${define_job_basename_sh name}
  ${lib.optionalString (scratch !=null) ''
    echo "${scratch}/$job_basename" > $scratch
    scratch_=$(cat $scratch)
    mkdir -p $scratch_; cd $scratch_
  ''}
  cancel() {
    scancel $(squeue -o %i -h -n $job_basename)
  }
  echo 'scancel $(squeue -o %i -h -n '$job_basename')'
  trap "cancel" USR1 INT TERM

  /usr/bin/env | /usr/bin/sort

  id=$(/usr/bin/sbatch --job-name=$job_basename --parsable --wait -o $out/job ${job})
  id=$(echo $id | awk '{ print $NF }')
  /usr/bin/scontrol show JobId=$id || true
  echo "job $id has run"
  cat $out/job

  set +x
''
