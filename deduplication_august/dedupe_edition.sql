-- Use mapping table to dedupe editions
USE mpce1;

-- Disable the trigger to enable insert
DROP TRIGGER IF EXISTS increment_edition;

-- Get rid of empty strings in edition table
UPDATE edition
SET edition_status = NULL
WHERE edition_status = '';

UPDATE edition
SET edition_type = NULL
WHERE edition_type = '';

UPDATE edition
SET short_book_titles = NULL
WHERE short_book_titles = '';

UPDATE edition
SET translated_title = NULL
WHERE translated_title = '';

UPDATE edition
SET translated_language = NULL
WHERE translated_language = '';

UPDATE edition
SET languages = NULL
WHERE languages = '';

UPDATE edition
SET imprint_publishers = NULL
WHERE imprint_publishers = '';

UPDATE edition
SET actual_publishers = NULL
WHERE actual_publishers = '';

UPDATE edition
SET imprint_publication_places = NULL
WHERE imprint_publication_places = '';

UPDATE edition
SET actual_publication_places = NULL
WHERE actual_publication_places = '';

UPDATE edition
SET imprint_publication_years = NULL
WHERE imprint_publication_years = '';

UPDATE edition
SET actual_publication_years = NULL
WHERE actual_publication_years = '';

UPDATE edition
SET pages = NULL
WHERE pages = '';

UPDATE edition
SET quick_pages = NULL
WHERE quick_pages = '';

UPDATE edition
SET section = NULL
WHERE section = '';

UPDATE edition
SET book_sheets = NULL
WHERE book_sheets = '';

UPDATE edition
SET notes = NULL
WHERE notes = '';

UPDATE edition
SET research_notes = NULL
WHERE research_notes = '';

UPDATE edition
SET url = NULL
WHERE url = '';


-- Use insert to update values
INSERT INTO edition (
    edition_code, work_code, edition_status, edition_type,
    full_book_title, short_book_titles, translated_title,
    translated_language, languages, imprint_publishers,
    actual_publishers, imprint_publication_places, actual_publication_places,
    imprint_publication_years, actual_publication_years, pages,
    quick_pages, number_of_volumes, section, edition, book_sheets,
    known_pirated, notes, research_notes, url
)
SELECT
    id_1 AS edition_code, ed.work_code, ed.edition_status, ed.edition_type,
    full_book_title, ed.short_book_titles, ed.translated_title,
    translated_language, ed.languages, ed.imprint_publishers,
    actual_publishers, ed.imprint_publication_places, ed.actual_publication_places,
    imprint_publication_years, ed.actual_publication_years, ed.pages,
    quick_pages, ed.number_of_volumes, ed.section, ed.edition, ed.book_sheets,
    known_pirated, ed.notes, ed.research_notes, ed.url
FROM final_edition_mapping
    LEFT JOIN edition AS ed
        ON final_edition_mapping.id_2 = ed.edition_code
ON DUPLICATE KEY UPDATE
    edition_code = COALESCE(edition.edition_code, VALUES(edition_code)),
    work_code = COALESCE(edition.work_code, VALUES(work_code)), 
    edition_status = COALESCE(edition.edition_status, VALUES(edition_status)), 
    edition_type = COALESCE(edition.edition_type, VALUES(edition_type)),
    full_book_title = COALESCE(edition.full_book_title, VALUES(full_book_title)), 
    short_book_titles = CONCAT_WS("; ", edition.short_book_titles, VALUES(short_book_titles)), 
    translated_title = COALESCE(edition.translated_title, VALUES(translated_title)),
    translated_language = COALESCE(edition.translated_language, VALUES(translated_language)), 
    languages = COALESCE(edition.languages, VALUES(languages)), 
    imprint_publishers = COALESCE(edition.imprint_publishers, VALUES(imprint_publishers)),
    actual_publishers = COALESCE(edition.actual_publishers, VALUES(actual_publishers)), 
    imprint_publication_places = COALESCE(edition.imprint_publication_places, VALUES(imprint_publication_places)), 
    actual_publication_places = COALESCE(edition.actual_publication_places, VALUES(actual_publication_places)),
    imprint_publication_years = COALESCE(edition.imprint_publication_years, VALUES(imprint_publication_years)), 
    actual_publication_years = COALESCE(edition.actual_publication_years, VALUES(actual_publication_years)), 
    pages = COALESCE(edition.pages, VALUES(pages)),
    quick_pages = COALESCE(edition.quick_pages, VALUES(quick_pages)), 
    number_of_volumes = COALESCE(edition.number_of_volumes, VALUES(number_of_volumes)), 
    section = COALESCE(edition.section, VALUES(section)), 
    edition = COALESCE(edition.edition, VALUES(edition)), 
    book_sheets = COALESCE(edition.book_sheets, VALUES(book_sheets)),
    known_pirated = COALESCE(edition.known_pirated, VALUES(known_pirated)), 
    notes = CONCAT_WS("; ", edition.notes, VALUES(notes)), 
    research_notes = CONCAT_WS("; ", edition.research_notes, VALUES(research_notes)), 
    url = COALESCE(edition.url, VALUES(url));

-- Delete all merged editions (a record of them still exists in spreadsheet)
DELETE FROM edition
WHERE edition_code IN (SELECT id_2 FROM final_edition_mapping);

-- Redefine trigger
DELIMITER //
CREATE TRIGGER increment_edition
BEFORE INSERT ON edition FOR EACH ROW
BEGIN
    INSERT INTO _edition_id VALUES (NULL);
    SET NEW.edition_code = CONCAT("bk", LPAD(LAST_INSERT_ID(), 8, "0"));
END; //
DELIMITER ;

-- Update edition_codes across database

-- edition_author
UPDATE IGNORE edition_author, final_edition_mapping
SET edition_author.edition_code = final_edition_mapping.id_1
WHERE edition_author.edition_code = final_edition_mapping.id_2;

DELETE FROM edition_author
WHERE edition_author.edition_code IN (SELECT id_2 FROM final_edition_mapping);

-- confiscation
UPDATE confiscation, final_edition_mapping
SET confiscation.edition_code = final_edition_mapping.id_1
WHERE confiscation.edition_code = final_edition_mapping.id_2;

-- stamping
UPDATE stamping, final_edition_mapping
SET stamping.stamped_edition = final_edition_mapping.id_1
WHERE stamping.stamped_edition = final_edition_mapping.id_2;

-- bastille_register_record
UPDATE bastille_register_record, final_edition_mapping
SET bastille_register_record.edition_code = final_edition_mapping.id_1
WHERE bastille_register_record.edition_code = final_edition_mapping.id_2;

-- provincial_inspection
UPDATE provincial_inspection, final_edition_mapping
SET provincial_inspection.edition_code = final_edition_mapping.id_1
WHERE provincial_inspection.edition_code = final_edition_mapping.id_2;

-- permission_simple_grant
UPDATE permission_simple_grant, final_edition_mapping
SET permission_simple_grant.edition_code = final_edition_mapping.id_1
WHERE permission_simple_grant.edition_code = final_edition_mapping.id_2;

-- parisian_stock_sale
UPDATE parisian_stock_sale, final_edition_mapping
SET parisian_stock_sale.purchased_edition = final_edition_mapping.id_1
WHERE parisian_stock_sale.purchased_edition = final_edition_mapping.id_2;

-- stn_transaction
UPDATE stn_transaction, final_edition_mapping
SET stn_transaction.edition_code = final_edition_mapping.id_1
WHERE stn_transaction.edition_code = final_edition_mapping.id_2;

-- stn_darnton_sample_order
UPDATE stn_darnton_sample_order, final_edition_mapping
SET stn_darnton_sample_order.edition_code = final_edition_mapping.id_1
WHERE stn_darnton_sample_order.edition_code = final_edition_mapping.id_2;