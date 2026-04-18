class Rename
  ClassName = "TemplateGameSDL"
  FileName = "template_game_sdl"
  ReplaceFiles = [
    "Makefile",
    "README.md",
    "shard.yml",
    "src/#{FileName}.cr",
    "src/rename.cr",
    "src/#{FileName}/game.cr",
    "src/#{FileName}/scene/start.cr"
  ]
  RenameFiles = ["src/#{FileName}.cr"]
  RenameDirectories = ["src/#{FileName}"]
  ReadmeFile = "README.md"

  @class_name = ""
  @file_name = ""

  def class_name(name)
    name.camelcase
  end

  def file_name(name)
    name.underscore
  end

  def name_prompt
    print "Rename class (#{ClassName}) to: "

    input = (gets || "")
    input = "GameExample" if input.blank?
    name = input.squeeze(' ').gsub(' ', '_')

    @class_name = class_name(name)
    @file_name = file_name(name)

    name_prompt_custom unless name_values_okay?
  end

  def name_values_okay?
    puts
    puts "class: #{@class_name}"
    puts "directory/file: #{@file_name}"
    puts
    print "Are these okay? y/n: "

    answer = gets || ""

    answer.downcase == "y"
  end

  def name_prompt_custom
    puts
    puts "Okay, lets go custom, one by one"
    puts
    print "Rename TemplateGameSDL class to: "

    @class_name = gets || ""

    print "Rename file (#{FileName}) to: "

    @file_name = gets || ""

    name_prompt_custom unless name_values_okay?
  end

  def replace_text
    puts "Replacing text..."

    ReplaceFiles.each do |file_name|
      file = File.read(file_name)

      file = file.gsub(ClassName, @class_name)
      file = file.gsub(FileName, @file_name)

      File.write(file_name, file)
    end
  end

  def rename_files
    puts "Renaming files..."

    RenameFiles.each do |file_name|
      base_name = File.basename(file_name)
      dir_name = File.dirname(file_name)

      File.rename(Path.new(file_name), Path.new(dir_name, base_name.gsub(FileName, @file_name)))
    end

    RenameDirectories.each do |file_name|
      base_name = File.basename(file_name)
      dir_name = File.dirname(file_name)

      File.rename(Path.new(file_name), Path.new(dir_name, base_name.gsub(FileName, @file_name)))
    end
  end

  def remove_readme_rename
    puts "Removing #{ReadmeFile} rename instructions..."

    lines = File.read_lines(ReadmeFile)

    # remove lines 3-13
    file = lines[0..1].join("\n") + lines[13..-1].join("\n") + "\n"

    File.write(ReadmeFile, file)
  end

  def run
    puts

    name_prompt

    puts

    replace_text
    rename_files
    remove_readme_rename

    puts
    puts "Done!"
  end
end

Rename.new.run
