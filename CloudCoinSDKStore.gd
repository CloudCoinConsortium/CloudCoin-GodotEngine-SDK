extends Node

var access
var wallet

signal purchase_success
signal purchase_failure


func _ready():
	access = get_node("AccessCloudBank")
	wallet = get_node("CloudCoinSDKWallet")
	access.Login()
	pass

#Begins the process of making a purchase
#Param info should be a Dictionary with at least a "Price" key/value
func BeginPurchase(info):
	if !access.loggedIn:
		PurchaseFailure("Not Logged into CloudBank")
	elif wallet == null:
		PurchaseFailure("No Instance of Wallet Found")
	elif !info.has("Price"):
		PurchaseFailure("info Dictionary passed in doesn't have a Price")
	elif info["Price"] > wallet.MaxCoins():
		PurchaseFailure("Not Enough Funds")
	else:
		var ExactChange = wallet.ExactChange(info["Price"])
		var totalcoins = ExactChange[0] + ExactChange[1] + ExactChange[2] + ExactChange[3] + ExactChange[4]
		if ExactChange[5] == 1:
			PurchaseFailure("You do not have exact change for this purchase")
		wallet.fileUtils.WriteJsonFile(ExactChange[0], ExactChange[1], ExactChange[2], ExactChange[3], ExactChange[4], "PaymentToCloudBank")
		access.Pay(wallet.fileUtils.exportFolder + "/"+ String(info["Price"]) + ".CloudCoins.PaymentToCloudBank.stack", totalcoins, info)
	pass

#The callback that is called when a purchase has been successfull.
#Perfoms some cleanup of files, and emits a signal so that the appropriate product/service can be activated.
func PurchaseSuccess(info):
	wallet.fileUtils.Dir.remove(wallet.fileUtils.exportFolder + "/" + String(info["Price"]) + ".CloudCoins.PaymentToCloudBank.stack")
	emit_signal("purchase_success", info)
	pass

#The callback that is called when a purchase has not been successfull.
#Prints to console the reason the purchase failed, and emits a signal so that the appropriate response to a failed purchase can occur.
func PurchaseFailure(errorMessage = ""):
	print("Purchase Failed: " + errorMessage)
	emit_signal("purchase_failure", errorMessage)
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
