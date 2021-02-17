use juniper::GraphQLObject;

#[derive(GraphQLObject)]
#[graphql(description = "A blog post, version 2")]
pub struct Post {
    pub id: i32,
    pub date: f64,
    pub title: String,
    pub content: String,
}
