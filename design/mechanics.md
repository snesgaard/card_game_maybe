# Theme and Inspiration
The game is a acyclic, roguelike deck builder heavily inspired by slay the spire and yu gi oh.

# Gamestate

## Deck
This is where your remaining cards are. These are shuffled and hidden from the player.

## Hand
This is where your current cards are. These can in general be normal or free cast'ed.

## Graveyard
Where cards in general go after being played. Can still be interacted with via card effects or the Necromancy keyword.

## Banished
Banished cards are generally out of the game entirely, cannot be played or interacted with.

## Resolving
This is the card currently being resolved.

## Action queue
This is a queue of actions/cards waiting to be resolved.

## Health
How much damage an actor can take before dying.

# Card Types

## Skills
These are instant cast, support effects. Any number can be used during a turn.

Skills should not in general deal damage directly and is mainly used to support spellcasting.

## Metamagic
These are a type of skill that transforms the next spell being cast.

For example the empower metamagic might increase the potency of the next cast spell by 150%.

## Spells
The main way of dealing damage and invoking powerful effects. This is main way of winning.

As a general rule, only 1 spell may be normal casted pr turn. This limitation does not apply to spells casted via Free Casting or Necromancy.

# Mechanics

## Normal Cast

Invoke a spell from hand without any cost. Only one spell may be invoked this way pr turn.

## Free Cast

Satisfying the Free Cast condition allows you to cast the spell from hand. There's no limit to the number of Free Casts pr turn.

## Necromancy

Satisfying the Necromancy allows you to cast the spell with it being in your graveyard. There's no limit to the number of Necromancies performed pr turn.

# Mechanics

## Draw
Take the top card of the deck and add it to your hand.

## Discard
Remove a card from your hand and add it to the Graveyard

## Banish
Remove a card from either deck, hand or graveyard. Add it to the banished set.

## Heal
Increase the health of an actor

## Damage

Decrease health of an actor

## Strength

Increase damage dealt

## armor

Decrease damage taken

## Evasion

Nullify next attack


# Sigils

Each card is associated with a sigil. It doesn't do anything on it's own, simply mark the card for effects from e.g. free cast or necromancy

* Death
* Prime
* Nature
* Time
* Metal
* Elemental
