extends Node

var rootFolder
var bankFolder
var frackedFolder
var suspectFolder
var counterfeitFolder
var importFolder
var exportFolder
var Dir = Directory.new()

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#Sets all of the member variables of this class based on the specified root folder
#Will also create any directories that are missing
func GetInstance(p_rootFolder):
	
	rootFolder = p_rootFolder
	Dir.open(rootFolder)
	bankFolder = rootFolder + "/Bank"
	if !Dir.dir_exists(bankFolder):
		Dir.make_dir(bankFolder)
	frackedFolder = rootFolder + "/Fracked"
	if !Dir.dir_exists(frackedFolder):
		Dir.make_dir(frackedFolder)
	suspectFolder = rootFolder + "/Suspect"
	if !Dir.dir_exists(suspectFolder):
		Dir.make_dir(suspectFolder)
	counterfeitFolder = rootFolder + "/Counterfeit"
	if !Dir.dir_exists(counterfeitFolder):
		Dir.make_dir(counterfeitFolder)
	importFolder = rootFolder + "/Import"
	if !Dir.dir_exists(importFolder):
		Dir.make_dir(importFolder)
	exportFolder = rootFolder + "/Export"
	if !Dir.dir_exists(exportFolder):
		Dir.make_dir(exportFolder)
	pass

#Counts the amount of CloudCoins found locally and return the result in the form of an array
#Element 0 has the total amount, elements 1 through 5 has the amount of specific denominations 1, 5, 25, 100, 250 respectively
func CountCoins():
	var returnCounts = [0, 0, 0, 0, 0, 0]
	Dir.change_dir(bankFolder)
	Dir.list_dir_begin(true, true)
	var file_name = Dir.get_next()
	while(file_name != ""):
		var dem = file_name.substr(0, file_name.find("."))
		match dem:
			"1":
				returnCounts[0] += 1
				returnCounts[1] += 1
			"5":
				returnCounts[0] += 5
				returnCounts[2] += 1
			"25":
				returnCounts[0] += 25
				returnCounts[3] += 1
			"100":
				returnCounts[0] += 100
				returnCounts[4] += 1
			"250":
				returnCounts[0] += 250
				returnCounts[5] += 1
			_:
				print("Wallet filename trim incorrect")
		file_name = Dir.get_next()
		if(file_name == "" && Dir.get_current_dir() == bankFolder):
			Dir.change_dir(frackedFolder)
			Dir.list_dir_begin(true, true)
			file_name = Dir.get_next() 
	Dir.change_dir(rootFolder)
	return returnCounts

#Will write the .stack file that holds a certain amount of cloudcoins for exporting.
#the file will be saved to the Export Folder.
func WriteJsonFile(exp_1, exp_5, exp_25, exp_100, exp_250, tag):
	var totalSaved = exp_1 + (exp_5 * 5) + (exp_25 * 25) + (exp_100 * 100) + (exp_250 * 250)
	var coinCount = exp_1 + exp_5 + exp_25 + exp_100 + exp_250
	var coinsToDelete = []
	coinsToDelete.resize(coinCount)
	var file = File.new()
	var c = 0
	var willExport = false
	var useFracked = false
	var json = "{\n\t\"cloudcoin\": \n\t["
	Dir.change_dir(bankFolder)
	Dir.list_dir_begin(true, true)
	var file_name = Dir.get_next()
	while(file_name != ""):
		var dem = file_name.substr(0, file_name.find("."))
		match dem:
			"1":
				if exp_1 > 0:
					exp_1 -= 1
					willExport = true
				else:
					willExport = false
			"5":
				if exp_5 > 0:
					exp_5 -= 1
					willExport = true
				else:
					willExport = false
			"25":
				if exp_25 > 0:
					exp_25 -= 1
					willExport = true
				else:
					willExport = false
			"100":
				if exp_100 > 0:
					exp_100 -= 1
					willExport = true
				else:
					willExport = false
			"250":
				if exp_250 > 0:
					exp_250 -= 1
					willExport = true
				else:
					willExport = false
			_:
				print("Wallet filename trim incorrect")
		if willExport:
			if c != 0:
				json += ",\n"
			if !useFracked:
				file.open(bankFolder + "/" + file_name, file.READ)
			else:
				file.open(frackedFolder + "/" + file_name, file.READ)
			var coinString = file.get_as_text()
			print(coinString)
			var coinNote = JSON.parse(coinString).result["cloudcoin"][0]
			file.close()
			json = json + setJson(coinNote)
			if !useFracked:
				coinsToDelete[c] = bankFolder + "/" + file_name
			else:
				coinsToDelete[c] = frackedFolder + "/" + file_name
			c += 1
		file_name = Dir.get_next()
		if(file_name == "" && Dir.get_current_dir() == bankFolder):
			Dir.change_dir(frackedFolder)
			Dir.list_dir_begin(true, true)
			file_name = Dir.get_next() 
			useFracked = true
	Dir.change_dir(rootFolder)
	json = json + "\t] \n}"
	var exportFileName = exportFolder +"/" + String(totalSaved) + ".CloudCoins." + tag + ".stack"
	if Dir.dir_exists(exportFileName):
		var rand = randi()%1001+1
		exportFileName = exportFolder +"/" + String(totalSaved) + ".CloudCoins." + tag + rand + ".stack"
	file.open(exportFileName, file.WRITE)
	file.store_string(json)
	file.close()
	print("writing to: " + exportFileName)
	for cc in coinsToDelete:
		Dir.remove(cc)

#Returns a string of the json formated text form of the supplied CloudCoin.
func setJson(cc):
	var quote = "\""
	var tab = "\t"
	var json = tab + tab + "{ \n";
	json += tab + tab + quote + "nn" + quote + ":" + quote + cc["nn"] + quote + ", \n"
	json += tab + tab + quote + "sn" + quote + ":" + quote + cc["sn"] + quote + ", \n"
	json += tab + tab + quote + "an" + quote + ": [" + quote
	for i in range(25):
		json += cc["an"][i]
		match i:
			4, 9, 14, 19:
				json += quote + ",\n" + tab + tab + tab + quote
			24:
				json = json
			_:
				json += quote + "," + quote
	json += quote + "],\n"
	json += tab + tab + quote + "ed" + quote + ":" + quote + cc["ed"] + quote + ",\n"
	if cc["pown"] == null or cc["pown"] == "":
		cc["pown"] = "uuuuuuuuuuuuuuuuuuuuuuuuu"
	json += tab + tab + quote + "pown" + quote + ":" + quote + cc["pown"] + quote + ",\n"
	json += tab + tab + quote + "aoid" + quote + ": []\n"
	json += tab + tab + "}\n"
	return json

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
