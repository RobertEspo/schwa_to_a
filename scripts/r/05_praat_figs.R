praatpicture(sound = here("recordings","aligned","jal_prodShadow2_gota2.wav"),
             start = 0.40,
             end = 0.90,
             frames = c("spectrogram", "TextGrid"),
             formant_maxN = 3,
             formant_plotOnSpec = TRUE,
             formant_color = "red"
             )

png(here::here("figs","gota.png"), width = 800, height = 600, res = 300)

dev.off()
