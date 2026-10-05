### RelicHelper
* **Description:** Designed specifically for the **World of Warcraft 2.5.3 client** (TBC Classic) to assist with the Ogr'la Simon-says daily quest ("Simon Says" / "Magtheridon's Eye" memory game minigame). It records sequence inputs via keyboard arrow keys and allows players to replay or iterate through the recorded pattern using custom macros.
* **How to Use:**
  1. Place the folder into `Interface\AddOns\` ensuring the folder name and `.toc` match (`RelicHelper`).
  2. Approach the Ogr'la memory crystal challenge in-game and use your keyboard arrow keys to input or record the pattern sequence.
  3. Bind a macro using the built-in command to step through or replay the sequence window:
     ```text
     /rh next
     ```
* **Known Issues & Gotchas:**
  * **Timing Windows:** If inputs or macro triggers are spammed faster than the game's frame update or server response threshold during the memory sequence, steps can occasionally clip or de-sync from the crystal's actual state.
  * **Keybind Conflicts:** Ensure your directional arrow keys are not bound to critical movement actions that conflict while recording sequences on the fly.
<img width="351" height="355" alt="image" src="https://github.com/user-attachments/assets/fa94dffe-0ee7-4a7b-b9a1-16a17cf2fbb1" />
