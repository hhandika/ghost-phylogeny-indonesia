"""A small Newick reader and writer with outgroup rooting and ladderizing."""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class Node:
    name: str | None = None
    length: float = 0.0
    support: float | None = None
    children: list["Node"] = field(default_factory=list)
    parent: "Node | None" = None

    @property
    def is_tip(self) -> bool:
        return not self.children

    def tips(self) -> list["Node"]:
        if self.is_tip:
            return [self]
        return [t for c in self.children for t in c.tips()]

    def walk(self):
        yield self
        for c in self.children:
            yield from c.walk()


def parse(text: str) -> Node:
    text = text.strip().rstrip(";")
    pos = 0

    def label() -> str:
        nonlocal pos
        start = pos
        if pos < len(text) and text[pos] == "'":
            end = text.index("'", pos + 1)
            pos = end + 1
            return text[start + 1 : end]
        while pos < len(text) and text[pos] not in ",():;":
            pos += 1
        return text[start:pos].strip()

    def node() -> Node:
        nonlocal pos
        n = Node()
        if text[pos] == "(":
            pos += 1
            while True:
                child = node()
                child.parent = n
                n.children.append(child)
                if text[pos] == ",":
                    pos += 1
                    continue
                if text[pos] == ")":
                    pos += 1
                    break
        name = label()
        if n.children:
            # Internal labels are support values: "95" or "95/0.9" (SH-aLRT/UFBoot).
            if name:
                n.support = float(name.split("/")[-1])
        else:
            n.name = name
        if pos < len(text) and text[pos] == ":":
            pos += 1
            start = pos
            while pos < len(text) and text[pos] not in ",();":
                pos += 1
            n.length = float(text[start:pos])
        return n

    return node()


def write(n: Node) -> str:
    def w(x: Node) -> str:
        s = "(" + ",".join(w(c) for c in x.children) + ")" if x.children else (x.name or "")
        if x.children and x.support is not None:
            s += f"{x.support:g}"
        return s + f":{x.length:.6g}"

    return w(n).rsplit(":", 1)[0] + ";"


def reroot(tree: Node, outgroup: set[str]) -> tuple[Node, bool]:
    """Root on the largest clade made only of outgroup taxa.

    Returns the rooted tree and whether all outgroups formed one clade.
    """
    edges = _undirected(tree)
    all_tips = {t.name for t in tree.tips()}
    best = None
    for a, b, length, support in edges:
        side = _side(edges, a, b)
        for s, (u, v) in ((side, (a, b)), (all_tips - side, (b, a))):
            if s and s <= outgroup and (best is None or len(s) > len(best[0])):
                best = (s, u, v, length, support)
    if best is None:
        return tree, False
    side, u, v, length, support = best
    return _build_rooted(edges, u, v, length, support), side == outgroup


# ---- Undirected representation keeps rerooting simple -----------------------

def _undirected(tree: Node):
    ids = {}
    for i, n in enumerate(tree.walk()):
        ids[id(n)] = (i, n)
    edges = []
    for n in tree.walk():
        for c in n.children:
            edges.append((ids[id(n)][0], ids[id(c)][0], c.length, c.support))
    nodes = {i: n for i, n in ids.values()}
    return _Graph(nodes, edges)


class _Graph(list):
    def __init__(self, nodes, edges):
        super().__init__(edges)
        self.nodes = nodes
        self.adj: dict[int, list[tuple[int, float, float | None]]] = {i: [] for i in nodes}
        for a, b, l, s in edges:
            self.adj[a].append((b, l, s))
            self.adj[b].append((a, l, s))


def _side(g: _Graph, a: int, b: int) -> set[str]:
    """Tip names reachable from b without crossing the a-b edge."""
    out, stack, seen = set(), [b], {a, b}
    while stack:
        x = stack.pop()
        n = g.nodes[x]
        if n.is_tip:
            out.add(n.name)
        for y, _, _ in g.adj[x]:
            if y not in seen:
                seen.add(y)
                stack.append(y)
    return out


def _build_rooted(g: _Graph, u: int, v: int, length: float, support: float | None) -> Node:
    """Root on edge u-v; v's side is the outgroup."""

    def grow(x: int, frm: int, ln: float, sup: float | None) -> Node:
        src = g.nodes[x]
        n = Node(name=src.name, length=ln, support=sup)
        for y, l, s in g.adj[x]:
            if y != frm:
                c = grow(y, x, l, s)
                c.parent = n
                n.children.append(c)
        # A degree-2 node left behind by the old root is collapsed.
        if len(n.children) == 1 and not src.is_tip:
            only = n.children[0]
            only.length += n.length
            only.parent = None
            return only
        if not n.children:
            n.name = src.name
        return n

    root = Node()
    ingroup = grow(u, v, length / 2, support)
    outgroup = grow(v, u, length / 2, None)
    for c in (ingroup, outgroup):
        c.parent = root
        root.children.append(c)
    return root


def ladderize(n: Node) -> None:
    for c in n.children:
        ladderize(c)
    n.children.sort(key=lambda c: len(c.tips()))
