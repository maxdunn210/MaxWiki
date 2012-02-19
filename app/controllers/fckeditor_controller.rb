# This was adapted from: 
# Fckeditor: Version 0.4.1, by Scott Rutherford, scott@caronsoftware.com, http://rubyforge.org/projects/fckeditorp/

require 'fileutils'
require 'tmpdir'

class FckeditorController < ApplicationController
  MIME_TYPES = [
    "image/jpg",
    "image/jpeg",
    "image/pjpeg",
    "image/gif",
    "image/png",
    "image/x-png",
    "application/x-shockwave-flash"
  ]
  
  RXML = <<-EOL
  xml.instruct!
    #=> <?xml version="1.0" encoding="utf-8" ?>
  xml.Connector("command" => params[:Command], "resourceType" => 'File') do
    xml.CurrentFolder("url" => @uurl, "path" => params[:CurrentFolder])
    xml.Folders do
      @folders.sort.each do |folder|
        xml.Folder("name" => folder)
      end
    end if !@folders.nil?
    xml.Files do
      @files.keys.sort.each do |f|
        if @files[f][:url] 
          xml.File("name" => f, "size" => @files[f][:size], "url" => @files[f][:url])
        else
          xml.File("name" => f, "size" => @files[f][:size])
        end
      end
    end if !@files.nil?
    xml.Error("number" => @errorNumber) if !@errorNumber.nil?
  end
  EOL
  
  # figure out who needs to handle this request
  def command   
    if params[:Command] == 'GetFoldersAndFiles' || params[:Command] == 'GetFolders'
      get_folders_and_files
    elsif params[:Command] == 'CreateFolder'
      create_folder
    elsif params[:Command] == 'FileUpload'
      upload_file
    elsif params[:Command] == 'GetPages'
      get_pages
    end
    
    unless params[:Command] == 'FileUpload'
      response.headers['Content-Type'] = 'text/xml; charset=UTF-8'
      render :inline => RXML, :type => :rxml 
    end
  end 
  
  def upload
    upload_file
  end
  
  #------------------
  private
  
  def get_folders_and_files(include_files = true)
    @folders = Array.new
    @files = {}
    begin
      @uurl = upload_directory_path
      if params[:Type] == 'Page'
        pages = @wiki.select_all(:main_and_layout_pages).by_name
        authorized_pages!(pages)
        pages.each do |page|
          @files[page.name] = {:size => 0, :url => page.link}
        end
      else  
        @current_folder = current_directory_path
        Dir.entries(@current_folder).each do |entry|
          next if entry =~ /^\./
          path = @current_folder + entry
          @folders.push entry if FileTest.directory?(path)
          @files[entry] = {:size => (File.size(path) / 1024)} if (include_files and FileTest.file?(path))
        end
      end
    rescue => e
      logger.error "fckeditor get_folders_and_files exception: #{e}"    
      @errorNumber = 110 if @errorNumber.nil?
    end
  end
  
  def create_folder
    begin 
      @uurl = current_directory_path
      path = safe_file_join(@uurl, params[:NewFolderName])
      if !(File.stat(@uurl).writable?)
        @errorNumber = 103
      elsif params[:NewFolderName] !~ /[\w\d\s]+/
        @errorNumber = 102
      elsif FileTest.exists?(path)
        @errorNumber = 101
      else
        Dir.mkdir(path,0775)
        @errorNumber = 0
      end
    rescue => e
      logger.error "fckeditor create_folder exception: #{e}"    
      @errorNumber = 110 if @errorNumber.nil?
    end
  end
  
  def upload_file
    begin
      new_file = check_file(params[:NewFile])
      @uurl = safe_file_join(upload_directory_path, new_file.original_filename)
      ftype = new_file.content_type.strip
      if ! MIME_TYPES.include?(ftype)
        @errorNumber = 202
        logger.error "fckeditor upload_file error: #{ftype} is invalid MIME type"
        raise "#{ftype} is invalid MIME type"
      else
        path = safe_file_join(current_directory_path, new_file.original_filename)
        File.open(path,"wb",0664) do |fp|
          FileUtils.copy_stream(new_file, fp)
        end
        @errorNumber = 0
      end
    rescue => e
      logger.error "fckeditor upload_file exception: #{e}"    
      @errorNumber = 110 if @errorNumber.nil?
    end
    
    # This was tested on FireFox 2.0.0.9, Safari 3.0.3, IE 6.0.2900
    render :text => %Q[<script>window.parent.OnUploadCompleted(#{@errorNumber}, '#{@uurl}');</script>]
  end
  
  def current_directory_path
    base_dir = full_directory_name(params[:page_name], @wiki.name)
    path = check_path("#{base_dir}#{params[:CurrentFolder]}")
    Dir.mkdir(base_dir,0775) unless File.exists?(base_dir)
    path
  end
  
  def upload_directory_path
    uploaded = request.relative_url_root.to_s + attachment_directory_name(params[:page_name], @wiki.name)
    "#{uploaded}#{params[:CurrentFolder]}"
  end
  
  def check_file(file)
    # check that the file is the right object
    unless ["Tempfile", "StringIO", "ActionController::UploadedTempfile"].include?("#{file.class}")
      logger.error "fckeditor upload error. File class is: #{file.class}"
      @errorNumber = 403
      throw Exception.new
    end
    file
  end
  
  def check_path(path)
    exp_path = File.expand_path path
    unless exp_path.starts_with?(File.join(MY_CONFIG[:file_upload_root], MY_CONFIG[:file_upload_top]))
      @errorNumber = 403
      throw Exception.new
    end
    path
  end
end
