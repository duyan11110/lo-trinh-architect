"""Shuffle the options of single/multi/truefalse/scenario questions in place.

Deterministic: the permutation for a question comes from random.Random(question id).
After the shuffle, option ids are a, b, c, ... in their new order again; `answer`,
the explanation keys and "(x)" references inside the question's own texts are
mapped to the new ids. Every byte outside the edited spans is kept.

usage: python shuffle_options.py [--dry] FILE...
"""
import json
import random
import re
import sys

SHUFFLED_TYPES = {'single', 'multi', 'scenario'}  # truefalse keeps its fixed true/false slots (Q09)


# --- a tiny JSON parser that remembers where every value sits in the text ---

class Node:
    def __init__(self, kind, start, end, value=None, items=None):
        self.kind, self.start, self.end = kind, start, end
        self.value = value          # python value for scalars
        self.items = items          # list[Node] for arrays, list[(keyNode, Node)] for objects


_WS = re.compile(r'[ \t\r\n]*')
_NUM = re.compile(r'-?(0|[1-9]\d*)(\.\d+)?([eE][+-]?\d+)?')


def parse(t, i=0):
    i = _WS.match(t, i).end()
    c = t[i]
    if c == '{':
        start, i, items = i, i + 1, []
        i = _WS.match(t, i).end()
        if t[i] == '}':
            return Node('obj', start, i + 1, items=items), i + 1
        while True:
            k, i = parse(t, i)
            i = _WS.match(t, i).end()
            assert t[i] == ':'
            v, i = parse(t, i + 1)
            items.append((k, v))
            i = _WS.match(t, i).end()
            if t[i] == ',':
                i += 1
                continue
            assert t[i] == '}'
            return Node('obj', start, i + 1, items=items), i + 1
    if c == '[':
        start, i, items = i, i + 1, []
        i = _WS.match(t, i).end()
        if t[i] == ']':
            return Node('arr', start, i + 1, items=items), i + 1
        while True:
            v, i = parse(t, i)
            items.append(v)
            i = _WS.match(t, i).end()
            if t[i] == ',':
                i += 1
                continue
            assert t[i] == ']'
            return Node('arr', start, i + 1, items=items), i + 1
    if c == '"':
        j = i + 1
        while t[j] != '"':
            j += 2 if t[j] == '\\' else 1
        return Node('str', i, j + 1, value=json.loads(t[i:j + 1])), j + 1
    for lit, val in (('true', True), ('false', False), ('null', None)):
        if t.startswith(lit, i):
            return Node('lit', i, i + len(lit), value=val), i + len(lit)
    m = _NUM.match(t, i)
    return Node('num', i, m.end(), value=json.loads(m.group(0))), m.end()


def get(obj, key):
    for k, v in obj.items:
        if k.value == key:
            return v
    return None


def string_nodes(node):
    """Every string value (not key) under node."""
    if node.kind == 'str':
        yield node
    elif node.kind == 'arr':
        for x in node.items:
            yield from string_nodes(x)
    elif node.kind == 'obj':
        for _, v in node.items:
            yield from string_nodes(v)


def js(s):
    return json.dumps(s, ensure_ascii=False)


# --- the shuffle ---

def plan_question(t, q):
    """Return a list of (start, end, replacement) edits for one question node."""
    qtype = get(q, 'type').value
    opts = get(q, 'options')
    if qtype not in SHUFFLED_TYPES or opts is None or len(opts.items) < 2:
        return []
    qid = get(q, 'id').value
    old_ids = [get(o, 'id').value for o in opts.items]
    if sorted(old_ids) != [chr(97 + k) for k in range(len(old_ids))]:
        raise ValueError(f'{qid}: option ids are not a, b, c…: {old_ids}')
    perm = list(range(len(old_ids)))
    rnd = random.Random(qid)
    answer = [a.value for a in get(q, 'answer').items]
    rnd.shuffle(perm)
    if [old_ids[k] for k in perm] == [chr(97 + k) for k in range(len(perm))]:
        return []
    # new slot k holds old option perm[k]; old id x becomes new id mapping[x]
    mapping = {old_ids[perm[k]]: chr(97 + k) for k in range(len(perm))}

    edits = []
    # options: move each option's text into its new slot, with its id rewritten
    for k, slot in enumerate(opts.items):
        src = opts.items[perm[k]]
        text = t[src.start:src.end]
        idn = get(src, 'id')
        rel_s, rel_e = idn.start - src.start, idn.end - src.start
        text = text[:rel_s] + js(chr(97 + k)) + text[rel_e:]
        # "(x)" references inside this option's own strings
        text = _map_refs_in_span(t, src, text, mapping, offset=src.start, skip=idn)
        edits.append((slot.start, slot.end, text))
    # answer: new ids, sorted
    ans = get(q, 'answer')
    new_answer = sorted(mapping[a] for a in answer)
    for node, val in zip(ans.items, new_answer):
        edits.append((node.start, node.end, js(val)))
    # explanation keys + "(x)" references in explanation, question, context
    expl = get(q, 'explanation')
    if expl is not None:
        for _, lang in expl.items:
            for k, v in lang.items:
                if k.value in mapping:
                    edits.append((k.start, k.end, js(mapping[k.value])))
    for field in ('explanation', 'question', 'context'):
        node = get(q, field)
        if node is None:
            continue
        for s in string_nodes(node):
            new = _map_refs(s.value, mapping)
            if new != s.value:
                edits.append((s.start, s.end, js(new)))
    return edits


_REF = re.compile(r'\(([a-f])\)')


def _map_refs(s, mapping):
    return _REF.sub(lambda m: f'({mapping.get(m.group(1), m.group(1))})', s)


def _map_refs_in_span(t, node, text, mapping, offset, skip):
    # rewrite string values of an option object (other than its id) inside `text`
    out, last = [], 0
    for s in string_nodes(node):
        if s is skip:
            continue
        new = _map_refs(s.value, mapping)
        if new == s.value:
            continue
        a, b = s.start - offset, s.end - offset
        # the id may have changed length? ids are one letter, so offsets hold
        out.append(text[last:a])
        out.append(js(new))
        last = b
    out.append(text[last:])
    return ''.join(out)


def apply_edits(t, edits):
    edits.sort(key=lambda e: e[0])
    out, last = [], 0
    for s, e, rep in edits:
        assert s >= last, 'overlapping edits'
        out.append(t[last:s])
        out.append(rep)
        last = e
    out.append(t[last:])
    return ''.join(out)


def shuffle_file(path, dry=False):
    raw = open(path, encoding='utf-8', newline='').read()
    bom = raw.startswith('﻿')
    t = raw[1:] if bom else raw
    root, _ = parse(t)
    edits = []
    for q in get(root, 'questions').items:
        edits.extend(plan_question(t, q))
    if not edits:
        return 0
    new = apply_edits(t, edits)
    before, after = json.loads(t), json.loads(new)
    _check(before, after)
    if not dry:
        open(path, 'w', encoding='utf-8', newline='').write(('﻿' if bom else '') + new)
    return sum(1 for q in after['questions'] if q['type'] in SHUFFLED_TYPES)


def _check(before, after):
    """Same questions, same option texts as sets, same correct texts."""
    for qb, qa in zip(before['questions'], after['questions']):
        assert qb['id'] == qa['id']
        if 'options' not in qb or qb['type'] not in SHUFFLED_TYPES:
            assert qb == qa
            continue
        tb = {o['id']: o['en'] for o in qb['options']}
        ta = {o['id']: o['en'] for o in qa['options']}
        assert sorted(tb.values()) == sorted(ta.values()), qb['id']
        assert sorted(tb[a] for a in qb['answer']) == sorted(ta[a] for a in qa['answer']), qb['id']
        assert [o['id'] for o in qa['options']] == [chr(97 + k) for k in range(len(qa['options']))], qa['id']
        for lang in ('en', 'vi'):
            eb, ea = qb['explanation'][lang], qa['explanation'][lang]
            assert eb.get('correct') is not None and len(eb) == len(ea), qb['id']
            for oid, txt in tb.items():
                if oid in eb:
                    new_id = next(k for k, v in ta.items() if v == txt)
                    assert ea.get(new_id) is not None, (qa['id'], new_id)


if __name__ == '__main__':
    args = sys.argv[1:]
    dry = '--dry' in args
    files = [a for a in args if a != '--dry']
    total = 0
    for f in files:
        total += shuffle_file(f, dry)
    print(f'{len(files)} files, {total} shuffled-type questions{" (dry run)" if dry else ""}')
