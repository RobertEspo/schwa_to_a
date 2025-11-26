form Arguments
	sentence input_dir C:\Users\rober\Desktop\schwa_to_a\recordings\testing\wavs_and_textgrids
	sentence output_dir C:\Users\rober\Desktop\schwa_to_a\recordings\testing\test
	positive tier_number 2
endform

Create Strings as file list: "fileList", input_dir$ + "\*.TextGrid"
object_list = selected("Strings")
num_files = Get number of strings

for i from 1 to num_files
	select object_list
	file_name$ = Get string: i
	base_name$ = replace$(file_name$, ".TextGrid", "", 0)
    
	wav_file$ = input_dir$ + "\" + base_name$ + ".wav"
	tg_file$ = input_dir$ + "\" + base_name$ + ".TextGrid"
	# Load TextGrid
	Read from file: tg_file$

	num_intervals = Get number of intervals: tier_number

	label$ = Get label of interval: tier_number, num_intervals
	
	# if last interval is not empty
	if label$ != ""
		start_time = Get start time of interval: tier_number, num_intervals
                end_time = Get end time of interval: tier_number, num_intervals

		# Extract and save textgrid
		Extract part: start_time, end_time, "no"
     		output_tg$ = output_dir$ + "\" + base_name$ + "_token.TextGrid"
    		Save as text file: output_tg$
		
		# Load corresponding WAV file
		Read from file: wav_file$
		sound = selected("Sound")

 		# Extract verb segment
    		select sound
    		Extract part: start_time, end_time, "rectangular", 1, "no"

		# Save the extracted verb
    		output_wav$ = output_dir$ + "\" + base_name$ + "_token.wav"
    		Save as WAV file: output_wav$
				
		# clean up
		select all
		minusObject: object_list
		Remove
	
	# if last interval is empty
	else
		label$ = Get label of interval: tier_number, num_intervals - 1
		
		start_time = Get start time of interval: tier_number, num_intervals - 1
                end_time = Get end time of interval: tier_number, num_intervals - 1

		# Extract and save textgrid
		Extract part: start_time, end_time, "no"
     		output_tg$ = output_dir$ + "\" + base_name$ + "_token.TextGrid"
    		Save as text file: output_tg$
		
		# Load corresponding WAV file
		Read from file: wav_file$
		sound = selected("Sound")

 		# Extract verb segment
    		select sound
    		Extract part: start_time, end_time, "rectangular", 1, "no"

		# Save the extracted verb
    		output_wav$ = output_dir$ + "\" + base_name$ + "_token.wav"
    		Save as WAV file: output_wav$
				
		# clean up
		select all
		minusObject: object_list
		Remove
	endif
endfor