# # 安装: pip install pillow
# from PIL import Image
# import os

# def remove_black_background(input_path, output_path):
#     img = Image.open(input_path).convert("RGBA")
#     pixels = img.load()
    
#     for y in range(img.height):
#         for x in range(img.width):
#             r, g, b, a = pixels[x, y]
#             # 将黑色(或接近黑色)像素设为透明
#             if r < 30 and g < 30 and b < 30:
#                 pixels[x, y] = (r, g, b, 0)
    
#     img.save(output_path, "PNG")

# # 批量处理
# input_folder = "assets/animations/walk"
# output_folder = "assets/animations/walk"
# os.makedirs(output_folder, exist_ok=True)

# for filename in os.listdir(input_folder):
#     if filename.endswith(".png"):
#         input_file = os.path.join(input_folder, filename)
#         output_file = os.path.join(output_folder, filename)
#         remove_black_background(input_file, output_file)
#         print(f"处理完成: {filename}")
