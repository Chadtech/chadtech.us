use actix_web::{web, App, HttpResponse, HttpServer};
use notify::{raw_watcher, RecursiveMode, Watcher};
use std::env;
use std::fs;
use std::process::Command;
use std::sync::mpsc::channel;
use std::thread;

////////////////////////////////////////////////////////////////////////////////
// TYPES //
////////////////////////////////////////////////////////////////////////////////

enum Model {
    Dev(DevModel),
    Prod(ProdModel),
}

impl Model {
    fn init() -> Model {
        let args: Vec<String> = env::args().collect();

        match args.get(1) {
            None => {
                let mut ip_address = String::new();

                ip_address.push_str("127.0.0.1");
                ip_address.push(':');
                ip_address.push_str(LOCAL_PORT.to_string().as_str());

                Model::Dev(DevModel { ip_address })
            }
            Some(ip_address) => Model::Prod(ProdModel {
                ip_address: ip_address.clone(),
                elm_file: read_elm_file().map_err(|err| err.to_string()),
                js_file: read_js_file().map_err(|err| err.to_string()),
            }),
        }
    }

    fn get_ip_address(self) -> String {
        match self {
            Model::Dev(dev_model) => dev_model.ip_address,
            Model::Prod(prod_model) => prod_model.ip_address,
        }
    }
}

struct DevModel {
    ip_address: String,
}

struct ProdModel {
    ip_address: String,
    elm_file: Result<String, String>,
    js_file: Result<String, String>,
}

////////////////////////////////////////////////////////////////////////////////
// MAIN //
////////////////////////////////////////////////////////////////////////////////

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let model = Model::init();

    write_frontend_api_code(&model)?;
    compile_elm();
    compile_js();

    if let Model::Dev(_) = model {
        thread::spawn(move || {
            watch_and_recompile_ui();
        });
    };

    HttpServer::new(|| {
        App::new()
            .data(Model::init())
            .route("/elm.js", web::get().to(elm_asset_route))
            .route("/app.js", web::get().to(js_asset_route))
            .default_service(web::get().to(frontend))
    })
    .bind(model.get_ip_address())?
    .run()
    .await
}

////////////////////////////////////////////////////////////////////////////////
// HELPER //
////////////////////////////////////////////////////////////////////////////////

fn ui_src(filename: &str) -> String {
    let mut buf = ui_dir("src/");
    buf.push_str(filename);
    buf
}

fn ui_public(filename: &str) -> String {
    let mut buf = ui_dir("public/");
    buf.push_str(filename);
    buf
}

fn ui_codegen(filename: &str) -> String {
    let mut buf = ui_dir("src/CodeGen/");
    buf.push_str(filename);
    buf
}

fn ui_dir(path: &str) -> String {
    let mut buf = String::new();
    buf.push_str("./ui/");
    buf.push_str(path);
    buf
}

fn read_elm_file() -> std::io::Result<String> {
    fs::read_to_string(ui_public("elm.js"))
}

fn read_js_file() -> std::io::Result<String> {
    fs::read_to_string(ui_public("app.js"))
}

////////////////////////////////////////////////////////////////////////////////
// ROUTES //
////////////////////////////////////////////////////////////////////////////////

async fn elm_asset_route(model: web::Data<Model>) -> HttpResponse {
    match model.get_ref() {
        Model::Dev(_) => match read_elm_file() {
            Ok(elm_file) => HttpResponse::Ok().body(elm_file),
            Err(error) => HttpResponse::InternalServerError().body(error.to_string()),
        },
        Model::Prod(prod_model) => match &prod_model.elm_file {
            Ok(file_str) => HttpResponse::Ok().body(file_str),
            Err(_) => HttpResponse::InternalServerError().body("elm file was missing"),
        },
    }
}

async fn js_asset_route(model: web::Data<Model>) -> HttpResponse {
    match model.get_ref() {
        Model::Dev(_) => match read_js_file() {
            Ok(elm_file) => HttpResponse::Ok().body(elm_file),
            Err(error) => HttpResponse::InternalServerError().body(error.to_string()),
        },
        Model::Prod(prod_model) => match &prod_model.js_file {
            Ok(file_str) => HttpResponse::Ok().body(file_str),
            Err(_) => HttpResponse::InternalServerError().body("elm file was missing"),
        },
    }
}

async fn frontend() -> HttpResponse {
    HttpResponse::Ok().body(
        r#"
<html>

<head>
  <script type="text/javascript" src="./elm.js"></script>
</head>

<body>
</body>
<script type="text/javascript" src="./app.js"></script>

</html>
        "#,
    )
}

////////////////////////////////////////////////////////////////////////////////
// COMPILATION //
////////////////////////////////////////////////////////////////////////////////

fn write_frontend_api_code(model: &Model) -> std::io::Result<()> {
    let url = match model {
        Model::Dev(_) => {
            let localhost_str = "localhost";

            let mut buf = String::new();

            buf.push_str(localhost_str);
            buf.push(':');
            buf.push_str(LOCAL_PORT.to_string().as_str());

            buf
        }
        Model::Prod(prod_model) => {
            let mut buf = String::new();

            buf.push_str(prod_model.ip_address.as_str());
            buf.push(':');
            buf.push_str(LOCAL_PORT.to_string().as_str());

            buf
        }
    };

    fs::write(
        ui_codegen("Api/Root.elm"),
        str::replace(
            r#"module CodeGen.Api.Root exposing 
    ( asString 
    )


---------------------------------------------------------------
-- API --
---------------------------------------------------------------


asString : String
asString =
    "${url}" 

"#,
            "${url}",
            url.as_str(),
        ),
    )
}

fn compile_elm() {
    clear_terminal();

    Command::new("elm")
        .current_dir("./ui")
        .args(&["make", "./src/Main.elm", "--output=./public/elm.js"])
        .spawn()
        .expect("Elm failed to compile");
}

fn compile_js() {
    clear_terminal();

    Command::new("cp")
        .args(&[ui_src("app.js"), ui_public("app.js")])
        .spawn()
        .expect("Failed to move app.js into ./public");
}

fn clear_terminal() {
    Command::new("clear")
        .spawn()
        .expect("Failed to clear terminal");
}

////////////////////////////////////////////////////////////////////////////////
// DEV //
////////////////////////////////////////////////////////////////////////////////

const LOCAL_PORT: i64 = 8080;

fn watch_and_recompile_ui() {
    let (sender, receiver) = channel();

    let mut watcher = raw_watcher(sender).unwrap();

    watcher.watch("./ui/src", RecursiveMode::Recursive).unwrap();

    loop {
        match receiver.recv() {
            Ok(event) => match event.path {
                None => {}
                Some(filepath) => {
                    let file_extension = filepath.extension().and_then(|ext| ext.to_str());

                    match file_extension {
                        Some("elm") => compile_elm(),
                        Some("js") => compile_js(),
                        _ => {}
                    }
                }
            },
            Err(e) => println!("watch error: {:?}", e),
        }
    }
}
