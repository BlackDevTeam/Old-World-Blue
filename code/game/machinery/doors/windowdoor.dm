/obj/machinery/door/window
	name = "interior door"
	desc = "A strong door."
	icon = 'icons/obj/doors/windoor.dmi'
	icon_state = "left"
	var/base_state = "left"
	min_force = 4
	hitsound = 'sound/effects/Glasshit.ogg'
	maxhealth = 150 //If you change this, consiter changing ../door/window/brigdoor/ health at the bottom of this .dm file
	health = 150
	visible = 0.0
	use_power = 0
	flags = ON_BORDER
	opacity = 0
	var/obj/item/weapon/airlock_electronics/electronics = null
	explosion_resistance = 5
	air_properties_vary_with_direction = 1

/obj/machinery/door/window/New()
	..()
	update_nearby_tiles()
	if (src.req_access && src.req_access.len)
		src.base_state = src.icon_state

/obj/machinery/door/window/update_icon()
	if(density)
		icon_state = base_state
	else
		icon_state = "[base_state]open"

/obj/machinery/door/window/proc/get_electronics()
	var/obj/item/weapon/airlock_electronics/ae
	if(!electronics)
		ae = new/obj/item/weapon/airlock_electronics( src.loc )
		if(!src.req_access)
			src.check_access()
		if(src.req_access.len)
			ae.conf_access = src.req_access
		else if (src.req_one_access.len)
			ae.conf_access = src.req_one_access
			ae.one_access = 1
	else
		ae = electronics
		electronics = null
		ae.forceMove(src.loc)
	if(operating == -1)
		ae.icon_state = "door_electronics_smoked"
	return ae

/obj/machinery/door/window/proc/shatter(var/display_message = 1)
	new /obj/item/weapon/material/shard(src.loc)
	new /obj/item/weapon/material/shard(src.loc)
	new /obj/item/stack/cable_coil(src.loc, 1)
	playsound(src, "shatter", 70, 1)
	if(display_message)
		visible_message("[src] shatters!")
	var/obj/item/E = get_electronics()
	E.forceMove(src.loc)
	qdel(src)

/obj/machinery/door/window/Destroy()
	density = 0
	update_nearby_tiles()
	..()

/obj/machinery/door/window/Bumped(atom/movable/AM as mob|obj)
	if (!ismob(AM))
		if(istype(AM,/mob/living/bot))
			var/mob/living/bot/bot = AM
			if(density && src.check_access(bot.botcard))
				open()
				sleep(50)
				close()
		else if(istype(AM, /obj/mecha))
			var/obj/mecha/mecha = AM
			if(density)
				if(mecha.occupant && src.allowed(mecha.occupant))
					open()
					sleep(50)
					close()
		return
	if (!ticker)
		return
	if (src.operating)
		return
	if (src.density && src.allowed(AM))
		open()
		if(src.check_access(null))
			sleep(50)
		else //secure doors close faster
			sleep(20)
		close()
	return

/obj/machinery/door/window/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(istype(mover) && mover.checkpass(PASSGLASS))
		return 1
	if(get_dir(loc, target) == dir) //Make sure looking at appropriate border
		if(air_group) return 0
		return !density
	else
		return 1

/obj/machinery/door/window/CheckExit(atom/movable/mover as mob|obj, turf/target as turf)
	if(istype(mover) && mover.checkpass(PASSGLASS))
		return 1
	if(get_dir(loc, target) == dir)
		return !density
	else
		return 1

/obj/machinery/door/window/open()
	if (operating == 1) //doors can still open when emag-disabled
		return 0
	if (!ticker)
		return 0
	if (!operating) //in case of emag
		operating = 1
	flick(text("[src.base_state]opening"), src)
	playsound(src.loc, 'sound/machines/windowdoor.ogg', 100, 1)
	sleep(10)

	explosion_resistance = 0
	density = 0
	update_icon()
	update_nearby_tiles()

	if(operating == 1) //emag again
		operating = 0
	return 1

/obj/machinery/door/window/close()
	if (operating || panel_open)
		return 0
	src.operating = 1
	flick(text("[]closing", src.base_state), src)
	playsound(src.loc, 'sound/machines/windowdoor.ogg', 100, 1)

	density = 1
	update_icon()
	explosion_resistance = initial(explosion_resistance)
	update_nearby_tiles()

	sleep(10)
	operating = 0
	return 1

/obj/machinery/door/window/take_damage(var/damage)
	src.health = max(0, src.health - damage)
	if (src.health <= 0)
		shatter()
		return

/obj/machinery/door/window/attack_ai(mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/door/window/attack_hand(mob/user as mob)

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.can_shred())
			user.next_move = world.time + 8
			playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)
			visible_message("<span class='danger'>[user] smashes against the [src.name].</span>", 1)
			take_damage(25)
			return
	return src.attackby(user, user)

/obj/machinery/door/window/emag_act(var/remaining_charges, var/mob/user)
	if (density && operable())
		operating = -1
		flick("[src.base_state]spark", src)
		sleep(6)
		open()
		return 1

/obj/machinery/door/window/default_deconstruction_screwdriver()
	if(!density) //Open
		return ..()
	else
		return 0

/obj/machinery/door/window/default_deconstruction_crowbar(mob/user, obj/item/weapon/crowbar/crowbar)
	if(!istype(crowbar))
		return 0

	if(!panel_open || in_use)
		return 1

	in_use = 1

	playsound(src.loc, 'sound/items/Crowbar.ogg', 100, 1)
	user.visible_message(
		"[user] removes the electronics from the windoor.",
		"You start to remove electronics from the windoor."
	)
	if (do_after(user,40,src) && panel_open)
		in_use = 0
		user << SPAN_NOTE("You removed the windoor electronics!")
		..()
	if(src)
		in_use = 0
	return 1

/obj/machinery/door/window/dismantle()
	var/obj/structure/windoor_assembly/wa = new(src.loc)
	wa.electronics = get_electronics()
	wa.electronics.forceMove(wa)

	if (istype(src, /obj/machinery/door/window/brigdoor))
		wa.secure = "secure_"
		wa.name = "secure wired windoor assembly"
	else
		wa.name = "wired windoor assembly"

	if (src.base_state == "right" || src.base_state == "rightsecure")
		wa.facing = "r"

	wa.set_dir(src.dir)
	wa.state = "02"
	wa.update_icon()
	qdel(src)


/obj/machinery/door/window/attackby(obj/item/weapon/I as obj, mob/user as mob)

	//If it's in the process of opening/closing, ignore the click
	if (src.operating == 1)
		return

	if(default_deconstruction_screwdriver(user,I))
		return 1
	if(default_deconstruction_crowbar(user,I))
		return 1

	//Emags and ninja swords? You may pass.
	if (istype(I, /obj/item/weapon/melee/energy/blade))
		if(emag_act(10, user))
			var/datum/effect/effect/system/spark_spread/spark_system = new
			spark_system.set_up(5, 0, src.loc)
			spark_system.start()
			playsound(src.loc, "sparks", 50, 1)
			playsound(src.loc, 'sound/weapons/blade1.ogg', 50, 1)
			visible_message("<span class='warning'>The glass door was sliced open by [user]!</span>")
		return 1

	//If it's a weapon, smash windoor. Unless it's an id card, agent card, ect.. then ignore it (Cards really shouldnt damage a door anyway)
	if(src.density && istype(I, /obj/item/weapon) && !istype(I, /obj/item/weapon/card))
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		playsound(src.loc, 'sound/effects/Glasshit.ogg', 75, 1)
		visible_message("<span class='danger'>[src] was hit by [I].</span>")
		if(I.damtype == BRUTE || I.damtype == BURN)
			take_damage(I.force)
		return


	src.add_fingerprint(user)

	if (src.allowed(user))
		if (src.density)
			open()
		else
			close()

	else if (src.density)
		flick(text("[]deny", src.base_state), src)

	return



/obj/machinery/door/window/brigdoor
	name = "secure door"
	icon = 'icons/obj/doors/windoor.dmi'
	icon_state = "leftsecure"
	base_state = "leftsecure"
	req_access = list(access_security)
	var/id = null
	maxhealth = 300
	health = 300.0 //Stronger doors for prison (regular window door health is 150)


/obj/machinery/door/window/northleft
	dir = NORTH

/obj/machinery/door/window/eastleft
	dir = EAST

/obj/machinery/door/window/westleft
	dir = WEST

/obj/machinery/door/window/southleft
	dir = SOUTH

/obj/machinery/door/window/northright
	dir = NORTH
	icon_state = "right"
	base_state = "right"

/obj/machinery/door/window/eastright
	dir = EAST
	icon_state = "right"
	base_state = "right"

/obj/machinery/door/window/westright
	dir = WEST
	icon_state = "right"
	base_state = "right"

/obj/machinery/door/window/southright
	dir = SOUTH
	icon_state = "right"
	base_state = "right"

/obj/machinery/door/window/brigdoor/northleft
	dir = NORTH

/obj/machinery/door/window/brigdoor/eastleft
	dir = EAST

/obj/machinery/door/window/brigdoor/westleft
	dir = WEST

/obj/machinery/door/window/brigdoor/southleft
	dir = SOUTH

/obj/machinery/door/window/brigdoor/northright
	dir = NORTH
	icon_state = "rightsecure"
	base_state = "rightsecure"

/obj/machinery/door/window/brigdoor/eastright
	dir = EAST
	icon_state = "rightsecure"
	base_state = "rightsecure"

/obj/machinery/door/window/brigdoor/westright
	dir = WEST
	icon_state = "rightsecure"
	base_state = "rightsecure"

/obj/machinery/door/window/brigdoor/southright
	dir = SOUTH
	icon_state = "rightsecure"
	base_state = "rightsecure"
