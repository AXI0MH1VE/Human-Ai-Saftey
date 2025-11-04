#!/usr/bin/env python3
import hashlib, sys
seed = open("PROOF/SEED.txt","r",encoding="utf-8").read().splitlines()[0]
print(hashlib.sha256(seed.encode()).hexdigest())