import sys
import os
# simple python script to submit to the cluster
MATCH_SEARCH_PATH="/nfs/gs/home/aklammer/crux/results/paper-figure/q-value/match_search"

if len(sys.argv) < 3:
  raise SystemExit, "%s: <mass-range-file> [mass-search args]*" % sys.argv[0]

mass_range_file = sys.argv[1]
match_search_args = sys.argv[2:]
fh = open(mass_range_file)
cwd = os.getcwd()
for line in fh:
  start, end = line.rstrip("\n").split()
  cmdFile = os.getcwd() + os.sep + "match_search_%s_%s" % (start, end)
  outFh = open(cmdFile, "w")
  cmd = "%s --spectrum-min-mass %.3f --spectrum-max-mass %.3f %s \n" \
     % (MATCH_SEARCH_PATH, float(start), float(end), " ".join(match_search_args))
  outFh.write(cmd)
  outFh.close()
  clusterCmd = "qsub -o %s -e %s %s" % (cwd, cwd, cmdFile)
  print clusterCmd

