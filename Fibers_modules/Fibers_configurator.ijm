var setup_file_headers = newArray(
    "*** Auto generated by BB Macros.\n" +
    "Do not modify unless you know exactly what you are doing.\n" +
    "\n" +
    "--------------------------------------------------------------------------------\n" +
        "\tIMAGE SETTINGS\n" +
    "--------------------------------------------------------------------------------\n" +
    "\n",
    "\n" +
    "--------------------------------------------------------------------------------\n" +
        "\tCHANNEL SETTINGS\n" +
    "--------------------------------------------------------------------------------\n" +
    "\n",
    "\n" +
    "--------------------------------------------------------------------------------\n" +
        "\tIMAGE VIEWER SETTINGS\n" +
    "--------------------------------------------------------------------------------\n" +
    "\n");

var color_choices           = newArray("Unused", 
                                       "Red", 
                                       "Green", 
                                       "Blue", 
                                       "Gray", 
                                       "Cyan", 
                                       "Magenta", 
                                       "Yellow");

var image_type_choices      = newArray(".tif (Single or multi-plane, single or multi-channel TIFF)", 
                                       ".zvi (Zeiss Vision Image)");

var image_type_extensions   = newArray(".tif", 
                                       ".zvi");

// IMAGE SETTINGS
var setup_block_01_labels   = newArray("Image type:", 
                                       "Channels (auto-detected):", 
                                       "Slices (auto-detected):");

var setup_block_01_defaults = newArray(".zvi", 
                                       1, 
                                       0);

// CHANNEL SETTINGS
var setup_block_02_labels   = newArray("Label:");

var setup_block_02_defaults = newArray("Default label");

// IMAGE VIEWER SETTINGS
var setup_block_03_labels   = newArray("Color:", 
                                       "Monotone display min value:", 
                                       "Monotone display max value:", 
                                       "Heat map display min value:", 
                                       "Heat map display max value:", 
                                       "Display channels as:", 
                                       "Show fiber traces:");

var setup_block_03_defaults = newArray("Unused", 
                                       0, 
                                       4095, 
                                       0, 
                                       4095, 
                                       "RGB Composite", 
                                       0);

var working_path        = get_working_paths("working_path");
var analysis_path       = get_working_paths("analysis_path");
var analysis_setup_file = get_working_paths("analysis_setup_file");

var temp_directory_fibers = getDirectory("temp") +
                            "BB_macros" + File.separator() +
                            "Fibers" + File.separator();

/*
--------------------------------------------------------------------------------
    MACRO
--------------------------------------------------------------------------------
*/

macro "Fibers_configurator" {

    args = getArgument();
    args = split(args, "|");

    /*
        This macro understands the following arguments:
        1) "create":
            Primarily used to create a new Setup.txt file in the Analysis
            directory. Can also be used to modify the first two blocks of the
            Setup.txt file, particularly the image type (e.g. ".zvi") and the
            Channel labels.
        2) "change|block_index|line_index|new_value":
            Used to modify a single value in the Setup.txt file. The block_index 
            and line_index values start at 1, not 0. Every other value in the
            file is copied into the new file, which overwrites the old file.
        3) "retrieve|block_index|line_index":
            Used to retrieve a single value in the Setup.txt file. The
            block_index and line_index values start at 1, not 0. The retrieved
            value is stored in the temp_directory_fibers in config_temp.txt.
        Multiple arguments must be separated by a pipe character.
    */

    if (args[0] == "create") {
        if (!File.exists(analysis_path)) {
            File.makeDirectory(analysis_path);
        }

        if (!File.exists(analysis_setup_file)) {
            create_setup_file(true);
        } else {
            // Cut away any text before the block of settings, including the header.
            //     If we're not at the last block, then cut away the remaining
            //     blocks so that only the text of settings remains.
            setup_block_01 = File.openAsString(analysis_setup_file);
            setup_block_01 = substring(setup_block_01,
                                       indexOf(setup_block_01, setup_file_headers[0]) +
                                       lengthOf(setup_file_headers[0]),
                                       lengthOf(setup_block_01));
            setup_block_01 = substring(setup_block_01,
                                       0,
                                       indexOf(setup_block_01, setup_file_headers[1]));
            setup_block_01 = split(setup_block_01, "\n");

            setup_block_02 = File.openAsString(analysis_setup_file);
            setup_block_02 = substring(setup_block_02,
                                       indexOf(setup_block_02, setup_file_headers[1]) +
                                       lengthOf(setup_file_headers[1]),
                                       lengthOf(setup_block_02));
            setup_block_02 = substring(setup_block_02,
                                       0,
                                       indexOf(setup_block_02, setup_file_headers[2]));
            setup_block_02 = split(setup_block_02, "\n");

            // Create a dialog with our existing settings for Blocks 1 and 2 and
            //     ask if we'd like to change those settings.
            Dialog.create("Current Settings");
            for (i = 0; i < image_type_choices.length; i++) {
                if (matches(toString(get_configuration(1, 1)), image_type_extensions[i])) {
                    Dialog.addMessage(setup_block_01_labels[0] + "\t" + image_type_choices[i]);
                }
            }
            for (i = 1; i < setup_block_01.length; i++) {
                Dialog.setInsets(0, 20, 0);
                Dialog.addMessage(setup_block_01[i]);
            }
            Dialog.addMessage("-----------------------------------");
            for (i = 0; i < setup_block_02.length; i++) {
                Dialog.setInsets(0, 20, 0);
                Dialog.addMessage(setup_block_02[i]);
            }
            Dialog.addMessage("-----------------------------------");
            Dialog.addCheckbox("Modify these settings? ", false);
            Dialog.show;

            if(Dialog.getCheckbox() == true) {
                create_setup_file(false);
            }
        }
    } else if (args[0] == "change") {
        modify_setup_file(args[1], args[2], args[3]);
    } else if (args[0] == "retrieve") {
        write_retrieved_to_temp(args[1], args[2]);
    }
}

/*
--------------------------------------------------------------------------------
    FUNCTIONS
--------------------------------------------------------------------------------
*/

function create_setup_file(first_time_setup) {

    if (first_time_setup == false) {
        last_block_01_settings = get_configuration(1, "all");
        last_block_02_settings = get_configuration(2, "all");
        last_block_03_settings = get_configuration(3, "all");
    }

    setup_file = File.open(analysis_setup_file);

    /*
    ----------------------------------------------------------------------------
        BLOCK 1
    ----------------------------------------------------------------------------
    */

    print(setup_file, setup_file_headers[0]);

    found_images = true;
    do {
        Dialog.create("Select image type");
        if (!found_images) {
            Dialog.addMessage("No " + choice + " files were found in the working directory.\n" +
                              "Please make sure that the working directory contains\n" +
                              "images of the selected type.");
        }
        if (first_time_setup) {
            for (i = 0; i < image_type_choices.length; i++) {
                if (setup_block_01_defaults[0] == image_type_extensions[i]) {
                    default = image_type_choices[i];
                }
            }
            Dialog.addChoice(setup_block_01_labels[0], image_type_choices, default);
        } else {
            for (i = 0; i < image_type_choices.length; i++) {
                if (last_block_01_settings[0] == image_type_extensions[i]) {
                    default = image_type_choices[i];
                }
            }
            Dialog.addChoice(setup_block_01_labels[0], image_type_choices, default);
        }
        Dialog.show();
        choice = Dialog.getChoice();
        for (i = 0; i < image_type_choices.length; i++) {
            if (choice == image_type_choices[i]) {
                extension = image_type_extensions[i];
                image_list = get_file_list_from_directory(working_path, extension);
            }
        }
        if (image_list.length == 0) {
            found_images = false;
        } else {
            found_images = true;
        }
    } while (found_images == false);
    print(setup_file, setup_block_01_labels[0] +    "\t" + extension);

    run("Close All");
    setBatchMode(true);
    open(working_path + image_list[0]);
    if (choice == ".zvi (Zeiss Vision Image)") {
        getDimensions(width, height, channels, slices, frames);
        n_channels = nImages();
    } else {
        getDimensions(width, height, channels, slices, frames);
        n_channels = channels;
    }
    run("Close All");
    print(setup_file, setup_block_01_labels[1] +    "\t" + n_channels);
    print(setup_file, setup_block_01_labels[2] +    "\t" + slices);

    if (slices > 1) {
        exit("The Fibers macro set doesn't know how to deal\n" +
             "with multi-slice images. Please flatten the\n" +
             "images first.");
    }
    if (frames > 1) {
        exit("The Fibers macro set doesn't know how to deal\n" +
             "with multi-frame images. Please flatten the\n" +
             "images or use images with a single representative\n" +
             "frame first.");
    }


    /*
    ----------------------------------------------------------------------------
        BLOCK 2
    ----------------------------------------------------------------------------
    */

    print(setup_file, setup_file_headers[1]);
    Dialog.create("Channel settings");

    for (i = 0; i < n_channels; i++) {
        if (first_time_setup == true) {
            Dialog.addString("Channel " + toString(i + 1) + "\t" +
                             setup_block_02_labels[0],
                             setup_block_02_defaults[0]);
        } else {
            if (i + 1 > (last_block_02_settings.length - 0) / 1) {
                Dialog.addString("Channel " + toString(i + 1) + "\t" +
                                 setup_block_02_labels[0],
                                 setup_block_02_defaults[0]);
            } else {
                Dialog.addString("Channel " + toString(i + 1) + "\t" +
                                 setup_block_02_labels[0],
                                 last_block_02_settings[i]);
            }
        }
    }

    Dialog.show();
    for (i = 0; i < n_channels; i++) {
        print(setup_file,
              "Channel " + toString(i + 1) + "\t" +
              setup_block_02_labels[0] + "\t" +
              Dialog.getString());
    }

    /*
    ----------------------------------------------------------------------------
        BLOCK 3
    ----------------------------------------------------------------------------
    */

    print(setup_file, setup_file_headers[2]);
    for (block_line = 0; block_line < setup_block_03_labels.length; block_line++) {
        if (block_line < 5) {
            for (channel = 0; channel < n_channels; channel++) {
                for (channel_line = 0; channel_line < 5; channel_line++) {
                    if (first_time_setup == true) {
                        print(setup_file,
                              "Channel " + toString(channel + 1) + "\t" +
                              setup_block_03_labels[channel_line] + "\t" +
                              setup_block_03_defaults[channel_line]);
                    } else {
                        if (channel + 1 > (last_block_03_settings.length - 2) / 5) {
                            print(setup_file,
                                  "Channel " + toString(channel + 1) + "\t" +
                                  setup_block_03_labels[channel_line] + "\t" +
                                  setup_block_03_defaults[channel_line]);
                        } else {
                            print(setup_file,
                                  "Channel " + toString(channel + 1) + "\t" +
                                  setup_block_03_labels[channel_line] + "\t" +
                                  last_block_03_settings[channel_line + (5 * channel)]);
                        }
                    }
                }
            }
            block_line = 4;
        } else {
            if (first_time_setup == true) {
                print(setup_file,
                      setup_block_03_labels[block_line] + "\t" +
                      setup_block_03_defaults[block_line]);
            } else {
                print(setup_file,
                      setup_block_03_labels[block_line] + "\t" +
                      last_block_03_settings[block_line + (5 * (n_channels - 1))]);
            }
        }
    }

    File.close(setup_file);
}

// Returns a single configuration value from the setup text file,
//     or all the settings in a block if line_index is "all".
//     The block_index and line_index numbering should be taken as
//     starting from 1 and not 0 when entered as arguments to this
//     function; they will be decremented by 1 within the function.
function get_configuration(block_index, line_index) {
    if (isNaN(parseInt(block_index)))
        exit("block_index = " + block_index + " was passed to\n" +
             "get_configuration() in Fibers_configurator.ijm.\n" +
             "\n" +
             "block_index must be a number.");
    block_index = parseInt(block_index);
    if (block_index < 1 || block_index > setup_file_headers.length)
        exit("block_index = " + block_index + " was passed to\n" +
             "get_configuration() in Fibers_configurator.ijm.\n" +
             "\n" +
             "block_index must be between 1 and " + setup_file_headers.length + ".");
    block_index -= 1;

    if (isNaN(parseInt(line_index))) {
        line_index = toLowerCase(line_index);
        if (!matches(line_index, "all"))
            exit("line_index = " + line_index + " was passed to\n" +
                 "get_configuration() in Fibers_configurator.ijm.\n" +
                 "\n" +
                 "line_index must be a positive integer or 'all'.");
    } else {
        line_index = parseInt(line_index);
        line_index  -= 1;
    }

    raw_text = File.openAsString(analysis_setup_file);

    // Get the number of channels, needed for enumerating repeating
    //     elements in the setup file.
    n_channels = substring(raw_text,
                           indexOf(raw_text, setup_block_01_labels[1] + "\t") +
                           lengthOf(setup_block_01_labels[1] + "\t"),
                           lengthOf(raw_text));
    n_channels = substring(n_channels, 0, indexOf(n_channels, "\n"));
    n_channels = parseInt(n_channels);
    if (isNaN(n_channels) == true) {
        exit("Fibers Configurator:\n" +
             "Could not get number of channels\n" +
             "from Setup.txt in get_configuration()");
    }

    // Now make sure that whatever called this function passed
    //     a block index that exists in the Setup.txt file. An
    //     exact match between the headers in this macro and the
    //     headers in the Setup.txt file is necessary in order
    //     to trim the raw text string of the setup file down
    //     to the individual configuration setting.
    if (indexOf(raw_text, setup_file_headers[block_index]) == -1) 
        exit("Fibers Configurator:\n" +
             "The header\n" +
             "\n" + 
             setup_file_headers[block_index] + "\n" +
             "\n" +
             "not found in Setup.txt file.");

    // Cut away any text before the block of settings, including the header.
    result = substring(raw_text,
                       indexOf(raw_text,
                               setup_file_headers[block_index]) +
                               lengthOf(setup_file_headers[block_index]),
                               lengthOf(raw_text));
    // If we're not at the last block, then cut away the remaining blocks so that
    //     only the text of settings remains.
    if (block_index < setup_file_headers.length - 1) {
        result = substring(result,
                           0,
                           indexOf(result,
                                   setup_file_headers[block_index + 1]));
    }

    // We now have a block of text without headers containing just the lines of cfg data.
    //     In each line, the cfg label is separated from the cfg datum by ':\t'.
    result = split(result, "\n");
    trimmed_result = newArray();
    for (i = 0; i < result.length; i++) {
        // This is so trailing newlines don't mess up the result.
        if (lengthOf(result[i]) == 0) continue;

        append = result[i];
        append = substring(append, indexOf(append, ":\t") + lengthOf(":\t"), lengthOf(append));
        trimmed_result = Array.concat(trimmed_result, append);
    }

    if (matches(line_index, "all")) {
        return trimmed_result;
    } else {
        if ((line_index + 1) < 1 || (line_index + 1) > trimmed_result.length)
            exit("line_index = " + (line_index + 1) + " was passed to\n" +
                 "get_configuration() in Fibers_configurator.ijm.\n" +
                 "\n" +
                 "If line_index is a number, it must be a positive\n" +
                 "integer between 1 and " + trimmed_result.length + ".");
        return trimmed_result[line_index];
    }
}

// Return a list of all the files with the specified extension in the directory.
function get_file_list_from_directory(directory, extension) {
    all_file_list = getFileList(directory);
    file_list = newArray();
    for (i=0; i<all_file_list.length; i++) {
        if (endsWith(toLowerCase(all_file_list[i]), extension) == true) {
            file_list = Array.concat(file_list, all_file_list[i]);
        }
    }
    return file_list;
}

// Runs the global configurator macro, which writes the resulting path
//     to a text file in the temp directory. This result is read back and
//     returned by the function and the temp file is deleted.
function get_working_paths(path_arg) {
    temp_directory_fibers = getDirectory("temp") +
                            "BB_macros" + File.separator() +
                            "Fibers" + File.separator();
    valid_path_args = newArray("working_path",
                               "analysis_path",
                               "obs_unit_ROI_path",
                               "analysis_setup_file");
    valid_arg = false;
    for (i = 0; i < valid_path_args.length; i++) {
        if (matches(path_arg, valid_path_args[i])) {
            valid_arg = true;
            i = valid_path_args.length;
        }
    }
    if (!valid_arg) {
        exit(path_arg + " is not recognized as\n" +
             "a valid argument for get_working_paths.");
    }
    if (File.exists(getDirectory("plugins") +
                    "BB_macros" + File.separator() +
                    "Fibers_modules" + File.separator() +
                    "Global_configuration_fibers.txt") == true) {
        runMacro(getDirectory("plugins") +
                 "BB_macros" + File.separator() +
                 "Fibers_modules" + File.separator() +
                 "Global_configurator_fibers.ijm", path_arg);
        retrieved = File.openAsString(temp_directory_fibers + "g_config_temp.txt");
        deleted = File.delete(temp_directory_fibers + "g_config_temp.txt");
        retrieved = split(retrieved, "\n");
        return retrieved[0];
    } else {
        exit("Global configuration not found.");
    }
}

// Change a single value in the Setup.txt file.
function modify_setup_file(block_index, line_index, new_value) {
    // First make sure that whatever called this function
    //     passed indices that exist in this macro.
    if (block_index > setup_file_headers.length - 1) {
        exit("Fibers Configurator",
             "Invalid Block Index passed to modify_setup_file()\n" +
             "in Fibers_configurator.ijm.");
    }

    last_block_01_settings = get_configuration(1, "all");
    last_block_02_settings = get_configuration(2, "all");
    last_block_03_settings = get_configuration(3, "all");

    setup_file = File.open(analysis_setup_file);

    /*
    ----------------------------------------------------------------------------
        BLOCK 1
    ----------------------------------------------------------------------------
    */

    // Continue to auto-detect and change n_channels.
    print(setup_file, setup_file_headers[0]);
    for (i = 0; i < setup_block_01_labels.length; i++) {
        if (block_index == 0 && line_index == i) {
            print(setup_file, setup_block_01_labels[i] + "\t" + new_value);
            if (setup_block_01_labels[i] == "Channels (auto-detected):") {
                n_channels = new_value;
            }
        } else {
            print(setup_file, setup_block_01_labels[i] + "\t" + last_block_01_settings[i]);
            if (setup_block_01_labels[i] == "Channels (auto-detected):") {
                n_channels = last_block_01_settings[i];
            }
        }
    }

    /*
    ----------------------------------------------------------------------------
        BLOCK 2
    ----------------------------------------------------------------------------
    */

    print(setup_file, setup_file_headers[1]);
    for (block_line = 0; block_line < setup_block_02_labels.length; block_line++) {
        if (block_line < 1) {
            for (channel = 0; channel < n_channels; channel++) {
                for (channel_line = 0; channel_line < 1; channel_line++) {
                    if (block_index == 1 && line_index == channel_line + (channel * 1)) {
                        print(setup_file,
                              "Channel " + toString(channel + 1) + "\t" +
                              setup_block_02_labels[channel_line] +  "\t" +
                              new_value);
                    } else {
                        print(setup_file,
                              "Channel " + toString(channel + 1) + "\t" +
                              setup_block_02_labels[channel_line] +  "\t" +
                              last_block_02_settings[channel_line + (channel * 1)]);
                    }
                }
            }
            i = 0;
        } else {
            if (block_index == 1 && line_index == block_line + (1 * (n_channels - 1))) {
                print(setup_file,
                      setup_block_02_labels[block_line] + "\t" +
                      new_value);
            } else {
                print(setup_file,
                      setup_block_02_labels[block_line] + "\t" +
                      last_block_02_settings[block_line + (1 * (n_channels - 1))]);
            }
        }
    }

    /*
    ----------------------------------------------------------------------------
        BLOCK 3
    ----------------------------------------------------------------------------
    */

    print(setup_file, setup_file_headers[2]);
    for (block_line = 0; block_line < setup_block_03_labels.length; block_line++) {
        if (block_line < 5) {
            for (channel = 0; channel < n_channels; channel++) {
                for (channel_line = 0; channel_line < 5; channel_line++) {
                    if (block_index == 2 && line_index == channel_line + (channel * 5)) {
                        print(setup_file,
                              "Channel " + toString(channel + 1) + "\t" +
                              setup_block_03_labels[channel_line] +  "\t" +
                              new_value);
                    } else {
                        print(setup_file,
                              "Channel " + toString(channel + 1) + "\t" +
                              setup_block_03_labels[channel_line] +  "\t" +
                              last_block_03_settings[channel_line + (channel * 5)]);
                    }
                }
            }
            i = 4;
        } else {
            if (block_index == 2 && line_index == block_line + (5 * (n_channels - 1))) {
                print(setup_file,
                      setup_block_03_labels[block_line] + "\t" +
                      new_value);
            } else {
                print(setup_file,
                      setup_block_03_labels[block_line] + "\t" +
                      last_block_03_settings[block_line + (5 * (n_channels - 1))]);
            }
        }
    }

    File.close(setup_file);
}

// Passes its arguments to retrieve_g_configuration and writes the
//    result to the temp file.
function write_retrieved_to_temp(block_index, line_index) {
    retrieved = retrieve_g_configuration(block_index, line_index);
    retrieved_temp = File.open(temp_directory_fibers + "config_temp.txt");
    print(retrieved_temp, retrieved);
    File.close(retrieved_temp);
}

// Retrieve a single value from the Fibers macro set global
//   settings, or all values in that block if line_index is
//   'all'.
function retrieve_g_configuration(block_index, line_index) {
    runMacro(getDirectory("plugins") +
             "BB_macros" + File.separator() +
             "Fibers_modules" + File.separator() +
             "Global_configurator_fibers.ijm",
             "retrieve|" + block_index + "|" + line_index);
    retrieved = File.openAsString(temp_directory_fibers + "g_config_temp.txt");
    deleted = File.delete(temp_directory_fibers + "g_config_temp.txt");
    retrieved = split(retrieved, "\n");
    return retrieved[0];
}