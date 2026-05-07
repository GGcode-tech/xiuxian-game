#!/usr/bin/env python3
"""OBJ模型预览图生成器 - 使用matplotlib 3D渲染"""

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
import os
import glob

def load_obj(filepath):
    """Load OBJ file and return vertices and faces"""
    vertices = []
    faces = []
    with open(filepath, 'r') as f:
        for line in f:
            if line.startswith('v '):
                parts = line.split()[1:4]
                vertices.append([float(x) for x in parts])
            elif line.startswith('f '):
                parts = line.split()[1:]
                face = []
                for p in parts:
                    idx = int(p.split('/')[0])
                    face.append(idx - 1)  # OBJ is 1-indexed
                faces.append(face)
    return np.array(vertices), faces

def render_model(ax, vertices, faces, color, alpha=0.8, edge=True):
    """Render a 3D model on the given axes"""
    # Center and normalize
    center = vertices.mean(axis=0)
    vertices = vertices - center
    scale = np.abs(vertices).max()
    if scale > 0:
        vertices = vertices / scale * 2
    
    # Create polygons
    polys = []
    for face in faces:
        poly = [vertices[i] for i in face]
        polys.append(poly)
    
    collection = Poly3DCollection(polys, alpha=alpha)
    collection.set_facecolor(color)
    if edge:
        collection.set_edgecolor('black')
        collection.set_linewidth(0.1)
    ax.add_collection3d(collection)
    
    return scale

def create_preview_image(obj_files, output_path, title, cols=4):
    """Create a preview image with multiple models"""
    rows = (len(obj_files) + cols - 1) // cols
    fig = plt.figure(figsize=(cols * 4, rows * 3.5))
    fig.suptitle(title, fontsize=16, fontweight='bold')
    
    # Color palette
    colors = ['#8B4513', '#CD853F', '#DEB887', '#D2691E', '#A0522D',  # Browns for buildings
              '#4169E1', '#6495ED', '#87CEEB', '#4682B4', '#5F9EA0']  # Blues for chars
    
    for i, obj_file in enumerate(obj_files):
        ax = fig.add_subplot(rows, cols, i + 1, projection='3d')
        
        try:
            vertices, faces = load_obj(obj_file)
            color = colors[i % len(colors)]
            render_model(ax, vertices, faces, color)
            
            # Set labels and limits
            ax.set_xlim([-1.5, 1.5])
            ax.set_ylim([-1.5, 1.5])
            ax.set_zlim([-1.5, 1.5])
            ax.set_xlabel('')
            ax.set_ylabel('')
            ax.set_zlabel('')
            ax.set_xticklabels([])
            ax.set_yticklabels([])
            ax.set_zticklabels([])
            
            # Model name as title
            name = os.path.basename(obj_file).replace('.obj', '').replace('_', ' ')
            ax.set_title(name, fontsize=10)
            
        except Exception as e:
            ax.text(0, 0, 0, f"Error:\n{str(e)[:20]}", ha='center')
            ax.set_title(os.path.basename(obj_file), fontsize=9)
    
    plt.tight_layout()
    plt.subplots_adjust(top=0.92)
    plt.savefig(output_path, dpi=120, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"Saved: {output_path}")

def create_scene_image(obj_files, output_path, title="修仙场景"):
    """Create a combined scene with multiple models"""
    fig = plt.figure(figsize=(12, 10))
    ax = fig.add_subplot(111, projection='3d')
    
    # Load and place models
    placements = [
        # (x_offset, z_offset, scale, color)
        (0, 0, 0.8, '#8B4513'),     # Center building
        (-3, -2, 0.6, '#A0522D'),   # Left building
        (3, -2, 0.6, '#CD853F'),    # Right building
        (-2, 2, 0.3, '#4169E1'),    # Character 1
        (2, 2, 0.3, '#6495ED'),     # Character 2
        (0, 3, 0.25, '#87CEEB'),    # Character 3
        (-4, 1, 0.35, '#9370DB'),   # Spirit beast
        (4, 1, 0.4, '#20B2AA'),     # Another beast
    ]
    
    for i, obj_file in enumerate(obj_files[:len(placements)]):
        try:
            vertices, faces = load_obj(obj_file)
            x_off, z_off, scale, color = placements[i]
            
            # Center vertices
            center = vertices.mean(axis=0)
            vertices = vertices - center
            
            # Scale and translate
            max_scale = np.abs(vertices).max()
            if max_scale > 0:
                vertices = vertices / max_scale * scale
            
            vertices[:, 0] += x_off  # X offset
            vertices[:, 2] += z_off  # Z offset
            
            # Render
            polys = [[vertices[j] for j in face] for face in faces]
            collection = Poly3DCollection(polys, alpha=0.85)
            collection.set_facecolor(color)
            collection.set_edgecolor('black')
            collection.set_linewidth(0.1)
            ax.add_collection3d(collection)
            
        except Exception as e:
            print(f"Error loading {obj_file}: {e}")
    
    # Ground plane
    xx, zz = np.meshgrid(np.linspace(-6, 6, 10), np.linspace(-4, 4, 10))
    yy = np.zeros_like(xx) - 0.5
    ax.plot_surface(xx, yy, zz, alpha=0.3, color='green')
    
    # Settings
    ax.set_xlim([-6, 6])
    ax.set_ylim([-2, 3])
    ax.set_zlim([-4, 5])
    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    ax.set_zlabel('Z')
    ax.set_title(title, fontsize=14, fontweight='bold')
    
    # Rotate view
    ax.view_init(elev=25, azim=45)
    
    plt.savefig(output_path, dpi=150, bbox_inches='tight', facecolor='white')
    plt.close()
    print(f"Saved: {output_path}")

# ============================================================
if __name__ == "__main__":
    base = "/home/agentuser/xiuxian_game/picture"
    
    print("=== 生成修仙3D模型预览图 ===\n")
    
    # Building previews
    building_files = sorted(glob.glob(f"{base}/buildings_custom/*.obj"))
    if building_files:
        create_preview_image(building_files, f"{base}/preview_buildings.png", 
                            "修仙东方建筑 (东方风格 3D Buildings)", cols=4)
    
    # Character previews  
    char_files = sorted(glob.glob(f"{base}/characters_custom/*.obj"))
    if char_files:
        create_preview_image(char_files, f"{base}/preview_characters.png",
                            "修仙角色与灵兽 (Cultivators & Spirit Beasts)", cols=5)
    
    # Combined scene
    scene_files = [
        f"{base}/buildings_custom/taoist_temple.obj",
        f"{base}/buildings_custom/alchemy_pavilion.obj",
        f"{base}/buildings_custom/pagoda_5tier.obj",
        f"{base}/characters_custom/sword_cultivator.obj",
        f"{base}/characters_custom/cultivator_female.obj",
        f"{base}/characters_custom/elder.obj",
        f"{base}/characters_custom/qilin.obj",
        f"{base}/characters_custom/spirit_crane.obj",
    ]
    scene_files = [f for f in scene_files if os.path.exists(f)]
    if len(scene_files) >= 4:
        create_scene_image(scene_files, f"{base}/preview_scene.png", 
                          "修仙家族模拟器 - 场景预览")
    
    # Summary
    print(f"\n✅ 预览图生成完成!")
    print(f"   - {base}/preview_buildings.png")
    print(f"   - {base}/preview_characters.png")
    print(f"   - {base}/preview_scene.png")
