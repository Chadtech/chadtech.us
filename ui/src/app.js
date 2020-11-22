var storageKey = "chadtechus__key"

function getStorage() {
    var storage = JSON.parse(localStorage.getItem(storageKey) || "{})");
    return storage;
}

function setStorage(payload) {
    var storage = getStorage();

    storage[payload.key] = payload.value;

    localStorage.setItem(storageKey, JSON.stringify(storage));

    toElm("storage updated", getStorage());
}

var app = Elm.Main.init({
    flags: {
        storage: getStorage()
    }
});

function toElm(type, body) {
	app.ports.fromJs.send({
		type: type,
		body: body
	});
}

var actions = {
	setStorage: setStorage
}

function jsMsgHandler(msg) {
	var action = actions[msg.type];
	if (typeof action === "undefined") {
		console.log("Unrecognized js msg type ->", msg.type);
		return;
	}
	action(msg.body);
}

app.ports.toJs.subscribe(jsMsgHandler)

