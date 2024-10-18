# Define the targets
.PHONY: test_all

test: test_fork test_invariant test_benchmark

test_fork:
	@forge test --mc Fork --fork-url $(FORK_URL)

test_invariant:
	@forge test --mc Invariant

test_benchmark:
	@forge test --mc Benchark --fork-url $(FORK_URL)