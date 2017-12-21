/obj/item/integrated_circuit/time
	name = "time circuit"
	desc = "Now you can build your own clock!"
	complexity = 2
	inputs = list()
	outputs = list()
	category_text = "Time"

/obj/item/integrated_circuit/time/delay
	name = "two-sec delay circuit"
	desc = "This sends a pulse signal out after a delay, critical for ensuring proper control flow in a complex machine.  \
	This circuit is set to send a pulse after a delay of two seconds."
	icon_state = "delay-20"
	var/delay = 20
	activators = list("incoming"= IC_PINTYPE_PULSE_IN,"outgoing" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 2

/obj/item/integrated_circuit/time/delay/do_work()
	addtimer(CALLBACK(src, .proc/activate_pin, 2), delay)

/obj/item/integrated_circuit/time/delay/five_sec
	name = "five-sec delay circuit"
	desc = "This sends a pulse signal out after a delay, critical for ensuring proper control flow in a complex machine.  \
	This circuit is set to send a pulse after a delay of five seconds."
	icon_state = "delay-50"
	delay = 50
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/time/delay/one_sec
	name = "one-sec delay circuit"
	desc = "This sends a pulse signal out after a delay, critical for ensuring proper control flow in a complex machine.  \
	This circuit is set to send a pulse after a delay of one second."
	icon_state = "delay-10"
	delay = 10
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/time/delay/half_sec
	name = "half-sec delay circuit"
	desc = "This sends a pulse signal out after a delay, critical for ensuring proper control flow in a complex machine.  \
	This circuit is set to send a pulse after a delay of half a second."
	icon_state = "delay-5"
	delay = 5
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/time/delay/tenth_sec
	name = "tenth-sec delay circuit"
	desc = "This sends a pulse signal out after a delay, critical for ensuring proper control flow in a complex machine.  \
	This circuit is set to send a pulse after a delay of 1/10th of a second."
	icon_state = "delay-1"
	delay = 1
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/time/delay/custom
	name = "custom delay circuit"
	desc = "This sends a pulse signal out after a delay, critical for ensuring proper control flow in a complex machine.  \
	This circuit's delay can be customized, between 1/10th of a second to one hour.  The delay is updated upon receiving a pulse."
	icon_state = "delay"
	inputs = list("delay time" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/time/delay/custom/do_work()
	var/delay_input = get_pin_data(IC_INPUT, 1)
	if(delay_input && isnum(delay_input) )
		var/new_delay = CLAMP(delay_input ,1 ,36000) //An hour.
		delay = new_delay

	..()

/obj/item/integrated_circuit/time/ticker
	name = "ticker circuit"
	desc = "This circuit sends an automatic pulse every four seconds."
	icon_state = "tick-m"
	complexity = 8
	var/delay = 4 SECONDS
	var/next_fire = 0
	var/is_running = FALSE
	inputs = list("enable ticking" = IC_PINTYPE_BOOLEAN)
	activators = list("outgoing pulse" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 4

/obj/item/integrated_circuit/time/ticker/Destroy()
	if(is_running)
		STOP_PROCESSING(SSfastprocess, src)
	return ..()

/obj/item/integrated_circuit/time/ticker/on_data_written()
	var/do_tick = get_pin_data(IC_INPUT, 1)
	if(do_tick && !is_running)
		is_running = TRUE
		tick()
	else if(is_running)
		is_running = FALSE


/obj/item/integrated_circuit/time/ticker/proc/tick()
	if(is_running)
		addtimer(CALLBACK(src, .proc/tick), delay)
		if(world.time > next_fire)
			next_fire = world.time + delay
			activate_pin(1)


/obj/item/integrated_circuit/time/ticker/fast
	name = "fast ticker"
	desc = "This advanced circuit sends an automatic pulse every two seconds."
	icon_state = "tick-f"
	complexity = 12
	delay = 2 SECONDS
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 8

/obj/item/integrated_circuit/time/ticker/slow
	name = "slow ticker"
	desc = "This simple circuit sends an automatic pulse every six seconds."
	icon_state = "tick-s"
	complexity = 4
	delay = 6 SECONDS
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 2

/obj/item/integrated_circuit/time/clock
	name = "integrated clock"
	desc = "Tells you what the local time is, specific to your station or planet."
	icon_state = "clock"
	inputs = list()
	outputs = list(
		"time" = IC_PINTYPE_STRING,
		"hours" = IC_PINTYPE_NUMBER,
		"minutes" = IC_PINTYPE_NUMBER,
		"seconds" = IC_PINTYPE_NUMBER
		)
	activators = list("get time" = IC_PINTYPE_PULSE_IN, "on time got" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 4

/obj/item/integrated_circuit/time/clock/do_work()
	var/wtime = world.time
	set_pin_data(IC_OUTPUT, 1, time2text(wtime, "hh:mm:ss") )
	set_pin_data(IC_OUTPUT, 2, text2num(time2text(wtime, "hh") ) )
	set_pin_data(IC_OUTPUT, 3, text2num(time2text(wtime, "mm") ) )
	set_pin_data(IC_OUTPUT, 4, text2num(time2text(wtime, "ss") ) )
	push_data()
	activate_pin(2)