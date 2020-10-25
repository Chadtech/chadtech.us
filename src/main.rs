use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use std::env;
use std::process;

async fn welcome() -> impl Responder {
    HttpResponse::Ok().body("Welcome to Chadtech.us")
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let args: Vec<String> = env::args().collect();

    match args.get(1) {
        None => {
            eprintln!("You must provide an argument for Chadtechus, if you are developing locally try `cargo run dev`");
            process::exit(0x0100);
        }
        Some(arg) => {

            let ip_address = if arg == "dev" {
                "127.0.0.1:8080"
            } else {
                arg
            };

            HttpServer::new(|| {
                App::new()
                    .route("/", web::get().to(welcome))
            })
                .bind(ip_address)?
                .run()
                .await
        }
    }


}