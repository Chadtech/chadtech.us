use juniper::{FieldError, FieldResult, RootNode};

use crate::blogposts;
use crate::db::Pool;
use diesel::result::Error;
use diesel::RunQueryDsl;
use mysql::{params, Error as DBError, Row};

pub struct Context {
    pub db_pool: Pool,
}

impl juniper::Context for Context {}

pub struct Query;

#[juniper::object(Context = Context)]
impl Query {
    #[graphql(description = "List of all version 2 blog posts")]
    fn blogposts_v2(context: &Context) -> FieldResult<Vec<blogposts::v2::Post>> {
        Ok(Vec::new())
    }
}

pub struct Mutation;

#[juniper::object(Context = Context)]
impl Mutation {
    fn create_blogpost_v2(
        ctx: &Context,
        date: f64,
        title: String,
        content: String,
    ) -> juniper::FieldResult<blogposts::v2::Post> {
        use crate::schema::blogpostv2;
        let mut conn = ctx.db_pool.get().unwrap();

        let new_post = blogposts::v2::New {
            title: title.as_str(),
        };

        let insert_result = diesel::insert_into(blogpostv2::table)
            .values(&new_post)
            .get_result(&conn);

        match insert_result {
            Ok(new_blogpost) => Ok(new_blogpost),
            Err(err) => {
                let msg = err.to_string();
                Err(FieldError::new(
                    "Failed to create new user",
                    graphql_value!({ "internal_error": msg }),
                ))
            }
        }
        // .get_result(conn)
        // .expect("Error saving new post")
        // let mut conn = ctx.db_pool.get().unwrap();
        //
        // let new_id = 0;
        //
        // let insert : Result<Option<Row>, DBError>  = conn.first_exec(
        //     "INSERT INTO blostpostv2(id, date, title, content) VALUES(:id, :date, :title, :content)",
        //     params! {
        //         "id" => &new_id,
        //         "date" => &date,
        //         "title" => &title,
        //         "content" => &content
        //     }
        // );
        //
        // match insert {
        //     Ok(opt_row) => Ok(blogposts::v2::Post {
        //         id: new_id,
        //         // date,
        //         // title,
        //         // content,
        //     }),
        //     Err(err) => {
        //         let msg = match err {
        //             DBError::MySqlError(sql_err) => sql_err.message,
        //             _ => "internal error".to_owned(),
        //         };
        //         Err(FieldError::new(
        //             "Failed to create new user",
        //             graphql_value!({ "internal_error": msg }),
        //         ))
        //     }
        // }
    }
}

pub type Schema = RootNode<'static, Query, Mutation>;

pub fn create_schema() -> Schema {
    Schema::new(Query {}, Mutation {})
}
