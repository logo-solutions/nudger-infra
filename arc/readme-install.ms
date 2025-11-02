cd ~/nudger-infra/arc && ls
ls ~/nudger-infra/arc/scripts/
export BW_SESSION=$(bw unlock --raw)
 ~/nudger-infra/arc/scripts/00_fetch_from_bw.sh
cat /etc/arc/arc_env.sh
./scripts/20_install_arc.sh
k get all -n arc
./scripts/35_verify_arc_github.sh
./scripts/36_verify_arc_full.sh

