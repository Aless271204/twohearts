"""Contact sheets made exclusively from actual Blender renders, for visual QA."""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'design/blender/fitting'
items=[('cap_pink','Gorra corazón'),('hat_garden','Sombrero jardín'),('beanie_cloud','Gorro nube'),('beret_chic','Boina chic')]
pets=[('penguin','Pingüino'),('bear','Oso'),('pig','Cerdito'),('chick','Pollito')]
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',22)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',18)
for view in ['front','profile','back']:
    sheet=Image.new('RGB',(1200,1760),'#FFF9FA');draw=ImageDraw.Draw(sheet)
    draw.text((28,15),'NIDO · Encaje de los modelos disponibles Meshy en Blender',fill='#382E36',font=font)
    for row,(species,label) in enumerate(pets):
        y=55+row*425;draw.text((24,y),label,fill='#BF4168',font=font)
        for col,(item,name) in enumerate(items):
            x=col*300+8
            image=Image.open(root/(species+'-'+item+'-'+view+'.png')).convert('RGBA');image.thumbnail((290,350))
            draw.rounded_rectangle((x,y+30,x+284,y+411),radius=18,fill='white',outline='#F3DFE5')
            sheet.paste(image,(x+(284-image.width)//2,y+32),image)
            draw.text((x+12,y+383),name,fill='#382E36',font=small)
    sheet.save(root/('contact-sheet-'+view+'.png'))
print('Three actual-model contact sheets saved.')
