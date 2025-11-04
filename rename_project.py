import os
import sys
from pathlib import Path
import platform

def rename_project():
    """
    Prompts for a new project name, confirms, renames all 'base_project'
    references, and provides a final reminder to rename the root folder.
    """
    project_root = Path(__file__).resolve().parent
    current_folder_name = project_root.name

    print("--- Project Renamer ---")
    print(f"Current project root: {project_root}")
    
    new_name_slug = input("Enter new project name (e.g., 'my_awesome_project'): ").strip().lower()

    if not new_name_slug or ' ' in new_name_slug or '-' in new_name_slug:
        print("\n[ERROR] Invalid name!")
        print("Please use only lowercase letters and underscores (e.g., 'my_new_project').")
        sys.exit(1)

    replacements = {
        "base_project": new_name_slug,
        
        "base-project": new_name_slug.replace("_", "-"),
        
        "Base Project": new_name_slug.replace("_", " ").title(),
        
        "Base project": new_name_slug.replace("_", " ").capitalize(),
    }

    print("\nWill make the following replacements:")
    for old, new in replacements.items():
        print(f"  '{old}'  ->  '{new}'")

    try:
        confirm = input("\nDo you want to proceed with these changes? (yes/no): ").strip().lower()
    except KeyboardInterrupt:
        print("\n\nOperation cancelled by user.")
        sys.exit(0)

    if not confirm.startswith('y'):
        print("\nOperation cancelled. No changes were made.")
        sys.exit(0)

    print("\nProceeding with rename...")
    
    files_to_scan = [
        project_root / "docker-compose.yml",
        project_root / "config/settings.py",
        project_root / "config/urls.py",
    ]

    print("Scanning files...")
    total_changes = 0

    # --- 5. Read, Replace, and Write ---
    for file_path in files_to_scan:
        if not file_path.exists():
            print(f"[WARNING] File not found, skipping: {file_path.name}")
            continue

        try:
            with file_path.open('r', encoding='utf-8') as f:
                original_content = f.read()
            
            modified_content = original_content
            file_changed = False

            # Apply all replacements to the content
            for old, new in replacements.items():
                if old in modified_content:
                    modified_content = modified_content.replace(old, new)
                    file_changed = True
            
            if file_changed:
                # Write the modified content back to the file
                with file_path.open('w', encoding='utf-8') as f:
                    f.write(modified_content)
                print(f"[UPDATED] {file_path.name}")
                total_changes += 1
            else:
                print(f"[OK] No changes needed in: {file_path.name}")

        except Exception as e:
            print(f"[ERROR] Could not process file {file_path.name}: {e}")

    # --- 6. Final Report ---
    print("\n--- Rename Complete! ---")
    if total_changes > 0:
        print("Successfully updated project files.")
    else:
        print("No files needed updating.")

    # --- UPDATED: Folder Rename Warning ---
    new_folder_name = new_name_slug + "_api" # Suggest a new name like 'ali_fathi_api'
    
    print("\n[IMPORTANT] Next Steps:")
    print("1. If you are using Docker, you MUST stop and remove old containers and volumes.")
    print("   Run: docker-compose down -v")
    
    print("\n2. **(MANUAL STEP)**")
    print(f"   If you want, remember to manually rename your main project folder")
    print(f"   (e.g., change '{current_folder_name}' to '{new_folder_name}').")

    print("\n3. You can now build and run your newly named project:")
    print("   Run: docker-compose up --build")


if __name__ == "__main__":
    try:
        rename_project()
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
        sys.exit(0)