# Clocks

A stupid experiment in which we use Lamport timestamp's algorithm to random shuffle a sentence.

We build a in-memory data store where every node support insertions in a distributed fashion. Nodes accept insertions and replicate their logs via a pub/sub messaging infrastructure.

Lamport timestamp's algorithm allows all our nodes to eventually agree, in a distrubuted fashion, on the order of insertions. All nodes therefore agree on a random shuffling of the words inserted in the system.
