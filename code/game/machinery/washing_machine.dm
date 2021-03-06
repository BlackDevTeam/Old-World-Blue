/obj/machinery/washing_machine
	name = "Washing Machine"
	icon = 'icons/obj/machines/washing_machine.dmi'
	icon_state = "wm_1"
	density = 1
	anchored = 1.0
	var/state = 1
	//1 = empty, open door
	//2 = empty, closed door
	//3 = full, open door
	//4 = full, closed door
	//5 = running
	//6 = blood, open door
	//7 = blood, closed door
	//8 = blood, running
	var/panel = 0
	//0 = closed
	//1 = open
	var/hacked = 1 //Bleh, screw hacking, let's have it hacked by default.
	//0 = not hacked
	//1 = hacked
	var/gibs_ready = 0
	var/obj/item/weapon/pen/crayon/crayon

/obj/machinery/washing_machine/verb/start()
	set name = "Start Washing"
	set category = "Object"
	set src in oview(1)

	if(!isliving(usr)) //ew ew ew usr, but it's the only way to check.
		return

	if( state != 4 )
		usr << "The washing machine cannot run in this state."
		return

	if( locate(/mob,contents) )
		state = 8
	else
		state = 5
	update_icon()
	sleep(200)
	for(var/atom/A in contents)
		A.clean_blood()
		if(crayon && istype(A, /obj/item/clothing))
			A.color = crayon.colour

	for(var/obj/item/I in contents)
		I.decontaminate()

	//Tanning!
	for(var/obj/item/stack/material/hairlesshide/HH in contents)
		var/obj/item/stack/material/wetleather/WL = new(src)
		WL.amount = HH.amount
		qdel(HH)

	if( locate(/mob,contents) )
		state = 7
		gibs_ready = 1
	else
		state = 4
	update_icon()

/obj/machinery/washing_machine/verb/climb_out()
	set name = "Climb out"
	set category = "Object"
	set src in usr.loc

	sleep(20)
	if(state in list(1,3,6))
		usr.forceMove(src.loc)


/obj/machinery/washing_machine/update_icon()
	overlays.Cut()
	icon_state = "wm_[state]"
	if(panel)
		overlays += "panel"

/obj/machinery/washing_machine/affect_grab(var/mob/user, var/mob/target)
	if((state == 1) && hacked)
		if(ishuman(user) && iscorgi(target))
			target.forceMove(src)
			state = 3
			return TRUE

/obj/machinery/washing_machine/attackby(obj/item/weapon/W as obj, mob/user as mob)
	/*if(istype(W,/obj/item/weapon/screwdriver))
		panel = !panel
		user << SPAN_NOTE("you [panel ? "open" : "close"] the [src]'s maintenance panel")*/
	if(istype(W,/obj/item/weapon/pen/crayon) || istype(W,/obj/item/weapon/stamp))
		if( state in list(	1, 3, 6 ) )
			if(!crayon)
				user.drop_from_inventory(W, src)
				crayon = W
			else
				..()
		else
			..()
	else if(is_type_in_list(W,list(\
		/obj/item/stack/material/hairlesshide,
		/obj/item/clothing/under,
		/obj/item/clothing/hidden,
		/obj/item/clothing/mask,
		/obj/item/clothing/head,
		/obj/item/clothing/gloves,
		/obj/item/clothing/shoes,
		/obj/item/clothing/suit,
		/obj/item/weapon/bedsheet)\
	))

		//YES, it's hardcoded... saves a var/can_be_washed for every single clothing item.
		if ( istype(W,/obj/item/clothing/suit/space ) )
			user << "This item does not fit."
			return
		if ( istype(W,/obj/item/clothing/suit/syndicatefake ) )
			user << "This item does not fit."
			return
//		if ( istype(W,/obj/item/clothing/suit/powered ) )
//			user << "This item does not fit."
//			return
		if ( istype(W,/obj/item/clothing/suit/cyborg_suit ) )
			user << "This item does not fit."
			return
		if ( istype(W,/obj/item/clothing/suit/bomb_suit ) )
			user << "This item does not fit."
			return
		if ( istype(W,/obj/item/clothing/suit/armor ) )
			user << "This item does not fit."
			return
		if ( istype(W,/obj/item/clothing/suit/armor ) )
			user << "This item does not fit."
			return
		if ( istype(W,/obj/item/clothing/mask/gas ) )
			user << "This item does not fit."
			return
		if ( istype(W,/obj/item/smokable/cigarette ) )
			user << "This item does not fit."
			return
		if ( istype(W,/obj/item/clothing/head/syndicatefake ) )
			user << "This item does not fit."
			return
//		if ( istype(W,/obj/item/clothing/head/powered ) )
//			user << "This item does not fit."
//			return
		if ( istype(W,/obj/item/clothing/head/helmet ) )
			user << "This item does not fit."
			return

		if(contents.len < 5)
			if ( state in list(1, 3) )
				user.drop_from_inventory(W, src)
				state = 3
			else
				user << SPAN_NOTE("You can't put the item in right now.")
		else
			user << SPAN_NOTE("The washing machine is full.")
	else
		..()
	update_icon()

/obj/machinery/washing_machine/attack_hand(mob/user as mob)
	switch(state)
		if(1)
			state = 2
		if(2)
			state = 1
			for(var/atom/movable/O in contents)
				O.forceMove(src.loc)
			crayon = null
		if(3)
			state = 4
		if(4)
			state = 3
			for(var/atom/movable/O in contents)
				O.forceMove(src.loc)
			crayon = null
			state = 1
		if(5)
			user << "\red The [src] is busy."
		if(6)
			state = 7
		if(7)
			if(gibs_ready)
				gibs_ready = 0
				if(locate(/mob,contents))
					var/mob/M = locate(/mob,contents)
					M.gib()
			for(var/atom/movable/O in contents)
				O.forceMove(src.loc)
			crayon = null
			state = 1


	update_icon()
