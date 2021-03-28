use crate::schema::blogpostv2;
use juniper::GraphQLObject;

#[derive(Queryable, GraphQLObject)]
#[graphql(description = "A blog post, version 2")]
pub struct Post {
    pub id: i32,
    // pub date: f64,
    pub title: String,
    // pub content: String,
}

#[derive(Insertable)]
#[table_name = "blogpostv2"]
pub struct New<'a> {
    pub title: &'a str,
}
