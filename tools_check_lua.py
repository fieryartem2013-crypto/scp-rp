import sys, glob, re
from luaparser import ast as last

CONT = re.compile(r'(?<![\w:])\bcontinue\b(?!\s*=)')
def preprocess(src):
    # GMod's Lua supports `continue`; plain Lua/luaparser does not.
    return CONT.sub('__continue__()', src)

files = sorted(glob.glob("garrysmod/gamemodes/darkrp/**/*.lua", recursive=True))
bad = 0
for f in files:
    src = open(f, encoding="utf-8").read()
    try:
        tree = last.parse(preprocess(src))
        print(f"OK   {f}")
    except Exception as e:
        bad += 1
        print(f"FAIL {f}\n     {type(e).__name__}: {str(e)[:250]}")
print(f"\n{len(files)} files, {bad} failed")
sys.exit(1 if bad else 0)
