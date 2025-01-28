CREATE OR REPLACE PROCEDURE PRTL_WC_STAGE_DUMP_SP (
    UPLOAD_ID IN NUMBER,
    TABLE_NAME IN VARCHAR2,
    JSON_DATA IN CLOB
) AS
    v_dynamic_sql  CLOB; -- To hold the dynamically constructed SQL
    v_columns      CLOB; -- Dynamically constructed column list
    v_values       CLOB; -- Dynamically constructed value list
    v_last_user    VARCHAR2(50); -- For LAST_UPDATED_BY_USER
    v_last_time    TIMESTAMP;    -- For LAST_UPDATED_BY_TIME
BEGIN
    -- Extract LAST_UPDATED_BY_USER and LAST_UPDATED_BY_TIME from the root JSON
    v_last_user := JSON_VALUE(JSON_DATA, '$.LAST_UPDATED_BY_USER' RETURNING VARCHAR2(50));
    v_last_time := JSON_VALUE(JSON_DATA, '$.LAST_UPDATED_BY_TIME' RETURNING TIMESTAMP);

    -- Process each row in the JSON
    FOR rec IN (
        SELECT
            jt.OPERATION_TYPE,
            jt.TOTAL_KEY_COLS,
            jt.KEY_VALUES
        FROM JSON_TABLE(
            JSON_DATA, '$.ROWS[*]'
            COLUMNS (
                OPERATION_TYPE VARCHAR2(10) PATH '$.OPERATION_TYPE',
                TOTAL_KEY_COLS NUMBER PATH '$.TOTAL_KEY_COLS',
                KEY_VALUES CLOB FORMAT JSON PATH '$.KEY_VALUES'
            )
        ) jt
    ) LOOP
        -- Initialize column and value lists for each row
        v_columns := 'UPLOAD_ID, TABLE_NAME, OPERATION_TYPE, TOTAL_KEY_COLS, LAST_UPDATED_BY_USER, LAST_UPDATED_BY_TIME';
        v_values := UPLOAD_ID || ', ' ||
                   '''' || TABLE_NAME || ''', ' ||
                   '''' || rec.OPERATION_TYPE || ''', ' ||
                   rec.TOTAL_KEY_COLS || ', ' ||
                   '''' || v_last_user || ''', ' ||
                   'TO_TIMESTAMP(''' || TO_CHAR(v_last_time, 'YYYY-MM-DD"T"HH24:MI:SS') || ''', ''YYYY-MM-DD"T"HH24:MI:SS'')';

DBMS_OUTPUT.PUT_LINE('LAST_UPDATED_BY_USER='||v_last_user);

        FOR keyval IN (
            SELECT
                ROW_NUMBER() OVER (order by NAME) AS rn,
                NAME,
                VALUE
            FROM JSON_TABLE(
                rec.KEY_VALUES, '$[*]'
                COLUMNS (
                    NAME  VARCHAR2(100) PATH '$.NAME',
                    VALUE VARCHAR2(1000) PATH '$.VALUE'
                )
            )
        ) LOOP
            v_columns := v_columns || ', NAME' || keyval.rn || ', VALUE' || keyval.rn;
            v_values := v_values || ', ' ||
                        '''' || keyval.NAME || ''', ''' || keyval.VALUE || '''';
        END LOOP;

        -- Construct and execute the dynamic INSERT statement
        v_dynamic_sql := 'INSERT INTO PRTL_WC_STAGE (' || v_columns || ') VALUES (' || v_values || ')';
        --EXECUTE IMMEDIATE v_dynamic_sql;
	dbms_output.put_line(v_dynamic_sql);
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END PRTL_WC_STAGE_DUMP_SP;
/

BEGIN
    PRTL_WC_STAGE_DUMP_SP(
        UPLOAD_ID => 1,
        TABLE_NAME => 'INSTRUMENT_TYPE',
        JSON_DATA => '{
    "UPLOAD_ID": 1,
    "TABLE_NAME": "INSTRUMENT_TYPE",
	"LAST_UPDATED_BY_USER": "JohnDoe",
    "LAST_UPDATED_BY_TIME": "2025-01-28T12:00:00",
    "ROWS": [
        {
            "OPERATION_TYPE": "INSERT",
            "TOTAL_KEY_COLS": 5,
            "KEY_VALUES": [
                {"NAME": "SRC_SYS_CD", "VALUE": "LONNA"},
                {"NAME": "INST_TYP_CD", "VALUE": "CHEQUE"},
                {"NAME": "INST_TYP_VAL", "VALUE": "3223"},
                {"NAME": "INST_LINK_CD", "VALUE": "HHM-JDS"},
                {"NAME": "INST_TYPE_DESC", "VALUE": "Special Type"}
            ]
        }, 
        {
            "OPERATION_TYPE": "INSERT",
            "TOTAL_KEY_COLS": 4,
            "KEY_VALUES": [
                {"NAME": "SRC_SYS_CD", "VALUE": "LONNA2"},
                {"NAME": "INST_TYP_CD", "VALUE": "CHEQUE2"},
                {"NAME": "INST_TYP_VAL", "VALUE": "32232"},
                {"NAME": "INST_LINK_CD", "VALUE": "HHM-JDS2"}
            ]
        }, 
        {
            "OPERATION_TYPE": "INSERT",
            "TOTAL_KEY_COLS": 3,
            "KEY_VALUES": [
                {"NAME": "SRC_SYS_CD", "VALUE": "LONNA1"},
                {"NAME": "INST_TYP_CD", "VALUE": "CHEQUE1"},
                {"NAME": "INST_TYP_VAL", "VALUE": "32231"}
            ]
        },
        {
            "OPERATION_TYPE": "UPDATE",
            "TOTAL_KEY_COLS": 4,
            "KEY_VALUES": [
                {"NAME": "SRC_SYS_CD", "VALUE": "LONNA5"},
                {"NAME": "INST_TYP_CD", "VALUE": "CHEQUE5"},
                {"NAME": "INST_TYP_VAL", "VALUE": "32235"},
                {"NAME": "INST_LINK_CD", "VALUE": "HHM-JDS5"}
            ]
        }
    ]
}'
    );
END;
/

BEGIN
    PRTL_WC_STAGE_DUMP_SP(
        UPLOAD_ID => 1,
        TABLE_NAME => 'INSTRUMENT_TYPE',
        JSON_DATA => '{
    "UPLOAD_ID": 1,
    "TABLE_NAME": "INSTRUMENT_TYPE",
	"LAST_UPDATED_BY_USER": "JohnDoe",
    "LAST_UPDATED_BY_TIME": "2025-01-28T12:00:00",
    "ROWS": [
        {
            "OPERATION_TYPE": "INSERT",
            "TOTAL_KEY_COLS": 5,
            "KEY_VALUES": [
                {"NAME": "SRC_SYS_CD", "VALUE": "LONNA"},
                {"NAME": "INST_TYP_CD", "VALUE": "CHEQUE"},
                {"NAME": "INST_TYP_VAL", "VALUE": "3223"},
                {"NAME": "INST_LINK_CD", "VALUE": "HHM-JDS"},
                {"NAME": "INST_TYPE_DESC", "VALUE": "Special Type"}
            ]
        }, 
        {
            "OPERATION_TYPE": "INSERT",
            "TOTAL_KEY_COLS": 4,
            "KEY_VALUES": [
                {"NAME": "SRC_SYS_CD", "VALUE": "LONNA2"},
                {"NAME": "INST_TYP_CD", "VALUE": "CHEQUE2"},
                {"NAME": "INST_TYP_VAL", "VALUE": "32232"},
                {"NAME": "INST_LINK_CD", "VALUE": "HHM-JDS2"}
            ]
        }, 
        {
            "OPERATION_TYPE": "INSERT",
            "TOTAL_KEY_COLS": 3,
            "KEY_VALUES": [
                {"NAME": "SRC_SYS_CD", "VALUE": "LONNA1"},
                {"NAME": "INST_TYP_CD", "VALUE": "CHEQUE1"},
                {"NAME": "INST_TYP_VAL", "VALUE": "32231"}
            ]
        },
        {
            "OPERATION_TYPE": "UPDATE",
            "TOTAL_KEY_COLS": 4,
            "KEY_VALUES": [
                {"NAME": "SRC_SYS_CD", "VALUE": "LONNA5"},
                {"NAME": "INST_TYP_CD", "VALUE": "CHEQUE5"},
                {"NAME": "INST_TYP_VAL", "VALUE": "32235"},
                {"NAME": "INST_LINK_CD", "VALUE": "HHM-JDS5"}
            ]
        }
    ]
}'
    );
END;
/
