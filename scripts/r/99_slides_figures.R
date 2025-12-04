source(here::here("scripts","r","00_libs.R"))

vowels <- data.frame(
  vowel = c("/a/", "/ɑ/", "/ə/"),
  F1 = c(638, 783, 665),
  F2 = c(1353, 1182, 1772)
)

vowel_space <- ggplot(vowels, aes(x = F2, y = F1, label = vowel)) +
  geom_text(aes(label = vowel)) +
  scale_x_reverse() +
  scale_y_reverse() +
  labs(x = "F2 (Hz)", y = "F1 (Hz)",
       title = "Vowel Space Plot (F1–F2)") +
  theme_minimal(base_size = 14)

ggsave(here("assets","phonetics_final_figs","vowels.png"))

