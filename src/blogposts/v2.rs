use juniper::{GraphQLEnum, GraphQLInputObject, GraphQLObject};

#[derive(GraphQLObject)]
#[graphql(description = "A blog post, version 2")]
pub struct Post {
    pub id: i32,
    pub date: u64,
    pub title: String,
    pub content: String,
}
