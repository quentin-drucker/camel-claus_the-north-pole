class_name AchievementData
extends Resource
## A goal tracked by Profile. Earned when `stat` reaches `target`: run stats come from the current run
## (GameState), lifetime stats from the profile's totals plus the run in progress
## (see Profile.progress()). Earning one pays `reward_coins` and can make a weapon buyable.
## Adding a goal = one new .tres in resources/achievements/ (+ a stat key Profile already knows).

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
## A key of Profile.progress(), e.g. "run_kills", "total_kills", "run_evolutions".
@export var stat: String = "run_kills"
@export var target: float = 1.0
@export var reward_coins: int = 0
## Weapon id this goal makes buyable in the Workshop ("" = none).
@export var unlocks_weapon: String = ""
