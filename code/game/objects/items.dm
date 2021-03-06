/obj/item
	name = "item"
	icon = 'icons/obj/items.dmi'
	w_class = ITEM_SIZE_NORMAL
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER

	var/tmp/image/blood_overlay = null //this saves our blood splatter overlay, which will be processed not to go over the edges of the sprite
	var/randpixel = 0
	var/tmp/abstract = 0
	var/r_speed = 1.0
	var/health = null
	var/burn_point = null
	var/burning = null
	var/hitsound = null
	var/tmp/slot_flags = 0		//This is used to determine on which slots an item can fit.
	var/no_attack_log = 0			//If it's an item we don't want to log attack_logs with, set this to 1
	pass_flags = PASSTABLE
	var/obj/item/master = null
	var/list/origin_tech = null	//Used by R&D to determine what research bonuses it grants.
	var/list/attack_verb = null //Used in attackby() to say how something was attacked "[x] has been [z.attack_verb] by [y] with [z]"
	var/force = 0

	var/heat_protection = 0 //flags which determine which body parts are protected from heat. Use the HEAD, UPPER_TORSO, LOWER_TORSO, etc. flags. See setup.dm
	var/cold_protection = 0 //flags which determine which body parts are protected from cold. Use the HEAD, UPPER_TORSO, LOWER_TORSO, etc. flags. See setup.dm
	var/max_heat_protection_temperature //Set this variable to determine up to which temperature (IN KELVIN) the item protects against heat damage. Keep at null to disable protection. Only protects areas set by heat_protection flags
	var/min_cold_protection_temperature //Set this variable to determine down to which temperature (IN KELVIN) the item protects against cold damage. 0 is NOT an acceptable number due to if(varname) tests!! Keep at null to disable protection. Only protects areas set by cold_protection flags

	var/icon_action_button //If this is set, The item will make an action button on the player's HUD when picked up.
	var/action_button_name //This is the text which gets displayed on the action button. If not set it defaults to 'Use [name]'. Note that icon_action_button needs to be set in order for the action button to appear.

	//This flag is used to determine when items in someone's inventory cover others. IE helmets making it so you can't see glasses, etc.
	//It should be used purely for appearance. For gameplay effects caused by items covering body parts, use body_parts_covered.
	var/flags_inv = 0
	var/body_parts_covered = 0 //see setup.dm for appropriate bit flags

	var/item_flags = 0 //Miscellaneous flags pertaining to equippable objects.

	//var/heat_transfer_coefficient = 1 //0 prevents all transfers, 1 is invisible
	var/gas_transfer_coefficient = 1 // for leaking gas from turf to mask and vice-versa (for masks right now, but at some point, i'd like to include space helmets)
	var/permeability_coefficient = 1 // for chemicals/diseases
	var/siemens_coefficient = 1 // for electrical admittance/conductance (electrocution checks and shit)
	var/slowdown = 0 // How much clothing is slowing you down. Negative values speeds you up
	var/canremove = 1 //Mostly for Ninja code at this point but basically will not allow the item to be removed if set to 0. /N
	var/list/armor = list(melee = 0, bullet = 0, laser = 0,energy = 0, bomb = 0, bio = 0, rad = 0)
	var/tmp/list/allowed = null //suit storage stuff.
	var/tmp/obj/item/device/uplink/hidden/hidden_uplink = null // All items can have an uplink hidden inside, just remember to add the triggers.
	var/zoomdevicename = null //name used for message when binoculars/scope is used
	var/zoom = 0 //1 if item is actively being used to zoom. For scoped guns and binoculars.

	var/icon_override = null  //Used to override hardcoded clothing dmis in human clothing proc.

	var/wear_state = ""   // If set used instead icon_state for on-mob clothing overlays.
	var/item_state = null // Used to specify the item state for the on-mob overlays.

	// Specify the icon file to be used when the item is holding.
	// If not set the default icon for that slot will be used.
	// If icon_override or sprite_sheets are set they will take precendence over this.
	var/tmp/sprite_group = null


	/* Species-specific sprite sheets for inventory sprites
	Works similarly to worn sprite_sheets, except the alternate sprites are used when the clothing/refit_for_species() proc is called.
	*/
	var/tmp/list/sprite_sheets_obj = null

/obj/item/initialize()
	. = ..()
	if(randpixel && (!pixel_x && !pixel_y)) //hopefully this will prevent us from messing with mapper-set pixel_x/y
		pixel_x = rand(-randpixel, randpixel)
		pixel_y = rand(-randpixel, randpixel)

/obj/item/Destroy()
	qdel(hidden_uplink)
	hidden_uplink = null
	if(ismob(loc))
		var/mob/m = loc
		m.drop_from_inventory(src)
		m.update_inv_r_hand()
		m.update_inv_l_hand()
		src.forceMove(null)
	. = ..()

/obj/item/device
	icon = 'icons/obj/device.dmi'

//Checks if the item is being held by a mob, and if so, updates the held icons
/obj/item/proc/update_held_icon()
	if(isliving(src.loc))
		var/mob/living/M = src.loc
		if(M.l_hand == src)
			M.update_inv_l_hand()
		else if(M.r_hand == src)
			M.update_inv_r_hand()

/obj/item/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(50))
				qdel(src)
				return
		if(3.0)
			if (prob(5))
				qdel(src)
				return
		else
	return

/obj/item/blob_act()
	return

//user: The mob that is suiciding
//damagetype: The type of damage the item will inflict on the user
//BRUTELOSS = 1
//FIRELOSS = 2
//TOXLOSS = 4
//OXYLOSS = 8
//Output a creative message and then return the damagetype done
/obj/item/proc/suicide_act(mob/user)
	return

/obj/item/verb/move_to_top()
	set name = "Move To Top"
	set category = "Object"
	set src in oview(1)

	if(!istype(src.loc, /turf) || usr.incapacitated() )
		return

	var/turf/T = src.loc

	src.loc = null
	src.loc = T

/obj/item/examine(mob/user, var/return_dist = 0)
	var/size
	switch(src.w_class)
		if(ITEM_SIZE_TINY)
			size = "tiny"
		if(ITEM_SIZE_SMALL)
			size = "small"
		if(ITEM_SIZE_NORMAL)
			size = "normal-sized"
		if(ITEM_SIZE_LARGE)
			size = "large"
		if(ITEM_SIZE_HUGE)
			size = "bulky"
		if(ITEM_SIZE_HUGE + 1 to INFINITY)
			size = "huge"
	return ..(user, return_dist, "", "It is a [size] item.")

/obj/item/proc/on_mob_description(var/mob/living/carbon/human/H, var/datum/gender/T, var/slot, var/slot_name)
	var/msg = "[T.He] [T.is] wearing \icon[src]"
	var/end_part = " on [T.his] [slot_name]"

	switch(slot)
		if(slot_w_uniform, slot_wear_suit)
			end_part = ""
		if(slot_back, slot_gloves)
			msg = "[T.He] [T.has] \icon[src]"
		if(slot_belt)
			msg = "[T.He] [T.has] \icon[src]"
			end_part = " about [T.his] waist"
		if(slot_s_store)
			msg = "[T.He] [T.is] carring \icon[src]"
		if(slot_glasses)
			msg = "[T.He] [T.has] \icon[src]"
			end_part = " covering [T.his] eyes"
		if(slot_l_hand, slot_r_hand)
			msg = "[T.He] [T.is] holding \icon[src]"
			end_part = " in [T.his] [slot_name]"
		if(slot_l_ear, slot_r_ear)
			return "[T.He] [T.has] \icon[src] \a [src] on [T.his] [slot_name]."
		if(slot_wear_id)
			return "[T.He] [T.is] wearing \icon[src] \a [src]."

	if(blood_DNA)
		msg = SPAN_WARN("[msg] [gender==PLURAL?"some":"a"] [(blood_color != SYNTH_BLOOD_COLOUR) ? "blood" : "oil"]-stained [src][end_part]!")
	else
		msg += " \a [src][end_part]."
	return msg



/obj/item/attack_hand(mob/living/user as mob)
	if (!user) return
	if (hasorgans(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/external/temp = H.get_organ(user.hand ? BP_L_HAND : BP_R_HAND)
		if(!temp)
			user << SPAN_NOTE("You try to use your hand, but realize it is no longer attached!")
			return
		if(!temp.is_usable())
			user << SPAN_NOTE("You try to move your [temp.name], but cannot!")
			return
	src.pickup(user)
	if (istype(src.loc, /obj/item/storage))
		var/obj/item/storage/S = src.loc
		S.remove_from_storage(src)

	src.throwing = 0
	if (src.loc == user)
		if(!user.unEquip(src))
			return
	else
		if(isliving(src.loc))
			return
	user.put_in_active_hand(src)
	return

/obj/item/attack_robot(mob/living/silicon/robot/user)
	if (istype(src.loc, /obj/item/weapon/robot_module))
		//If the item is part of a cyborg module, equip it
		if(!isrobot(user))
			return
		var/mob/living/silicon/robot/R = user
		R.activate_module(src)
		R.hud_used.update_robot_modules_display()

// Due to storage type consolidation this should get used more now.
// I have cleaned it up a little, but it could probably use more.  -Sayu
/obj/item/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W,/obj/item/storage))
		var/obj/item/storage/S = W
		if(S.use_to_pickup)
			if(S.collection_mode) //Mode is set to collect all items on a tile and we clicked on a valid one.
				if(isturf(src.loc))
					var/list/rejections = list()
					var/success = 0
					var/failure = 0

					for(var/obj/item/I in src.loc)
						if(I.type in rejections) // To limit bag spamming: any given type only complains once
							continue
						if(!S.can_be_inserted(I))	// Note can_be_inserted still makes noise when the answer is no
							rejections += I.type	// therefore full bags are still a little spammy
							failure = 1
							continue
						success = 1
						S.handle_item_insertion(I, 1)	//The 1 stops the "You put the [src] into [S]" insertion message from being displayed.
					if(success && !failure)
						user << SPAN_NOTE("You put everything in [S].")
					else if(success)
						user << SPAN_NOTE("You put some things in [S].")
					else
						user << SPAN_NOTE("You fail to pick anything up with \the [S].")

			else if(S.can_be_inserted(src))
				S.handle_item_insertion(src)

	return

/obj/item/proc/talk_into(mob/M as mob, text)
	return

/obj/item/proc/moved(mob/user as mob, old_loc as turf)
	return

// apparently called whenever an item is removed from a slot, container, or anything else.
/obj/item/proc/dropped(mob/user as mob)
	if(zoom) zoom() //binoculars, scope, etc
	return


// called just as an item is picked up (loc is not yet changed)
/obj/item/proc/pickup(mob/user)
	return

// called when this item is removed from a storage item, which is passed on as S. The loc variable is already set to the new destination before this is called.
/obj/item/proc/on_exit_storage(obj/item/weapon/storage/S as obj)
	return

// called when this item is added into a storage item, which is passed on as S. The loc variable is already set to the storage item.
/obj/item/proc/on_enter_storage(obj/item/weapon/storage/S as obj)
	return

// called when "found" in pockets and storage items. Returns 1 if the search should end.
/obj/item/proc/on_found(mob/finder as mob)
	return

// called after an item is placed in an equipment slot
// user is mob that equipped it
// slot uses the slot_X defines found in setup.dm
// for items that can be placed in multiple slots
// note this isn't called during the initial dressing of a player
/obj/item/proc/equipped(var/mob/user, var/slot)
	return

//Defines which slots correspond to which slot flags
var/list/global/slot_flags_enumeration = list(
	"[slot_wear_mask]" = SLOT_MASK,
	"[slot_back]" = SLOT_BACK,
	"[slot_wear_suit]" = SLOT_OCLOTHING,
	"[slot_gloves]" = SLOT_GLOVES,
	"[slot_shoes]" = SLOT_FEET,
	"[slot_belt]" = SLOT_BELT,
	"[slot_glasses]" = SLOT_EYES,
	"[slot_head]" = SLOT_HEAD,
	"[slot_l_ear]" = SLOT_EARS|SLOT_TWOEARS,
	"[slot_r_ear]" = SLOT_EARS|SLOT_TWOEARS,
	"[slot_w_uniform]" = SLOT_ICLOTHING,
	"[slot_wear_id]" = SLOT_ID,
	"[slot_tie]" = SLOT_TIE,
	)

//the mob M is attempting to equip this item into the slot passed through as 'slot'. Return 1 if it can do this and 0 if it can't.
//If you are making custom procs but would like to retain partial or complete functionality of this one, include a 'return ..()' to where you want this to happen.
//Set disable_warning to 1 if you wish it to not give you outputs.
//Should probably move the bulk of this into mob code some time, as most of it is related to the definition of slots and not item-specific
/obj/item/proc/mob_can_equip(M as mob, slot, disable_warning = 0)
	if(!slot) return 0
	if(!M) return 0

	if(!ishuman(M)) return 0

	var/mob/living/carbon/human/H = M
	var/list/mob_equip = list()
	if(slot in list(slot_socks, slot_underwear, slot_undershirt))
		if(!istype(src, /obj/item/clothing/hidden))
			return 0
	else
		if(H.species.hud && H.species.hud.equip_slots)
			mob_equip = H.species.hud.equip_slots

		if(!(slot in mob_equip))
			return 0

	//First check if the item can be equipped to the desired slot.
	if("[slot]" in slot_flags_enumeration)
		var/req_flags = slot_flags_enumeration["[slot]"]
		if(!(req_flags & slot_flags))
			return 0

	//Next check that the slot is free
	if(H.get_equipped_item(slot))
		return 0

	//Next check if the slot is accessible.
	var/mob/_user = disable_warning? null : H
	if(!H.slot_is_accessible(slot, src, _user))
		return 0

	//Lastly, check special rules for the desired slot.
	switch(slot)
		if(slot_l_ear, slot_r_ear)
			if((w_class > ITEM_SIZE_TINY) && !(slot_flags & SLOT_EARS))
				return 0
		if(slot_wear_id)
			if(!H.w_uniform && (slot_w_uniform in mob_equip))
				if(!disable_warning)
					H << "<span class='warning'>You need a jumpsuit before you can attach this [name].</span>"
				return 0
		if(slot_l_store, slot_r_store)
			if(!H.w_uniform && (slot_w_uniform in mob_equip))
				if(!disable_warning)
					H << "<span class='warning'>You need a jumpsuit before you can attach this [name].</span>"
				return 0
			if(slot_flags & SLOT_DENYPOCKET)
				return 0
			if(w_class > ITEM_SIZE_SMALL && !(slot_flags & SLOT_POCKET))
				return 0
			if(get_storage_cost() == ITEM_SIZE_NO_CONTAINER)
				return 0 //pockets act like storage and should respect ITEM_SIZE_NO_CONTAINER. Suit storage might be fine as is
		if(slot_s_store)
			if(!H.wear_suit && (slot_wear_suit in mob_equip))
				if(!disable_warning)
					H << "<span class='warning'>You need a suit before you can attach this [name].</span>"
				return 0
			if(!H.wear_suit.allowed)
				if(!disable_warning)
					usr << "<span class='warning'>You somehow have a suit with no defined allowed items for suit storage, stop that.</span>"
				return 0
			if( !(istype(src, /obj/item/device/pda) || istype(src, /obj/item/weapon/pen) || is_type_in_list(src, H.wear_suit.allowed)) )
				return 0
		if(slot_handcuffed)
			if(!istype(src, /obj/item/weapon/handcuffs))
				return 0
		if(slot_legcuffed)
			if(!istype(src, /obj/item/weapon/legcuffs))
				return 0
		if(slot_in_backpack) //used entirely for equipping spawned mobs or at round start
			if(H.back && istype(H.back, /obj/item/storage))
				var/obj/item/storage/B = H.back
				if(!B.can_be_inserted(src, disable_warning))
					return 0
		if(slot_tie)
			if(!H.w_uniform && (slot_w_uniform in mob_equip))
				if(!disable_warning)
					H << "<span class='warning'>You need a jumpsuit before you can attach this [name].</span>"
				return 0
			var/obj/item/clothing/under/uniform = H.w_uniform
			if(uniform.accessories.len && !uniform.can_attach_accessory(src))
				if (!disable_warning)
					H << "<span class='warning'>You already have an accessory of this type attached to your [uniform].</span>"
				return 0
	return 1

/obj/item/proc/mob_can_unequip(mob/M, slot, disable_warning = 0)
	if(!slot) return 0
	if(!M) return 0

	if(!canremove)
		return 0
	if(!M.slot_is_accessible(slot, src, disable_warning? null : M))
		return 0
	return 1

/obj/item/verb/verb_pickup()
	set src in oview(1)
	set category = "Object"
	set name = "Pick up"

	if(!usr) //BS12 EDIT
		return
	if(!Adjacent(usr))
		return
	if((!iscarbon(usr)) || (isbrain(usr)))//Is humanoid, and is not a brain
		usr << "<span class='warning'>You can't pick things up!</span>"
		return
	if(usr.incapacitated())//Is not asleep/dead and is not restrained
		usr << "<span class='warning'>You can't pick things up!</span>"
		return
	if(src.anchored) //Object isn't anchored
		usr << "<span class='warning'>You can't pick that up!</span>"
		return
	var/mob/living/carbon/C = usr
	if(C.get_active_hand()) //Hand is not full
		usr << "<span class='warning'>Your hand is full.</span>"
		return
	if(!istype(src.loc, /turf)) //Object is on a turf
		usr << "<span class='warning'>You can't pick that up!</span>"
		return
	//All checks are done, time to pick it up!
	usr.UnarmedAttack(src)
	return


//This proc is executed when someone clicks the on-screen UI button.
//The default action is attack_self().
//Checks before we get to here are: mob is alive, mob is not restrained, paralyzed, asleep, resting, laying, item is on the mob.
/obj/item/proc/ui_action_click()
	attack_self(usr)


/obj/item/proc/handle_shield(mob/user, var/damage, atom/damage_source = null, mob/attacker = null, var/attack_text = "the attack")
	return 0

/obj/item/proc/get_loc_turf()
	var/atom/L = loc
	while(L && !istype(L, /turf/))
		L = L.loc
	return loc

/obj/item/proc/eyestab(mob/living/carbon/M as mob, mob/living/carbon/user as mob)

	var/mob/living/carbon/human/H = M
	if(istype(H))
		for(var/obj/item/protection in list(H.head, H.wear_mask, H.glasses))
			if(protection && (protection.body_parts_covered & EYES))
				// you can't stab someone in the eyes wearing a mask!
				user << "<span class='warning'>You're going to need to remove the eye covering first.</span>"
				return

	if(!M.has_eyes())
		user << "<span class='warning'>You cannot locate any eyes on [M]!</span>"
		return

	admin_attack_log(user, M,
		"Attacked [key_name(M)] with [src.name] (INTENT: [uppertext(user.a_intent)])",
		"Attacked by [key_name(user)] with [src.name] (INTENT: [uppertext(user.a_intent)])",
		"used [src.name] to eyestub"
	)

	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	user.do_attack_animation(M)

	src.add_fingerprint(user)
	//if((CLUMSY in user.mutations) && prob(50))
	//	M = user
		/*
		M << "<span class='warning'>You stab yourself in the eye.</span>"
		M.sdisabilities |= BLIND
		M.weakened += 4
		M.adjustBruteLoss(10)
		*/

	if(istype(H))

		var/obj/item/organ/internal/eyes/eyes = H.internal_organs_by_name[O_EYES]

		if(H != user)
			for(var/mob/O in (viewers(M) - user - M))
				O.show_message("<span class='danger'>[M] has been stabbed in the eye with [src] by [user].</span>", 1)
			M << "<span class='danger'>[user] stabs you in the eye with [src]!</span>"
			user << "<span class='danger'>You stab [M] in the eye with [src]!</span>"
		else
			user.visible_message( \
				"<span class='danger'>[user] has stabbed themself with [src]!</span>", \
				"<span class='danger'>You stab yourself in the eyes with [src]!</span>" \
			)

		eyes.damage += rand(3,4)
		if(eyes.damage >= eyes.min_bruised_damage)
			if(M.stat != DEAD)
				if(eyes.robotic <= 1) //robot eyes bleeding might be a bit silly
					M << "<span class='danger'>Your eyes start to bleed profusely!</span>"
			if(prob(50))
				if(!M.stat)
					M << "<span class='warning'>You drop what you're holding and clutch at your eyes!</span>"
					M.drop_active_hand()
				M.eye_blurry += 10
				M.Paralyse(1)
				M.Weaken(4)
			if (eyes.damage >= eyes.min_broken_damage)
				if(M.stat != DEAD)
					M << "<span class='warning'>You go blind!</span>"
		var/obj/item/organ/external/affecting = H.get_organ(BP_HEAD)
		if(affecting.take_damage(7))
			M:UpdateDamageIcon()
	else
		M.take_organ_damage(7)
	M.eye_blurry += rand(3,4)
	return

/obj/item/clean_blood()
	. = ..()
	if(blood_overlay)
		overlays.Remove(blood_overlay)
	if(istype(src, /obj/item/clothing/gloves))
		var/obj/item/clothing/gloves/G = src
		G.transfer_blood = 0

/obj/item/reveal_blood()
	if(was_bloodied && !fluorescent)
		fluorescent = 1
		blood_color = COLOR_LUMINOL
		blood_overlay.color = COLOR_LUMINOL
		update_icon()

/obj/item/add_blood(mob/living/carbon/human/M as mob)
	if (!..())
		return 0

	if(istype(src, /obj/item/weapon/melee/energy))
		return

	//if we haven't made our blood_overlay already
	if( !blood_overlay )
		generate_blood_overlay()

	//apply the blood-splatter overlay if it isn't already in there
	if(!blood_DNA.len)
		blood_overlay.color = blood_color
		overlays += blood_overlay

	//if this blood isn't already in the list, add it
	if(istype(M))
		if(blood_DNA[M.dna.unique_enzymes])
			return 0 //already bloodied with this blood. Cannot add more.
		blood_DNA[M.dna.unique_enzymes] = M.dna.b_type
	return 1 //we applied blood to the item

/obj/item/proc/generate_blood_overlay()
	if(blood_overlay)
		return

	var/icon/I = new /icon(icon, icon_state)
	I.Blend(new /icon('icons/effects/blood.dmi', rgb(255,255,255)),ICON_ADD) //fills the icon_state with white (except where it's transparent)
	I.Blend(new /icon('icons/effects/blood.dmi', "itemblood"),ICON_MULTIPLY) //adds blood and the remaining white areas become transparant

	//not sure if this is worth it. It attaches the blood_overlay to every item of the same type if they don't have one already made.
	for(var/obj/item/A in world)
		if(A.type == type && !A.blood_overlay)
			A.blood_overlay = image(I)

/obj/item/proc/showoff(mob/user)
	for (var/mob/M in view(user))
		M.show_message("[user] holds up [src]. <a HREF=?src=\ref[M];lookitem=\ref[src]>Take a closer look.</a>",1)

/mob/living/carbon/verb/showoff()
	set name = "Show Held Item"
	set category = "Object"

	var/obj/item/I = get_active_hand()
	if(I && !I.abstract)
		I.showoff(src)

/*
For zooming with scope or binoculars. This is called from
modules/mob/mob_movement.dm if you move you will be zoomed out
modules/mob/living/carbon/human/life.dm if you die, you will be zoomed out.
*/
//Looking through a scope or binoculars should /not/ improve your periphereal vision. Still, increase viewsize a tiny bit so that sniping isn't as restricted to NSEW
/obj/item/proc/zoom(var/tileoffset = 14,var/viewsize = 9) //tileoffset is client view offset in the direction the user is facing. viewsize is how far out this thing zooms. 7 is normal view

	var/devicename

	if(zoomdevicename)
		devicename = zoomdevicename
	else
		devicename = src.name

	var/cannotzoom

	if(usr.incapacitated() || !(ishuman(usr)))
		usr << "You are unable to focus through the [devicename]"
		cannotzoom = 1
	else if(!zoom && global_hud.darkMask[1] in usr.client.screen)
		usr << "Your visor gets in the way of looking through the [devicename]"
		cannotzoom = 1
	else if(!zoom && usr.get_active_hand() != src)
		usr << "You are too distracted to look through the [devicename], perhaps if it was in your active hand this might work better"
		cannotzoom = 1

	if(!zoom && !cannotzoom)
		if(usr.hud_used.hud_shown)
			usr.toggle_zoom_hud()	// If the user has already limited their HUD this avoids them having a HUD when they zoom in
		usr.client.view = viewsize
		zoom = 1

		var/tilesize = 32
		var/viewoffset = tilesize * tileoffset

		switch(usr.dir)
			if (NORTH)
				usr.client.pixel_x = 0
				usr.client.pixel_y = viewoffset
			if (SOUTH)
				usr.client.pixel_x = 0
				usr.client.pixel_y = -viewoffset
			if (EAST)
				usr.client.pixel_x = viewoffset
				usr.client.pixel_y = 0
			if (WEST)
				usr.client.pixel_x = -viewoffset
				usr.client.pixel_y = 0

		usr.visible_message("[usr] peers through the [zoomdevicename ? "[zoomdevicename] of the [src.name]" : "[src.name]"].")

	else
		usr.client.view = world.view
		if(!usr.hud_used.hud_shown)
			usr.toggle_zoom_hud()
		zoom = 0

		usr.client.pixel_x = 0
		usr.client.pixel_y = 0

		if(!cannotzoom)
			usr.visible_message("[zoomdevicename ? "[usr] looks up from the [src.name]" : "[usr] lowers the [src.name]"].")

	return

/obj/item/proc/pwr_drain()
	return 0 // Process Kill
