// MaxWiki settings for CKEditor
CKEDITOR.editorConfig = function( config )
{
	config.toolbar = 'MaxWikiToolbar';
  config.toolbar_MaxWikiToolbar =
	 [
    ['Save'],
    ['Cut','Copy','Paste','PasteText','PasteFromWord'],
    ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
    ['Image','Flash','Table','HorizontalRule','Smiley','SpecialChar'],
		['About'],
		'/',
    ['Bold','Italic','Underline','Strike','-','Subscript','Superscript'],
    ['NumberedList','BulletedList','-','Outdent','Indent','Blockquote','CreateDiv'],
    ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
    ['Link','Unlink','Anchor'],
    '/',
    ['Styles','Format','Font','FontSize'],
    ['TextColor','BGColor'],
    ['Maximize', 'ShowBlocks','-','Source']
  ];
	config.skin = 'v2';
	config.protectedSource.push( /<%[\s\S]*?%>/g ) ;
	// config.filebrowserBrowseUrl = '/_action/fckeditor/command';
	// config.filebrowserImageBrowseUrl = '/_action/fckeditor/command?Type=Image';
	// config.filebrowserUploadUrl = '/_action/fckeditor/upload';
	// config.filebrowserImageUploadUrl = '/_action/fckeditor/upload?Type=Image';
	// config.filebrowserFlashUploadUrl = '/_action/fckeditor/upload?Type=Flash';
};

// ------- Old -------


FCKConfig.ProtectedTags = 'NOWIKI' ;
FCKConfig.EditorAreaCSS = '/stylesheets/main.css' ;
FCKConfig.BodyId = 'fck_body'


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

