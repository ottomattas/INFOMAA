# Note: You may not change methods in the Strategy class, nor their input parameters.
# Information about the entire game is given in the *initialize* method, as it gets the entire MatrixSuite.
# During play the payoff matrix doesn't change so if your strategy needs that information,
#  you can save it to Class attributes of your strategy. (like the *actions* attribute of Aselect)

import abc
import random
from typing import List

import MatrixSuite
from MatrixSuite import Action, Payoff


class Strategy(metaclass=abc.ABCMeta):
    """Abstract representation of a what a Strategy should minimally implement.

    Class attributes:
        name: A string representing the name of the strategy.
    """
    name: str

    def __repr__(self) -> str:
        """The string representation of a strategy is just it's name.
        So it you call **print()** it will output the name.
        """
        return self.name

    @abc.abstractmethod
    def initialize(self, matrix_suite: MatrixSuite, player: str) -> None:
        """Initialize/reset the strategy with a new game.
        :param matrix_suite: The current MatrixSuite,
        so the strategy can extract the information it needs from the payoff matrix.
        :param player: A string of either 'row' or 'col',
        representing which player the strategy is currently playing as.
        """
        pass

    @abc.abstractmethod
    def get_action(self, round_: int) -> Action:
        """Calculate the action for this round.
        :param round_: The current round number.
        """
        pass

    @abc.abstractmethod
    def update(self, round_: int, action: Action, payoff: Payoff, opp_action: Action) -> None:
        """Update the strategy with the result of this round.
        :param round_: The current round number.
        :param action: The action this strategy played this round.
        :param payoff: The payoff this strategy received this round.
        :param opp_action: The action the opposing strategy played this round.
        """
        pass


# As an example we have implemented the first strategy for you.


class Aselect(Strategy):
    """Implements the Aselect (random play) algorithm."""
    actions: List[Action]

    def __init__(self):
        """The __init__ method will be called when you create an object.
        This should set the name of the strategy and handle any additional parameters.

        Example:
            To create an object of the Aselect class you use, "Aselect()"

            If you want to pass it parameters on creation, e.g. "Aselect(0.1)",

            you need to modify "__init__(self)" to "__init__(self, x: float)",
            and you probably also want to save "x", or whatever you name it,
            to a class attribute, so you can use it in other methods.
            """
        self.name = "Aselect"

    def initialize(self, matrix_suite: MatrixSuite, player: str) -> None:
        """Just save the actions as that's the only thing we need."""
        self.actions = matrix_suite.get_actions(player)

    def get_action(self, round_: int) -> Action:
        """Pick the next action randomly from the possible actions."""
        return random.choice(self.actions)

    def update(self, round_: int, action: Action, payoff: Payoff, opp_action: Action) -> None:
        """Aselect has no update mechanic."""
        pass


# Add the other strategies below

