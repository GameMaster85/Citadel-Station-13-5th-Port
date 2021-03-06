/mob/living/carbon/alien/humanoid/sentinel
	name = "alien sentinel"
	caste = "s"
	maxHealth = 150
	health = 150
	icon_state = "aliens_s"
	butcher_results = list(/obj/item/weapon/xeno_skull/s = 1,
	/obj/item/weapon/reagent_containers/food/snacks/meat/slab/xeno = 5,
	/obj/item/stack/sheet/animalhide/xeno = 1,
	/obj/item/weapon/xenos_tail = 1,
	/obj/item/weapon/xenos_claw = 1)

/mob/living/carbon/alien/humanoid/sentinel/New()
	internal_organs += new /obj/item/organ/internal/alien/plasmavessel/sentinel
	internal_organs += new /obj/item/organ/internal/alien/acid
	internal_organs += new /obj/item/organ/internal/alien/neurotoxin

	AddAbility(new /obj/effect/proc_holder/alien/sneak)
	..()

/mob/living/carbon/alien/humanoid/sentinel/handle_hud_icons_health()
	if (healths)
		if (stat != 2)
			switch(health)
				if(150 to INFINITY)
					healths.icon_state = "health0"
				if(125 to 150)
					healths.icon_state = "health1"
				if(75 to 125)
					healths.icon_state = "health2"
				if(50 to 75)
					healths.icon_state = "health3"
				if(25 to 50)
					healths.icon_state = "health4"
				if(0 to 25)
					healths.icon_state = "health5"
				else
					healths.icon_state = "health6"
		else
			healths.icon_state = "health7"

/mob/living/carbon/alien/humanoid/sentinel/movement_delay()
	. = ..()
	. += 1
/mob/living/carbon/alien/humanoid/sentinel/MiddleClickOn(atom/A, params, mob/user)
//	new = /obj/item/projectile/bullet/neurotoxin/N(user.loc)
//	N.throwAt(A)
	..()
