# exit on any failure
set -e
# remove old dump
rm -f seaport.dump
# spin up anvil and prepare to dump state
anvil --hardfork shanghai --dump-state ./seaport.dump &
# save pid to kill later
pid=$!
# execute foundry script to deploy seaport
FOUNDRY_PROFILE=optimized forge script TstorishDeploy --rpc-url http://localhost:8545 --slow --skip-simulation --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
# get code of 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
seaport=$(curl -sX POST --data '{"jsonrpc":"2.0","method":"eth_getCode","params":["0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", "latest"],"id":1}' -H "Content-Type: application/json" http://localhost:8545 | jq '.result')
# execute first Tstorish test
FOUNDRY_PROFILE=tstorishLegacy forge test --match-test test_preActivate -vvvv --fork-url http://localhost:8545 --evm-version shanghai
# exit anvil
if kill -0 $pid 2>/dev/null; then
    kill $pid
    echo ">>> Shutting down shanghai anvil"
else
    echo ">>> Unable to locate shanghai anvil PID"
fi
anvil --hardfork shanghai &
# save pid to kill later
pid=$!
# wait for anvil to warm up
sleep 1
# call setCode on the 0xe7f address with the $seaport var
curl -sX POST --data '{"jsonrpc":"2.0","method":"anvil_setCode","params":["0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", '"$seaport"'],"id":1}' -H "Content-Type: application/json" http://localhost:8545
# mine a block
# execute second Tstorish test
FOUNDRY_PROFILE=tstorish forge test --match-test test_activate -vvvv --fork-url http://localhost:8545 --evm-version cancun
# get exit code of previous
exit_code=$?
# exit anvil
if kill -0 $pid 2>/dev/null; then
    kill $pid
    echo ">>> Shutting down cancun anvil"
else
    echo ">>> Unable to locate cancun anvil PID"
fi
# exit with exit code of previous
exit $exit_code
