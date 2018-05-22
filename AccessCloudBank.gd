extends Node

var keys
var bank
var loggedIn = false
export(String) var publicURL
export(String) var privateKey
export(String) var email
signal logged_in

func _ready():
	
	pass

#Creates an instance of Cloudbankutils using the current key settings,
# then uses the instance to connect to a cloudbank and run the show_coins service.
# This method needs to be called first before using any other method of this class.
func Login():
	keys = {"publickey":publicURL, "privatekey":privateKey, "email":email}
	bank = load("res://CloudCoinSDK/CloudBankUtils.tscn").instance()
	add_child(bank)
	emit_signal("logged_in")
	bank.ConnectToBank(keys)
	loggedIn = true
	bank.ShowCoins()

#Sends a cloudcoin the connected CloudBank, runs ShowCoins afterwards so ui elements that display those numbers may update
# returns false if you haven't run Login() yet
func Deposit(file_name):
	if loggedIn:
		bank.LoadStackFromFile(file_name)
		bank.SendStackToCloudBank()
		bank.ShowCoins()
		return true
	else:
		return false


#Sends and Authenticates CloudCoins for the purpose of paying for a in-game product/service.
#Will call the appropiate PurchaseSuccess or PurchaseFailure method of CloudCoinSDKStore depending on the result
func Pay(file_name, totalcoins, info):
	var store = get_node("../")
	if Deposit(file_name):
		bank.GetReceipt()
		var interp = bank.InterpretReceipt()
		if interp.has("error"):
			store.PurchaseFailure("BankServices receipt error, " + interp["error"])
		elif interp["totalAuthenticNotes"] < totalcoins:
			store.PurchaseFailure("Some coins came back counterfeit")
		else:
			store.PurchaseSuccess(info)
	else:
		store.PurchaseFailure("Not Logged into a CloudBank")

#Withdraws cloudcoins from the connected CloudBank, runs ShowCoins afterwards so ui elements that display those numbers may update
# returns false if you haven't run Login() yet
func Withdraw(amount):
	if loggedIn:
		bank.GetStackFromCloudBank(amount)
		var wallet = get_node("../CloudCoinSDKWallet")
		bank.SaveStackToFile(wallet.fileUtils.importFolder +"/")
		bank.ShowCoins()
		return true
	else:
		return false

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
