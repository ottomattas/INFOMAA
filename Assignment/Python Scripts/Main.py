# Note: From this script the program can be run.
# You may change everything about this file.

from MatrixSuite import FixedMatrixSuite
import Strategies
import Game
from GrandTable import GrandTable
from ReplicatorDynamic import ReplicatorDynamic
import Nash

# Output some basic things to show how to call the classes.
matrix_suite = FixedMatrixSuite()
print(matrix_suite)
strategies = [Strategies.Aselect(), Strategies.Aselect(), Strategies.Aselect()]
print(strategies)
grand_table = GrandTable(matrix_suite, strategies, 9, 1000)
print(grand_table)

# Example of how to test a strategy:
matrix_suite = FixedMatrixSuite()  # Create a matrix suite

strat = Strategies.Aselect()  # Create the strategy you want to test.

strat.initialize(matrix_suite, "row")  # Initialise it with the game suite and as either "row" or "col" player.

action = strat.get_action(1)  # Get the next action
print("Strategy plays action:" + action.__repr__())

strat.update(1, action, 1.5, 1)  # Update the strategy with a fake payoff and opponent action.
# Now you might want to look at the class attributes of the strategy,
# which you can call the same as functions, just without any parentheses.
print("Aselect actions:")
print(strat.actions)
print()


# Test to see if gambit runs properly, see Section 5 of the assignment and Nash.py
m = [[3, 0, 5],
     [1, 0, 1],
     [3, 1, 3]]
print("Gambit test result:")
Nash.run_gambit(strategies, m)
# The output should be this:
# ======================|
#  Aselect: 1.00 | 1.00 |
#  Aselect: ---- | ---- |
#  Aselect: ---- | ---- |
# ======================|
#  Aselect: 1.00 | ---- |
#  Aselect: ---- | ---- |
#  Aselect: ---- | 1.00 |
# ======================|
#  Aselect: ---- | 1.00 |
#  Aselect: ---- | ---- |
#  Aselect: 1.00 | ---- |
# ======================|
