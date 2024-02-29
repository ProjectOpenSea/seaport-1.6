# remove old dump
rm -f seaport.dump
# spin up anvil and prepare to dump state
anvil --hardfork shanghai --dump-state $cwd/seaport.dump &
# save pid to kill later
pid=$!
# execute foundry script to deploy seaport
FOUNDRY_PROFILE=optimized forge script TstorishDeploy --fork-url http://localhost:8545 --slow --skip-simulation --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
# exit anvil
kill $pid
sleep 0.5
# spin up anvil and load dumped state
anvil --hardfork cancun --load-state $cwd/seaport.dump &
# save pid to kill later
pid=$!
# execute Tstorish test
FOUNDRY_PROFILE=tstorish forge test --fork-url http://localhost:8545
# get exit code of previous
exit_code=$?
# kill anvil
kill $pid
# exit with exit code of previous
exit $exit_code
