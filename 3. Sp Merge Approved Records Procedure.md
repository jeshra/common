Yes, there is a more dynamic and efficient way to handle this without explicitly checking each column (e.g., `ELSIF i = 1`, `ELSIF i = 2`, etc.). Instead, you can use **dynamic PL/SQL** with an array to iterate over the column values programmatically. Here’s how:

---

### **Alternative Approach with an Array**
Instead of writing multiple `ELSIF` blocks, store the `key` and `value` pairs in a **PL/SQL associative array (index-by table)**. Then, loop through the array dynamically to construct the SQL.

---

### **Updated Procedure**
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

    TYPE key_value_array IS TABLE OF VARCHAR2(300) INDEX BY PLS_INTEGER;

    keys    key_value_array;
    values  key_value_array;

    v_sql           VARCHAR2(4000);
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

        -- Populate keys and values into the arrays
        keys(1) := rec.key1;   values(1) := rec.value1;
        keys(2) := rec.key2;   values(2) := rec.value2;
        keys(3) := rec.key3;   values(3) := rec.value3;
        keys(4) := rec.key4;   values(4) := rec.value4;
        keys(5) := rec.key5;   values(5) := rec.value5;
        -- Repeat up to key25, value25
        keys(25) := rec.key25; values(25) := rec.value25;

        -- Construct dynamic SQL based on operation_type
        CASE v_operation
            WHEN 'INSERT' THEN
                FOR i IN 1..25 LOOP
                    IF keys(i) IS NOT NULL THEN
                        v_insert_cols := v_insert_cols || keys(i) || ', ';
                        v_insert_vals := v_insert_vals || '''' || values(i) || ''', ';
                    END IF;
                END LOOP;

                -- Remove trailing commas
                v_insert_cols := RTRIM(v_insert_cols, ', ');
                v_insert_vals := RTRIM(v_insert_vals, ', ');

                v_sql := 'INSERT INTO ' || v_table_name || ' (' || v_insert_cols || ') VALUES (' || v_insert_vals || ')';

            WHEN 'UPDATE' THEN
                FOR i IN 1..25 LOOP
                    IF keys(i) IS NOT NULL THEN
                        v_set_clause := v_set_clause || keys(i) || ' = ''' || values(i) || ''', ';
                    END IF;
                END LOOP;

                -- Remove trailing comma
                v_set_clause := RTRIM(v_set_clause, ', ');

                -- Assuming Key1 represents the primary key column for WHERE clause
                v_where_clause := keys(1) || ' = ''' || values(1) || '''';

                v_sql := 'UPDATE ' || v_table_name || ' SET ' || v_set_clause || ' WHERE ' || v_where_clause;

            WHEN 'DELETE' THEN
                -- Assuming Key1 represents the primary key column for WHERE clause
                v_where_clause := keys(1) || ' = ''' || values(1) || '''';

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

### **Key Improvements**
1. **Dynamic Iteration:**
   - Uses associative arrays (`keys` and `values`) to store `key1` to `key25` and `value1` to `value25`.
   - Loops through the array indices dynamically without hardcoding column checks.

2. **Simplified Code:**
   - Eliminates the need for `ELSIF` statements for every column.

3. **Flexibility:**
   - Supports future changes (e.g., increasing the number of key-value pairs) with minimal adjustments.

---

### **Testing**
#### **Input Data in `stage_table`**
| row_id | table_name | operation_type | status   | key1    | value1 | key2     | value2 | key3 | value3 |
|--------|------------|----------------|----------|---------|--------|----------|--------|------|--------|
| 1      | EMPLOYEES  | INSERT         | APPROVED | emp_id  | 101    | name     | John   | NULL | NULL   |
| 2      | EMPLOYEES  | UPDATE         | APPROVED | emp_id  | 101    | salary   | 5000   | NULL | NULL   |
| 3      | EMPLOYEES  | DELETE         | APPROVED | emp_id  | 102    | NULL     | NULL   | NULL | NULL   |

#### **Expected Results**
- Row 1: Inserts into `EMPLOYEES (emp_id, name) VALUES (101, 'John')`.
- Row 2: Updates `EMPLOYEES` with `SET salary = 5000 WHERE emp_id = 101`.
- Row 3: Deletes from `EMPLOYEES WHERE emp_id = 102`.

---

### **Advantages**
- Compact, maintainable code.
- Easy to handle changes (e.g., adding more key-value pairs).

Let me know if you have additional questions or need further customization!
