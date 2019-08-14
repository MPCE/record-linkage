-- Use mapping table to dedupe works
USE mpce1;

-- Disable the trigger to enable insert
DROP TRIGGER IF EXISTS increment_work;

-- Get rid of empty strings in work table
UPDATE work
SET illegality_notes = NULL
WHERE illegality_notes = '';

UPDATE work
SET categorisation_notes = NULL
WHERE categorisation_notes = '';

-- Use insert to update values
INSERT INTO work (
    work_code, work_title, parisian_keyword, illegality_notes,
    categorisation_fuzzy_value, categorisation_notes
)
SELECT
    id_1 AS work_code, wk.work_title, wk.parisian_keyword,
    wk.illegality_notes, wk.categorisation_fuzzy_value, 
    wk.categorisation_notes
FROM final_work_mapping
    LEFT JOIN work AS wk
        ON final_work_mapping.id_2 = wk.work_code
ON DUPLICATE KEY UPDATE
    work.work_title=COALESCE(work.work_title, VALUES(work_title)),
    work.parisian_keyword=COALESCE(work.parisian_keyword, VALUES(parisian_keyword)),
    work.illegality_notes=CONCAT_WS("; ", work.illegality_notes, VALUES(illegality_notes)),
    work.categorisation_fuzzy_value=COALESCE(work.categorisation_fuzzy_value, VALUES(categorisation_fuzzy_value)),
    work.categorisation_notes=CONCAT_WS("; ", work.categorisation_notes, VALUES(categorisation_notes));

-- Delete all merged works (a record of them still exists in spreadsheet)
DELETE FROM work
WHERE work_code IN (SELECT id_2 FROM final_work_mapping);

-- Redefine trigger
DELIMITER //
CREATE TRIGGER increment_work
BEFORE INSERT ON work FOR EACH ROW
BEGIN
    INSERT INTO _work_id VALUES (NULL);
    SET NEW.work_code = CONCAT("spbk", LPAD(LAST_INSERT_ID(), 8, "0"));
END; //
DELIMITER ;

-- Update work_codes across database

-- edition
UPDATE edition, final_work_mapping
SET edition.work_code = final_work_mapping.id_1
WHERE edition.work_code = final_work_mapping.id_2;

-- keyword assignments
UPDATE IGNORE work_keyword, final_work_mapping
SET work_keyword.work_code = final_work_mapping.id_1
WHERE work_keyword.work_code = final_work_mapping.id_2;

DELETE FROM work_keyword
WHERE work_code IN (SELECT id_2 FROM final_work_mapping);

-- banned books
UPDATE banned_list_record, final_work_mapping
SET banned_list_record.work_code = final_work_mapping.id_1
WHERE banned_list_record.work_code = final_work_mapping.id_2;

-- bastille books
UPDATE bastille_register_record, final_work_mapping
SET bastille_register_record.work_code = final_work_mapping.id_1
WHERE bastille_register_record.work_code = final_work_mapping.id_2;

-- condemnation
UPDATE condemnation, final_work_mapping
SET condemnation.work_code = final_work_mapping.id_1
WHERE condemnation.work_code = final_work_mapping.id_2;

-- provincial_inspection
UPDATE provincial_inspection, final_work_mapping
SET provincial_inspection.work_code = final_work_mapping.id_1
WHERE provincial_inspection.work_code = final_work_mapping.id_2;

-- stn transaction
UPDATE stn_transaction, final_work_mapping
SET stn_transaction.work_code = final_work_mapping.id_1
WHERE stn_transaction.work_code = final_work_mapping.id_2;

-- That should be it