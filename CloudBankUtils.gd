extends HTTPRequest

var http
var keys
var rawStackForDeposit
var rawStackFromWithdrawal
var rawReceipt
var receiptNumber
var totalCoinsWithdrawn = 0
var onesInBank = 0
var fivesInBank = 0
var twentyFivesInBank = 0
var hundredsInBank = 0
var twohundredfiftiesInBank = 0
signal called_show_coins

func _ready():
	pass

#Creates an httpclient and connects to a CloudBank server using the provided Dictionary of keys
func ConnectToBank(p_keys):
	keys = p_keys
	http = HTTPClient.new()
	http.connect_to_host(keys["publickey"], 443, true, false)
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print("connecting to bank..")
		OS.delay_msec(300)
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

#Uses HTTP POST to call the CloudBank's show_coins service. Saves the results in this class's member variables
func ShowCoins():
	var json = "error"
	var formFields = {"pk": keys.privatekey}
	var formContent = http.query_string_from_dict(formFields)
	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(formContent.length())]
	var result = http.request(http.METHOD_POST, "/show_coins.aspx", headers, formContent)
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		print("requesting show coins..")
		OS.delay_msec(300)
	if http.has_response():
		var responseBytes = PoolByteArray()
		while http.get_status() == HTTPClient.STATUS_BODY:
			http.poll()
			print("processing show coins..")
			responseBytes = responseBytes + http.read_response_body_chunk()
		json = responseBytes.get_string_from_ascii()
		if json.find("error") > -1:
			print(json)
		else:
			var bankTotals = JSON.parse(json)
			onesInBank = bankTotals.result["ones"]
			fivesInBank = bankTotals.result["fives"]
			twentyFivesInBank = bankTotals.result["twentyfives"]
			hundredsInBank = bankTotals.result["hundreds"]
			twohundredfiftiesInBank = bankTotals.result["twohundredfifties"]
	else:
		print("httpclient status:" + String(http.get_status()))
	emit_signal("called_show_coins")

#Reads a CloudCoin stack file and saves it into member variable rawStackForDeposit ready to be sent to a CloudBank
func LoadStackFromFile(file_name):
	var file = File.new()
	if(file.file_exists(file_name)):
		file.open(file_name, File.READ)
		rawStackForDeposit = file.get_as_text()
		file.close()
	else:
		print("file not found at:" + filename)

#Uses HTTP POST to send the CloudCoin stack that is saved in member variable rawStackInDeposit to the CloudBank
#When the response is read the ID for the receipt created by the CloudBank when receiving CloudCoins is saved in member variable receiptNumber
func SendStackToCloudBank():
	var CloudBankFeedback
	var formFields = {"stack":rawStackForDeposit}
	var formContent = http.query_string_from_dict(formFields)
	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(formContent.length()), "User-Agent: Pirulo/1.0 (Godot)"]
	var result = http.request(http.METHOD_POST, "/deposit_one_stack.aspx", headers, formContent)
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
        http.poll()
        OS.delay_msec(300)
	if http.has_response():
		var responseBytes = PoolByteArray()
		while http.get_status() == HTTPClient.STATUS_BODY:
			http.poll()
			responseBytes = responseBytes + http.read_response_body_chunk()
		CloudBankFeedback = responseBytes.get_string_from_ascii()
		var j = JSON.parse(CloudBankFeedback)
		if typeof(j.result) == TYPE_DICTIONARY:
			receiptNumber = j.result["receipt"]
		else:
			print("CloudServices error: " + CloudBankFeedback)
	else:
		print("httpclient status:" + String(http.get_status()))

#Uses HTTP GET to read the receipt from the last deposit to the CloudBank done by this class.
#Needs the receiptNumber that is collected by SendStackToCloudBank()
#The entire receipt is saved in member variable rawReceipt
func GetReceipt():
	var headers = ["User-Agent: Pirulo/1.0 (Godot)"]
	var result = http.request(http.METHOD_GET,"/"+ keys.privatekey + "/Receipts/" + receiptNumber + ".json", headers)
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
        http.poll()
        OS.delay_msec(300)
	if http.has_response():
		var responseBytes = PoolByteArray()
		while http.get_status() == HTTPClient.STATUS_BODY:
			http.poll()
			responseBytes = responseBytes + http.read_response_body_chunk()
		rawReceipt = responseBytes.get_string_from_ascii()
	else:
		print("httpclient status:" + http.get_status())

#Uses HTTP POST to withdraw a certain amount of CloudCoins from the CloudBank.
#The response will be a CloudCoin stack that will be saved into the member variable rawStackFromWithdrawal
func GetStackFromCloudBank(amountToWithdraw):
	var totalCoinsWithdrawn = amountToWithdraw
	var formFields = {"pk": keys.privatekey, "amount": totalCoinsWithdrawn}
	var formContent = http.query_string_from_dict(formFields)
	var headers = ["Content-Type: application/x-www-form-urlencoded", "Content-Length: " + str(formContent.length())]
	var result = http.request(http.METHOD_POST, "/withdraw_account.aspx", headers, formContent)
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
        http.poll()
        OS.delay_msec(300)
	if http.has_response():
		var responseBytes = PoolByteArray()
		while http.get_status() == HTTPClient.STATUS_BODY:
			http.poll()
			responseBytes = responseBytes + http.read_response_body_chunk()
		rawStackFromWithdrawal = responseBytes.get_string_from_ascii()
		var j = JSON.parse(rawStackFromWithdrawal)
		if rawStackFromWithdrawal.find("status") > -1:
			print(j.result["status"] + ", " + j.result["message"])
		elif typeof(j.result) != TYPE_DICTIONARY :
			print("CloudServices error: " + rawStackFromWithdrawal)
	else:
		print("httpclient status:" + http.get_status())

#A helper function for calculating a CloudCoin's denomination by looking at its serial number(sn)
func GetDenomination(sn):
	var nom = 0
	if sn < 1:
		nom = 0
	elif sn < 2097153:
		nom = 1
	elif sn < 4194305:
		nom = 5
	elif sn < 6291457:
		nom = 25
	elif sn < 14680065:
		nom = 100
	elif sn < 167772117:
		nom = 250
	else:
		nom = 0
	return nom

#Reads the receipt held in member variable rawReceipt and returns a Dictionary containing pertinent information
#Said Dictionary's contents: "receipt": a JSONParseResult containing the entire receipt,
#"totalAuthenticCoins": how many total CloudCoins of the last deposit where determined to be authentic,
#"totalAuthenticNotes": how many CloudCoin Notes compose the CloudCoins that were determined to be authentic
func InterpretReceipt():
	var json = JSON.parse(rawReceipt)
	if typeof(json.result) != TYPE_DICTIONARY:
		var error = {"error": rawReceipt}
		return error
	var totalNotes = json.result["total_authentic"] + json.result["total_fracked"]
	var totalCoins = 0
	for detail in json.result["receipt"]:
		if detail["status"] == "authentic":
			totalCoins = totalCoins + GetDenomination(detail["sn"]) 
	var interpretation = {"receipt": json, "totalAuthenticCoins": totalCoins, "totalAuthenticNotes": totalNotes}
	return interpretation

#Helper function that returns a possible filename for a CloudCoin that was recently withdrawn.
func GetStackName():
	var tag
	if receiptNumber == null:
		tag = "NewWithdrawal"
	else:
		tag = String(receiptNumber)
	return String(totalCoinsWithdrawn) + ".CloudCoin." + tag + ".stack"

#Saves the CloudCoin stack that is in member variable rawStackFromWithdrawal into a cloudcoin .stack file.
#Param path should be the full filepath and filename of the file being created.
func SaveStackToFile(path):
	var file = File.new()
	file.open(path + GetStackName(), File.WRITE)
	file.store_string(rawStackFromWithdrawal)
	file.close()





