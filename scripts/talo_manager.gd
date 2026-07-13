extends Node


const TALO_KEY: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjE5MTYsImFwaSI6dHJ1ZSwiaWF0IjoxNzgzNzY4MDkxfQ.XZMm4O34nIAS9x2zyLnBJbFs6YkcrEefsPubbDTqt7U"
const BASE_URL: String = "https://api.trytalo.com/v1"
const LEADERBOARD_NAME: String = "runner_global"

func submit_score_to_talo(player_name: String, score_value: int) -> void:
	var http = HTTPRequest.new()
	add_child(http)

	var identify_url = BASE_URL + "/players/identify?service=arcade&identifier=" + player_name.uri_encode()
	var headers = ["Authorization: Bearer " + TALO_KEY]

	print("📡 Talo: Identifying player session for '" + player_name + "'...")
	http.request(identify_url, headers, HTTPClient.METHOD_GET)

	var response = await http.request_completed
	var json = JSON.new()
	json.parse(response[3].get_string_from_utf8())
	var data = json.get_data()

	if response[1] != 200 or not data.has("alias"):
		print("❌ Talo Error: Handshake failed. HTTP Status: ", response[1])
		http.queue_free()
		return

	var alias_id = int(data["alias"]["id"])

	var submit_url = BASE_URL + "/leaderboards/" + LEADERBOARD_NAME + "/entries"
	var submit_headers = [
		"Authorization: Bearer " + TALO_KEY,
		"x-talo-alias: " + str(alias_id),
        "Content-Type: application/json"
	]


	var payload = {
		"score": score_value
	}

	print("📡 Talo: Submitting score of " + str(score_value) + " to leaderboard " + LEADERBOARD_NAME + "...")
	http.request(submit_url, submit_headers, HTTPClient.METHOD_POST, JSON.stringify(payload))

	var submit_response = await http.request_completed
	if submit_response[1] == 200 or submit_response[1] == 201:
		print("✅ Talo: High score successfully locked into the cloud architecture!")
	else:
		print("❌ Talo Error: Score submission rejected. Status: ", submit_response[1])

	http.queue_free()

func fetch_top_scores(board_name: String) -> Array:
	var http = HTTPRequest.new()
	add_child(http)

	var url = BASE_URL + "/leaderboards/" + board_name + "/entries"
	var headers = ["Authorization: Bearer " + TALO_KEY]

	http.request(url, headers, HTTPClient.METHOD_GET)
	var response = await http.request_completed

	var score_list = []
	if response[1] == 200:
		var json = JSON.new()
		json.parse(response[3].get_string_from_utf8())
		var data = json.get_data()

		if data.has("entries") and typeof(data["entries"]) == TYPE_ARRAY:
			var limit = min(data["entries"].size(), 10)
			for i in range(limit):
				var entry = data["entries"][i]
				var name_str = "GUEST"

				if entry.has("playerAlias") and entry["playerAlias"].has("identifier"):
					name_str = entry["playerAlias"]["identifier"]

				score_list.append({
					"player_name": name_str,
					"score": int(entry["score"])
				})

	http.queue_free()
	return score_list
