SELECT * FROM DB={{ .DB
                    | description "the database name"
                    | required "customer_id is required"
                    | type "text" }};