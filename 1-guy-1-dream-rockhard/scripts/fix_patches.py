import sys

with open('scripts/terrain.gd', 'r', encoding='utf-8') as f:
    text = f.read()

air_patch = '''
\t\t\t\t\t\t\t\t{
\t\t\t\t\t\t\t\t\t"noise_freq": 0.05,
\t\t\t\t\t\t\t\t\t"seed_offset": 0x9E3779B9,
\t\t\t\t\t\t\t\t\t"noise_type": FastNoiseLite.TYPE_PERLIN,
\t\t\t\t\t\t\t\t\t"fractal_type": FastNoiseLite.FRACTAL_RIDGED,
\t\t\t\t\t\t\t\t\t"fractal_octaves": 1,
\t\t\t\t\t\t\t\t\t"threshold": 0.8,
\t\t\t\t\t\t\t\t\t"type": -1,
\t\t\t\t\t\t\t\t},'''

base_air_patch = '''
\t\t\t\t\t\t\t\t{
\t\t\t\t\t\t\t\t\t"noise_freq": 0.015,
\t\t\t\t\t\t\t\t\t"seed_offset": 0,
\t\t\t\t\t\t\t\t\t"noise_type": FastNoiseLite.TYPE_PERLIN,
\t\t\t\t\t\t\t\t\t"threshold": -0.45,
\t\t\t\t\t\t\t\t\t"type": -1,
\t\t\t\t\t\t\t\t},'''

text = text.replace('"patches": [', '"patches": [' + air_patch + base_air_patch)

text = text.replace('"patches": [' + air_patch + base_air_patch + '\n\t\t\t\t\t\t\t\t]', '"patches": []')
text = text.replace('"patches": [' + air_patch + base_air_patch + ']', '"patches": []')

with open('scripts/terrain.gd', 'w', encoding='utf-8') as f:
    f.write(text)
