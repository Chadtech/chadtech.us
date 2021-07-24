table! {
    analytics_event (id) {
        id -> Integer,
        name -> Varchar,
        zasedani_id -> Char,
        page_name -> Varchar,
        props_json -> Varchar,
        event_time -> Double,
    }
}

table! {
    blogpostv2 (id) {
        id -> Integer,
        title -> Varchar,
    }
}

allow_tables_to_appear_in_same_query!(
    analytics_event,
    blogpostv2,
);
