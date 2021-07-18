#[macro_use]
extern crate juniper;
#[macro_use]
extern crate diesel;
extern crate r2d2;
extern crate r2d2_mysql;
extern crate serde_json;

use crate::db::Pool;
use crate::flags::Flags;
use crate::graphql_schema::{create_schema, Schema};
use actix_web::middleware::Logger;
use actix_web::{middleware, web, App, HttpResponse, HttpServer};
use juniper::http::graphiql::graphiql_source;
use juniper::http::GraphQLRequest;
use notify::{raw_watcher, RecursiveMode, Watcher};
use std::fs;
use std::process::Command;
use std::sync::mpsc::channel;
use std::thread;

mod blogposts;
mod db;
mod flags;
mod graphql_schema;
mod schema;

////////////////////////////////////////////////////////////////////////////////
// TYPES //
////////////////////////////////////////////////////////////////////////////////

#[derive(Clone)]
struct Modelka {
    pub ip_address: String,
    pub admin_password: String,
    pub port_number: u64,
    pub okoli: Okoli,
}

impl Modelka {
    fn poca() -> Result<Modelka, String> {
        let flags = Flags::poca()?;

        let okoli: Okoli = if flags.dev_mode {
            Okoli::Dev(DevModelka {
                show_elm_output: flags.show_elm_output,
            })
        } else {
            Okoli::Prod(ProdModelka {
                elm_file: read_elm_file().map_err(|err| err.to_string()),
                js_file: read_js_file().map_err(|err| err.to_string()),
            })
        };

        Ok(Modelka {
            ip_address: flags.ip_address,
            admin_password: flags.admin_password,
            port_number: flags.port_number,
            okoli,
        })
    }
}

#[derive(Clone)]
enum Okoli {
    Prod(ProdModelka),
    Dev(DevModelka),
}

impl Okoli {
    pub fn is_dev(&self) -> bool {
        match self {
            Okoli::Dev(_) => true,
            _ => false,
        }
    }
}

#[derive(Clone)]
struct DevModelka {
    show_elm_output: bool,
}

#[derive(Clone)]
struct ProdModelka {
    elm_file: Result<String, String>,
    js_file: Result<String, String>,
}

////////////////////////////////////////////////////////////////////////////////
// MAIN //
////////////////////////////////////////////////////////////////////////////////

#[actix_web::main]
async fn main() -> Result<(), String> {
    let pool = db::get_pool("mysql://root:password@localhost/chadtechus".to_string());

    let modelka = Modelka::poca()?;

    let dev_mode = modelka.okoli.is_dev();

    write_frontend_api_code(&modelka).map_err(|err| err.to_string())?;
    compile_elm(&modelka.okoli)?;
    compile_js(dev_mode)?;

    if dev_mode {
        let okoli = modelka.okoli.clone();
        thread::spawn(move || {
            watch_and_recompile_ui(&okoli);
        });
    };

    let socket_address = {
        let mut buf = String::new();

        if dev_mode {
            buf.push_str("localhost");
        } else {
            buf.push_str(modelka.ip_address.as_str());
        }

        buf.push(':');
        buf.push_str(modelka.port_number.to_string().as_str());

        buf
    };

    // Create Juniper schema

    let web_modelka = actix_web::web::Data::new(modelka.clone());

    let schema = create_schema();
    let web_schema = actix_web::web::Data::new(schema);

    // env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    std::env::set_var("RUST_LOG", "actix_web=info");
    env_logger::init();
    println!("8");
    HttpServer::new(move || {
        App::new()
            .wrap(Logger::default())
            .wrap(Logger::new("%a %{User-Agent}i"))
            .data(pool.clone())
            .app_data(web_schema.clone())
            .app_data(web_modelka.clone())
            .route("/elm.js", web::get().to(elm_asset_route))
            .route("/app.js", web::get().to(js_asset_route))
            .route("/graphql", web::post().to(graphql))
            .route("/graphiql", web::get().to(graphiql))
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

async fn graphiql() -> HttpResponse {
    let html = graphiql_source("http://127.0.0.1:8080/graphql");
    HttpResponse::Ok()
        .content_type("text/html; charset=utf-8")
        .body(html)
}

async fn graphql(
    pool: web::Data<Pool>,
    schema: web::Data<Schema>,
    req: web::Json<GraphQLRequest>,
) -> Result<HttpResponse, actix_web::Error> {
    let ktx = graphql_schema::Kontext {
        db_pool: pool.get_ref().to_owned(),
    };

    println!("9");
    let user = web::block(move || {
        println!("A");
        let res = req.execute(&schema, &ktx);

        let graphql_res_str = serde_json::to_string(&res)?;

        println!("{}", &graphql_res_str);
        Ok::<_, serde_json::error::Error>(graphql_res_str)
    })
    .await
    .map_err(actix_web::Error::from)?;

    Ok(HttpResponse::Ok()
        .content_type("application/json")
        .body(user))
}

async fn elm_asset_route(model: web::Data<Modelka>) -> HttpResponse {
    match &model.get_ref().okoli {
        Okoli::Dev(_) => match read_elm_file() {
            Ok(elm_file) => HttpResponse::Ok().body(elm_file),
            Err(error) => HttpResponse::InternalServerError().body(error.to_string()),
        },
        Okoli::Prod(prod_model) => match &prod_model.elm_file {
            Ok(file_str) => HttpResponse::Ok().body(file_str),
            Err(_) => HttpResponse::InternalServerError().body("elm file was missing"),
        },
    }
}

async fn js_asset_route(model: web::Data<Modelka>) -> HttpResponse {
    match &model.get_ref().okoli {
        Okoli::Dev(_) => match read_js_file() {
            Ok(elm_file) => HttpResponse::Ok().body(elm_file),
            Err(error) => HttpResponse::InternalServerError().body(error.to_string()),
        },
        Okoli::Prod(prod_model) => match &prod_model.js_file {
            Ok(file_str) => HttpResponse::Ok().body(file_str),
            Err(_) => HttpResponse::InternalServerError().body("elm file was missing"),
        },
    }
}

async fn frontend() -> HttpResponse {
    HttpResponse::Ok().body(include_str!("./assets/index.html"))
}

////////////////////////////////////////////////////////////////////////////////
// COMPILATION //
////////////////////////////////////////////////////////////////////////////////

fn write_frontend_api_code(model: &Modelka) -> std::io::Result<()> {
    let url = match &model.okoli {
        Okoli::Dev(_) => {
            let mut buf = String::new();

            buf.push_str("localhost:");
            buf.push_str(model.port_number.to_string().as_str());

            buf
        }
        Okoli::Prod(_) => {
            let mut buf = String::new();

            buf.push_str(model.ip_address.as_str());
            buf.push(':');
            buf.push_str(model.port_number.to_string().as_str());

            buf
        }
    };

    fs::write(
        ui_codegen("Api/Root.elm"),
        str::replace(include_str!("./assets/ApiRoot.elm"), "${url}", url.as_str()),
    )
}

fn compile_elm(okoli: &Okoli) -> Result<(), String> {
    match okoli {
        Okoli::Dev(dev_modelka) => {
            if dev_modelka.show_elm_output {
                clear_terminal();

                Command::new("elm")
                    .current_dir("./ui")
                    .args(&["make", "./src/Main.elm", "--output=./public/elm.js"])
                    .spawn()
                    .map(|_| ())
                    .map_err(|err| err.to_string())
            } else {
                Command::new("elm")
                    .current_dir("./ui")
                    .args(&["make", "./src/Main.elm", "--output=./public/elm.js"])
                    .output()
                    .map(|_| ())
                    .map_err(|err| err.to_string())
            }
        }
        Okoli::Prod(_) => {
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

fn watch_and_recompile_ui(okoli: &Okoli) {
    let (sender, receiver) = channel();

    let mut watcher = raw_watcher(sender).unwrap();

    watcher.watch("./ui/src", RecursiveMode::Recursive).unwrap();

    loop {
        let result: Result<(), String> = match receiver.recv() {
            Ok(event) => match event.path {
                None => Ok(()),
                Some(filepath) => {
                    let file_extension = filepath.extension().and_then(|ext| ext.to_str());

                    match file_extension {
                        Some("elm") => compile_elm(okoli),
                        Some("js") => compile_js(true),
                        _ => Ok(()),
                    }
                }
            },
            Err(err) => Err(err.to_string()),
        };

        if let Err(err) = result {
            panic!("{}", err);
        };
    }
}
