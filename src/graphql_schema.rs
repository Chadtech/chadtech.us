use juniper::{FieldError, FieldResult, RootNode};

use crate::analytics;
use crate::blogposts;
use crate::db::Pool;
use diesel::RunQueryDsl;
use rand::Rng;

pub struct Kontext {
    pub db_pool: Pool,
}

impl juniper::Context for Kontext {}

pub struct Query;

#[juniper::object(Context = Kontext)]
impl Query {
    #[graphql(description = "List of all version 2 blog posts")]
    fn blogposts_v2(ktx: &Kontext) -> FieldResult<Vec<blogposts::v2::Post>> {
        use crate::schema::blogpostv2::dsl::*;
        let conn = ktx.db_pool.get()?;
        let query_results = blogpostv2
            .load::<blogposts::v2::Post>(&conn)
            .expect("Error querying posts");

        Ok(query_results)
    }
}

pub struct Mutation;

#[juniper::object(Context = Kontext)]
impl Mutation {
    fn api_version() -> &str {
        "0.0.0"
    }
    fn record_analytics(
        ktx: &Kontext,
        events: Vec<analytics::event::NovaEvent>,
    ) -> juniper::FieldResult<&str> {
        use crate::schema::analytics_event;
        let conn = ktx.db_pool.get()?;

        let mut nova_events = Vec::new();
        let mut rng = rand::thread_rng();

        for event in events.iter() {
            let id: i32 = rng.gen();
            let nova_event = analytics::event::Nova {
                id,
                name: event.name.as_str(),
                zasedani_id: event.zasedani_id.as_str(),
                page_name: event.page_name.as_str(),
                props_json: event.props_json.as_str(),
            };

            nova_events.push(nova_event);
        }

        let insert_result = diesel::insert_into(analytics_event::table)
            .values(&nova_events)
            .execute(&conn);

        match insert_result {
            Ok(_) => Ok("Success"),
            Err(err) => {
                let msg = err.to_string();
                Err(FieldError::new(
                    "Failed to record analytics events",
                    graphql_value!({ "internal_error": msg }),
                ))
            }
        }
    }

    fn create_blogpost_v2(
        ktx: &Kontext,
        date: f64,
        title: String,
        content: String,
    ) -> juniper::FieldResult<blogposts::v2::Post> {
        use crate::schema::blogpostv2;
        use diesel::sql_types::BigInt;
        let conn = ktx.db_pool.get()?;

        #[derive(QueryableByName)]
        struct CountQuery {
            #[sql_type = "BigInt"]
            count: i64,
        }

        let count_query = diesel::sql_query(r#"SELECT COUNT(*) AS count FROM blogpostv2;"#)
            .load::<CountQuery>(&conn)
            .expect("Query failed")
            .pop()
            .expect("No Count Query");

        let new_post = blogposts::v2::New {
            id: count_query.count as i32,
            title: title.as_str(),
        };

        let insert_result = diesel::insert_into(blogpostv2::table)
            .values(&new_post)
            .execute(&conn);

        match insert_result {
            Ok(n) => {
                if n == 1 {
                    // TODO re-query post
                    Ok(blogposts::v2::Post {
                        id: new_post.id,
                        title: new_post.title.to_string(),
                    })
                } else {
                    let mut buf = String::new();

                    buf.push_str("Inserted ");
                    buf.push_str(n.to_string().as_str());
                    buf.push_str(" rows");

                    Err(FieldError::new(
                        "Failed to create new user",
                        graphql_value!({ "internal_error": buf }),
                    ))
                }
            }
            Err(err) => {
                let msg = err.to_string();
                Err(FieldError::new(
                    "Failed to create new user",
                    graphql_value!({ "internal_error": msg }),
                ))
            }
        }
    }
}

pub type Schema = RootNode<'static, Query, Mutation>;

pub fn create_schema() -> Schema {
    Schema::new(Query {}, Mutation {})
}
