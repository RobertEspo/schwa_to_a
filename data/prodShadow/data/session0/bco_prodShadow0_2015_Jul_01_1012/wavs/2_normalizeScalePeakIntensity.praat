Create Strings as file list... soundFiles /Users/casillas/academia/research/in_progress/dissertation/experiments/3_prod/experimentFiles/prodShadow/data/session0/bco_prodShadow0_2015_Jul_01_1012/wavs/*.wav
select Strings soundFiles
numberOfFiles = Get number of strings

for i to numberOfFiles
	select Strings soundFiles
	soundName$ = Get string... i
	Read from file... /Users/casillas/academia/research/in_progress/dissertation/experiments/3_prod/experimentFiles/prodShadow/data/session0/bco_prodShadow0_2015_Jul_01_1012/wavs/'soundName$'
	Scale peak... 0.99
	Write to binary file... /Users/casillas/academia/research/in_progress/dissertation/experiments/3_prod/experimentFiles/prodShadow/data/session0/bco_prodShadow0_2015_Jul_01_1012/wavs/'soundName$'
	Remove
endfor