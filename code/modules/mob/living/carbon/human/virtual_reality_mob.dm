//this human mob is to be used in virtual reality, typically in their own environment where they won't interact with the rest of the world

/mob/living/carbon/human/virtual_reality/death(gibbed)//the body is deleted when you die to simulate your virtual avatar being deleted
	..()
	qdel(src)


/mob/living/carbon/human/virtual_reality/realm //Vaurca realm mobs are very special and very different

/mob/living/carbon/human/virtual_reality/realm/proc/DisablePsi(var/mob/living/carbon/human/H)
	if(H.species.has_psionics)
		H.species.has_psionics = FALSE //Otherwise avatars can affect the Nlom & appear in Srom

/mob/living/carbon/human/virtual_reality/realm/verb/VRform_item()
	set name = "Form Item"
	set category = "VR"

	var/mob/living/carbon/human/realself = old_mob

	var/list/ItemsOnSelf = list(realself.back, realself.l_store, realself.r_store, realself.wear_mask, realself.l_hand,
	realself.r_hand, realself.wear_id, realself.glasses, realself.gloves, realself.head, realself.shoes, realself.belt,
	realself.wear_suit, realself.w_uniform, realself.s_store, realself.l_ear, realself.r_ear, realself.wrists, realself.pants
	)

	var/obj/item/formed = tgui_input_list(src, "Select an item on your real self to form", "Form Item", ItemsOnSelf)
	var/formname = formed.name
	var/formdesc = formed.desc
	if(istype(formed, /obj/item/storage))
		var/choice = tgui_alert(src, "Form this alone, or select from contents within?", "Form Item", list("Form Storage", "Select Contents"))
		if(choice == "Select Contents")
			formed = tgui_input_list(src, "Select an item within the container", "Form Item", formed.contents)
			formname = "[formed.name]"
			formdesc = "[formed.desc]"
			if(istype(formed, /obj/item/storage))
				choice = tgui_alert(src, "Form this alone, or select from contents within?", "Form Item", list("Form Storage", "Select Contents"))
				if(choice == "Select Contents")
					formed = tgui_input_list(src, "Select an item within the container?", "Form Item", formed.contents)
					formname = formed.name
					formdesc = formed.desc

	formed = new formed.type(src.loc)
	formed.name = "[formname]"
	formed.desc = "[formdesc]"
	put_in_hands(formed)
	visible_message("[src] flicks [get_pronoun("his")] wrist and \a [formed.name] forms in hand.")

/mob/living/carbon/human/virtual_reality/realm/mode() //Conditional, contextual & intent-based abilities.
	. = ..()
	var/a_hand = get_active_hand()
	var/target_zone = src.zone_sel.selecting
	var/taste_sensitivity = src.species.taste_sensitivity

//Attach healing somewhere
	if(a_intent == I_HELP && target_zone == BP_MOUTH)
		if(a_hand == null)
			var/list/tastes = list("Hypersensitive" = TASTE_HYPERSENSITIVE, "Vaurca-like" = TASTE_SENSITIVE, "Human-like" = TASTE_NORMAL, "Dull" = TASTE_DULL, "Numb" = TASTE_NUMB)
			var/taste_choice = input(src, "How will you adjust your taste grasp's sensitivity?", "Taste Sensitivity", "Vaurca-like") as null|anything in tastes
			if(taste_choice)
				to_chat(src, SPAN_NOTICE("Your grasp's sense of taste will be <b>[taste_choice]</b>."))
				taste_sensitivity = tastes[taste_choice]
		var/obj/item/reagent_containers/food/food = a_hand
		to_chat(src, SPAN_NOTICE("You grasp \the [food]'s' taste...[food.reagents.generate_taste_message(src, taste_sensitivity)]"))

	if(a_intent == I_GRAB && a_hand == null && target_zone == BP_L_HAND || target_zone == BP_R_HAND)
		VRform_item() //Creation! Activate an empty hand w/ Grab intent to form an item

/mob/living/carbon/human/virtual_reality/realm/pointed(atom/A as mob|obj|turf in view())
	. = ..() //Help + face should share skill w/ target, Disarm should lock down, Harm should kick

	if(a_intent == I_HELP)
		if(ishuman(A) && src.zone_sel.selecting == BP_HEAD) //Information! My skills are yours!
			to_world("[A] TO BE FINISHED.")
		if(istype(A, src) && src.zone_sel.selecting == BP_MOUTH)
			var/mob/living/carbon/human/realself = old_mob
			src.species.reagent_tag ^= realself.species.reagent_tag
			to_chat(src, SPAN_NOTICE("You do away with normal taste."))

	if(a_intent == I_GRAB)
		if(isturf(A) && A in view(src.loc))
			var/turf/T = A
			if(!T || T.density || T.contains_dense_objects()) //Teleportation! Just copied & tweaked Veilstep
				to_chat(src, SPAN_WARNING("You may not teleport there."))
				return
			forceMove(get_turf(T))
			visible_message("[src] appears at \the [A].", SPAN_NOTICE("You appear at the location."))

		if(isitem(A) && A in view(src.loc)) //Apportation! Summon distant items for convenience
			var/obj/item/I = A
			I.visible_message("\The [I] vanishes.")
			I.forceMove(get_turf(src.loc))
			put_in_hands(I)
			visible_message("\A [I] appears in <b>[src]</b>'s hand.", SPAN_NOTICE("\The [I] is now in your grip."))

		if(istype(A, src) && src.zone_sel.selecting == BP_MOUTH) //Non-oxygenation! Toggle breathing
			if(HAS_TRAIT(src, TRAIT_PRESSURE_IMMUNITY))
				REMOVE_TRAIT(src, TRAIT_PRESSURE_IMMUNITY, INNATE_TRAIT)
				visible_message("[src]'s breaths fade.", SPAN_WARNING("You return a need to breathe and care for atmosphere."))
			else
				ADD_TRAIT(src, TRAIT_PRESSURE_IMMUNITY, INNATE_TRAIT)
				visible_message("[src] takes a breath.", SPAN_NOTICE("You remove your need to breathe and care for atmosphere."))

		if(istype(A, src) && src.zone_sel.selecting == BP_HEAD) //Self-mutation! Morph your own appearance or species for convenience
			var/list/morphable_species = list(SPECIES_HUMAN, SPECIES_SKRELL, SPECIES_SKRELL_AXIORI, SPECIES_UNATHI)
			var/mob/living/carbon/human/realself = old_mob
			morphable_species += realself.get_species()
			visible_message("[src]'s appearance ripples and warps slightly.", SPAN_NOTICE("You morph your avatar at will!"))
			var/choice = tgui_alert(src, "Morph your species?", "Morph avatar", list("Yes", "No"))
			if(choice == "Yes")
				choice = tgui_input_list(src, "Morph to which species?", "Morph avatar", morphable_species)
				src.set_species(choice)
				DisablePsi(src)
				if(choice == morphable_species[5]) //You can always return back to your original self
					src.UpdateAppearance() //Relies on avatar DNA not actually changing
			src.change_appearance(APPEARANCE_PLASTICSURGERY, src, FALSE)

/mob/living/carbon/human/virtual_reality/realm/verb/VRswitchgravity()
	set name = "Switch Gravity"
	set category = "VR"
	var/area/A = get_area(loc)
	to_world("[A] is A.")

	if(A.name != "Virtual Realm")
		return
	if(A && A.has_gravity())
		A.gravitychange(FALSE)
		to_world("Swapped false.")
	else
		A.gravitychange(TRUE)
		to_world("Swapped true.")

/mob/living/carbon/human/virtual_reality/realm/death(gibbed)
	..()
	qdel(src)
//TODO Have the body teleport to the Cephalon
//Origin & traits need to be same as realself, check for other vars too
//TODO abilities should log to Cephalon, in-realm Hivenet should also be encrypted to non-users
//Consider Lii'dra ewar too??
