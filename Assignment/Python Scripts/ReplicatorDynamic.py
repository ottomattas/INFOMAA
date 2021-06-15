# NOTE: Execute the replicator dynamic on the grand table also visualize it as a graph.
# You may change everything in this file.

from typing import List
import matplotlib as plt

from GrandTable import GrandTable


# Proportions you will have to use:
uniform_with_own_strat = [1/9] * 9
uniform_without_own_strat = [1/8] * 8
non_uniform_with_own_strat = [0.12, 0.08, 0.06, 0.15, 0.05, 0.21, 0.06, 0.09, 0.18]
non_uniform_without_own_strat = [0.22, 0.19, 0.04, 0.06, 0.13, 0.10, 0.05, 0.21]


class ReplicatorDynamic:
    def __init__(self, start_proportions: List[float], grand_table: GrandTable):
        pass

    def to_graph(self):
        """Visualize the evolution of proportions."""
        pass
