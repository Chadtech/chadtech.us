use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use notify::{raw_watcher, RecursiveMode, Watcher};
use std::env;
use std::process::Command;
use std::sync::mpsc::channel;
use std::thread;

#[derive(PartialEq)]
enum Deployment {
    Dev,
    Prod { ip_address: String },
}

////////////////////////////////////////////////////////////////////////////////
// MAIN //
////////////////////////////////////////////////////////////////////////////////

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let args: Vec<String> = env::args().collect();

    let mode = &match args.get(1) {
        None => Deployment::Dev,
        Some(ip_address) => Deployment::Prod {
            ip_address: ip_address.clone(),
        },
    };

    let ip_address = match mode {
        Deployment::Dev => "127.0.0.1:8080",
        Deployment::Prod { ip_address } => ip_address.as_str(),
    };

    compile_elm();
    compile_js();

    if mode == &Deployment::Dev {
        thread::spawn(move || {
            watch_and_recompile_ui();
        });
    }

    HttpServer::new(|| App::new().route("/", web::get().to(welcome)))
        .bind(ip_address)?
        .run()
        .await
}

////////////////////////////////////////////////////////////////////////////////
// ROUTES //
////////////////////////////////////////////////////////////////////////////////

async fn welcome() -> impl Responder {
    HttpResponse::Ok().body("Welcome to Chadtech.us")
}

////////////////////////////////////////////////////////////////////////////////
// COMPILATION //
////////////////////////////////////////////////////////////////////////////////

fn compile_elm() {
    Command::new("elm")
        .current_dir("./ui")
        .args(&["make", "./src/Main.elm", "--output=./public/elm.js"])
        .spawn()
        .expect("Elm failed to compile");
}

fn compile_js() {
    Command::new("cp")
        .args(&["./ui/src/app.js", "ui/public/app.js"])
        .spawn()
        .expect("Failed to move app.js into ./public");
}

////////////////////////////////////////////////////////////////////////////////
// DEV //
////////////////////////////////////////////////////////////////////////////////

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
