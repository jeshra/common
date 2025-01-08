### **Stored Procedure to Merge Approved Records into Original Tables**

To handle **INSERT**, **UPDATE**, and **DELETE** operations from the **stage table** into their respective original tables, we’ll create a stored procedure that:

1. **Reads all APPROVED records** from the stage table.  
2. Processes them based on the `operation_type` (**INSERT**, **UPDATE**, **DELETE**).  
3. Dynamically constructs and executes the appropriate SQL statement for each record.  
4. **Deletes processed records** from the stage table after successful merging.

---

## **1. Stored Procedure: Merge Approved Records**

```sql
CREATE OR REPLACE PROCEDURE SP_MERGE_APPROVED_RECORDS
AS
    CURSOR approved_records_cur IS
        SELECT row_id,
               table_name,
               operation_type,
               key1, value1, key2, value2, key3, value3, key4, value4,
               key5, value5, key6, value6, key7, value7, key8, value8,
               key9, value9, key10, value10, key11, value11, key12, value12,
               key13, value13, key14, value14, key15, value15, key16, value16,
               key17, value17, key18, value18, key19, value19, key20, value20,
               key21, value21, key22, value22, key23, value23, key24, value24,
               key25, value25
        FROM stage_table
        WHERE status = 'APPROVED';

    v_sql           VARCHAR2(4000);
    v_key           VARCHAR2(50);
    v_value         VARCHAR2(300);
    v_table_name    VARCHAR2(100);
    v_operation     VARCHAR2(50);
    v_set_clause    VARCHAR2(4000);
    v_where_clause  VARCHAR2(4000);
    v_insert_cols   VARCHAR2(4000);
    v_insert_vals   VARCHAR2(4000);
BEGIN
    FOR rec IN approved_records_cur LOOP
        v_table_name := rec.table_name;
        v_operation := rec.operation_type;

        -- Clear dynamic clauses
        v_set_clause := '';
        v_where_clause := '';
        v_insert_cols := '';
        v_insert_vals := '';

        -- Construct dynamic SQL based on operation_type
        CASE v_operation
            WHEN 'INSERT' THEN
                -- Build INSERT Statement
                FOR i IN 1..25 LOOP
                    EXIT WHEN rec['key' || i] IS NULL;
                    v_insert_cols := v_insert_cols || rec['key' || i] || ', ';
                    v_insert_vals := v_insert_vals || '''' || rec['value' || i] || ''', ';
                END LOOP;

                -- Remove trailing commas
                v_insert_cols := RTRIM(v_insert_cols, ', ');
                v_insert_vals := RTRIM(v_insert_vals, ', ');

                v_sql := 'INSERT INTO ' || v_table_name || ' (' || v_insert_cols || ') VALUES (' || v_insert_vals || ')';

            WHEN 'UPDATE' THEN
                -- Build UPDATE Statement
                FOR i IN 1..25 LOOP
                    EXIT WHEN rec['key' || i] IS NULL;
                    v_set_clause := v_set_clause || rec['key' || i] || ' = ''' || rec['value' || i] || ''', ';
                END LOOP;

                -- Remove trailing comma
                v_set_clause := RTRIM(v_set_clause, ', ');

                -- Assuming Key1 represents the primary key column for WHERE clause
                v_where_clause := rec.key1 || ' = ''' || rec.value1 || '''';

                v_sql := 'UPDATE ' || v_table_name || ' SET ' || v_set_clause || ' WHERE ' || v_where_clause;

            WHEN 'DELETE' THEN
                -- Build DELETE Statement
                -- Assuming Key1 represents the primary key column for WHERE clause
                v_where_clause := rec.key1 || ' = ''' || rec.value1 || '''';

                v_sql := 'DELETE FROM ' || v_table_name || ' WHERE ' || v_where_clause;
        END CASE;

        -- Execute the dynamically built SQL statement
        EXECUTE IMMEDIATE v_sql;

        -- After successful execution, remove the record from stage_table
        DELETE FROM stage_table WHERE row_id = rec.row_id;

        -- Commit after each successful operation
        COMMIT;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'Error in SP_MERGE_APPROVED_RECORDS: ' || SQLERRM);
END;
/
```

---

## **2. Explanation of the Procedure**

1. **Cursor for Approved Records:**  
   - Fetches all rows with `status = 'APPROVED'`.

2. **Dynamic SQL Construction:**  
   - For **INSERT:** Constructs column names and values dynamically.  
   - For **UPDATE:** Constructs a `SET` clause and a `WHERE` condition (using `Key1` as the primary key).  
   - For **DELETE:** Constructs a `WHERE` clause (using `Key1` as the primary key).

3. **SQL Execution:**  
   - The dynamically created SQL is executed using `EXECUTE IMMEDIATE`.

4. **Record Cleanup:**  
   - After successful execution, the row is deleted from the `stage_table`.

5. **Transaction Control:**  
   - Commits after each processed row.  
   - Rolls back in case of any error.

---

## **3. Example Data in Stage Table**

| row_id | table_name | operation_type | status   | key1       | value1 | key2       | value2 |
|--------|------------|---------------|---------|-----------|--------|-----------|--------|
| 1      | EMPLOYEES  | INSERT        | APPROVED | emp_id     | 101    | name       | John   |
| 2      | EMPLOYEES  | UPDATE        | APPROVED | emp_id     | 101    | salary     | 5000   |
| 3      | EMPLOYEES  | DELETE        | APPROVED | emp_id     | 102    |           |        |

### **Expected Result After Execution**
- **Row 1:** Inserted into `EMPLOYEES` table.
- **Row 2:** Updated `salary` column where `emp_id = 101`.
- **Row 3:** Deleted record where `emp_id = 102`.
- Corresponding rows removed from the `stage_table`.

---

## **4. Scheduled Job (Optional)**

You can schedule this procedure to run periodically using Oracle's **DBMS_SCHEDULER**.

```sql
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'job_merge_stage_table',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN SP_MERGE_APPROVED_RECORDS; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=5',
        enabled         => TRUE
    );
END;
/
```

- Runs every 5 minutes to process approved records.

---

## **5. Best Practices**
1. Validate keys and values before dynamic SQL execution.
2. Ensure proper indexing on frequently used columns (`status`, `table_name`, `key1`) in the stage table.
3. Handle schema changes carefully across tables.

---

Let me know if you encounter any issues or need enhancements!
