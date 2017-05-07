//Created to fit with the code standard already employed for mobs. Though this file contains very little at the moment
/mob/living/update_scale(var/animate = 0)
	var/matrix/M = matrix()
	M.Scale(size_multiplier)
	M.Translate(0, 16*(size_multiplier-1))
	if (animate)
		animate(src, transform = M, time = 30)
	else
		transform = M