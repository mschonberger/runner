import os

# ==========================================
#              CONFIGURATION
# ==========================================

# 1. SCOPING: Only include files that contain these strings.
# Leave empty [] to include EVERYTHING.
FOCUS_MATCHERS = []

# 2. DEFINITIONS: What goes into which file?
CODE_EXTENSIONS = {".gd", ".shader"}
SCENE_EXTENSIONS = {".tscn", ".tres", ".godot"}

# 3. IGNORE DIRS (Global Folder Names to skip everywhere)
IGNORE_DIRS = {".git", ".godot", ".import", "builds", "docs", "assets"}

# --- NEW SETTINGS BELOW ---

# 4. IGNORE SPECIFIC PATHS
# Skip these specific sub-folders (relative to project root).
# formatting: use forward slashes matching your structure.
IGNORE_PATHS = [
    #"scenes/minigames",   # <--- Removes this specific folder
    "art/trainer",        # <--- Example: Remove trainer art folder
    "scenes/fx",
    "scenes/maps",
    "scenes/shader",
    
]

# 5. TREE NOISE FILTER
# Files with these extensions will be HIDDEN from the File Tree
# to reduce clutter (e.g., .import, .uid, .png, .svg).
IGNORE_TREE_EXTENSIONS = {".import", ".uid", ".png", ".svg", ".jpg", ".pdn", ".ttf", ".wav", ".ogg"}

OUTPUT_CODE_FILE = "project_code.txt"
OUTPUT_SCENE_FILE = "project_scenes.txt"

# ==========================================
#                 LOGIC
# ==========================================

def should_skip_path(path):
    """
    Checks if a path (folder or file) is in the IGNORE_PATHS list.
    """
    # Normalize path to forward slashes for comparison
    norm_path = path.replace(os.sep, "/")
    
    for ignore_p in IGNORE_PATHS:
        # Check if the path starts with or contains the ignored path
        if ignore_p in norm_path:
            return True
    return False

def is_focused(file_path):
    """Returns True if the file matches the focus list (or if list is empty)."""
    if not FOCUS_MATCHERS:
        return True
    norm_path = file_path.replace(os.sep, "/")
    return any(m in norm_path for m in FOCUS_MATCHERS)

def get_file_tree(start_path):
    tree_str = "==== PROJECT STRUCTURE ====\n"
    for root, dirs, files in os.walk(start_path):
        # 1. Filter Directories (Standard Ignore)
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        
        # 2. Filter Directories (Specific Paths)
        # We must iterate a copy of dirs to safely modify the original list
        for d in list(dirs):
            full_dir_path = os.path.join(root, d)
            if should_skip_path(full_dir_path):
                dirs.remove(d)
        
        level = root.replace(start_path, '').count(os.sep)
        indent = ' ' * 4 * (level)
        tree_str += f"{indent}{os.path.basename(root)}/\n"
        subindent = ' ' * 4 * (level + 1)
        
        for f in files:
            # 3. Filter Tree Extensions (Noise reduction)
            ext = os.path.splitext(f)[1]
            if ext in IGNORE_TREE_EXTENSIONS:
                continue
                
            tree_str += f"{subindent}{f}\n"
    return tree_str

def get_file_contents(start_path):
    code_content = "\n==== CODE FILES ====\n"
    scene_content = "\n==== SCENE FILES ====\n"
    
    code_count = 0
    scene_count = 0
    
    for root, dirs, files in os.walk(start_path):
        # 1. Filter Directories (Standard)
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS]
        
        # 2. Filter Directories (Specific Paths)
        for d in list(dirs):
            if should_skip_path(os.path.join(root, d)):
                dirs.remove(d)
        
        for f in files:
            file_path = os.path.join(root, f)
            ext = os.path.splitext(f)[1]
            
            # Skip if it doesn't match our Focus Matchers
            if not is_focused(file_path):
                continue
            
            # Read file content
            content_block = ""
            if ext in CODE_EXTENSIONS or ext in SCENE_EXTENSIONS:
                content_block += f"\n\n---- FILE: {file_path} ----\n"
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='replace') as file_obj:
                        content_block += file_obj.read()
                except Exception as e:
                    content_block += f"[Error reading file: {e}]"

            # Sort into the correct bucket
            if ext in CODE_EXTENSIONS:
                code_content += content_block
                code_count += 1
            elif ext in SCENE_EXTENSIONS:
                scene_content += content_block
                scene_count += 1
                    
    return code_content, code_count, scene_content, scene_count

def estimate_tokens(text):
    return len(text) // 4

def main():
    print(f"--- STARTING CLEAN DUMP ---")
    if FOCUS_MATCHERS:
        print(f"Focus Filter: {FOCUS_MATCHERS}")
    if IGNORE_PATHS:
        print(f"Ignoring Paths: {IGNORE_PATHS}")
    
    tree = get_file_tree(".")
    code_body, n_code, scene_body, n_scene = get_file_contents(".")
    
    full_code_output = tree + code_body
    full_scene_output = tree + scene_body 
    
    with open(OUTPUT_CODE_FILE, "w", encoding="utf-8") as f:
        f.write(full_code_output)
        
    with open(OUTPUT_SCENE_FILE, "w", encoding="utf-8") as f:
        f.write(full_scene_output)
    
    print(f"\n--- DONE ---")
    print(f"1. {OUTPUT_CODE_FILE} ({n_code} files)")
    print(f"2. {OUTPUT_SCENE_FILE} ({n_scene} files)")
    print(f"Tree cleaned of: {IGNORE_TREE_EXTENSIONS}")

if __name__ == "__main__":
    main()