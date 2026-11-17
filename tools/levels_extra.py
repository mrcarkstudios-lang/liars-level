# Extra levels (executed from build_levels.py, so `lvl` and the Lv helpers are in scope).
# Every level has a bot solution; tests/run_tests.gd must pass. Difficulty ordering is done in build_levels.py (SCORE).

# ---------------------------------------------------------------- 1. leftward level
a = lvl("Wrong Way", 1, hint="The sign points right. The exit is on the LEFT. Run back past everything.",
        signs=["EXIT >>> this way!", "Turn around. You're going the wrong way?", "Almost there. Keep going left."],
        sol=["L940", "JL790", "G", "L730", "JL550", "G", "L485", "JL320", "G", "L300", "JL150", "G", "L105"])
a.pit(9, 10)
a.put(27, 15, "P").put(29, 15, "F").put(24, 15, "S").put(21, 15, "^").put(15, 15, "h").put(12, 15, "S")
a.put(5, 15, "F").put(7, 15, "S").put(2, 15, "D")

# ---------------------------------------------------------------- 2. descent level
a = lvl("Trust Fall", 1, hint="Walk off the edges. Every drop lands on the next platform. Don't jump.",
        signs=["Do NOT walk off the edge. Seriously.", "Stairs ahead. Take your time.", "The floor ahead is real.", "Honest door. Honest hidden spike."],
        sol=["R960", "G", "R990", "JR1170", "G", "R1215"])
a.rect(1, 5, 7, 5).rect(9, 9, 14, 9).rect(16, 12, 21, 12)
for c in range(2, 23):
    a.put(c, 15, "^")
a.put(2, 4, "P").put(4, 4, "S").put(11, 8, "S").put(18, 11, "S").put(25, 15, "S")
a.put(28, 15, "h").put(30, 15, "D")

# ---------------------------------------------------------------- 3. hurdles + falling ceiling blocks
a = lvl("Hurdle Race", 1, hint="Spike, double spike, hidden spike. Then run: the ceiling drops behind you.",
        signs=["A friendly little jog."],
        sol=["R300", "JR450", "G", "R500", "JR690", "G", "R710", "JR890", "G", "R1185"])
a.rect(23, 1, 30, 10)
a.put(2, 15, "P").put(4, 15, "S").put(9, 15, "^").put(14, 15, "^").put(15, 15, "^").put(20, 15, "h")
a.put(24, 11, "c").put(27, 11, "c").put(29, 15, "D")

# ---------------------------------------------------------------- 4. crumbling bridge with hurdles
a = lvl("Domino Bridge", 2, hint="The bridge crumbles when you stand still. Land, then keep moving.",
        signs=["Sturdy bridge. Built by experts.", "Do not look down."],
        sol=["R420", "JR570", "G", "R660", "JR810", "G", "R860", "JR1010", "G", "R1135"])
a.pit(6, 24)
for c in range(6, 25):
    a.put(c, 16, "o")
a.put(12, 15, "^").put(18, 15, "^").put(23, 15, "^")
a.put(2, 15, "P").put(4, 15, "S").put(9, 15, "S").put(28, 15, "D")

# ---------------------------------------------------------------- 5. crumbling staircase up
a = lvl("Crumble Climb", 2, hint="Every step crumbles. Jump the moment you land.",
        signs=["Stairs! Totally permanent.", "Keep climbing."],
        sol=["R170", "JR280", "G", "R305", "JR520", "G", "R585", "JR775", "G", "R825", "JR1015", "G", "R1065", "JR1170", "G"])
for c in range(5, 9):
    a.put(c, 14, "o")
for c in range(11, 15):
    a.put(c, 12, "o")
for c in range(17, 21):
    a.put(c, 10, "o")
for c in range(23, 27):
    a.put(c, 8, "o")
for c in range(28, 31):
    a.put(c, 6, "o")
for c in range(9, 30):
    a.put(c, 15, "^")
a.put(2, 15, "P").put(6, 13, "S").put(12, 11, "S").put(29, 5, "D")

# ---------------------------------------------------------------- 6. moving bridge over spikes
a = lvl("Moving Bridge", 2, hint="Step on, wait, and step off. Don't jump while it moves.",
        signs=["The bridge is automatic. Totally reliable."],
        sol=["R330", "PX790", "R1135"])
a.rect(1, 14, 7, 15)
a.pit(8, 21)
for c in range(8, 22):
    a.put(c, 16, "^")
a.rect(22, 14, 29, 15)
a.put(8, 14, "m").put(2, 13, "P").put(4, 13, "S").put(28, 13, "D")

# ---------------------------------------------------------------- 7. button + gate puzzle
a = lvl("Honest Button", 3, hint="The button is real. The floor after it is not.",
        signs=["Press the button. It opens the gate. Honest."],
        sol=["R620", "R670", "JR850", "G", "R870", "JR1050", "G", "R1185"])
a.rect(20, 1, 20, 15, "G")
a.put(2, 15, "P").put(5, 15, "S").put(14, 15, "b").put(19, 15, "h").put(24, 15, "h").put(29, 15, "D")

# ---------------------------------------------------------------- 9. cursed coin over a pit
a = lvl("Cursed Trail", 3, hint="The purple coin flips your controls. Wait for it, then cross the pit backwards.",
        signs=["A free coin. No catch."],
        sol=["R200", "I", "R550", "JR770", "G", "R1135"])
a.pit(14, 17)
a.put(2, 15, "P").put(4, 15, "S").put(7, 15, "q").put(28, 15, "D")

# ---------------------------------------------------------------- 10. lava + springs
a = lvl("Hot Springs", 4, hint="Step on a spring and keep pushing right. Lava rises if you wait.",
        signs=["Hot springs! Very relaxing."],
        sol=["R140", "T46", "G", "R410", "T46", "G", "R690", "T46", "G", "R1100"])
a.put(30, 1, "L")
a.rect(7, 11, 12, 11).rect(13, 6, 18, 6).rect(20, 3, 28, 3)
a.put(2, 15, "P").put(3, 15, "B").put(11, 10, "B").put(18, 5, "B").put(27, 2, "D").put(5, 15, "S")

# ---------------------------------------------------------------- 11. gravity pads maze
a = lvl("Gravity Dance", 4, hint="Walk onto a pink pad to flip gravity, hop the spikes, then flip back.",
        signs=["Down is up. Probably."],
        sol=["R228", "G", "R420", "JR610", "G", "R670", "G", "R780", "JR970", "G", "R1185"])
a.rect(1, 1, 30, 2)
a.put(2, 15, "P").put(4, 15, "S").put(6, 15, "Y").put(17, 3, "Y")
a.put(12, 3, "v").put(13, 3, "v").put(21, 15, "^").put(22, 15, "^").put(29, 15, "D")

# ---------------------------------------------------------------- 12. double fake exit
a = lvl("Fake Victory", 4, hint="The 'cleared' screen lies. Wait for the real door to appear.",
        signs=["LEVEL CLEARED! Walk into the door."],
        sol=["R540", "JR730", "G", "R1185"])
a.put(2, 15, "P").put(4, 15, "S").put(15, 15, "^").put(16, 15, "^").put(24, 15, "K").put(29, 15, "Q")

# ---------------------------------------------------------------- 13. runaway door in a spike field
a = lvl("Door Chase", 5, hint="The real door runs. Spikes on the floor: jump, then dash.",
        signs=["Any door will do."],
        sol=["R830", "JR1000", "G", "L980", "JL830", "G", "L500", "JL350", "G", "L150"])
a.put(16, 15, "P").put(27, 15, "E").put(3, 15, "e").put(14, 15, "S")
a.put(10, 15, "^").put(22, 15, "^")

# ---------------------------------------------------------------- 14. everything at once, short
a = lvl("Trap Buffet", 5, hint="Crumbling floor, a hidden spike, a shy floor, another hidden spike.",
        signs=["A very normal hallway.", "Nothing unusual."],
        sol=["R470", "JR650", "G", "R635", "JR840", "G", "R910", "JR1090", "G", "R1185"])
a.pit(8, 11).pit(17, 19)
for c in (8, 9, 10, 11):
    a.put(c, 16, "o")
for c in (17, 18, 19):
    a.put(c, 16, "p")
a.put(2, 15, "P").put(4, 15, "S").put(14, 15, "h").put(25, 15, "h").put(21, 15, "S").put(29, 15, "D")

# ---------------------------------------------------------------- 15. precision jumps over wide gaps
a = lvl("Spike Hopper", 5, hint="Four wide gaps. Jump right at the very edge of each platform.",
        signs=["Four gentle little hops."],
        sol=["R235", "JR440", "G", "R475", "JR680", "G", "R715", "JR920", "G", "R955", "JR1160", "G", "R1185"])
a.rect(1, 14, 5, 15).rect(10, 14, 11, 14).rect(16, 14, 17, 14).rect(22, 14, 23, 14).rect(28, 14, 30, 15)
a.pit(6, 27)
for c in range(6, 28):
    a.put(c, 16, "^")
a.put(2, 13, "P").put(4, 13, "S").put(29, 13, "D")

# ---------------------------------------------------------------- 16. six tricks in a row
a = lvl("Marathon", 5, hint="Spike, hidden spike, wide pit, double spike, then run under the ceiling blocks.",
        signs=["Take a deep breath. It's only six tricks."],
        sol=["R180", "JR330", "G", "R350", "JR530", "G", "R550", "JR770", "G", "R780", "JR970", "G", "R1185"])
a.pit(14, 17)
a.rect(24, 1, 30, 10)
a.put(2, 15, "P").put(4, 15, "S").put(6, 15, "^").put(11, 15, "h").put(21, 15, "^").put(22, 15, "^")
a.put(25, 11, "c").put(27, 11, "c").put(29, 15, "D")

# ---------------------------------------------------------------- 17. hurdles into a saw alley
a = lvl("Saw Marathon", 5, hint="Two hurdles first. Then wait for the saws in the alley and dash through.",
        signs=["The alley is perfectly safe."],
        sol=["R220", "JR370", "G", "R390", "JR570", "G", "Z1185"])
a.rect(17, 1, 30, 11)
a.put(2, 15, "P").put(4, 15, "S").put(7, 15, "^").put(12, 15, "h")
a.put(20, 12, "x").put(25, 15, "X").put(29, 15, "D")

# =============================================================== BATCH 3: ten harder levels (41-50)
# ---------------------------------------------------------------- A. five spike groups
a = lvl("Spike Alley", 5, hint="Five spike groups in a row. Jump 60 px before each one.",
        signs=["A short walk. Nothing dangerous."],
        sol=["R140", "JR290", "G", "R300", "JR490", "G", "R510", "JR700", "G", "R700", "JR850", "G", "R860", "JR1050", "G", "R1185"])
a.put(2, 15, "P").put(3, 15, "S").put(5, 15, "^").put(9, 15, "^").put(10, 15, "^").put(15, 15, "h").put(19, 15, "^")
a.put(23, 15, "^").put(24, 15, "^").put(29, 15, "D")

# ---------------------------------------------------------------- B. three wide pits with a hurdle between
a = lvl("Pit Chain", 5, hint="Three wide pits and a hidden spike. Jump right at each edge.",
        signs=["Mind the gaps."],
        sol=["R235", "JR450", "G", "R460", "JR610", "G", "R670", "JR890", "G", "R870", "JR1060", "G", "R1215"])
a.pit(6, 9).pit(17, 20)
a.put(2, 15, "P").put(4, 15, "S").put(13, 15, "^").put(24, 15, "h").put(30, 15, "D")

# ---------------------------------------------------------------- C. long crumbling bridge with five hazards
a = lvl("Crumble Marathon", 5, hint="Keep moving. The bridge crumbles under you and the spikes don't.",
        signs=["Sturdy bridge. Built by experts, again."],
        sol=["R300", "JR450", "G", "R460", "JR650", "G", "R670", "JR860", "G", "R860", "JR1010", "G", "R1135"])
a.pit(6, 24)
for c in range(6, 25):
    a.put(c, 16, "o")
a.put(9, 15, "^").put(13, 15, "^").put(14, 15, "^").put(19, 15, "h").put(23, 15, "^")
a.put(2, 15, "P").put(4, 15, "S").put(28, 15, "D")

# ---------------------------------------------------------------- D. falling levels with spikes on every platform
a = lvl("Spiked Descent", 5, hint="Walk off each edge. Hop the spike, drop to the next platform.",
        signs=["Do NOT walk off the edge.", "One spike. Then another.", "The last drop is real."],
        sol=["R460", "JR610", "G", "R700", "JR850", "G", "R975", "G", "R990", "JR1170", "G", "R1215"])
a.rect(1, 5, 7, 5).rect(9, 9, 14, 9).rect(15, 12, 22, 12)
for c in range(2, 23):
    a.put(c, 15, "^")
a.put(2, 4, "P").put(4, 4, "S").put(11, 8, "S").put(13, 8, "^").put(17, 11, "S").put(19, 11, "^")
a.put(25, 15, "S").put(28, 15, "h").put(30, 15, "D")

# ---------------------------------------------------------------- E. runaway door that flees three times
a = lvl("Runaway Rally", 5, hint="The real door runs three times. Chase it left and right over the spikes.",
        signs=["Doors can't run. Obviously."],
        sol=["R830", "JR1000", "G", "L960", "JL800", "G", "L480", "JL290", "G", "L240", "R360", "JR540", "G", "R830", "JR1000", "G",
             "R1030", "L980", "JL830", "G", "L590"])
a.put(16, 15, "P").put(27, 15, "E").put(3, 15, "e").put(28, 15, "f").put(14, 15, "g").put(12, 15, "S")
a.put(10, 15, "^").put(22, 15, "^")

# ---------------------------------------------------------------- F. four gravity pads
a = lvl("Gravity Gauntlet", 5, hint="Flip, hop the ceiling spikes, flip back, hop the floor spikes, flip, hop, flip. You drift a little after each pad.",
        signs=["Gravity is only a suggestion."],
        sol=["R250", "W15", "G", "R420", "JR610", "G", "R690", "W15", "G", "R740", "JR930", "G", "R970", "W15", "G", "R1060", "JR1210", "G", "R1215"])
a.rect(1, 1, 30, 2)
a.put(2, 15, "P").put(4, 15, "S").put(6, 15, "Y").put(17, 3, "Y").put(24, 15, "Y").put(30, 3, "Y")
a.put(12, 3, "v").put(13, 3, "v").put(20, 15, "^").put(21, 15, "^").put(28, 3, "v").put(30, 15, "D")

# ---------------------------------------------------------------- G. only invisible stepping stones
a = lvl("Ghost Steps", 5, hint="Four invisible stones over a long pit. Jump from each stone's right edge.",
        signs=["There is definitely floor here."],
        sol=["R240", "JR400", "G", "R420", "JR600", "G", "R620", "JR800", "G", "R820", "JR1000", "G", "R1020", "JR1120", "G", "R1185"])
a.pit(7, 26)
for c in (9, 10, 14, 15, 19, 20, 24, 25):
    a.put(c, 15, "i")
a.put(2, 15, "P").put(4, 15, "S").put(29, 15, "D")

# ---------------------------------------------------------------- H. moving platform, then hurdles on the far side
a = lvl("Ferry Fare", 5, hint="Ride the ferry across, then a spike and a fake door wait on the far shore.",
        signs=["The ferry is automatic. Totally reliable."],
        sol=["R330", "PX790", "R860", "JR1010", "G", "R1066", "JR1200", "G", "R1215"])
a.rect(1, 14, 7, 15)
a.pit(8, 21)
for c in range(8, 22):
    a.put(c, 16, "^")
a.rect(22, 14, 30, 15)
a.put(8, 14, "m").put(2, 13, "P").put(4, 13, "S").put(23, 13, "^").put(28, 13, "F").put(30, 13, "D")

# ---------------------------------------------------------------- I. everything, one breath
a = lvl("Final Exam", 5, hint="Spike, hidden spike, wide pit, double spike, fake door, ceiling blocks.",
        signs=["An easy test. Pencils down."],
        sol=["R100", "JR250", "G", "R270", "JR460", "G", "R510", "JR730", "G", "R700", "JR890", "G", "R890", "JR1070", "G", "R1215"])
a.pit(13, 16)
a.rect(26, 1, 30, 10)
a.put(2, 15, "P").put(3, 15, "S").put(4, 15, "^").put(9, 15, "h").put(19, 15, "^").put(20, 15, "^").put(24, 15, "F")
a.put(27, 11, "c").put(29, 11, "c").put(30, 15, "D")

# ---------------------------------------------------------------- J. beat the lava clock
a = lvl("Lava Dash", 5, hint="The lava rises about 2.5 seconds after you move. Don't stop for anything.",
        signs=["Lava? Never heard of it."],
        sol=["R180", "JR330", "G", "R390", "JR610", "G", "R630", "JR820", "G", "R820", "JR1010", "G", "R1135"])
a.put(30, 1, "L")
a.pit(10, 13)
a.put(2, 15, "P").put(4, 15, "S").put(6, 15, "^").put(18, 15, "h").put(22, 15, "^").put(23, 15, "^").put(28, 15, "D")
