use crate::schema::analytics_event;
use juniper::meta::MetaType;
use juniper::{DefaultScalarValue, FromInputValue, GraphQLObject, GraphQLType, Registry};

#[derive(Queryable, GraphQLObject)]
#[graphql(description = "An analytics event")]
pub struct Event {
    pub id: i32,
    pub name: String,
    pub zasedani_id: String,
    pub page_name: String,
    pub props_json: String,
}

#[derive(Insertable)]
#[table_name = "analytics_event"]
pub struct New<'a> {
    pub id: i32,
    pub name: &'a str,
    pub zasedani_id: &'a str,
    pub page_name: &'a str,
    pub props_json: &'a str,
}

#[derive(FromInputValue, GraphQLType)]
pub struct NewSubmission {
    pub name: String,
    pub zasedani_id: String,
    pub page_name: String,
    pub props_json: String,
}

impl GraphQLType<DefaultScalarValue> for NewSubmission {
    fn name(_: &()) -> Option<&'static str> {
        Some("Analytics Event")
    }

    fn meta<'r>(_: &(), registry: &mut Registry<'r>) -> MetaType<'r>
    where
        DefaultScalarValue: 'r,
    {
        let fields = &[
            registry.field::<&String>("name", &()),
            registry.field::<&String>("zasedani_id", &()),
            registry.field::<&String>("page_name", &()),
            registry.field::<&String>("props_json", &()),
        ];

        registry
            .build_object_type::<NewSubmission>(&(), fields)
            .into_meta()
    }
}
