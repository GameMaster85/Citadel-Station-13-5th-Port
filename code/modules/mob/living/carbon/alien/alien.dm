#define HEAT_DAMAGE_LEVEL_1 2 //Amount of damage applied when your body temperature just passes the 360.15k safety point
#define HEAT_DAMAGE_LEVEL_2 3 //Amount of damage applied when your body temperature passes the 400K point
#define HEAT_DAMAGE_LEVEL_3 8 //Amount of damage applied when your body temperature passes the 460K point and you are on fire

/mob/living/carbon/alien
	name = "alien"
	voice_name = "alien"
	icon = 'icons/mob/alien.dmi'
	gender = FEMALE
	dna = null
	faction = list("alien")
	ventcrawler = 2
	languages = ALIEN
	verb_say = "hisses"
	type_of_meat = /obj/item/weapon/reagent_containers/food/snacks/meat/slab/xeno
	var/nightvision = 1
	var/crawling = 0
	var/obj/item/weapon/card/id/wear_id = null // Fix for station bounced radios -- Skie
	var/has_fine_manipulation = 0
	var/move_delay_add = 0 // movement delay to add

	status_flags = CANPARALYSE|CANPUSH

	var/heat_protection = 0.5
	var/leaping = 0
	gib_type = /obj/effect/decal/cleanable/xenoblood/xgibs
	unique_name = 1

/mob/living/carbon/alien/New()
	verbs += /mob/living/proc/mob_sleep
	verbs += /mob/living/proc/lay_down

//	create_dna(src)
//	dna.initialize_dna()

	internal_organs += new /obj/item/organ/internal/brain/alien
	internal_organs += new /obj/item/organ/internal/alien/hivenode
	for(var/obj/item/organ/internal/I in internal_organs)
		I.Insert(src)

	AddAbility(new/obj/effect/proc_holder/alien/nightvisiontoggle(null))
	..()

/mob/living/carbon/alien/adjustToxLoss(amount)
	return

/mob/living/carbon/alien/adjustFireLoss(amount) // Weak to Fire
	if(amount > 0)
		..(amount * 2)
	if(amount > 19)
		src.say ("*hurt")
	else
		..(amount)
	return

/mob/living/carbon/alien/check_eye_prot()
	return ..() + 2

/mob/living/carbon/alien/getToxLoss()
	return 0

/mob/living/carbon/alien/handle_environment(datum/gas_mixture/environment)
	if(!environment)
		return

	var/loc_temp = get_temperature(environment)

	// Aliens are now weak to fire.

	//After then, it reacts to the surrounding atmosphere based on your thermal protection
	if(!on_fire) // If you're on fire, ignore local air temperature
		if(loc_temp > bodytemperature)
			//Place is hotter than we are
			var/thermal_protection = heat_protection //This returns a 0 - 1 value, which corresponds to the percentage of heat protection.
			if(thermal_protection < 1)
				bodytemperature += (1-thermal_protection) * ((loc_temp - bodytemperature) / BODYTEMP_HEAT_DIVISOR)
		else
			bodytemperature += 1 * ((loc_temp - bodytemperature) / BODYTEMP_HEAT_DIVISOR)

	if(bodytemperature > 360.15)
		//Body temperature is too hot.
		throw_alert("alien_fire", /obj/screen/alert/alien_fire)
		switch(bodytemperature)
			if(360 to 400)
				apply_damage(HEAT_DAMAGE_LEVEL_1, BURN)
			if(400 to 460)
				apply_damage(HEAT_DAMAGE_LEVEL_2, BURN)
			if(460 to INFINITY)
				if(on_fire)
					apply_damage(HEAT_DAMAGE_LEVEL_3, BURN)
				else
					apply_damage(HEAT_DAMAGE_LEVEL_2, BURN)
	else
		clear_alert("alien_fire")


/mob/living/carbon/alien/ex_act(severity, target)
	..()

	switch (severity)
		if (1)
			gib()
			return

		if (2)
			adjustBruteLoss(60)
			adjustFireLoss(60)
			adjustEarDamage(30,120)

		if(3)
			adjustBruteLoss(30)
			if (prob(50))
				Paralyse(1)
			adjustEarDamage(15,60)

	updatehealth()


/mob/living/carbon/alien/handle_fire()//Aliens on fire code
	if(..())
		return
	bodytemperature += BODYTEMP_HEATING_MAX //If you're on fire, you heat up!
	return

/mob/living/carbon/alien/reagent_check(datum/reagent/R) //can metabolize all reagents
	return 0

/mob/living/carbon/alien/IsAdvancedToolUser()
	return has_fine_manipulation

/mob/living/carbon/alien/Stat()
	..()

	if(statpanel("Status"))
		stat(null, "Intent: [a_intent]")

/mob/living/carbon/alien/Stun(amount)
	if(status_flags & CANSTUN)
		stunned = max(max(stunned,amount),0) //can't go below 0, getting a low amount of stun doesn't lower your current stun
	else
		// add some movement delay
		move_delay_add = min(move_delay_add + round(amount / 2), 10) // a maximum delay of 10
	return

/mob/living/carbon/alien/getTrail()
	if(getBruteLoss() < 200)
		return pick (list("xltrails_1", "xltrails2"))
	else
		return pick (list("xttrails_1", "xttrails2"))
/*----------------------------------------
Proc: AddInfectionImages()
Des: Gives the client of the alien an image on each infected mob.
----------------------------------------*/
/mob/living/carbon/alien/proc/AddInfectionImages()
	if (client)
		for (var/mob/living/C in mob_list)
			if(C.status_flags & XENO_HOST)
				var/obj/item/organ/internal/body_egg/alien_embryo/A = C.getorgan(/obj/item/organ/internal/body_egg/alien_embryo)
				if(A)
					var/I = image('icons/mob/alien.dmi', loc = C, icon_state = "infected[A.stage]")
					client.images += I
	return


/*----------------------------------------
Proc: RemoveInfectionImages()
Des: Removes all infected images from the alien.
----------------------------------------*/
/mob/living/carbon/alien/proc/RemoveInfectionImages()
	if (client)
		for(var/image/I in client.images)
			if(dd_hasprefix_case(I.icon_state, "infected"))
				qdel(I)
	return

/mob/living/carbon/alien/canBeHandcuffed()
	return 1

/mob/living/carbon/alien/get_standard_pixel_y_offset(lying = 0)
	return initial(pixel_y)

//SMASHY SMASHY//
/*
/turf/simulated/wall/attack_alien(mob/user)
	..(user, 1)
	if(isalienravager(user))
		if(hardness > 10 && prob(hardness))
			playsound(src, 'sound/effects/meteorimpact.ogg', 100, 1)
			user.do_attack_animation(src)
			user << text("<span class='notice'>You smash through the wall.</span>")
			user.say("*roar")
			dismantle_wall(1)

		else
			playsound(src, 'sound/effects/wallbang.ogg', 100, 1)
			user.do_attack_animation(src)
			user << text("<span class='notice'>You smash into the wall.</span>")

	if(isalienroyal(user))
		if(hardness > 15 && prob(hardness))
			playsound(src, 'sound/effects/meteorimpact.ogg', 100, 1)
			user.do_attack_animation(src)
			user << text("<span class='notice'>You smash through the wall.</span>")
			user.say("*roar")
			dismantle_wall(1)

		else
			playsound(src, 'sound/effects/wallbang.ogg', 100, 1)
			user.do_attack_animation(src)
			user << text("<span class='notice'>You smash into the wall.</span>")

	else
		return


/obj/structure/falsewall/attack_alien(mob/living/carbon/alien/humanoid/user)
	..(user, 1)
	playsound(src, 'sound/effects/meteorimpact.ogg', 100, 1)
	user.do_attack_animation(src)
	user << text("<span class='notice'>You easily smash through and destroy the false wall.</span>")
	user.say("*roar")
	qdel(src)

/obj/structure/girder/attack_alien(mob/living/carbon/alien/humanoid/user)
	..(user, 1)
	playsound(src, 'sound/effects/meteorimpact.ogg', 100, 1)
	user.do_attack_animation(src)
	user << text("<span class='notice'>You easily smash through and destroy the flimsy girder.</span>")
	state = GIRDER_DISASSEMBLED
	user.say("*roar")
	qdel(src)
*/
//XENO CRAFTING STUFF//

/obj/item/weapon/xeno_skull
	name = "alien skull"
	desc = "The skull from some unfortunate alien. It's been hollowed out."
	icon = 'icons/mob/alien.dmi'
	icon_state = "skull_h"
	origin_tech = "materials=3"
	w_class = 4
	unacidable = 1

/obj/item/weapon/xeno_skull/h
	name = "alien hunter skull"
	icon_state = "skull_h"
/obj/item/weapon/xeno_skull/d
	name = "alien drone skull"
	icon_state = "skull_d"
/obj/item/weapon/xeno_skull/s
	name = "alien sentinel skull"
	icon_state = "skull_s"
/obj/item/weapon/xeno_skull/r
	name = "alien ravager skull"
	icon_state = "skull_r"
/obj/item/weapon/xeno_skull/p
	name = "alien praetorian skull"
	icon_state = "skull_p"
/obj/item/weapon/xeno_skull/q
	name = "alien queen skull"
	icon_state = "skull_q"
	w_class = 5

/obj/item/weapon/xenos_claw
	name = "alien claws"
	desc = "The claws of a terrible creature."
	icon = 'icons/mob/alien.dmi'
	icon_state = "claw"
	origin_tech = "materials=3"
	hitsound = 'sound/weapons/bladeslice.ogg'
	force = 7
	throwforce = 7
	w_class = 2
	unacidable = 1

/obj/item/weapon/xenos_tail
	name = "alien tail barb"
	desc = "The sharp end of a xenomorph's tail."
	icon = 'icons/mob/alien.dmi'
	icon_state = "tail"
	origin_tech = "materials=3"
	embed_chance = 60
	hitsound = 'sound/weapons/bladeslice.ogg'
	force = 7
	throwforce = 14
	w_class = 2
	unacidable = 1

/obj/item/stack/sheet/animalhide/xeno
	name = "alien hide"
	icon = 'icons/mob/alien.dmi'
	desc = "The skin of a terrible creature."
	singular_name = "alien hide piece"
	icon_state = "hide"
	origin_tech = "materials=3"
	w_class = 3
	unacidable = 1

//CRAFTABLES//

//SPEAR
/obj/item/weapon/twohanded/spear/xeno
	name = "alien spear"
	desc = "A simple metal rod with the sharp end of a xenomorph tail tied on the end of it. Give em' a taste of their own medicine!"
	force = 15
	throwforce = 22
	force_wielded = 22
	embed_chance = 80
	embedded_impact_pain_multiplier = 4
	icon = 'icons/mob/alien.dmi'
	icon_state = "spearxeno0"
	unacidable = 1

/obj/item/weapon/twohanded/spear/xeno/update_icon()
	if(explosive)
		icon_state = "spearxeno_bomb[wielded]"
	else
		icon_state = "spearxeno[wielded]"

//SHIELD
/obj/item/weapon/shield/xeno
	name = "alien shield"
	desc = "The skull of an alien, hollowed out and fashioned into an arm-length piece of chitin which effectively blocks melee attacks. Acid-resistant!"
	unacidable = 1
	icon = 'icons/mob/alien.dmi'
	icon_state = "xeno_shield"
	item_state = "xeno_shield"
	force = 10
	origin_tech = "materials=3"
	attack_verb = list("shoved", "bashed")

/obj/item/weapon/shield/xeno/IsShield()
	return 1
//ARMOR
/obj/item/clothing/suit/xeno_armor
	name = "alien armor"
	desc = "A suit made out of chitinous alien hide."
	icon_state = "xenos"
	item_state = "alien_helm"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS|HANDS
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT
	allowed = list(/obj/item/clothing/mask/facehugger)
	armor = list(melee = 35, bullet = 10, laser = -50, energy = 0, bomb = 10, bio = 10, rad = 30)
//HELMET
/obj/item/clothing/head/xeno_helm
	name = "alien helmet"
	icon_state = "xenos"
	item_state = "alien_helm"
	desc = "A helmet made out of chitinous alien hide."
	flags = BLOCKHAIR
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE
	armor = list(melee = 35, bullet = 10, laser = -50, energy = 0, bomb = 10, bio = 10, rad = 30)
//CRAFTING RECIPES//
/datum/table_recipe/xenoshield
	name = "alien shield"
	result = /obj/item/weapon/shield/xeno
	reqs = list(/obj/item/weapon/xeno_skull)
	tools = list(/obj/item/weapon/kitchen/knife)
	time = 50
	category = CAT_MISC

/datum/table_recipe/xeno_armor
	name = "alien armor"
	result = /obj/item/clothing/suit/xeno_armor
	reqs = list(/obj/item/stack/sheet/animalhide/xeno = 2)
	tools = list(/obj/item/weapon/kitchen/knife)
	time = 100
	category = CAT_MISC

/datum/table_recipe/xeno_helm
	name = "alien helmet"
	result = /obj/item/clothing/head/xeno_helm
	reqs = list(/obj/item/weapon/xeno_skull)
	tools = list(/obj/item/weapon/kitchen/knife)
	time = 50
	category = CAT_MISC

#undef HEAT_DAMAGE_LEVEL_1
#undef HEAT_DAMAGE_LEVEL_2
#undef HEAT_DAMAGE_LEVEL_3
