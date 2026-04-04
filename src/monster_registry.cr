# src/monster_registry.cr
# Central registry — maps monster IDs to their templates.
# Add a require here whenever a new monster file is created.

require "./monsters/zombie_man"
require "./monsters/shotgun_guy"
require "./monsters/chain_gun_guy"
require "./monsters/imp"
require "./monsters/demon"
require "./monsters/spectre"
require "./monsters/lost_soul"
require "./monsters/cacodemon"
require "./monsters/pain_elemental"
require "./monsters/hell_knight"
require "./monsters/baron_of_hell"
require "./monsters/arachnotron"
require "./monsters/mancubus"
require "./monsters/revenant"
require "./monsters/arch_vile"
require "./monsters/spider_mastermind"
require "./monsters/cyberdemon"
require "./monsters/wolfenstein_ss"

ALL_MONSTERS = {
  "zombie_man"        => ZOMBIE_MAN,
  "shotgun_guy"       => SHOTGUN_GUY,
  "chain_gun_guy"     => CHAIN_GUN_GUY,
  "imp"               => IMP,
  "demon"             => DEMON,
  "spectre"           => SPECTRE,
  "lost_soul"         => LOST_SOUL,
  "cacodemon"         => CACODEMON,
  "pain_elemental"    => PAIN_ELEMENTAL,
  "hell_knight"       => HELL_KNIGHT,
  "baron_of_hell"     => BARON_OF_HELL,
  "arachnotron"       => ARACHNOTRON,
  "mancubus"          => MANCUBUS,
  "revenant"          => REVENANT,
  "arch_vile"         => ARCH_VILE,
  "spider_mastermind" => SPIDER_MASTERMIND,
  "cyberdemon"        => CYBERDEMON,
  "wolfenstein_ss"    => WOLFENSTEIN_SS,
}
