use juniper::{FieldResult, RootNode};

use crate::blogposts;
use tokio_postgres::Client;

pub struct Context {
    pub client: Client,
}

impl juniper::Context for Context {}

pub struct Query;

#[juniper::object(Context = Context)]
impl Query {
    #[graphql(description = "List of all version 2 blog posts")]
    fn blogposts_v2(context: &Context) -> FieldResult<Vec<blogposts::v2::Post>> {
        Ok(Vec::new())
    }
    // #[graphql(description = "List of all users")]
    // fn users(context: &Context) -> FieldResult<Vec<User>> {
    //     let mut conn = context.dbpool.get().unwrap();
    //     let users = conn
    //         .prep_exec("select * from user", ())
    //         .map(|result| {
    //             result
    //                 .map(|x| x.unwrap())
    //                 .map(|mut row| {
    //                     let (id, name, email) = from_row(row);
    //                     User { id, name, email }
    //                 })
    //                 .collect()
    //         })
    //         .unwrap();
    //     Ok(users)
    // }
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
        let id = 0;

        ctx.client.execute(
            "INSERT INTO blogpostv2 (id, date, title, content) VALUES ($1, $2, $3, $4)",
            &[&id, &date, &title, &content],
        );

        Ok(blogposts::v2::Post {
            id: 0,
            date,
            title,
            content,
        })
    }
}

// let id = uuid::Uuid::new_v4();
// let email = email.to_lowercase();
// ctx.client
// .execute(
// "INSERT INTO customers (id, name, age, email, address) VALUES ($1, $2, $3, $4, $5)",
// &[&id, &name, &age, &email, &address],
// )
// .await?;
// Ok(Customer {
// id: id.to_string(),
// name,
// age,
// email,
// address,
// })

// #[juniper::graphql_object(Context = Context)]
// impl MutationRoot {
//     async fn register_customer(
//         ctx: &Context,
//         name: String,
//         age: i32,
//         email: String,
//         address: String,
//     ) -> juniper::FieldResult<Customer> {
//         Ok(Customer {
//             id: "1".into(),
//             name,
//             age,
//             email,
//             address,
//         })
//     }
pub type Schema = RootNode<'static, Query, Mutation>;

pub fn create_schema() -> Schema {
    Schema::new(Query {}, Mutation {})
}
