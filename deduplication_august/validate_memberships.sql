SELECT
    imo.member,
    imo.corporate_entity AS entity,
    m.name AS member_name,
    m.corporate_entity AS member_type,
    e.name AS entity_name,
    e.corporate_entity AS entity_type
INTO OUTFILE 'false_memberships.csv'
    CHARACTER SET `latin1`
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
    LINES TERMINATED BY '\n'
FROM
    is_member_of AS imo
    LEFT JOIN agent AS m
        ON imo.member = m.agent_code
    LEFT JOIN agent AS e
        ON imo.corporate_entity = e.agent_code
WHERE
    m.corporate_entity != 0 OR
    e.corporate_entity != 1

-- Executed, and output sent to SB 7/8/2019