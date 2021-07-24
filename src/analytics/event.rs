use crate::schema::analytics_event;
use juniper::{GraphQLInputObject, GraphQLObject};

#[derive(Queryable, GraphQLObject)]
#[graphql(description = "An analytics event")]
pub struct Event {
    pub id: i32,
    pub event_time: f64,
    pub name: String,
    pub zasedani_id: String,
    pub page_name: String,
    pub props_json: String,
}

#[derive(Insertable)]
#[table_name = "analytics_event"]
pub struct Nova<'a> {
    pub id: i32,
    pub event_time: f64,
    pub name: &'a str,
    pub zasedani_id: &'a str,
    pub page_name: &'a str,
    pub props_json: &'a str,
}

#[derive(GraphQLInputObject)]
#[graphql(description = "An analytics event submission")]
pub struct NovaEvent {
    pub name: String,
    pub event_time: f64,
    pub zasedani_id: String,
    pub page_name: String,
    pub props_json: String,
}
