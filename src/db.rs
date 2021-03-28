use diesel::mysql::MysqlConnection;
use diesel::r2d2::ConnectionManager;
// use r2d2_mysql::mysql::{Opts, OptsBuilder};
// use r2d2_mysql::MysqlConnectionManager;

// pub type Pool = r2d2::Pool<MysqlConnectionManager>;

pub type Pool = r2d2::Pool<ConnectionManager<MysqlConnection>>;

pub fn get_pool(db_url: String) -> Pool {
    // let opts = Opts::from_url(&db_url).unwrap();
    // let builder = OptsBuilder::from_opts(opts);
    // let manager = MysqlConnectionManager::new(builder);
    // r2d2::Pool::new(manager).expect("Failed to create DB Pool")

    // let manager = ConnectionManager::<MySqlConnection>::new(db_url);
    // let pool = r2d2::Pool::builder()
    //     .build(manager)
    //     .expect("Failed to create pool.");
    //
    // pool

    // MysqlConnection::establish(&db_url).unwrap_or_else(|_| panic!("Error connecting to {}", db_url))

    let manager = ConnectionManager::<MysqlConnection>::new(db_url);
    r2d2::Pool::builder()
        .build(manager)
        .expect("Failed to create pool")
}
