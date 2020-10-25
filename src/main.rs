use actix_web::{web, App, HttpResponse, HttpServer, Responder};

async fn welcome() -> impl Responder {
    HttpResponse::Ok().body("Welcome to Chadtech.us")
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .route("/", web::get().to(welcome))
    })
        .bind("127.0.0.1:8080")?
        .run()
        .await
}