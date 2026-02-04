use std::fs;
use std::path::PathBuf;
use std::process::Command;

#[tauri::command]
async fn read_prg_file(path: String) -> Result<PrgData, String> {
    let prg_path = PathBuf::from(&path);

    // Read PRG file
    let bytes = fs::read(&prg_path)
        .map_err(|e| format!("Failed to read PRG file: {}", e))?;

    // Determine cdis path
    let cdis_path = prg_path.with_extension("cdis");

    // Try to read existing cdis file
    let cdis_content = fs::read_to_string(&cdis_path).ok();

    // Get filename
    let file_name = prg_path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown.prg")
        .to_string();

    Ok(PrgData {
        file_name,
        bytes,
        cdis_content,
        cdis_path: cdis_path.to_string_lossy().to_string(),
    })
}

#[tauri::command]
async fn save_cdis_file(path: String, content: String) -> Result<(), String> {
    fs::write(&path, &content)
        .map_err(|e| format!("Failed to save CDIS file: {}", e))
}

#[derive(serde::Serialize)]
struct PrgData {
    file_name: String,
    bytes: Vec<u8>,
    cdis_content: Option<String>,
    cdis_path: String,
}

#[tauri::command]
async fn run_in_vice(load_address: u16, bytes: Vec<u8>) -> Result<(), String> {
    // Write temp PRG file (not in /tmp - VICE doesn't autostart from there)
    let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".to_string());
    let temp_path = PathBuf::from(home).join(".cdis-run.prg");

    // PRG format: 2-byte load address (little endian) + program bytes
    let mut prg_data = Vec::with_capacity(bytes.len() + 2);
    prg_data.push((load_address & 0xFF) as u8);
    prg_data.push((load_address >> 8) as u8);
    prg_data.extend(&bytes);

    fs::write(&temp_path, &prg_data)
        .map_err(|e| format!("Failed to write temp PRG: {}", e))?;

    // Try common VICE executable names
    let vice_commands = ["vice-jz.x64sc", "x64sc", "x64", "vice"];

    for cmd in &vice_commands {
        if let Ok(child) = Command::new(cmd)
            .arg("-autostart")
            .arg(temp_path.to_string_lossy().to_string())
            .spawn()
        {
            // Detach - don't wait for VICE to exit
            std::mem::forget(child);
            return Ok(());
        }
    }

    Err("Could not find VICE emulator (tried x64sc, x64, vice). Make sure VICE is installed and in your PATH.".to_string())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![read_prg_file, save_cdis_file, run_in_vice])
        .setup(|app| {
            if cfg!(debug_assertions) {
                app.handle().plugin(
                    tauri_plugin_log::Builder::default()
                        .level(log::LevelFilter::Info)
                        .build(),
                )?;
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
