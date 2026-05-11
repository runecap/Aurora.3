SUBSYSTEM_DEF(virtualreality)
	name = "Virtual Reality"
	init_order = INIT_ORDER_MISC_FIRST
	flags = SS_NO_FIRE

	// MECHA
	var/list/mechnetworks = list(REMOTE_GENERIC_MECH, REMOTE_AI_MECH, REMOTE_PRISON_MECH) // A list of all the networks a mech can possibly connect to
	var/list/list/mechs = list() // A list of lists, containing the mechs and their networks

	// IPC BODIES
	var/list/robotnetworks = list(REMOTE_GENERIC_ROBOT, REMOTE_BUNKER_ROBOT, REMOTE_PRISON_ROBOT, REMOTE_WARDEN_ROBOT)
	var/list/list/robots = list()

	// STATIONBOUND BODIES
	var/list/boundnetworks = list(REMOTE_AI_ROBOT)
	var/list/list/bounded = list()

	//VAURCA REALM
	var/list/realmspawn = list() //Spawn points
	var/list/realm_areas = list()
	var/list/realm_users = list() //Users and their permission level
//	var/list/realmbanned_augs = list() //Unused, but a simple blacklist to skip over when creating realm avatars
	var/unlocked = FALSE

/datum/controller/subsystem/virtualreality/Initialize()
	for(var/network in mechnetworks)
		mechs[network] = list()
	for(var/network in robotnetworks)
		robots[network] = list()
	for(var/network in boundnetworks)
		bounded[network] = list()

	return SS_INIT_SUCCESS


/datum/controller/subsystem/virtualreality/proc/add_mech(var/mob/living/heavy_vehicle/mech, var/network)
	if(mech && network)
		mechs[network] += mech

/datum/controller/subsystem/virtualreality/proc/remove_mech(var/mob/living/heavy_vehicle/mech, var/network)
	if(mech && network)
		mechs[network].Remove(mech)

/datum/controller/subsystem/virtualreality/proc/add_robot(var/mob/living/robot, var/network)
	if(robot && network)
		robots[network] += robot
		RegisterSignal(robot, COMSIG_QDELETING, PROC_REF(remove_robot), TRUE)

/datum/controller/subsystem/virtualreality/proc/remove_robot(var/mob/living/robot, var/network)
	if(robot)
		if(network in robots) //This is because signals cannot pass parameters, and QDEL passes the force parameter here
			robots[network].Remove(robot)
		else
			for(var/k in robots)
				robots[k].Remove(robot)

/datum/controller/subsystem/virtualreality/proc/add_bound(var/mob/living/silicon/bound, var/network)
	if(bound && network)
		bounded[network] += bound

/datum/controller/subsystem/virtualreality/proc/remove_bound(var/mob/living/silicon/bound, var/network)
	if(bound && network)
		bounded[network].Remove(bound)


/mob
	var/mob/living/vr_mob = null // In which mob is our mind
	var/mob/living/old_mob = null // Which mob is our old mob

/// Return to original body
/mob/proc/body_return()
	set name = "Return to Body"
	set category = "IC"

	if(old_mob)
		ckey_transfer(old_mob)
		languages = list(GLOB.all_languages[LANGUAGE_TCB])
		if(old_mob.client)
			old_mob.client.init_verbs() // We need to have the stat panel to update, so we call this directly
		to_chat(old_mob, SPAN_NOTICE("System exited safely."))
		old_mob = null
	else
		to_chat(src, SPAN_DANGER("Interface error, you cannot exit the system at this time."))
		to_chat(src, SPAN_WARNING("Ahelp to get back into your body, a bug has occurred."))

/mob/living/silicon/body_return()
	set name = "Return to Body"
	set category = "IC"

	if(old_mob)
		ckey_transfer(old_mob)
		speech_synthesizer_langs = list(GLOB.all_languages[LANGUAGE_TCB])
		if(old_mob.client)
			old_mob.client.init_verbs()
		to_chat(old_mob, SPAN_NOTICE("System exited safely, we hope you enjoyed your stay."))
		old_mob = null
	else
		to_chat(src, SPAN_DANGER("Interface error, you cannot exit the system at this time."))
		to_chat(src, SPAN_WARNING("Ahelp to get back into your body, a bug has occurred."))

/mob/living/simple_animal/spiderbot/body_return()
	set name = "Return to Body"
	set category = "IC"

	if(old_mob)
		ckey_transfer(old_mob)
		languages = list(GLOB.all_languages[LANGUAGE_TCB])
		internal_id.access = list()
		if(old_mob.client)
			old_mob.client.init_verbs()
		to_chat(old_mob, SPAN_NOTICE("System exited safely, we hope you enjoyed your stay."))
		old_mob = null
	else
		to_chat(src, SPAN_DANGER("Interface error, you cannot exit the system at this time."))
		to_chat(src, SPAN_WARNING("Ahelp to get back into your body, a bug has occurred."))

/mob/living/carbon/human/virtual_reality/body_return()
	set name = "Return to Body"
	set category = "IC"

	if(old_mob)
		ckey_transfer(old_mob)
		languages = list(GLOB.all_languages[LANGUAGE_TCB])
		if(old_mob.client)
			old_mob.client.init_verbs()
		to_chat(old_mob, SPAN_NOTICE("System exited safely, we hope you enjoyed your stay."))
		old_mob = null
		qdel(src)
	else
		to_chat(src, SPAN_DANGER("Interface error, you cannot exit the system at this time."))
		to_chat(src, SPAN_WARNING("Ahelp to get back into your body, a bug has occurred."))

/mob/living/proc/vr_mob_exit_languages()
	languages = list(GLOB.all_languages[LANGUAGE_TCB])

/mob/living/silicon/vr_mob_exit_languages()
	..()
	speech_synthesizer_langs = list(GLOB.all_languages[LANGUAGE_TCB])

// Handles saving of the original mob and assigning the new mob
/datum/controller/subsystem/virtualreality/proc/mind_transfer(var/mob/living/M, var/mob/living/target, var/realm = FALSE)
	var/new_ckey = M.ckey
	target.old_mob = M
	M.vr_mob = target
	target.ckey = new_ckey
	M.ckey = "@[new_ckey]"
	add_verb(target, /mob/proc/body_return)

	target.get_vr_name(M)
	M.swap_languages(target)

	if(target.client)
		target.client.screen |= GLOB.global_hud.vr_control

	if(istype(target, /mob/living/simple_animal/spiderbot) && !istype(target, /mob/living/simple_animal/spiderbot/ai))
		var/mob/living/simple_animal/spiderbot/spider = target
		var/obj/item/card/id/original_id = M.GetIdCard()
		if(original_id)
			var/mob/living/simple_animal/spiderbot/SB = target
			SB.internal_id.access = original_id.access
		// Update radio
		var/obj/item/encryptionkey/Key = spider.radio.keyslot
		var/obj/item/radio/Radio = M.get_radio()
		if(Key && Radio)
			Key.channels = Radio.channels
			spider.radio.recalculateChannels()

	target.client.init_verbs()
	if(realm)
		to_chat(target, SPAN_NOTICE("You feel your mind broaden and senses enhance as the connection establishes."))
		to_chat(target, "<i><span class='game say'>Hivenet, <span class='name'>Cephalon</span> projects <span class='vaurca'>a new arrival.</span></span></i>")
	else
		to_chat(target, SPAN_NOTICE("Connection established, system suite active and calibrated."))
	to_chat(target, SPAN_WARNING("To exit this mode, use the \"Return to Body\" verb in the IC tab."))

/mob/living/proc/swap_languages(var/mob/target)
	target.languages = languages
	if(issilicon(target))
		var/mob/living/silicon/T = target
		T.speech_synthesizer_langs = languages

/mob/living/silicon/swap_languages(mob/target)
	target.languages = speech_synthesizer_langs
	if(issilicon(target))
		var/mob/living/silicon/T = target
		T.speech_synthesizer_langs = speech_synthesizer_langs

/mob/proc/get_vr_name(var/mob/user)
	return

/mob/living/simple_animal/spiderbot/get_vr_name(mob/user)
	real_name = "Remote-Bot ([user.real_name])"
	name = real_name
	voice_name = user.real_name // name that'll display on radios

/mob/proc/ckey_transfer(var/mob/target, var/null_vr_mob = TRUE)
	target.ckey = src.ckey
	src.ckey = null
	if(null_vr_mob)
		target.vr_mob = null

/// Returns a list with all remote controlable exosuits on the given network
/datum/controller/subsystem/virtualreality/proc/mech_choices(var/user, var/network)
	var/list/mech = list()

	for(var/mob/living/heavy_vehicle/R in mechs[network])
		var/turf/T = get_turf(R)
		if(!T)
			continue
		if(!is_station_level(T.z))
			continue
		if(!R.remote)
			continue
		if(!R.pilots.len)
			continue
		var/mob/living/mech_pilot = R.pilots[1]
		if(mech_pilot.client || mech_pilot.ckey)
			continue
		if(mech_pilot.stat == DEAD)
			continue
		mech[R.name] = R

	return mech

/// Retrieves a list returned by mech_choices and prompts user to select an option to transfer to
/datum/controller/subsystem/virtualreality/proc/mech_selection(var/user, var/network)
	var/list/remote = mech_choices(user, network)
	if(!length(remote))
		to_chat(user, SPAN_WARNING("No active remote mechs are available."))
		return

	var/choice = tgui_input_list(usr, "Please select a remote control compatible mech to take over.", "Remote Mech Selection", remote)
	if(!choice)
		return

	var/mob/living/heavy_vehicle/chosen_mech = remote[choice]
	var/mob/living/remote_pilot = chosen_mech.pilots[1] // the first pilot
	mind_transfer(user, remote_pilot)


/// Returns a list with all remote controlable robots on the given network
/datum/controller/subsystem/virtualreality/proc/robot_choices(var/user, var/network)
	var/list/robot = list()

	for(var/mob/living/R in robots[network])
		var/turf/T = get_turf(R)
		if(!T)
			continue
		if(!is_station_level(T.z))
			continue
		if(R.client || R.ckey)
			continue
		if(R.stat == DEAD)
			continue
		robot[R.name] = R

	return robot

/// Retrieves a list returned by robot_choices and prompts user to select an option to transfer to
/datum/controller/subsystem/virtualreality/proc/robot_selection(var/user, var/network)
	var/list/remote = robot_choices(user, network)
	if(!length(remote))
		to_chat(user, SPAN_WARNING("No active remote units are available."))

	var/choice = tgui_input_list(usr, "Please select a remote control unit to take over.", "Remote Unit Selection", remote)
	if(!(choice in remote))
		return

	mind_transfer(user, choice)

/// Returns a list with all remote controlable bound on the given network
/datum/controller/subsystem/virtualreality/proc/bound_choices(var/user, var/network)
	var/list/bound = list()

	for(var/mob/living/silicon/R in bounded[network])
		var/turf/T = get_turf(R)
		if(!T)
			continue
		if(!is_station_level(T.z))
			continue
		if(R.client || R.ckey)
			continue
		if(R.stat == DEAD)
			continue
		bound += R

	return bound

/// Retrieves a list returned by bound_choices and prompts user to select an option to transfer to
/datum/controller/subsystem/virtualreality/proc/bound_selection(var/user, var/network)
	var/list/remote = bound_choices(user, network)
	if(!length(remote))
		to_chat(user, SPAN_WARNING("No active remote units are available."))

	var/choice = tgui_input_list(usr, "Please select a remote control unit to take over.", "Remote Unit Selection", remote)
	if(!(choice in remote))
		return

	mind_transfer(user, choice)

//TODO: copy origin, culture, citizenship, flavortext, etc. vars & iterate through organs in user.contents to dupe augments
/datum/controller/subsystem/virtualreality/proc/create_virtual_reality_avatar(var/mob/living/carbon/human/user, var/realm = FALSE)
	if(GLOB.virtual_reality_spawn.len)
		if(realm)
			var/mob/living/carbon/human/virtual_reality/realm/H = new /mob/living/carbon/human/virtual_reality/realm(pick(realmspawn))
			H.set_species(user.species.name, 1)

			H.age = user.age
			H.gender = user.gender
			H.dna = user.dna.Clone()
			H.real_name = user.real_name
			H.culture = user.culture
			H.origin = user.origin
			H.citizenship = user.citizenship
			H.religion = user.religion
			H.accent = user.accent
			H.height = user.height
			H.employer_faction = user.employer_faction
			H.flavor_texts = user.flavor_texts.Copy()
			H.UpdateAppearance()

			for(var/obj/item/organ/external/O in user.contents) //Copy robot limbs
				if(BP_IS_ROBOTIC(O))
					var/savedname = "[O.name]"
					var/saveddesc = "[O.desc]"
					var/savedtype = "[O.robotize_type]"
					var/savedicon = "[O.force_icon]"
					O = new O.type(H.loc)
					O.name = "[savedname]"
					O.desc = "[saveddesc]"
					O.robotize_type = savedtype
					O.force_icon = savedicon
					var/obj/item/organ/external/targetpart = H.get_organ(O.parent_organ)
					var/obj/item/organ/external/replaceme = H.organs_by_name[O.limb_name]
					H.organs -= replaceme
					H.contents -= replaceme
					to_world("[O] is prosthetic! BP is [replaceme], robotized!")
					O.robotize()
					O.replaced(H, targetpart)
					H.UpdateAppearance()
					to_world("O:[O]")

			for(var/obj/item/organ/internal/O in user.contents) //Now copy internal augments & organs
				if(BP_IS_ROBOTIC(O))
					var/savedname = "[O.name]"
					var/saveddesc = "[O.desc]"
					var/savedtype = "[O.robotize_type]"
					O = new O.type(H.loc)
					O.name = "[savedname]"
					O.desc = "[saveddesc]"
					O.robotize_type = savedtype
					var/obj/item/organ/external/targetpart = H.get_organ(O.parent_organ)
					var/obj/item/organ/external/replaceme = H.internal_organs_by_name[O.organ_tag]
					H.internal_organs -= replaceme
					H.contents -= replaceme
					O.robotize()
					O.replaced(H, targetpart)
					H.UpdateAppearance()

			if(H.species.has_psionics)
				H.species.has_psionics = FALSE //Otherwise avatars can affect the Nlom & appear in Srom

			for(var/obj/item/i in user.get_equipped_items(INCLUDE_POCKETS|INCLUDE_HELD))
				var/savedname = "[i.name]"
				var/saveddesc = "[i.desc]"
				var/savedcontents
				if(istype(i, /obj/item/storage))
					savedcontents = i.contents.Copy()
				i = new i.type(H.loc)
				i.name = "[savedname]"
				i.desc = "[saveddesc]"
				if(savedcontents)
					i.contents = savedcontents
				H.equip_to_appropriate_slot(i)

			mind_transfer(user, H, TRUE)
			to_chat(H, SPAN_NOTICE("You are now in the Aether. Dying will return you to the Cephalon."))
		else
			var/mob/living/carbon/human/virtual_reality/H = new /mob/living/carbon/human/virtual_reality(pick(GLOB.virtual_reality_spawn))
			H.set_species(user.species.name, 1)

			H.gender = user.gender
			H.dna = user.dna.Clone()
			H.real_name = user.real_name
			H.UpdateAppearance()

			H.preEquipOutfit(/obj/outfit/admin/virtual_reality, FALSE)
			H.equipOutfit(/obj/outfit/admin/virtual_reality, FALSE)

			mind_transfer(user, H)
			to_chat(H, SPAN_NOTICE("You are now in control of a virtual reality body. Dying will return you to your original body."))

/area/centcom/realm
	name = "Virtual Realm"
	icon_state = "realm"
	area_blurb = "A local pocket realm of VR. Normally locked without a Ta's approval."
