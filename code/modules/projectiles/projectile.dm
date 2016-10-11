/obj/item/projectile
	name = "projectile"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bullet"
	density = 0
	anchored = 1
	flags = ABSTRACT
	pass_flags = PASSTABLE
	mouse_opacity = 0
	hitsound = 'sound/weapons/pierce.ogg'
	var/hitsound_wall = ""

	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/def_zone = ""	//Aiming at
	var/mob/firer = null//Who shot it
	var/obj/item/ammo_casing/ammo_casing = null
	var/suppressed = 0	//Attack message
	var/yo = null
	var/xo = null
	var/current = null
	var/atom/original = null // the original target clicked
	var/turf/starting = null // the projectile's starting turf
	var/list/permutated = list() // we've passed through these atoms, don't try to hit them again
	var/paused = FALSE //for suspending the projectile midair
	var/p_x = 16
	var/p_y = 16			// the pixel location of the tile that the player clicked. Default is the center
	var/speed = 1			//Amount of deciseconds it takes for projectile to travel
	var/Angle = 0
	var/spread = 0			//amount (in degrees) of projectile spread
	var/legacy = 0			//legacy projectile system
	animate_movement = 0	//Use SLIDE_STEPS in conjunction with legacy

	var/damage = 10
	var/damage_type = BRUTE //BRUTE, BURN, TOX, OXY, CLONE are the only things that should be in here
	var/nodamage = 0 //Determines if the projectile will skip any damage inflictions
	var/flag = "bullet" //Defines what armor to use when it hits things.  Must be set to bullet, laser, energy,or bomb
	var/projectile_type = /obj/item/projectile
	var/range = 50 //This will de-increment every step. When 0, it will delete the projectile.
		//Effects
	var/stun = 0
	var/weaken = 0
	var/paralyze = 0
	var/irradiate = 0
	var/stutter = 0
	var/slur = 0
	var/eyeblur = 0
	var/drowsy = 0
	var/stamina = 0
	var/jitter = 0
	var/forcedodge = 0 //to pass through everything
	var/dismemberment = 0 //The higher the number, the greater the bonus to dismembering. 0 will not dismember at all.
	var/impact_effect_type //what type of impact effect to show when hitting something

/obj/item/projectile/New()
	permutated = list()
	return ..()

/obj/item/projectile/proc/Range()
	range--
	if(range <= 0 && loc)
		on_range()

/obj/item/projectile/proc/on_range() //if we want there to be effects when they reach the end of their range
	qdel(src)

//to get the correct limb (if any) for the projectile hit message
/mob/living/proc/check_limb_hit(hit_zone)
	if(has_limbs)
		return hit_zone

/mob/living/carbon/check_limb_hit(hit_zone)
	if(get_bodypart(hit_zone))
		return hit_zone
	else //when a limb is missing the damage is actually passed to the chest
		return "chest"

/obj/item/projectile/proc/on_hit(atom/target, blocked = 0)
	var/turf/target_loca = get_turf(target)
	if(!isliving(target))
		if(impact_effect_type)
			PoolOrNew(impact_effect_type, list(target_loca, target, src))
		return 0
	var/mob/living/L = target
	if(blocked != 100) // not completely blocked
		if(damage && L.blood_volume && damage_type == BRUTE)
			var/splatter_dir = dir
			if(starting)
				splatter_dir = get_dir(starting, target_loca)
			if(isalien(L))
				PoolOrNew(/obj/effect/overlay/temp/dir_setting/bloodsplatter/xenosplatter, list(target_loca, splatter_dir))
			else
				PoolOrNew(/obj/effect/overlay/temp/dir_setting/bloodsplatter, list(target_loca, splatter_dir))
			if(prob(33))
				L.add_splatter_floor(target_loca)
		else if(impact_effect_type)
			PoolOrNew(impact_effect_type, list(target_loca, target, src))

		var/organ_hit_text = ""
		var/limb_hit = L.check_limb_hit(def_zone)//to get the correct message info.
		if(limb_hit)
			organ_hit_text = " in \the [parse_zone(limb_hit)]"
		if(suppressed)
			playsound(loc, hitsound, 5, 1, -1)
			L << "<span class='userdanger'>You're shot by \a [src][organ_hit_text]!</span>"
		else
			if(hitsound)
				var/volume = vol_by_damage()
				playsound(loc, hitsound, volume, 1, -1)
			L.visible_message("<span class='danger'>[L] is hit by \a [src][organ_hit_text]!</span>", \
								"<span class='userdanger'>[L] is hit by \a [src][organ_hit_text]!</span>")	//X has fired Y is now given by the guns so you cant tell who shot you if you could not see the shooter
		L.on_hit(type)

	var/reagent_note
	if(reagents && reagents.reagent_list)
		reagent_note = " REAGENTS:"
		for(var/datum/reagent/R in reagents.reagent_list)
			reagent_note += R.id + " ("
			reagent_note += num2text(R.volume) + ") "

	add_logs(firer, L, "shot", src, reagent_note)
	return L.apply_effects(stun, weaken, paralyze, irradiate, slur, stutter, eyeblur, drowsy, blocked, stamina, jitter)

/obj/item/projectile/proc/vol_by_damage()
	if(src.damage)
		return Clamp((src.damage) * 0.67, 30, 100)// Multiply projectile damage by 0.67, then clamp the value between 30 and 100
	else
		return 50 //if the projectile doesn't do damage, play its hitsound at 50% volume

/obj/item/projectile/Bump(atom/A, yes)
	if(!yes) //prevents double bumps.
		return
	if(firer)
		if(A == firer || (A == firer.loc && istype(A, /obj/mecha))) //cannot shoot yourself or your mech
			loc = A.loc
			return 0

	var/distance = get_dist(get_turf(A), starting) // Get the distance between the turf shot from and the mob we hit and use that for the calculations.
	def_zone = ran_zone(def_zone, max(100-(7*distance), 5)) //Lower accurancy/longer range tradeoff. 7 is a balanced number to use.

	if(isturf(A) && hitsound_wall)
		var/volume = Clamp(vol_by_damage() + 20, 0, 100)
		if(suppressed)
			volume = 5
		playsound(loc, hitsound_wall, volume, 1, -1)

	var/turf/target_turf = get_turf(A)

	var/permutation = A.bullet_act(src, def_zone) // searches for return value, could be deleted after run so check A isn't null
	if(permutation == -1 || forcedodge)// the bullet passes through a dense object!
		loc = target_turf
		if(A)
			permutated.Add(A)
		return 0
	else
		if(A && A.density && !ismob(A) && !(A.flags & ON_BORDER)) //if we hit a dense non-border obj or dense turf then we also hit one of the mobs on that tile.
			var/list/mobs_list = list()
			for(var/mob/living/L in target_turf)
				mobs_list += L
			if(mobs_list.len)
				var/mob/living/picked_mob = pick(mobs_list)
				picked_mob.bullet_act(src, def_zone)
	qdel(src)

/obj/item/projectile/Process_Spacemove(var/movement_dir = 0)
	return 1 //Bullets don't drift in space

/obj/item/projectile/proc/fire(var/setAngle)
	if(setAngle)
		Angle = setAngle
	if(!legacy) //new projectiles
		set waitfor = 0
		var/next_run = world.time
		while(loc)
			if(paused)
				next_run = world.time
				sleep(1)
				continue

			if((!( current ) || loc == current))
				current = locate(Clamp(x+xo,1,world.maxx),Clamp(y+yo,1,world.maxy),z)

			if(!Angle)
				Angle=round(Get_Angle(src,current))
			if(spread)
				Angle += (rand() - 0.5) * spread
			var/matrix/M = new
			M.Turn(Angle)
			transform = M

			var/Pixel_x=round(sin(Angle)+16*sin(Angle)*2)
			var/Pixel_y=round(cos(Angle)+16*cos(Angle)*2)
			var/pixel_x_offset = pixel_x + Pixel_x
			var/pixel_y_offset = pixel_y + Pixel_y
			var/new_x = x
			var/new_y = y

			while(pixel_x_offset > 16)
				pixel_x_offset -= 32
				pixel_x -= 32
				new_x++// x++
			while(pixel_x_offset < -16)
				pixel_x_offset += 32
				pixel_x += 32
				new_x--

			while(pixel_y_offset > 16)
				pixel_y_offset -= 32
				pixel_y -= 32
				new_y++
			while(pixel_y_offset < -16)
				pixel_y_offset += 32
				pixel_y += 32
				new_y--

			step_towards(src, locate(new_x, new_y, z))
			next_run += max(world.tick_lag, speed)
			var/delay = next_run - world.time
			if(delay <= world.tick_lag*2)
				pixel_x = pixel_x_offset
				pixel_y = pixel_y_offset
			else
				animate(src, pixel_x = pixel_x_offset, pixel_y = pixel_y_offset, time = max(1, (delay <= 3 ? delay - 1 : delay)))

			if(original && (original.layer>=2.75) || ismob(original))
				if(loc == get_turf(original))
					if(!(original in permutated))
						Bump(original, 1)
			Range()
			if (delay > 0)
				sleep(delay)

	else //old projectile system
		set waitfor = 0
		while(loc)
			if(!paused)
				if((!( current ) || loc == current))
					current = locate(Clamp(x+xo,1,world.maxx),Clamp(y+yo,1,world.maxy),z)
				step_towards(src, current)
				if(original && (original.layer>=2.75) || ismob(original))
					if(loc == get_turf(original))
						if(!(original in permutated))
							Bump(original, 1)
				Range()
			sleep(config.run_speed * 0.9)


/obj/item/projectile/Crossed(atom/movable/AM) //A mob moving on a tile with a projectile is hit by it.
	..()
	if(isliving(AM) && AM.density && !checkpass(PASSMOB))
		Bump(AM, 1)

/obj/item/projectile/Destroy()
	ammo_casing = null
	return ..()

/obj/item/projectile/proc/dumbfire(var/dir)
	current = get_ranged_target_turf(src, dir, world.maxx)
	fire()


/obj/item/projectile/experience_pressure_difference()
	return