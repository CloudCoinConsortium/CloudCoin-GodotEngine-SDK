extends Node

var fileUtils = load("res://CloudCoinSDK/FileUtils.tscn").instance()
export(String) var rootFolder
var FileNameList
var AvailableIndexies
var totalIndexies

func _ready():
	fileUtils.GetInstance(rootFolder)
	FileNameList = CreateFileNameList()
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

#Returns a list of every filename for CloudCoins contained in your Bank and Fracked Folders
#Also saves the indexies of this list into member variable AvailableIndexies sorted by denomination
#The five arrays in AvailableIndexies are for the denominations 1, 5, 25, 100, 250 in that order
func CreateFileNameList():
	AvailableIndexies = [[],[],[],[],[]]
	var list = []
	var BankDir = Directory.new()
	BankDir.open(fileUtils.bankFolder)
	BankDir.list_dir_begin(true, true)
	var file_name = BankDir.get_next()
	var index = 0
	while(file_name != ""):
		list.append(file_name)
		var dem = file_name.substr(0, file_name.find("."))
		match dem:
			"1":
				AvailableIndexies[0].append(index)
			"5":
				AvailableIndexies[1].append(index)
			"25":
				AvailableIndexies[2].append(index)
			"100":
				AvailableIndexies[3].append(index)
			"250":
				AvailableIndexies[4].append(index)
			_:
				print("Wallet filename trim incorrect")
		index = index + 1
		file_name = BankDir.get_next()
		if(file_name == "" && BankDir.get_current_dir() == fileUtils.bankFolder):
			BankDir.change_dir(fileUtils.frackedFolder)
			BankDir.list_dir_begin(true, true)
			file_name = BankDir.get_next() 
	return list

#Function for selecting a new CloudCoin holding Directory and recreates the FileNameList
func ChangeCoinDirectory(NewDirectory):
	rootFolder = NewDirectory
	fileUtils.GetInstance(rootFolder)
	FileNameList = CreateFileNameList()

#Calculates the amount of each denomination of CloudCoin needed to get exact change for a certain Price,
# using the coins available locally, and returns an array that reads how many of each denomination is needed.
# If Less CloudCoins are available than the Price, or Exact Change can't be parsed then Element 5 of the array will be 1 otherwise it'll be 0
func ExactChange(Price):
	var Exact = [0, 0, 0, 0, 0, 0]
	var amount = Price
	var totals = fileUtils.CountCoins()
	if (amount >= 250 && totals[5] >0):
		Exact[4] = (amount / 250) if (amount / 250) < totals[5] else totals[5]
		amount -= (Exact[4] * 250)
	if (amount >= 100 && totals[4] > 0):
		Exact[3] = (amount / 100) if (amount /250 ) < totals[4] else totals[4]
		amount -= (Exact[3] * 100)
	if (amount >= 25 && totals[3] > 0):
		Exact[2] = (amount/25) if(amount/25) < totals[3] else totals[3]
		amount -= (Exact[2] * 25)
	if(amount >= 5 && totals[2] > 0):
		Exact[1] = (amount/ 5) if (amount / 5) < totals[2] else totals[2]
		amount -= (Exact[1] * 5)
	if(amount >= 1 && totals[1] > 0):
		Exact[0] = amount if amount < totals[1] else totals[1]
		amount -= Exact[0]
	if(amount > 0):
		Exact[5] += 1
	return Exact

#Returns the Total amount of CloudCoins held locally
func MaxCoins():
	var totals = fileUtils.CountCoins()
	return totals[0]

