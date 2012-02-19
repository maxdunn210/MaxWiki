// MaxWiki settings for FCKEditor
FCKConfig.SkinPath = FCKConfig.BasePath + 'skins/default/' ;
FCKConfig.ShowDropDialog = false;
FCKConfig.ProtectedSource.Add( /<%[\s\S]*?%>/g ) ;
FCKConfig.ProtectedTags = 'NOWIKI' ;
FCKConfig.EditorAreaCSS = '/stylesheets/main.css' ;
FCKConfig.BodyId = 'fck_body'

FCKConfig.ToolbarSets["WikiBasic"] = [
	['ajaxAutoSave','-','Bold','Italic','Underline','StrikeThrough','-','Subscript','Superscript'],
	['OrderedList','UnorderedList','-','Outdent','Indent'],
	['JustifyLeft','JustifyCenter','JustifyRight','JustifyFull'],
	['Table','Rule'],
	['Link','Unlink','Image','-','RemoveFormat','Source','-','About'],
	'/',
	['TextColor','BGColor'],['Style','FontFormat','FontName','FontSize']
	 ] ;

// ** Rails FCKEditor plugin configuration **
// CHANGE FOR APPS HOSTED IN SUBDIRECTORY
FCKRelativePath = '';

// DON'T CHANGE THESE
FCKConfig.LinkBrowserURL = FCKConfig.BasePath + 'filemanager/browser/default/browser.html?Connector='+FCKRelativePath+'/_action/fckeditor/command';
FCKConfig.PageBrowserURL = FCKConfig.BasePath + 'filemanager/browser/default/browser.html?Type=Page&Connector='+FCKRelativePath+'/_action/fckeditor/command';
FCKConfig.ImageBrowserURL = FCKConfig.BasePath + 'filemanager/browser/default/browser.html?Type=Image&Connector='+FCKRelativePath+'/_action/fckeditor/command';
FCKConfig.FlashBrowserURL = FCKConfig.BasePath + 'filemanager/browser/default/browser.html?Type=Flash&Connector='+FCKRelativePath+'/_action/fckeditor/command';

FCKConfig.LinkUploadURL = FCKRelativePath+'/_action/fckeditor/upload';
FCKConfig.ImageUploadURL = FCKRelativePath+'/_action/fckeditor/upload?Type=Image';
FCKConfig.FlashUploadURL = FCKRelativePath+'/_action/fckeditor/upload?Type=Flash';
FCKConfig.AllowQueryStringDebug = false;
FCKConfig.SpellChecker = 'SpellerPages';

//----------------------------------------------------
// ajaxAutoSave plugin 
FCKConfig.Plugins.Add( 'ajaxAutoSave','en') ;

// --- config settings for the ajaxAutoSave plugin ---
// URL to post to
FCKConfig.ajaxAutoSaveTargetUrl = '/_action/wiki/autosave' ;

// Enable / Disable Plugin onBeforeUpdate Action 
FCKConfig.ajaxAutoSaveBeforeUpdateEnabled = true ;

// RefreshTime
FCKConfig.ajaxAutoSaveRefreshTime = 30 ;

// Sensitivity to key strokes
FCKConfig.ajaxAutoSaveSensitivity = 2 ;

