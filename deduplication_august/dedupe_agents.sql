-- Use mapping table to dedupe agents
USE mpce1;

-- Disable the trigger to enable insert
DROP TRIGGER IF EXISTS increment_agent;

-- Use insert to update values
INSERT INTO agent (
    agent_code, name, sex, title, other_names,
    designation, status, start_date, end_date, notes,
    cerl_id, corporate_entity
)
SELECT
    id_1 AS agent_code, ag.name, ag.sex, ag.title, ag.other_names,
    ag.designation, ag.status, ag.start_date, ag.end_date, ag.notes,
    ag.cerl_id, ag.corporate_entity
FROM final_agent_mapping
    LEFT JOIN agent AS ag
        ON final_agent_mapping.id_2 = ag.agent_code
ON DUPLICATE KEY UPDATE
    agent.name=COALESCE(agent.name, VALUES(name)),
    agent.sex=COALESCE(agent.sex, VALUES(sex)),
    agent.title=CONCAT_WS("; ", agent.title, VALUES(title)),
    agent.other_names=CONCAT_WS("; ", agent.other_names, VALUES(other_names)),
    agent.designation=CONCAT_WS("; ", agent.designation, VALUES(designation)),
    agent.status=COALESCE(agent.status, VALUES(status)),
    agent.start_date=COALESCE(agent.start_date, VALUES(start_date)),
    agent.end_date=COALESCE(agent.end_date, VALUES(end_date)),
    agent.notes=CONCAT_WS("; ", agent.notes, VALUES(notes)),
    agent.cerl_id=COALESCE(agent.cerl_id, VALUES(cerl_id)),
    agent.corporate_entity=COALESCE(agent.corporate_entity, VALUES(corporate_entity));

-- Delete all merged agents (a record of them still exists in spreadsheet)
DELETE FROM agent
WHERE agent_code IN (SELECT id_2 FROM final_agent_mapping);

-- Redefine trigger
DELIMITER //
CREATE TRIGGER increment_agent
BEFORE INSERT ON agent FOR EACH ROW
BEGIN
    INSERT INTO _agent_id VALUES (NULL);
    SET NEW.agent_code = CONCAT("id", LPAD(LAST_INSERT_ID(), 6, "0"));
END; //
DELIMITER ;

-- Update agent codes across database

-- is_member_of (beware unique index)
UPDATE IGNORE is_member_of, final_agent_mapping
SET is_member_of.member = final_agent_mapping.id_1
WHERE is_member_of.member = final_agent_mapping.id_2;

UPDATE IGNORE is_member_of, final_agent_mapping
SET is_member_of.corporate_entity = final_agent_mapping.id_1
WHERE is_member_of.corporate_entity = final_agent_mapping.id_2;

DELETE FROM is_member_of
WHERE member IN (SELECT id_2 FROM final_agent_mapping);
DELETE FROM is_member_of
WHERE corporate_entity IN (SELECT id_2 FROM final_agent_mapping);

-- stn_client_agent
UPDATE IGNORE stn_client_agent, final_agent_mapping
SET stn_client_agent.agent_code = final_agent_mapping.id_1
WHERE stn_client_agent.agent_code = final_agent_mapping.id_2;

DELETE FROM stn_client_agent
WHERE agent_code IN (SELECT id_2 FROM final_agent_mapping);

-- agent_profession (beware unique index)
UPDATE IGNORE agent_profession, final_agent_mapping
SET agent_profession.agent_code = final_agent_mapping.id_1
WHERE agent_profession.agent_code = final_agent_mapping.id_2;

DELETE FROM agent_profession
WHERE agent_code IN (SELECT id_2 FROM final_agent_mapping);

-- edition_author (beware unique index)
UPDATE IGNORE edition_author, final_agent_mapping
SET edition_author.author = final_agent_mapping.id_1
WHERE edition_author.author = final_agent_mapping.id_2;

DELETE FROM edition_author
WHERE author IN (SELECT id_2 FROM final_agent_mapping);

-- agent_address
UPDATE agent_address, final_agent_mapping
SET agent_address.agent_code = final_agent_mapping.id_1
WHERE agent_address.agent_code = final_agent_mapping.id_2;

-- consignment
UPDATE consignment, final_agent_mapping
SET consignment.other_stakeholder = final_agent_mapping.id_1
WHERE consignment.other_stakeholder = final_agent_mapping.id_2;

UPDATE consignment, final_agent_mapping
SET consignment.returned_to_agent = final_agent_mapping.id_1
WHERE consignment.returned_to_agent = final_agent_mapping.id_2;

-- consignment_addressee (there should be no trouble with the index)
UPDATE consignment_addressee, final_agent_mapping
SET consignment_addressee.agent_code = final_agent_mapping.id_1
WHERE consignment_addressee.agent_code = final_agent_mapping.id_2;

-- consignment_signatory (there should be no trouble with the index)
UPDATE consignment_signatory, final_agent_mapping
SET consignment_signatory.agent_code = final_agent_mapping.id_1
WHERE consignment_signatory.agent_code = final_agent_mapping.id_2;

-- consignment_handling_agent (there should be no trouble with the index)
UPDATE consignment_handling_agent, final_agent_mapping
SET consignment_handling_agent.agent_code = final_agent_mapping.id_1
WHERE consignment_handling_agent.agent_code = final_agent_mapping.id_2;

-- confiscation
UPDATE confiscation, final_agent_mapping
SET confiscation.censor = final_agent_mapping.id_1
WHERE confiscation.censor = final_agent_mapping.id_2;

UPDATE confiscation, final_agent_mapping
SET confiscation.signatory = final_agent_mapping.id_1
WHERE confiscation.signatory = final_agent_mapping.id_2;

UPDATE confiscation, final_agent_mapping
SET confiscation.signatory_signed_on_behalf_of = final_agent_mapping.id_1
WHERE confiscation.signatory_signed_on_behalf_of = final_agent_mapping.id_2;

-- stamping
UPDATE stamping, final_agent_mapping
SET stamping.attending_inspector = final_agent_mapping.id_1
WHERE stamping.attending_inspector = final_agent_mapping.id_2;

UPDATE stamping, final_agent_mapping
SET stamping.attending_adjoint = final_agent_mapping.id_1
WHERE stamping.attending_adjoint = final_agent_mapping.id_2;

-- condemnation has no agent_codes, just an empty column waiting

-- permission_simple_grant
UPDATE permission_simple_grant, final_agent_mapping
SET permission_simple_grant.licensee = final_agent_mapping.id_1
WHERE permission_simple_grant.licensee = final_agent_mapping.id_2;

-- parisian_stock_auction
UPDATE parisian_stock_auction, final_agent_mapping
SET parisian_stock_auction.previous_owner = final_agent_mapping.id_1
WHERE parisian_stock_auction.previous_owner = final_agent_mapping.id_2;

-- auction_administrator
UPDATE auction_administrator, final_agent_mapping
SET auction_administrator.administrator_id = final_agent_mapping.id_1
WHERE auction_administrator.administrator_id = final_agent_mapping.id_2;

-- parisian_stock_sale
UPDATE parisian_stock_sale, final_agent_mapping
SET parisian_stock_sale.purchaser = final_agent_mapping.id_1
WHERE parisian_stock_sale.purchaser = final_agent_mapping.id_2;

-- That should be all the tables.

