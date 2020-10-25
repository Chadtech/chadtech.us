use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use notify::{watcher, RecursiveMode, Watcher};
use std::env;
use std::process::Command;
use std::sync::mpsc::channel;
use std::thread;
use std::time::Duration;

async fn welcome() -> impl Responder {
    HttpResponse::Ok().body("Welcome to Chadtech.us")
}

#[derive(PartialEq)]
enum Deployment {
    Dev,
    Prod { ip_address: String },
}

fn watch_and_recompile_ui() {
    // Create a channel to receive the events.
    let (sender, receiver) = channel();

    // Create a watcher object, delivering debounced events.
    // The notification back-end is selected based on the platform.
    let mut watcher = watcher(sender, Duration::from_secs(10)).unwrap();

    // Add a path to be watched. All files and directories at that path and
    // below will be monitored for changes.
    watcher.watch("./ui/src", RecursiveMode::Recursive).unwrap();

    loop {
        match receiver.recv() {
            Ok(event) => {
                println!("{:?}", event);
                Command::new("elm")
                    .current_dir("./ui")
                    .args(&["make", "./src/Main.elm", "--output=./public/elm.js"])
                    .spawn()
                    .expect("elm failed to compile");
            }
            Err(e) => println!("watch error: {:?}", e),
        }
    }
}

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
