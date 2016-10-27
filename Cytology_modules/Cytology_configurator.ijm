var setupFileHeaders = newArray(
	"*** Auto generated by BB Macros.\n" +
	"Do not modify unless you know exactly what you are doing.\n" +
	"\n" +
	"--------------------------------------------------------------------------------\n" +
		"\tIMAGE SETTINGS\n" +
	"--------------------------------------------------------------------------------\n" +
	"\n" +
	"",
	"\n" +
	"--------------------------------------------------------------------------------\n" +
		"\tCHANNEL SETTINGS\n" +
	"--------------------------------------------------------------------------------\n" +
	"\n" +
	"",
	"\n" +
	"--------------------------------------------------------------------------------\n" +
		"\tIMAGE VIEWER SETTINGS\n" +
	"--------------------------------------------------------------------------------\n" +
	"\n" +
	"",
	"\n" +
	"--------------------------------------------------------------------------------\n" +
		"\tOBSERVATIONAL UNITS SETTINGS\n" +
	"--------------------------------------------------------------------------------\n" +
	"\n" +
	"",
	"\n" +
	"--------------------------------------------------------------------------------\n" +
		"\tFOCUS COUNTER SETTINGS\n" +
	"--------------------------------------------------------------------------------\n" +
	"\n" +
	"",
	"\n" +
	"--------------------------------------------------------------------------------\n" +
		"\tAUTO MONTAGE SETTINGS\n" +
	"--------------------------------------------------------------------------------\n" +
	"\n" +
	"",
	"\n" +
	"--------------------------------------------------------------------------------\n" +
		"\tMANUAL MONTAGE SETTINGS\n" +
	"--------------------------------------------------------------------------------\n" +
	"\n" +
	"");

var colorChoices         = newArray("Unused", 
									"Red", 
									"Green", 
									"Blue", 
									"Gray", 
									"Cyan", 
									"Magenta", 
									"Yellow");

var imageTypeChoices     = newArray(".tif (Single or multi-plane, single or multi-channel TIFF)", 
									".zvi (Zeiss Vision Image)", 
									".lsm (Leica confocal image)");

var imageTypeExtensions  = newArray(".tif", 
								   	".zvi", 
								   	".lsm");

var zSeriesChoices       = newArray("Do nothing", 
							  		"Flatten (MAX)", 
							  		"Flatten (SUM)");

var setupBlock01Labels   = newArray("Image type:", 
								  	"Channels (auto-detected):", 
								  	"Slices (auto-detected):", 
								  	"Z-series options:");

var setupBlock01Defaults = newArray(".zvi", 
									1, 
									0, 
									"Do nothing");

var setupBlock02Labels   = newArray("Label:", 
								  	"Obs Unit/Submask Channel:");

var setupBlock02Defaults = newArray("Default label", 
									1);

var setupBlock03Labels   = newArray("Color:", 
								  	"Monotone display min value:", 
								  	"Monotone display max value:", 
								  	"Heat map display min value:", 
								  	"Heat map display max value:", 
								  	"Display channels as:", 
								  	"Show obs unit boxes:", 
								  	"Show global masks:", 
								  	"Show submasks:");

var setupBlock03Defaults = newArray("Unused", 
									0, 
									4095, 
									0, 
									4095, 
									"RGB Composite", 
									0, 
									0, 
									0);

var setupBlock04Labels   = newArray("Box size for enclosing obs unit:");

var setupBlock04Defaults = newArray(-1, 
									"dummy");

var setupBlock05Labels   = newArray("Calibration images (image,obs unit;...):", 
								  	"Background subtraction data:", 
								  	"Maxima tolerance:", 
								  	"Lower threshold:", 
								  	"Minimum focus size:", 
								  	"Minimum focus avg. intensity:", 
								  	"Minimum focus intensity:", 
								  	"Minimum focus upper decile:", 
								  	"Active channel for focus counting:");
var setupBlock05Defaults = newArray("null", 
									-50, 
									70, 
									250, 
									10, 
									50, 
									3000, 
									500, 
									-1);

var setupBlock06Labels   = newArray("Display channel (if single):", 
								  	"Panels wide:", 
								  	"Panels high:", 
								  	"Randomize:", 
								  	"Max overlap between obs units:");
var setupBlock06Defaults = newArray(1, 
									5, 
									4, 
									0, 
									0.50);

var setupBlock07Labels   = newArray("Display panels as:", 
								  	"Spacer length between panels:");
var setupBlock07Defaults = newArray("RGB/Monotone", 
									20);

var workingPath = getWorkingPaths("workingPath");
var analysisPath = getWorkingPaths("analysisPath");
var analysisSetupFile = getWorkingPaths("analysisSetupFile");

/*
--------------------------------------------------------------------------------
	MACRO
--------------------------------------------------------------------------------
*/

macro "Cytology Configurator" {

	args = getArgument();
	args = split(args, "|");

	if (args[0] == "create") {
		if (File.exists(analysisPath) != true) {
			File.makeDirectory(analysisPath);
		}

		if (File.exists(analysisSetupFile) != true) {
			createSetupFile(true);
		} else {
			setupBlock01 = File.openAsString(analysisSetupFile);
			setupBlock01 = substring(setupBlock01, indexOf(setupBlock01, setupFileHeaders[0]) + lengthOf(setupFileHeaders[0]), lengthOf(setupBlock01));
			setupBlock01 = substring(setupBlock01, 0, indexOf(setupBlock01, setupFileHeaders[1]));
			setupBlock01 = split(setupBlock01, "\n");

			setupBlock02 = File.openAsString(analysisSetupFile);
			setupBlock02 = substring(setupBlock02, indexOf(setupBlock02, setupFileHeaders[1]) + lengthOf(setupFileHeaders[1]), lengthOf(setupBlock02));
			setupBlock02 = substring(setupBlock02, 0, indexOf(setupBlock02, setupFileHeaders[2]));
			setupBlock02 = split(setupBlock02, "\n");

			Dialog.create("Current Settings");
			for (i=0; i<imageTypeChoices.length; i++) {
				if (toString(getConfiguration(0, 0)) == imageTypeExtensions[i]) {
					Dialog.addMessage(setupBlock01Labels[0] + 	"\t" + imageTypeChoices[i]);
				}
			}
			for (i=1; i<setupBlock01.length; i++) {
				Dialog.setInsets(0, 20, 0);
				Dialog.addMessage(setupBlock01[i]);
			}
			Dialog.addMessage("-----------------------------------");
			for (i=0; i<setupBlock02.length; i++) {
				Dialog.setInsets(0, 20, 0);
				Dialog.addMessage(setupBlock02[i]);
			}
			Dialog.addMessage("-----------------------------------");
			Dialog.addCheckbox("Modify these settings? ", false);
			Dialog.show;

			if(Dialog.getCheckbox() == true) {
				createSetupFile(false);
			}
		}
	} else if (args[0] == "change") {
		modifySetupFile(args[1], args[2], args[3]);
	} else if (args[0] == "retrieve") {
		writeRetrievedToTemp(args[1], args[2]);
	}
}

/*
--------------------------------------------------------------------------------
	FUNCTIONS
--------------------------------------------------------------------------------
*/

function createSetupFile(firstTimeSetupBoolean) {

	if (firstTimeSetupBoolean == false) {
		lastBlock01Settings = getConfiguration(0, -1);
		lastBlock02Settings = getConfiguration(1, -1);
		lastBlock03Settings = getConfiguration(2, -1);
		lastBlock04Settings = getConfiguration(3, -1);
		lastBlock05Settings = getConfiguration(4, -1);
		lastBlock06Settings = getConfiguration(5, -1);
		lastBlock07Settings = getConfiguration(6, -1);
	}

	setupFile = File.open(analysisSetupFile);

	/*
	----------------------------------------------------------------------------
		BLOCK 1
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[0]);

	foundImages = true;
	do {
		Dialog.create("Select image type");
		if (foundImages == false) {
			Dialog.addMessage("No " + choice + " files were found in the working directory.");
		}
		if (firstTimeSetupBoolean == true) {
			for (i=0; i<imageTypeChoices.length; i++) {
				if (setupBlock01Defaults[0] == imageTypeExtensions[i]) {
					default = imageTypeChoices[i];
				}
			}
			Dialog.addChoice(setupBlock01Labels[0], imageTypeChoices, default);
		} else {
			for (i=0; i<imageTypeChoices.length; i++) {
				if (lastBlock01Settings[0] == imageTypeExtensions[i]) {
					default = imageTypeChoices[i];
				}
			}
			Dialog.addChoice(setupBlock01Labels[0], imageTypeChoices, default);
		}
		Dialog.show();
		choice = Dialog.getChoice();
		for (i=0; i<imageTypeChoices.length; i++) {
			if (choice == imageTypeChoices[i]) {
				extension = imageTypeExtensions[i];
				imageList = getFileListFromDirectory(workingPath, extension);
			}
		}
		if (imageList.length == 0) {
			foundImages = false;
		} else {
			foundImages = true;
		}
	} while (foundImages == false);
	print(setupFile, setupBlock01Labels[0] + 	"\t" + extension);

	run("Close All");
	setBatchMode(true);
	open(workingPath + imageList[0]);
	if (choice == ".zvi (Zeiss Vision Image)") {
		getDimensions(width, height, channels, slices, frames);
		nChannels = nImages();
	} else {
		getDimensions(width, height, channels, slices, frames);
		nChannels = channels;
	}
	run("Close All");
	print(setupFile, setupBlock01Labels[1] + 	"\t" + nChannels);
	print(setupFile, setupBlock01Labels[2] + 	"\t" + slices);
	nChannelsCheck = nChannels;

	if (slices > 1) {
		Dialog.create("Handling of Z-slices");
		zSeriesChoices2 = Array.concat(zSeriesChoices[1], zSeriesChoices[2]);
		if (firstTimeSetupBoolean == true) {
			Dialog.addChoice(setupBlock01Labels[3], zSeriesChoices2, setupBlock01Defaults[3]);
		} else {
			Dialog.addChoice(setupBlock01Labels[3], zSeriesChoices2, lastBlock01Settings[3]);
		}
		Dialog.show();
		choice = Dialog.getChoice();
		print(setupFile, setupBlock01Labels[3] + 	"\t" + choice);
	} else {
		print(setupFile, setupBlock01Labels[3] + 	"\t" + "Do nothing");
	}


	/*
	----------------------------------------------------------------------------
		BLOCK 2
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[1]);
	Dialog.create("Channel settings");

	for (i=0; i<nChannels; i++) {
		if (firstTimeSetupBoolean == true) {
			Dialog.addString("Channel " + toString(i + 1) + 	"\t" + setupBlock02Labels[0], setupBlock02Defaults[0]);
		} else {
			if (i + 1 > lastBlock02Settings.length - 1) {
				Dialog.addString("Channel " + toString(i + 1) + 	"\t" + setupBlock02Labels[0], setupBlock02Defaults[0]);
			} else {
				Dialog.addString("Channel " + toString(i + 1) + 	"\t" + setupBlock02Labels[0], lastBlock02Settings[i]);
			}
		}
	}

	channelChoices = newArray();
	for (i=0; i<nChannels; i++) {
		channelChoices = Array.concat(channelChoices, "Channel " + toString(i + 1));
	}
	if (firstTimeSetupBoolean == true) {
		Dialog.addChoice(setupBlock02Labels[1], channelChoices, "Channel " + setupBlock02Defaults[1]);
	} else {
		Dialog.addChoice(setupBlock02Labels[1], channelChoices, "Channel " + lastBlock02Settings[nChannels]);
	}

	Dialog.show();
	for (i=0; i<nChannels; i++) {
		print(setupFile, "Channel " + toString(i + 1) + 	"\t" + setupBlock02Labels[0] + 	"\t" + Dialog.getString());
	}
	choice = Dialog.getChoice();
	choice = substring(choice, lengthOf("Channel "), lengthOf(choice));
	print(setupFile, setupBlock02Labels[1] + 	"\t" + choice);

	/*
	----------------------------------------------------------------------------
		BLOCK 3
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[2]);
	for (i=0; i<setupBlock03Labels.length; i++) {
		if (i < 5) {
			for (j=0; j<nChannels; j++) {
				for (k=0; k<5; k++) {
					if (firstTimeSetupBoolean == true) {
						print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock03Labels[k] + 	"\t" + setupBlock03Defaults[k]);
					} else {
						if (j + 1 > (lastBlock03Settings.length - 3) / 5) {
							print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock03Labels[k] + 	"\t" + setupBlock03Defaults[k]);
						} else {
							print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock03Labels[k] + 	"\t" + lastBlock03Settings[k + (5 * j)]);
						}
					}
				}
			}
			i = 4;
		} else {
			if (firstTimeSetupBoolean == true) {
				print(setupFile, setupBlock03Labels[i] + 	"\t" + setupBlock03Defaults[i]);
			} else {
				print(setupFile, setupBlock03Labels[i] + 	"\t" + lastBlock03Settings[i + (5 * (nChannels - 1))]);
			}
		}
	}

	/*
	----------------------------------------------------------------------------
		BLOCK 4
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[3]);
	for (i=0; i<setupBlock04Labels.length; i++) {
		if (firstTimeSetupBoolean == true) {
			print(setupFile, setupBlock04Labels[i] + 	"\t" + setupBlock04Defaults[i]);
		} else {
			print(setupFile, setupBlock04Labels[i] + 	"\t" + lastBlock04Settings[i]);
		}
	}

	/*
	----------------------------------------------------------------------------
		BLOCK 5
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[4]);
	for (i=0; i<setupBlock05Labels.length; i++) {
		if (i < 8) {
			for (j=0; j<nChannels; j++) {
				for (k=0; k<8; k++) {
					if (firstTimeSetupBoolean == true) {
						print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock05Labels[k] + 	"\t" + setupBlock05Defaults[k]);
					} else {
						if (j + 1 > (lastBlock05Settings.length - 1) / 8) {
							print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock05Labels[k] + 	"\t" + setupBlock05Defaults[k]);
						} else {
							print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock05Labels[k] + 	"\t" + lastBlock05Settings[k + (8 * j)]);
						}
					}
				}
			}
			i = 7;
		} else {
			if (firstTimeSetupBoolean == true) {
				print(setupFile, setupBlock05Labels[i] + 	"\t" + setupBlock05Defaults[i]);
			} else {
				print(setupFile, setupBlock05Labels[i] + 	"\t" + lastBlock05Settings[i + (8 * (nChannels - 1))]);
			}
		}
	}

	/*
	----------------------------------------------------------------------------
		BLOCK 6
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[5]);
	for (i=0; i<setupBlock06Labels.length; i++) {
		if (firstTimeSetupBoolean == true) {
			print(setupFile, setupBlock06Labels[i] + 	"\t" + setupBlock06Defaults[i]);
		} else {
			print(setupFile, setupBlock06Labels[i] + 	"\t" + lastBlock06Settings[i]);
		}
	}

	/*
	----------------------------------------------------------------------------
		BLOCK 7
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[6]);
	for (i=0; i<setupBlock07Labels.length; i++) {
		if (firstTimeSetupBoolean == true) {
			print(setupFile, setupBlock07Labels[i] + 	"\t" + setupBlock07Defaults[i]);
		} else {
			print(setupFile, setupBlock07Labels[i] + 	"\t" + lastBlock07Settings[i]);
		}
	}

	File.close(setupFile);
}

function getConfiguration(blockIndex, lineIndex) {
	blockIndex = parseInt(blockIndex);
	lineIndex = parseInt(lineIndex);
	rawText = File.openAsString(analysisSetupFile);

	// Get the number of channels, needed for enumerating repeating elements in the setup file
	nChannels = substring(rawText, indexOf(rawText, setupBlock01Labels[1] + 	"\t") + lengthOf(setupBlock01Labels[1] + 	"\t"), lengthOf(rawText));
	nChannels = substring(nChannels, 0, indexOf(nChannels, "\n"));
	nChannels = parseInt(nChannels);
	if (isNaN(nChannels) == true) {
		exit("Cytology Configurator:\nCould not get number of channels\nfrom Setup.txt in getConfiguration()");
	}

	// First make sure that whatever called this function passed indices that exist in this macro
	error = false;
	if (blockIndex > setupFileHeaders.length - 1) {
		showMessage("Cytology Configurator", "Invalid Block Index passed to getConfiguration()");
		error = true;
	}

	if (error == true) {
		return "ERROR";
	}

	// Now make sure that whatever called this function passed a block index that exists in the Setup.txt file
	notFound = false;
	if (indexOf(rawText, setupFileHeaders[blockIndex]) == -1) {
		showMessage("Cytology Configurator", "The header\n\n" + setupFileHeaders[blockIndex] + "\n\n" + "not found in Setup.txt file.");
		return "ERROR";
	} else {
		// Trim the Setup.txt rawtext to the designated block
		result = substring(rawText, indexOf(rawText, setupFileHeaders[blockIndex]) + lengthOf(setupFileHeaders[blockIndex]), lengthOf(rawText));
		// Trim off the rest of the text, but only if we're not at the last block in the Setup.txt file
		if (blockIndex < setupFileHeaders.length - 1) {
			if (indexOf(result, setupFileHeaders[blockIndex + 1]) != -1) {
				result = substring(result, 0, indexOf(result, setupFileHeaders[blockIndex + 1]));
			}
		}

		// We now have a block of text without headers containing just the lines of cfg data
		// In each line, the cfg label is separated from the cfg datum by ':\t'
		result = split(result, "\n");
		trimmedResult = newArray();
		for (i=0; i<result.length; i++) {
			if (lengthOf(result[i]) == 0) { continue; }
			append = result[i];
			append = substring(append, indexOf(append, ":\t") + lengthOf(":\t"), lengthOf(append));
			trimmedResult = Array.concat(trimmedResult, append);
		}

		// We now have an array of cfg data without headers or labels that is ready to use
		// These are the value(s) that whatever called this function are looking for
		// Now check to see that whatever called this function passed a line index that exists in the Setup.txt file
		if (lineIndex > trimmedResult.length - 1) {
			showMessage("Cytology Configurator", "Line " + toString(lineIndex + 1) + " in block\n" + setupFileHeaders[blockIndex] + "\nnot found in Setup.txt file.\nThe max line index on this block is " + toString(trimmedResult.length - 1));
			return "ERROR";
		}
	}

	// Return the default value if an invalid block or line index was passed, otherwise return the value in the Setup.txt file
	if (lineIndex < 0) {
		return trimmedResult;
	} else {
		return trimmedResult[lineIndex];
	}
}

function getFileListFromDirectory(directory, extension) {
	allFileList = getFileList(directory);
	fileList = newArray();
	for (i=0; i<allFileList.length; i++) {
		if (endsWith(toLowerCase(allFileList[i]), extension) == true) {
			fileList = Array.concat(fileList, allFileList[i]);
		}
	}
	return fileList;
}

function getWorkingPaths(pathArg) {
	pathArgs = newArray("workingPath", "analysisPath", "obsUnitRoiPath", "analysisSetupFile", "imageIndexFile", "groupLabelsFile");
	if (File.exists(getDirectory("plugins") +
		"BB_macros" + File.separator() +
		"Cytology_modules" + File.separator() +
		"Global_configuration.txt") == true) {
		runMacro(getDirectory("plugins") +
			"BB_macros" + File.separator() +
			"Cytology_modules" + File.separator() +
			"Global_configurator.ijm", pathArg);
		retrieved = File.openAsString(getDirectory("temp") + "temp retrieved value.txt");
		deleted = File.delete(getDirectory("temp") + "temp retrieved value.txt");
		retrieved = split(retrieved, "\n");
		return retrieved[0];
	} else {
		exit("Global configuration not found.");
	}
}

function modifySetupFile(blockIndex, lineIndex, newValue) {
	// First make sure that whatever called this function passed indices that exist in this macro
	error = false;
	if (blockIndex > setupFileHeaders.length - 1) {
		exit("Cytology Configurator", "Invalid Block Index passed to modifySetupFile()");
	}

	lastBlock01Settings = getConfiguration(0, -1);
	lastBlock02Settings = getConfiguration(1, -1);
	lastBlock03Settings = getConfiguration(2, -1);
	lastBlock04Settings = getConfiguration(3, -1);
	lastBlock05Settings = getConfiguration(4, -1);
	lastBlock06Settings = getConfiguration(5, -1);
	lastBlock07Settings = getConfiguration(6, -1);

	setupFile = File.open(analysisSetupFile);

	/*
	----------------------------------------------------------------------------
		BLOCK 1
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[0]);
	for (i=0; i<setupBlock01Labels.length; i++) {
		if (blockIndex == 0 && lineIndex == i) {
			print(setupFile, setupBlock01Labels[i] + 	"\t" + newValue);
			if (setupBlock01Labels[i] == "Channels (auto-detected):") {
				nChannels = newValue;
			}
		} else {
			print(setupFile, setupBlock01Labels[i] + 	"\t" + lastBlock01Settings[i]);
			if (setupBlock01Labels[i] == "Channels (auto-detected):") {
				nChannels = lastBlock01Settings[i];
			}
		}
	}

	/*
	----------------------------------------------------------------------------
		BLOCK 2
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[1]);
	for (i=0; i<setupBlock02Labels.length; i++) {
		if (i < 1) {
			for (j=0; j<nChannels; j++) {
				for (k=0; k<1; k++) {
					if (blockIndex == 1 && lineIndex == k + (j * 1)) {
						print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock02Labels[k] + 	"\t" + newValue);
					} else {
						print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock02Labels[k] + 	"\t" + lastBlock02Settings[k + (j * 1)]);
					}
				}
			}
			i = 0;
		} else {
			if (blockIndex == 1 && lineIndex == i + (1 * (-1 + nChannels))) {
				print(setupFile, setupBlock02Labels[i] + 	"\t" + newValue);
			} else {
				print(setupFile, setupBlock02Labels[i] + 	"\t" + lastBlock02Settings[i + (1 * (-1 + nChannels))]);
			}
		}
	}

	/*
	----------------------------------------------------------------------------
		BLOCK 3
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[2]);
	for (i=0; i<setupBlock03Labels.length; i++) {
		if (i < 5) {
			for (j=0; j<nChannels; j++) {
				for (k=0; k<5; k++) {
					if (blockIndex == 2 && lineIndex == k + (j * 5)) {
						print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock03Labels[k] + 	"\t" + newValue);
					} else {
						print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock03Labels[k] + 	"\t" + lastBlock03Settings[k + (j * 5)]);
					}
				}
			}
			i = 4;
		} else {
			if (blockIndex == 2 && lineIndex == i + (5 * (-1 + nChannels))) {
				print(setupFile, setupBlock03Labels[i] + 	"\t" + newValue);
			} else {
				print(setupFile, setupBlock03Labels[i] + 	"\t" + lastBlock03Settings[i + (5 * (-1 + nChannels))]);
			}
		}
	}

	/*
	----------------------------------------------------------------------------
		BLOCK 4
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[3]);
	for (i=0; i<setupBlock04Labels.length; i++) {
		if (blockIndex == 3 && lineIndex == i) {
			print(setupFile, setupBlock04Labels[i] + 	"\t" + newValue);
		} else {
			print(setupFile, setupBlock04Labels[i] + 	"\t" + lastBlock04Settings[i]);
		}
	}

	/*
	----------------------------------------------------------------------------
		BLOCK 5
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[4]);
	for (i=0; i<setupBlock05Labels.length; i++) {
		if (i < 8) {
			for (j=0; j<nChannels; j++) {
				for (k=0; k<8; k++) {
					if (blockIndex == 4 && lineIndex == k + (j * 8)) {
						print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock05Labels[k] + 	"\t" + newValue);
					} else {
						print(setupFile, "Channel " + toString(j + 1) + 	"\t" + setupBlock05Labels[k] + 	"\t" + lastBlock05Settings[k + (j * 8)]);
					}
				}
			}
			i = 7;
		} else {
			if (blockIndex == 4 && lineIndex == i + (8 * (-1 + nChannels))) {
				print(setupFile, setupBlock05Labels[i] + 	"\t" + newValue);
			} else {
				print(setupFile, setupBlock05Labels[i] + 	"\t" + lastBlock05Settings[i + (8 * (-1 + nChannels))]);
			}
		}
	}

	/*
	----------------------------------------------------------------------------
		BLOCK 6
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[5]);
	for (i=0; i<setupBlock06Labels.length; i++) {
		if (blockIndex == 5 && lineIndex == i) {
			print(setupFile, setupBlock06Labels[i] + 	"\t" + newValue);
		} else {
			print(setupFile, setupBlock06Labels[i] + 	"\t" + lastBlock06Settings[i]);
		}
	}

	/*
	----------------------------------------------------------------------------
		BLOCK 7
	----------------------------------------------------------------------------
	*/

	print(setupFile, setupFileHeaders[6]);
	for (i=0; i<setupBlock07Labels.length; i++) {
		if (blockIndex == 6 && lineIndex == i) {
			print(setupFile, setupBlock07Labels[i] + 	"\t" + newValue);
		} else {
			print(setupFile, setupBlock07Labels[i] + 	"\t" + lastBlock07Settings[i]);
		}
	}

	File.close(setupFile);
}

function writeRetrievedToTemp(blockIndex, lineIndex) {
	retrieved = getConfiguration(blockIndex, lineIndex);
	retrievedTemp = File.open(getDirectory("temp") + "temp retrieved value.txt");
	print(retrievedTemp, retrieved);
	File.close(retrievedTemp);
}