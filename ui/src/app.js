var storageKey = "chadtechus__key";

function uuidv4() {
  return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
    (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
  );
}

function getStorage() {
    var storage = JSON.parse(localStorage.getItem(storageKey) || "{}");
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
        storage: getStorage(),
        id: uuidv4(),
        currentTime: (new Date()).getTime()
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
};

function jsMsgHandler(msg) {
	var action = actions[msg.type];
	if (typeof action === "undefined") {
		console.log("Unrecognized js msg type ->", msg.type);
		return;
	}
	action(msg.body);
}

app.ports.toJs.subscribe(jsMsgHandler)

