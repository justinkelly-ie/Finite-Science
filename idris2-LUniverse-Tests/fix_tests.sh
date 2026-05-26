for testdir in adaptive-cycle-pipeline adaptive-cycle-findings adaptive-cycle-chemistry adaptive-cycle-scales; do
  cd properties/$testdir
  cat << 'RUN' > run
#!/bin/sh
rm -rf build/
pack -q install-deps test.ipkg
pack -q run test.ipkg
rm -rf build/
RUN
  chmod +x run
  toolbox run -c fedora-toolbox-44 bash -c "./run" > expected
  cd ../..
done
