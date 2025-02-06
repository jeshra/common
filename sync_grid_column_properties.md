To automate the insertion and updating of column metadata (names, lengths, nullability, primary key order, data types) into the `grid_column_properties` table for tables listed in `table_master`, follow these steps:

---

### **1. Create the `grid_column_properties` Table**
Ensure the table has columns to store metadata (adjust as needed):
```sql
CREATE TABLE grid_column_properties (
    table_name      VARCHAR2(30) NOT NULL,
    column_name     VARCHAR2(30) NOT NULL,
    data_type       VARCHAR2(30),
    data_length     NUMBER,
    nullable        VARCHAR2(1),  -- 'Y' or 'N'
    primary_key_order NUMBER,     -- 0 if not a PK, else order in PK
    last_updated    TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_grid_col_props PRIMARY KEY (table_name, column_name)
);
```

---

### **2. Create a Stored Procedure to Sync Column Metadata**
This procedure will:
- Use Oracle's data dictionary views (`ALL_TAB_COLUMNS`, `ALL_CONSTRAINTS`, `ALL_CONS_COLUMNS`) to fetch metadata.
- Merge (insert/update) data into `grid_column_properties`.
- Delete columns that no longer exist.

```sql
CREATE OR REPLACE PROCEDURE sync_grid_column_properties AS
BEGIN
  -- Loop through all tables in table_master
  FOR tbl IN (SELECT table_name FROM table_master) LOOP
    -- Merge column metadata into grid_column_properties
    MERGE INTO grid_column_properties tgt
    USING (
      SELECT
        c.table_name,
        c.column_name,
        c.data_type,
        c.data_length,
        c.nullable,
        NVL(pk.column_position, 0) AS primary_key_order
      FROM all_tab_columns c
      LEFT JOIN (
        SELECT
          cc.table_name,
          cc.column_name,
          cc.position AS column_position
        FROM all_constraints pk_con
        JOIN all_cons_columns cc
          ON pk_con.constraint_name = cc.constraint_name
          AND pk_con.owner = cc.owner
        WHERE pk_con.constraint_type = 'P'
      ) pk ON c.table_name = pk.table_name AND c.column_name = pk.column_name
      WHERE c.table_name = tbl.table_name
    ) src
    ON (tgt.table_name = src.table_name AND tgt.column_name = src.column_name)
    WHEN MATCHED THEN
      UPDATE SET
        tgt.data_type = src.data_type,
        tgt.data_length = src.data_length,
        tgt.nullable = src.nullable,
        tgt.primary_key_order = src.primary_key_order,
        tgt.last_updated = SYSTIMESTAMP
    WHEN NOT MATCHED THEN
      INSERT (
        table_name, column_name, data_type, data_length,
        nullable, primary_key_order, last_updated
      )
      VALUES (
        src.table_name, src.column_name, src.data_type, src.data_length,
        src.nullable, src.primary_key_order, SYSTIMESTAMP
      );

    -- Delete columns that no longer exist in the table
    DELETE FROM grid_column_properties tgt
    WHERE tgt.table_name = tbl.table_name
      AND NOT EXISTS (
        SELECT 1
        FROM all_tab_columns src
        WHERE src.table_name = tgt.table_name
          AND src.column_name = tgt.column_name
      );

  END LOOP;
  COMMIT;
END sync_grid_column_properties;
/
```

---

### **3. Schedule Periodic Sync with DBMS_SCHEDULER**
Run the procedure daily/hourly to keep `grid_column_properties` updated:
```sql
BEGIN
  DBMS_SCHEDULER.create_job(
    job_name        => 'SYNC_GRID_COLUMNS_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN sync_grid_column_properties; END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=HOURLY; INTERVAL=1',  -- Adjust as needed
    enabled         => TRUE
  );
END;
/
```

---

### **4. (Optional) Automatically Capture DDL Changes with a Trigger**
Create a DDL trigger to detect schema changes and trigger the sync.  
**Note**: DDL triggers require careful handling (e.g., use autonomous transactions).

```sql
CREATE OR REPLACE TRIGGER sync_after_alter_table
AFTER ALTER ON DATABASE
DECLARE
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_table_name VARCHAR2(30);
BEGIN
  -- Check if the altered object is a table
  IF ora_dict_obj_type = 'TABLE' THEN
    v_table_name := ora_dict_obj_name;

    -- Check if the table is in table_master
    IF EXISTS (
      SELECT 1
      FROM table_master
      WHERE table_name = v_table_name
    ) THEN
      -- Sync metadata for this table
      sync_grid_column_properties;
      COMMIT;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/
```

---

### **Key Features**
1. **Automated Sync**: The procedure `sync_grid_column_properties` updates column metadata (inserts/updates/deletes) based on Oracle's data dictionary.
2. **Primary Key Handling**: Uses `ALL_CONSTRAINTS` and `ALL_CONS_COLUMNS` to determine primary key order.
3. **Scheduled Updates**: The job ensures periodic synchronization.
4. **DDL Trigger**: Optional real-time updates after `ALTER TABLE` statements.

---

### **Testing**
1. **Initial Sync**: Manually execute the procedure:
   ```sql
   EXEC sync_grid_column_properties;
   ```
2. **Verify Data**:
   ```sql
   SELECT * FROM grid_column_properties;
   ```
3. **Test Schema Changes**:
   - Alter a column in a table from `table_master`.
   - Verify `grid_column_properties` updates automatically (via trigger or job).

---

### **Notes**
- **Privileges**: Ensure the Oracle user has access to `ALL_TAB_COLUMNS`, `ALL_CONSTRAINTS`, and permissions to create jobs/triggers.
- **Performance**: For large schemas, optimize the procedure (e.g., bulk operations).
- **Error Handling**: Add logging or exceptions to the procedure for debugging.

This approach ensures your `grid_column_properties` table stays synchronized with the actual database schema.