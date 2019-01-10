# see jobs/default.nix
{ pkgs
, date ? "20181210"
}:
with pkgs;

let
  define_job_basename_sh = name: ''job_out=$(basename $out); job_basename=${name}-''${job_out:0:12}'';
  sbatch = rec {
    job_template = name: options: script: writeScript "${name}.sbatch" ''
      #!${stdenv.shell}
      ${lib.concatMapStrings (n: if lib.isBool options.${n} then
           lib.optionalString options.${n} "#SBATCH --${n}\n"
      else "#SBATCH --${n}=${options.${n}}\n") (lib.attrNames options)}

      source ${stdenvNoCC}/setup
      set -ue -o pipefail
      runHook jobSetup
      set -x
      ${script}
      set +x
      runHook jobDone
      echo 'done'
    '';

    runJob = { name
             , job ? job_template name options script
             , script ? ""
             , options ? {}
             , buildInputs ? []
             }: let
      in runCommand name { buildInputs = [
        /*benchPrintEnvironmentHook*/
      ] ++ buildInputs; } ''
      failureHooks+=(_benchFail)
      _benchFail() {
        cat $out/job
      }
      set -xuef -o pipefail
      mkdir $out
      ${define_job_basename_sh name}
      cancel() {
        scancel $(squeue -o %i -h -n $job_basename)
      }
      echo 'scancel $(squeue -o %i -h -n '$job_basename')'
      trap "cancel" USR1 INT TERM

      id=$(/usr/bin/sbatch --job-name=$job_basename --parsable --wait -o $out/job ${job})
      /usr/bin/scontrol show JobId=$id
      echo "job $id has run"
      cat $out/job

      set +x
    '';

    scontrol_show = keyword: condition: let
        json_file="${date}-${keyword}.json";
      in runCommand "${json_file}" { buildInputs = [ coreutils jq ]; } ''
      set -xeufo pipefail
      echo "{" >${json_file}
      /usr/bin/scontrol show -o ${keyword}${condition} | sed -e 's@^\(${keyword}Name\|${keyword}\)=\([^ ]\+\)@"\2": {@'   \
                                                 -e 's@ \([A-Za-z0-9]\+\)=@","\1": "@g' \
                                                 -e 's@$@"},@' |tee -a ${json_file}
      echo "}" >> ${json_file}

      # cleanup
      sed -i -e 's@{",@{@' ${json_file}
      sed -i -e 's@,}@}@' ${json_file}
      n=$(wc -l ${json_file} | awk '{print $1}')
      n=$((n-1))
      sed -i -e "$n s@},@}@" ${json_file}

      # format json file
      cat ${json_file} | jq '.' > $out
      set +x
    '';

    partitions_json = scontrol_show "PartitionName" "";
    nodes_json      = scontrol_show "Node" ""; #"=genji500";

    partitions = let
      extendNodeSet = p/*name*/: p_/*value*/:
        p_ // rec {
          name = p;
          NodeSet_ = lib.splitString " " (builtins.readFile (runCommand "nodeset-${p}" {} ''
            set -xeufo pipefail
            nodeset=$(/usr/bin/nodeset -e -S' ' -O '%s' ${p_.Nodes})
            echo -n $nodeset > $out
            set +x
          ''));
          # keep only available nodes
          NodeSet = filtered_nodes NodeSet_;
        };
      in lib.mapAttrs extendNodeSet (builtins.fromJSON (builtins.readFile partitions_json));

    nodes = builtins.fromJSON (builtins.readFile nodes_json);

    filtered_nodes = node_names: builtins.filter (n:
    let n_ = builtins.getAttr n nodes; in n_.State != "DOWN"
                                       && n_.State != "DOWN*"
                                       && n_.State != "DOWN*+DRAIN"
                                       && n_.State != "IDLE+DRAIN"
                                       && n_.State != "RESERVED"
                                       && n_.State != "RESERVED+DRAIN"
       )
       node_names;
  };

in sbatch
