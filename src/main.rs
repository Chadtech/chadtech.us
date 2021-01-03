mod flags;

use crate::flags::Flags;
use actix_web::{web, App, HttpResponse, HttpServer};
use notify::{raw_watcher, RecursiveMode, Watcher};
use std::fs;
use std::process::Command;
use std::sync::mpsc::channel;
use std::thread;

////////////////////////////////////////////////////////////////////////////////
// TYPES //
////////////////////////////////////////////////////////////////////////////////

#[derive(Clone)]
struct Model {
    pub ip_address: String,
    pub admin_password: String,
    pub port_number: u64,
    pub prod_model: Option<ProdModel>,
}

impl Model {
    fn init() -> Result<Model, String> {
        let flags = Flags::init()?;

        let maybe_prod_model: Option<ProdModel> = if flags.dev_mode {
            None
        } else {
            Some(ProdModel {
                elm_file: read_elm_file().map_err(|err| err.to_string()),
                js_file: read_js_file().map_err(|err| err.to_string()),
            })
        };

        Ok(Model {
            ip_address: flags.ip_address,
            admin_password: flags.admin_password,
            port_number: flags.port_number,
            prod_model: maybe_prod_model,
        })
    }
}

#[derive(Clone)]
struct ProdModel {
    elm_file: Result<String, String>,
    js_file: Result<String, String>,
}

////////////////////////////////////////////////////////////////////////////////
// MAIN //
////////////////////////////////////////////////////////////////////////////////

#[actix_web::main]
async fn main() -> Result<(), String> {
    let model = Model::init()?;

    let dev_mode = if let None = model.prod_model {
        true
    } else {
        false
    };

    write_frontend_api_code(&model).map_err(|err| err.to_string())?;
    compile_elm(dev_mode)?;
    compile_js(dev_mode)?;

    if dev_mode {
        thread::spawn(move || {
            watch_and_recompile_ui();
        });
    };

    let mut socket_address = String::new();

    if dev_mode {
        socket_address.push_str("localhost");
    } else {
        socket_address.push_str(model.ip_address.as_str());
    }

    socket_address.push_str(":");
    socket_address.push_str(model.port_number.to_string().as_str());

    HttpServer::new(move || {
        let model = model.clone();
        App::new()
            .data(model)
            .route("/elm.js", web::get().to(elm_asset_route))
            .route("/app.js", web::get().to(js_asset_route))
            // .service("/api/checkpassword", web::get().to(check_password))
            .default_service(web::get().to(frontend))
    })
    .bind(socket_address)
    .map_err(|err| err.to_string())?
    .run()
    .await
    .map_err(|err| err.to_string())
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
    match &model.get_ref().prod_model {
        None => match read_elm_file() {
            Ok(elm_file) => HttpResponse::Ok().body(elm_file),
            Err(error) => HttpResponse::InternalServerError().body(error.to_string()),
        },
        Some(prod_model) => match &prod_model.elm_file {
            Ok(file_str) => HttpResponse::Ok().body(file_str),
            Err(_) => HttpResponse::InternalServerError().body("elm file was missing"),
        },
    }
}

async fn js_asset_route(model: web::Data<Model>) -> HttpResponse {
    match &model.get_ref().prod_model {
        None => match read_js_file() {
            Ok(elm_file) => HttpResponse::Ok().body(elm_file),
            Err(error) => HttpResponse::InternalServerError().body(error.to_string()),
        },
        Some(prod_model) => match &prod_model.js_file {
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

// async fn check_password(data: web::Data<Model>) -> HttpResponse {
//     let mut counter = data.counter.lock().unwrap(); // <- get counter's MutexGuard
//     *counter += 1; // <- access counter inside MutexGuard
//     HttpResponse::Ok().body("hello")
// }

////////////////////////////////////////////////////////////////////////////////
// COMPILATION //
////////////////////////////////////////////////////////////////////////////////

fn write_frontend_api_code(model: &Model) -> std::io::Result<()> {
    let url = match &model.prod_model {
        None => {
            let mut buf = String::new();

            buf.push_str("localhost:");
            buf.push_str(model.port_number.to_string().as_str());

            buf
        }
        Some(_) => {
            let mut buf = String::new();

            buf.push_str(model.ip_address.as_str());
            buf.push(':');
            buf.push_str(model.port_number.to_string().as_str());

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

fn compile_elm(dev_mode: bool) -> Result<(), String> {
    if dev_mode {
        clear_terminal();

        Command::new("elm")
            .current_dir("./ui")
            .args(&["make", "./src/Main.elm", "--output=./public/elm.js"])
            .spawn()
            .map(|_| ())
            .map_err(|err| err.to_string())
    } else {
        let output_result = Command::new("elm")
            .current_dir("./ui")
            .args(&[
                "make",
                "./src/Main.elm",
                "--output=./public/elm.js",
                "--optimize",
            ])
            .output();

        match output_result {
            Ok(output) => {
                if output.status.success() {
                    Ok(())
                } else {
                    let mut buf = "failed to compiled Elm with status code : ".to_string();

                    buf.push_str(output.status.to_string().as_str());

                    Err(buf)
                }
            }
            Err(err) => Err(err.to_string()),
        }
    }
}

fn compile_js(dev_mode: bool) -> Result<(), String> {
    if dev_mode {
        clear_terminal();
    };

    Command::new("cp")
        .args(&[ui_src("app.js"), ui_public("app.js")])
        .spawn()
        .map(|_| ())
        .map_err(|err| err.to_string())
}

fn clear_terminal() {
    Command::new("clear")
        .spawn()
        .expect("Failed to clear terminal");
}

////////////////////////////////////////////////////////////////////////////////
// DEV //
////////////////////////////////////////////////////////////////////////////////

fn watch_and_recompile_ui() {
    let (sender, receiver) = channel();

    let mut watcher = raw_watcher(sender).unwrap();

    watcher.watch("./ui/src", RecursiveMode::Recursive).unwrap();

    loop {
        let result = match receiver.recv() {
            Ok(event) => match event.path {
                None => Ok(()),
                Some(filepath) => {
                    let file_extension = filepath.extension().and_then(|ext| ext.to_str());

                    match file_extension {
                        Some("elm") => compile_elm(true),
                        Some("js") => compile_js(true),
                        _ => Ok(()),
                    }
                }
            },
            Err(err) => Err(err.to_string()),
        };

        if let Err(err) = result {
            panic!(err);
        };

        ()
    }
}
