/obj/item/weapon/teleportation_scroll
	name = "scroll of teleportation"
	desc = "A scroll for moving around."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "scroll"
	var/uses = 4
	w_class = 2
	item_state = "paper"
	throw_speed = 3
	throw_range = 7
	origin_tech = "bluespace=6"
	resistance_flags = FLAMMABLE

/obj/item/weapon/teleportation_scroll/apprentice
	name = "lesser scroll of teleportation"
	uses = 1
	origin_tech = "bluespace=5"



/obj/item/weapon/teleportation_scroll/attack_self(mob/user)
	user.set_machine(src)
	var/dat = "<B>Teleportation Scroll:</B><BR>"
	dat += "Number of uses: [src.uses]<BR>"
	dat += "<HR>"
	dat += "<B>Four uses, use them wisely:</B><BR>"
	dat += "<A href='byond://?src=\ref[src];spell_teleport=1'>Teleport</A><BR>"
	dat += "Kind regards,<br>Wizards Federation<br><br>P.S. Don't forget to bring your gear, you'll need it to cast most spells.<HR>"
	user << browse(dat, "window=scroll")
	onclose(user, "scroll")
	return

/obj/item/weapon/teleportation_scroll/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained() || src.loc != usr)
		return
	if (!ishuman(usr))
		return 1
	var/mob/living/carbon/human/H = usr
	if ((H == src.loc || (in_range(src, H) && istype(src.loc, /turf))))
		H.set_machine(src)
		if (href_list["spell_teleport"])
			if (src.uses >= 1)
				teleportscroll(H)
	if(H)
		attack_self(H)
	return

/obj/item/weapon/teleportation_scroll/proc/teleportscroll(mob/user)

	var/A

	A = input(user, "Area to jump to", "BOOYEA", A) in teleportlocs|null
	if(!A)
		return
	var/area/thearea = teleportlocs[A]

	if (!user || user.stat || user.restrained() || uses <= 0)
		return
	if(!((user == loc || (in_range(src, user) && istype(src.loc, /turf)))))
		return

	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(2, user.loc)
	smoke.attach(user)
	smoke.start()
	var/list/L = list()
	for(var/turf/T in get_area_turfs(thearea.type))
		if(!T.density)
			var/clear = 1
			for(var/obj/O in T)
				if(O.density)
					clear = 0
					break
			if(clear)
				L+=T

	if(!L.len)
		user <<"The spell matrix was unable to locate a suitable teleport destination for an unknown reason. Sorry."
		return

	if(user && user.buckled)
		user.buckled.unbuckle_mob(user, force=1)

	var/list/tempL = L.Copy()
	var/attempt = null
	var/success = 0
	while(tempL.len)
		attempt = pick(tempL)
		user.Move(attempt)
		if(get_turf(user) == attempt)
			success = 1
			break
		else
			tempL.Remove(attempt)

	if(!success)
		user.loc = pick(L)

	smoke.start()
	src.uses -= 1
