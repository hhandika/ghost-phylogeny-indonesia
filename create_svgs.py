import os
import re

nexus_file = "data/indonesian_ghosts.nex"
output_dir = "assets"

os.makedirs(output_dir, exist_ok=True)

# 13 basic morphologies mapped from characters 11-23 (indices 10-22)
svg_templates = {
    # 0: Detached_flying_head (Head + dangling entrails)
    0: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="30" r="15" fill="black"/><path d="M45 45 Q40 70 50 80 T45 95" fill="none" stroke="black" stroke-width="4"/><path d="M55 45 Q60 65 50 75 T55 90" fill="none" stroke="black" stroke-width="4"/></svg>',
    
    # 1: Detached_upper_torso (Torso with no legs)
    1: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="20" r="10" fill="black"/><path d="M40 30 Q50 25 60 30 L65 50 L55 55 L55 65 L45 65 L45 55 L35 50 Z" fill="black"/></svg>',
    
    # 2: Spectral_female (Long hair, dress)
    2: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="15" r="8" fill="black"/><path d="M45 10 C35 15 35 40 40 40 C42 40 42 20 45 15 Z" fill="black"/><path d="M55 10 C65 15 65 40 60 40 C58 40 58 20 55 15 Z" fill="black"/><path d="M50 25 L35 85 L65 85 Z" fill="black"/><path d="M45 25 L30 50 L35 55 L45 35 Z" fill="black"/><path d="M55 25 L70 50 L65 55 L55 35 Z" fill="black"/></svg>',
    
    # 3: Bipedal_primateape (Gorilla-like)
    3: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="20" r="10" fill="black"/><path d="M35 30 Q50 20 65 30 L75 60 L65 65 L60 50 L60 85 L55 85 L55 60 L45 60 L45 85 L40 85 L40 50 L35 65 L25 60 Z" fill="black"/></svg>',
    
    # 4: Shrouded_corpse (Pocong)
    4: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M48 10 L52 10 L55 15 C58 20 58 80 55 85 L52 90 L48 90 L45 85 C42 80 42 20 45 15 Z" fill="black"/><path d="M45 25 L55 25" stroke="white" stroke-width="2"/><path d="M45 75 L55 75" stroke="white" stroke-width="2"/></svg>',
    
    # 5: Floating_fireball
    5: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M50 10 C70 40 80 60 65 80 C50 100 30 90 35 70 C20 80 15 60 30 50 C20 40 35 30 50 10 Z" fill="black"/></svg>',
    
    # 6: Gigantic_humanoidogre (Bulky, horns)
    6: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="15" r="12" fill="black"/><path d="M40 10 L30 5 L35 15 Z" fill="black"/><path d="M60 10 L70 5 L65 15 Z" fill="black"/><path d="M30 30 Q50 20 70 30 L80 50 L70 55 L65 40 L65 90 L55 90 L55 60 L45 60 L45 90 L35 90 L35 40 L30 55 L20 50 Z" fill="black"/></svg>',
    
    # 7: Winged_hominid
    7: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="20" r="8" fill="black"/><path d="M40 30 Q50 25 60 30 L60 80 L55 80 L55 50 L45 50 L45 80 L40 80 Z" fill="black"/><path d="M45 35 Q20 20 5 45 Q20 40 30 55 Q15 60 5 80 Q30 70 45 50 Z" fill="black"/><path d="M55 35 Q80 20 95 45 Q80 40 70 55 Q85 60 95 80 Q70 70 55 50 Z" fill="black"/></svg>',
    
    # 8: Tigerhuman_hybrid
    8: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M25 40 C30 30, 50 30, 70 40 C85 45, 90 60, 85 75 L75 70 L75 90 C65 90, 60 80, 65 70 L55 70 L55 90 C45 90, 40 80, 45 70 L35 70 L35 90 C25 90, 20 80, 25 70 L15 75 C10 60, 15 45, 25 40 Z" fill="black"/><path d="M70 40 C80 30 90 35 95 25 C90 35 80 45 75 40" fill="black"/></svg>',
    
    # 9: Elongatedstretching_humanoid
    9: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="10" r="5" fill="black"/><path d="M45 15 Q50 15 55 15 L55 95 L45 95 Z" fill="black"/><path d="M45 25 L20 25 L20 30 L45 30 Z" fill="black"/><path d="M55 25 L80 25 L80 30 L55 30 Z" fill="black"/></svg>',
    
    # 10: Flying_coffinspectral_procession
    10: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M35 25 L65 25 L75 40 L65 75 L35 75 L25 40 Z" fill="black"/></svg>',
    
    # 11: Serpentnaga_hybrid
    11: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M30 20 C40 10, 50 20, 55 30 C70 10, 90 30, 75 50 C60 70, 80 80, 70 90 C50 100, 30 80, 40 60 C50 40, 30 30, 30 20 Z" fill="black"/></svg>',
    
    # 12: Maskedcostumed_deity_form
    12: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M20 30 C30 10, 70 10, 80 30 C90 50, 70 80, 50 90 C30 80, 10 50, 20 30 Z" fill="black"/><circle cx="35" cy="45" r="5" fill="white"/><circle cx="65" cy="45" r="5" fill="white"/><path d="M40 70 Q50 80 60 70" stroke="white" stroke-width="4" fill="none"/></svg>',
    
    # Generic
    'generic': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="30" fill="black"/></svg>'
}

created_count = 0

try:
    with open(nexus_file, "r") as f:
        lines = f.readlines()

    in_matrix = False
    for line in lines:
        line = line.strip()
        if line.upper() == "MATRIX":
            in_matrix = True
            continue
        if in_matrix:
            if line == ";" or line.upper() == "END;":
                break
            if line.startswith("[") or not line:
                continue
            parts = line.split()
            if len(parts) >= 2:
                species_name = parts[0]
                sequence = parts[1]
                
                # Characters 11 to 23 are morphology (indices 10 to 22)
                # But some sequences might have '?'
                morph_seq = sequence[10:23] if len(sequence) >= 23 else ""
                selected_morph = 'generic'
                for i, char in enumerate(morph_seq):
                    if char == "1":
                        selected_morph = i
                        break
                
                svg_content = svg_templates.get(selected_morph, svg_templates['generic'])
                svg_path = os.path.join(output_dir, f"{species_name}.svg")
                with open(svg_path, "w") as svg_file:
                    svg_file.write(svg_content)
                created_count += 1
                
    print(f"Successfully created {created_count} SVGs in the '{output_dir}' directory.")

except Exception as e:
    print(f"An error occurred: {e}")
