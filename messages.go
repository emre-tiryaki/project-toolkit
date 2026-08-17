package main

// Message keys used across the toolkit.
type msgKey string

const (
	msgErrNameMissing         msgKey = "err_name_missing"
	msgErrExists              msgKey = "err_exists"
	msgErrNotExists           msgKey = "err_not_exists"
	msgErrBaseDirNotExists    msgKey = "err_base_dir_not_exists"
	msgErrInvalidParam        msgKey = "err_invalid_param"
	msgErrInvalidCommand      msgKey = "err_invalid_command"
	msgErrCodeEditorNotFound  msgKey = "err_code_editor_not_found"
	msgErrTemplateMissing     msgKey = "err_template_missing"
	msgErrProjectNotEmpty     msgKey = "err_project_not_empty"
	msgErrProgramNotExists    msgKey = "err_program_not_exists"
	msgErrUnknownFlag         msgKey = "err_unknown_flag"
	msgErrNoRepoArg           msgKey = "err_no_repo_arg"
	msgErrCloneFailed         msgKey = "err_clone_failed"
	msgErrOpenFailed          msgKey = "err_open_failed"
	msgErrNoFzf               msgKey = "err_no_fzf"
	msgWarnInstalling         msgKey = "warning_downloading_necessity"
	msgInfoSelectProject      msgKey = "info_select_project"
	msgInfoListProject        msgKey = "info_list_project"
	msgInfoProjectsToRemove   msgKey = "info_projects_to_remove"
	msgPromptSelectRemove     msgKey = "prompt_select_projects_to_remove"
	msgConfirmRm              msgKey = "confirm_rm"
	msgCancelRm               msgKey = "cancel_rm"
	msgSuccessRm              msgKey = "success_rm"
	msgSuccessNew             msgKey = "success_new"
	msgSuccessRename          msgKey = "success_rename"
	msgSuccessClone        msgKey = "success_clone"
	msgCloning              msgKey = "cloning"

	// config command messages
	msgConfigSet        msgKey = "config_set"
	msgConfigUnset      msgKey = "config_unset"
	msgConfigNoSet      msgKey = "config_no_set"
	msgConfigKeys       msgKey = "config_keys"
	msgConfigListTitle  msgKey = "config_list_title"
	msgConfigNotSet      msgKey = "config_not_set"
	msgConfigHint        msgKey = "config_hint"
)

// messages returns the localized string for each key. The strings may contain
// printf-style verbs (%s) that getMsg fills with param/cmdType.
func messages(lang string) map[msgKey]string {
	tr := map[msgKey]string{
		msgErrNameMissing:         "Hata: Proje ismi eksik. Kullanım: project %s <isim>",
		msgErrExists:              "Hata: '%s' isimli bir proje zaten mevcut!",
		msgErrNotExists:           "Hata: '%s' isimli bir proje bulunamadı!",
		msgErrBaseDirNotExists:    "Hata: Proje klasörü bulunamadı!",
		msgErrInvalidParam:        "Hata: Geçersiz parametre: %s",
		msgErrInvalidCommand:      "Hata: Geçersiz komut: %s",
		msgErrCodeEditorNotFound:  "Hata: '%s' editörü sistemde bulunamadı",
		msgErrTemplateMissing:     "Hata: Şablon tipi belirtilmedi. Kullanım: project new <isim> -t <tip>",
		msgErrProjectNotEmpty:     "Hata: Proje boş değil!",
		msgErrProgramNotExists:    "Hata: %s sistemde yüklü değil!",
		msgErrUnknownFlag:         "Hata: bilinmeyen bayrak (%s)",
		msgErrNoRepoArg:           "Hata: Klonlanacak repo belirtilmedi. Kullanım: project clone <url> veya <arama>",
		msgErrCloneFailed:         "Hata: '%s' klonlanamadı!",
		msgErrOpenFailed:          "Hata: '%s' açılamadı (editör bulunamadı)!",
		msgErrNoFzf:               "Hata: fzf yüklü değil. Lütfen bir proje ismi girin.",
		msgWarnInstalling:         "Uyarı: Gerekli %s bağımlılıkları yükleniyor...",
		msgInfoSelectProject:      "Proje seç >>",
		msgInfoListProject:        "Proje listesi >>",
		msgInfoProjectsToRemove:   "Silinecek projeler >>",
		msgPromptSelectRemove:     "Silinecekleri TAB ile seçin, ENTER ile onaylayın > ",
		msgConfirmRm:              "Projeleri silmek istediğinize emin misiniz? (y/n): ",
		msgCancelRm:               "Project '%s' was not removed",
		msgSuccessRm:              "'%s' başarıyla silindi.",
		msgSuccessNew:             "'%s' projesi başarıyla oluşturuldu.",
		msgSuccessRename:          "Proje ismi başarıyla değiştirildi.",
		msgSuccessClone:          "'%s' başarıyla klonlandı.",
		msgCloning:                "Klonlanıyor: %s",
		msgConfigSet:             "Ayarlandı: %s = %s",
		msgConfigUnset:           "Kaldırıldı: %s",
		msgConfigNoSet:           "Henüz ayar yapılmadı. Kullanım: project config set <anahtar> <değer>",
		msgConfigKeys:            "Anahtarlar: workspace, github_user, github_token, editor, templates_dir",
		msgConfigListTitle:       "Proje Toolkit yapılandırması:",
		msgConfigNotSet:          "(ayarlanmadı)",
		msgConfigHint:            "İpucu: değişiklikler yeni kabuk oturumlarında geçerli. Hemen uygulamak için terminali yeniden başlatın veya wrapper'ı tekrar kaynak edin (source).",
	}
	en := map[msgKey]string{
		msgErrNameMissing:         "Error: Project name is missing. Usage: project %s <name>",
		msgErrExists:              "Error: Project '%s' already exists!",
		msgErrNotExists:           "Error: Project '%s' not found!",
		msgErrBaseDirNotExists:    "Error: Project directory not found!",
		msgErrInvalidParam:        "Error: Invalid parameter: %s",
		msgErrInvalidCommand:      "Error: Invalid command: %s",
		msgErrCodeEditorNotFound:  "Error: '%s' editor not found in the system",
		msgErrTemplateMissing:     "Error: Template type not specified. Usage: project new <name> -t <type>",
		msgErrProjectNotEmpty:     "Error: Project is not empty!",
		msgErrProgramNotExists:    "Error: %s is not installed on the system!",
		msgErrUnknownFlag:         "Error: Unknown flag (%s)",
		msgErrNoRepoArg:           "Error: No repo to clone. Usage: project clone <url> or <search>",
		msgErrCloneFailed:         "Error: Failed to clone '%s'!",
		msgErrOpenFailed:          "Error: Failed to open '%s' (no editor found)!",
		msgErrNoFzf:               "Error: fzf is not installed. Please provide a project name.",
		msgWarnInstalling:         "Warning: Installing required %s dependencies...",
		msgInfoSelectProject:      "Select Project >>",
		msgInfoListProject:        "Project List >>",
		msgInfoProjectsToRemove:   "Projects to remove >>",
		msgPromptSelectRemove:     "Use TAB to select items, press ENTER to confirm > ",
		msgConfirmRm:              "Are you sure you want to remove the projects? (y/n): ",
		msgCancelRm:               "Project '%s' was not removed",
		msgSuccessRm:              "Project '%s' successfully removed.",
		msgSuccessNew:             "Project '%s' created successfully.",
		msgSuccessRename:          "Project name successfully changed.",
		msgSuccessClone:          "Project '%s' cloned successfully.",
		msgCloning:                "Cloning: %s",
		msgConfigSet:             "Set %s = %s",
		msgConfigUnset:           "Unset %s",
		msgConfigNoSet:           "No configuration set. Use `project config set <key> <value>`.",
		msgConfigKeys:            "Keys: workspace, github_user, github_token, editor, templates_dir",
		msgConfigListTitle:       "Project Toolkit configuration:",
		msgConfigNotSet:          "(not set)",
		msgConfigHint:            "Hint: changes apply to new shell sessions. To apply now, restart your terminal or re-source the wrapper.",
	}
	if lang == "tr" {
		return tr
	}
	return en
}
