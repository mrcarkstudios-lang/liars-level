"""Builds scripts/level_data.gd from compact Python level definitions.

Grid is 32 x 18 cells (40 px each). Row 16-17 is the floor, so the player stands on row 15.
Legend
  #  wall            P  player start      D  exit door        F  FAKE door (kills)
  E  runaway door (flees to e,f,g markers)
  ^  spike  v  ceiling spike   h  hidden spike (pops when you walk by)
  o  crumbling floor (falls after you stand on it)   p  shy floor (vanishes when you approach)
  c  ceiling block (drops when you walk under)       i  invisible solid block
  S  liar sign (text from list)  b  button (opens gates)  d  DO-NOT-PRESS button (chaos + opens gates)
  G  gate   C  coin   q  cursed coin (reverses controls)  B  spring
  w/W saw patrolling right/left     x/X saw patrolling down/up
  m/n moving platform right/left    M/N moving platform up/down (2 cells wide, rides the player)
  L  rising lava (anywhere in map)  Y gravity pad (flips gravity)
  K  FAKE level exit (fake 'cleared' screen, then Q appears)    Q  hidden real exit revealed by K
"""
import os

W, H = 32, 18


class Lv:
    def __init__(self, name, world, hint="", signs=None, sol=None, intro=""):
        self.quip = ""
        self.name, self.world, self.hint = name, world, hint
        self.signs = signs or []
        self.sol = sol or []
        self.intro = intro
        self.g = [["."] * W for _ in range(H)]
        self.rect(0, 0, 31, 0)
        self.rect(0, 0, 0, 17)
        self.rect(31, 0, 31, 17)
        self.rect(0, 16, 31, 17)

    def rect(self, c0, r0, c1, r1, ch="#"):
        for r in range(r0, r1 + 1):
            for c in range(c0, c1 + 1):
                self.g[r][c] = ch
        return self

    def put(self, c, r, ch):
        self.g[r][c] = ch
        return self

    def pit(self, c0, c1):
        for c in range(c0, c1 + 1):
            self.g[16][c] = "."
            self.g[17][c] = "."
        return self

    def row(self, r, c0, c1, ch):
        return self.rect(c0, r, c1, r, ch)

    def lines(self):
        for r in range(H):
            assert len(self.g[r]) == W
        return ["".join(r) for r in self.g]


L = []


def lvl(*a, **k):
    x = Lv(*a, **k)
    L.append(x)
    return x


# =============================================================== WORLD 1 : TRUST ISSUES
a = lvl("Honest Start", 1, hint="Spikes hurt. Jump over them.",
        signs=["Arrow keys or A/D to move. Space to jump.", "Spike ahead. Jump over it.", "Nothing here can hurt you."],
        sol=["R540", "JR690", "G", "R1130"])
a.put(2, 15, "P").put(5, 15, "S").put(12, 15, "S").put(15, 15, "^").put(22, 15, "S").put(28, 15, "D")

a = lvl("The Helpful Sign", 1, hint="Walk up to a spot, then jump BEFORE the floor does something.",
        signs=["The floor is perfectly safe. Walk.", "Trust me.", "Yes. Still safe.", "This spike is real. Not a trick."],
        sol=["R350", "JR540", "G", "R590", "JR780", "G", "R800", "JR990", "G", "R1000", "JR1100", "G", "R1135"])
a.put(2, 15, "P").put(5, 15, "S").put(11, 15, "h").put(14, 15, "S").put(17, 15, "h").put(20, 15, "S")
a.put(22, 15, "h").put(23, 15, "S").put(26, 15, "^").put(28, 15, "D").put(11, 13, "C").put(17, 13, "C")

a = lvl("Wrong Door", 1, hint="Real doors never have a red frame. Also: jump over the fake one.",
        signs=["EXIT >>>", "Take the nearest door!"],
        sol=["R290", "JR480", "G", "R690", "JR790", "G", "R810", "JR905", "G", "R950", "JR1130"])
a.rect(18, 15, 20, 15).rect(21, 14, 30, 15)
a.put(2, 15, "P").put(5, 15, "S").put(9, 15, "F").put(22, 13, "S").put(25, 13, "F").put(28, 13, "D")

a = lvl("Greedy", 1, hint="The coin over the pit is a free jump. The coin over the spike isn't.",
        signs=["Free coins!", "More coins. Take them all."],
        sol=["R355", "JR560", "G", "R590", "JR790", "G", "R835", "JR1050", "G", "R1135"])
a.pit(10, 12)
a.put(2, 15, "P").put(5, 15, "S").put(11, 12, "C").put(14, 15, "S").put(16, 15, "h").put(16, 13, "C")
a.put(22, 15, "^").put(23, 15, "^").put(28, 15, "D")

a = lvl("Bouncy Castle", 1, hint="Springs always bounce you full height. Get moving toward the platform.",
        signs=["Higher is safer.", "Door. Finally."],
        sol=["R262", "T40", "R560", "G", "R526"])
a.rect(4, 7, 8, 7)
for c in (5, 6, 7):
    a.put(c, 8, "v")
a.rect(9, 10, 14, 10)
a.put(2, 15, "P").put(3, 15, "S").put(6, 15, "B").put(13, 9, "D").put(10, 9, "S")

# =============================================================== WORLD 2 : CRUMBLING PROMISES
a = lvl("Fragile", 2, hint="Don't stop. The floor only falls if you stand still... on it.",
        signs=["Walk slowly. This floor is fragile."],
        sol=["R1130"])
a.pit(8, 21)
for c in range(8, 22):
    a.put(c, 16, "o")
a.put(2, 15, "P").put(5, 15, "S").put(28, 15, "D")

a = lvl("Shy Floor", 2, hint="If it looks like floor but runs away, jump from further back.",
        signs=["These floors are brand new.", "Nope. Still brand new."],
        sol=["R325", "JR480", "G", "R670", "JR840", "G", "R1130"])
a.pit(9, 11).pit(18, 20)
for c in (9, 10, 11, 18, 19, 20):
    a.put(c, 16, "p")
a.put(2, 15, "P").put(5, 15, "S").put(15, 15, "S").put(28, 15, "D")

a = lvl("Thwomp Alley", 2, hint="Keep moving. They only drop if you dawdle underneath.",
        signs=["Take your time."],
        sol=["R1130"])
a.rect(1, 1, 30, 10)
for c in (7, 11, 15, 19, 23):
    a.put(c, 11, "c")
a.put(2, 15, "P").put(4, 15, "S").put(28, 15, "D")

a = lvl("Door Dodger", 2, hint="The door is shy. It runs away. Twice.",
        signs=["Doors can't run. Obviously."],
        sol=["R830", "JR1000", "G", "L960", "JL800", "G", "L480", "JL290", "G", "L240", "R360", "JR540", "G",
             "R830", "JR1000", "G", "R1135"])
a.put(16, 15, "P").put(27, 15, "E").put(3, 15, "e").put(28, 15, "f").put(14, 15, "S")
a.put(10, 15, "^").put(22, 15, "^")

a = lvl("Checkpoint of Lies", 2, hint="Four tricks in a row. Learn them one at a time.",
        signs=["Everything ahead is safe.", "Real door is the one on the right."],
        sol=["R290", "JR470", "G", "R490", "JR640", "G", "R870", "R890", "JR1070", "G", "R1185"])
a.pit(15, 20)
for c in range(15, 21):
    a.put(c, 16, "o")
a.pit(24, 26)
for c in (24, 25, 26):
    a.put(c, 16, "p")
a.put(2, 15, "P").put(4, 15, "S").put(8, 15, "h").put(14, 15, "F").put(22, 15, "S").put(29, 15, "D")

# =============================================================== WORLD 3 : BETRAYAL
a = lvl("Invisible Wall", 3, hint="Some floor is invisible. Take a leap of faith.",
        signs=["That pit is bottomless. Don't jump."],
        sol=["R340", "JR500", "G", "R540", "JR690", "G", "R830", "JR1010", "G", "R1135"])
a.pit(9, 18)
for c in (11, 12, 13, 16, 17, 18):
    a.put(c, 16, "i")
a.put(2, 15, "P").put(5, 15, "S").put(22, 14, "i").put(22, 15, "i").put(28, 15, "D")

a = lvl("Do Not Press", 3, hint="Press it. Then run. Everything wakes up.",
        signs=["DO NOT PRESS."],
        sol=["R700", "R810", "JR1000", "G", "R1020", "JR1190", "G"])
a.rect(18, 10, 30, 10)
a.rect(20, 1, 20, 15, "G")
a.put(2, 15, "P").put(14, 15, "S").put(16, 15, "d").put(22, 15, "h").put(27, 15, "h").put(23, 11, "c").put(29, 15, "D")

a = lvl("Buzzsaw Boulevard", 3, hint="The saws go up and down. Wait for the gap, then dash.",
        signs=["Saws are just for decoration."],
        sol=["Z1130"])
a.rect(1, 1, 30, 11)
a.put(2, 15, "P").put(4, 15, "S").put(9, 12, "x").put(15, 15, "X").put(21, 13, "x").put(28, 15, "D")

a = lvl("Mirror Mirror", 3, hint="The purple coin reverses your controls until you die.",
        signs=["Free coin. Take it. Take it."],
        sol=["R200", "I", "R440", "JR620", "G", "R690", "JR870", "G", "R1135"])
a.rect(5, 14, 9, 14)
a.put(2, 15, "P").put(4, 15, "S").put(7, 15, "q").put(12, 15, "^").put(18, 15, "^").put(19, 15, "^").put(28, 15, "D")

a = lvl("Coin Trail", 3, hint="The coins don't lie. Jump from coin to coin.",
        signs=["Follow the coins. They never lie.", "Almost there. Probably."],
        sol=["R290", "JR470", "G", "R505", "JR680", "G", "R715", "JR880", "G", "R915", "JR1100", "G", "R1180"])
a.pit(8, 24)
for c in (10, 11, 12, 15, 16, 17, 20, 21, 22):
    a.put(c, 15, "i")
a.put(2, 15, "P").put(4, 15, "S").put(11, 12, "C").put(16, 12, "C").put(21, 12, "C").put(26, 15, "h").put(27, 15, "S").put(29, 15, "D")

# =============================================================== WORLD 4 : TOTAL LIES
a = lvl("Skyward", 4, hint="Climb. The second step crumbles. The pink ones vanish when you get close.",
        signs=["Don't jump. It's a trap.", "Careful, the floor is hot.", "Nearly there!"],
        sol=["R170", "JR280", "G", "R305", "JR520", "G", "R585", "JR775", "G", "R825", "JR1015", "G", "R1065", "JR1170", "G"])
a.rect(5, 14, 8, 14)
for c in range(11, 15):
    a.put(c, 12, "o")
a.rect(17, 10, 20, 10)
a.rect(23, 8, 26, 8)
a.put(23, 8, "p")
a.rect(28, 6, 30, 6)
for c in (9, 10, 15, 16, 21, 22, 27, 28):
    a.put(c, 15, "^")
a.put(2, 15, "P").put(6, 13, "S").put(12, 11, "S").put(24, 7, "S").put(19, 8, "C").put(29, 5, "D")

a = lvl("Collapsing Stairs", 4, hint="Walk under the blocks, step back, wait. The ceiling builds your stairs.",
        signs=["Take your time.", "The ceiling is on your side."],
        sol=["R930", "W70", "JL/6", "G", "JR990", "G", "R1135"])
a.rect(1, 1, 30, 5)
a.put(10, 6, "c").put(14, 6, "c").put(22, 6, "c").put(22, 7, "c")
a.rect(24, 13, 30, 15)
a.put(2, 15, "P").put(4, 15, "S").put(18, 15, "S").put(28, 12, "D")

a = lvl("Decoys", 4, hint="Real doors have golden frames. The real one runs. Twice.",
        signs=["Any door will do!", "The real door is shy."],
        sol=["R300", "JR490", "G", "R560", "JR750", "G", "R960", "L720", "JL530", "G", "L480", "JL290", "G", "L185"])
a.put(2, 15, "P").put(4, 15, "S").put(10, 15, "F").put(16, 15, "F").put(26, 15, "E").put(4, 15, "e").put(19, 15, "S")

a = lvl("The Gauntlet", 4, hint="Bottom lane: left to right. Bounce up the spring. Top lane: right to left.",
        signs=["A very short, very safe corridor.", "Jump to the top. It's quicker.", "Almost done. (Not almost done.)"],
        sol=["R250", "JR430", "G", "R445", "JR620", "G", "JR810", "G", "R840", "JR1010", "G", "R1160", "T14", "L1100", "G",
             "Y900", "L540", "L525", "JL340", "G", "L305", "JL100", "G", "L95"])
a.rect(1, 10, 28, 11)
a.rect(1, 1, 30, 3)
a.pit(16, 18)
for c in (16, 17, 18):
    a.put(c, 16, "p")
a.put(2, 15, "P").put(4, 15, "S").put(8, 15, "h").put(12, 15, "F").put(22, 15, "^").put(23, 15, "^")
a.put(25, 12, "c").put(29, 15, "B").put(27, 9, "S")
for c in range(14, 20):
    a.put(c, 10, "o")
    a.put(c, 11, ".")
a.put(22, 8, "x").put(11, 9, "h").put(6, 8, "i").put(6, 9, "i").put(2, 9, "D")

a = lvl("The Liar", 4, hint="The door runs three times. Be patient. Mind the shy floor.",
        signs=["I'm so glad you made it.", "The exit is right there. Go on."],
        sol=["R790", "JR900", "G", "R945", "JR1010", "G", "JR1100", "G", "L915", "JL695", "G", "L695", "JL500", "G", "L450", "JL360", "G", "JL270", "G", "JL200", "G", "JL110", "G", "R505", "JR710", "G", "R790"])
a.pit(13, 16)
for c in (13, 14, 15, 16):
    a.put(c, 16, "p")
a.rect(22, 15, 23, 15).rect(24, 13, 25, 15).rect(26, 11, 27, 15).rect(28, 10, 30, 15)
a.rect(8, 15, 9, 15).rect(6, 13, 7, 15).rect(4, 11, 5, 15).rect(1, 10, 3, 15)
a.put(18, 15, "P").put(29, 9, "E").put(11, 15, "e").put(2, 9, "f").put(19, 15, "g").put(21, 15, "^").put(20, 15, "S")



# =============================================================== NEW IN THE REVIEW PASS
a = lvl("Moving Day", 2, hint="Short-hop (tap jump) for the coin. Don't ride the lift to the very top.",
        signs=["Moving platforms are totally reliable.", "Ride the elevator all the way up!", "The very top is the best part."],
        sol=["R330", "PX790", "R960", "R1090", "PD556", "R1150", "G", "PU420", "JL1080", "G", "L1020"])
a.rect(1, 14, 7, 15)
a.pit(8, 21)
a.rect(22, 14, 27, 15)
a.rect(13, 9, 16, 9)
for c in (13, 14, 15, 16):
    a.put(c, 10, "v")
a.put(2, 13, "P").put(4, 13, "S").put(8, 14, "m").put(14, 12, "C").put(25, 13, "S")
a.put(28, 13, "M").rect(28, 5, 30, 5).put(29, 6, "v").put(30, 6, "v")
a.rect(23, 8, 27, 8).put(24, 7, "S").put(25, 7, "D")

a = lvl("Congratulations!", 3, hint="The door that's right there is a lie. The real exit is up the stairs.",
        signs=["Congratulations! You win!", "Real stairs. Real door. Honest."],
        sol=["R500", "W175", "R500", "JR650", "G", "R705", "JR860", "G", "R930", "JR1060", "G", "R1100", "JR1190", "G", "R1180"])
a.rect(14, 14, 17, 14)
for c in (20, 21, 22, 23):
    a.put(c, 12, "o")
a.rect(25, 10, 27, 10).rect(29, 8, 30, 8)
for c in (18, 19, 24, 28):
    a.put(c, 15, "^")
a.put(2, 15, "P").put(4, 15, "S").put(11, 15, "K").put(22, 11, "C").put(26, 9, "S").put(29, 7, "Q")

a = lvl("Floor Is Lava", 4, hint="Don't stop climbing. Lava rises after 2-3 seconds. The pink floor-tiles are dust.",
        signs=["Lava? Never heard of it. Take your time.", "You're doing great. Keep climbing!"],
        sol=["R110", "JR270", "G", "R340", "JR495", "G", "R670", "JR825", "G", "L775", "JL620", "G", "L455", "JL300", "G", "R345", "JR500", "G", "R665", "JR820", "G", "R1020"])
a.put(30, 1, "L")
a.rect(4, 14, 8, 14)
for c in range(11, 17):
    a.put(c, 12, "o")
a.rect(19, 10, 23, 10).rect(11, 8, 16, 8).rect(4, 6, 8, 6).rect(11, 4, 16, 4).rect(19, 3, 27, 3)
a.put(2, 15, "P").put(5, 13, "S").put(6, 12, "C").put(20, 8, "C").put(25, 2, "D")

a = lvl("Upside Down", 5, hint="Stop moving the moment gravity flips, or you overshoot into the spikes.",
        signs=["Gravity is more of a suggestion.", "Down is up. Up is down. Left is left."],
        sol=["R228", "G", "R340", "JR500", "G", "R590", "G", "R690", "JR870", "G", "R908", "G", "JR1130", "G", "W200"])
a.rect(1, 1, 30, 2)
a.put(2, 15, "P").put(4, 15, "S").put(6, 15, "Y")
for c in (9, 10, 11):
    a.put(c, 3, "v")
a.put(15, 3, "Y").put(19, 15, "^").put(20, 15, "^").put(23, 15, "Y")
a.put(26, 3, "v").put(27, 3, "v").put(28, 3, "Y").put(30, 15, "D")

ORDER = ["Honest Start", "The Helpful Sign", "Wrong Door", "Greedy", "Bouncy Castle",
         "Fragile", "Shy Floor", "Thwomp Alley", "Moving Day", "Checkpoint of Lies",
         "Invisible Wall", "Do Not Press", "Buzzsaw Boulevard", "Mirror Mirror", "Congratulations!",
         "Door Dodger", "Coin Trail", "Skyward", "Collapsing Stairs", "Floor Is Lava",
         "Decoys", "Upside Down", "The Gauntlet", "The Liar"]
WORLD_SIZES = [5, 5, 5, 5, 4]
QUIPS = {
    "Honest Start": "Relax. This one's honest. I promise.",
    "The Helpful Sign": "Signs are friends. Trust the signs.",
    "Wrong Door": "Any door will do. Probably.",
    "Greedy": "Coins are free! Nothing is ever free.",
    "Bouncy Castle": "Higher is safer. Always.",
    "Fragile": "Walk slowly. Admire the view.",
    "Shy Floor": "The floor is shy. Be gentle.",
    "Thwomp Alley": "Take your time. Really.",
    "Moving Day": "Everyone loves an elevator.",
    "Checkpoint of Lies": "Four little tricks. What could go wrong?",
    "Invisible Wall": "I'd never hide anything from you.",
    "Do Not Press": "Whatever you do... don't.",
    "Buzzsaw Boulevard": "Decorative saws. Purely decorative.",
    "Mirror Mirror": "A free coin. Nothing odd about that.",
    "Congratulations!": "You made it! Already?",
    "Door Dodger": "Doors can't run. Don't be silly.",
    "Coin Trail": "Follow the coins. They never lie.",
    "Skyward": "Going up! Mind the crumbs.",
    "Collapsing Stairs": "The ceiling is your friend.",
    "Floor Is Lava": "Lava? Never heard of it.",
    "Decoys": "Pick a door. Any door.",
    "Upside Down": "Gravity is more of a suggestion.",
    "The Gauntlet": "A very short, very safe corridor.",
    "The Liar": "Oh. You actually made it.",
}


def finalize():
    global L
    by = {l.name: l for l in L}
    assert set(by) == set(ORDER), (set(by) ^ set(ORDER))
    L = [by[n] for n in ORDER]
    i = 0
    for w, n in enumerate(WORLD_SIZES):
        for _ in range(n):
            L[i].world = w + 1
            L[i].quip = QUIPS[L[i].name]
            i += 1


def emit(path):
    out = ["class_name LevelData", "extends RefCounted", "## GENERATED by tools/build_levels.py - edit that file, not this one.", ""]
    out.append('const WORLD_NAMES := ["Trust Issues", "Crumbling Promises", "Betrayal", "Chaos Theory", "Total Lies"]')
    out.append("const LEVELS := [")
    for l in L:
        out.append("\t{")
        out.append('\t\t"name": %s,' % gd(l.name))
        out.append('\t\t"world": %d,' % l.world)
        out.append('\t\t"hint": %s,' % gd(l.hint))
        out.append('\t\t"quip": %s,' % gd(l.quip))
        out.append('\t\t"signs": [%s],' % ", ".join(gd(s) for s in l.signs))
        out.append('\t\t"sol": [%s],' % ", ".join(gd(s) for s in l.sol))
        out.append('\t\t"map": [')
        for r in l.lines():
            out.append("\t\t\t%s," % gd(r))
        out.append("\t\t],")
        out.append("\t},")
    out.append("]")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")


def gd(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


if __name__ == "__main__":
    finalize()
    here = os.path.dirname(os.path.abspath(__file__))
    emit(os.path.join(here, "..", "scripts", "level_data.gd"))
    print("levels:", len(L))
