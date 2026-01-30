use tauri::Manager;
use std::fs;
use std::path::PathBuf;

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

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .invoke_handler(tauri::generate_handler![read_prg_file, save_cdis_file])
        .setup(|app| {
            if cfg!(debug_assertions) {
                app.handle().plugin(
                    tauri_plugin_log::Builder::default()
                        .level(log::LevelFilter::Info)
                        .build(),
                )?;
                // Open devtools in debug mode
                if let Some(window) = app.get_webview_window("main") {
                    window.open_devtools();
                }
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
