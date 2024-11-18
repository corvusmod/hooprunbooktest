SELECT customerid, firstname, lastname
FROM customers
WHERE customerid = {{ .customer_id
                    | description "the id of the customer"
                    | required "customer_id is required"
                    | type "number"
                    | squote }}