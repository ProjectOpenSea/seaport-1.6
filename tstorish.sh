# remove old dump
rm -f seaport.dump
# spin up anvil and prepare to dump state
anvil --hardfork shanghai --dump-state ./seaport.dump &
# save pid to kill later
pid=$!
# execute foundry script to deploy seaport
FOUNDRY_PROFILE=optimized forge script TstorishDeploy --rpc-url http://localhost:8545 --slow --skip-simulation --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
# get code of 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
seaport=$(curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getCode","params":["0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", "latest"],"id":1}' -H "Content-Type: application/json" http://localhost:8545)
# exit anvil
echo $seaport
kill $pid
anvil --hardfork shanghai &
# call setCode on the 0xe7f address with the $seaport var
curl -X POST --data '{"jsonrpc":"2.0","method":"anvil_setCode","params":["0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512", '"$seaport"'],"id":1}' -H "Content-Type: application/json" http://localhost:8545
# call setCode on the 0xcafac3dd18ac6c6e92c921884f9e4176737c052c address with 0x3d5c
curl -X POST --data '{"jsonrpc":"2.0","method":"anvil_setCode","params":["0xcafac3dd18ac6c6e92c921884f9e4176737c052c", "0x3d5c"],"id":1}' -H "Content-Type: application/json" http://localhost:8545
# save pid to kill later
pid=$!
# mine a block
# execute Tstorish test
FOUNDRY_PROFILE=tstorish forge test -vvvv --fork-url http://localhost:8545
# get exit code of previous
exit_code=$?
# kill anvil
kill $pid
# exit with exit code of previous
exit $exit_code
