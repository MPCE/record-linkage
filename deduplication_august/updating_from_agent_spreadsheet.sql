UPDATE agent AS a, agent_temp AS t
SET
    a.name = t.name,
    a.sex = t.sex,
    a.title = t.title,
    a.other_names = t.other_names,
    a.designation = t.designation,
    a.status = t.status,
    a.start_date = t.start_date,
    a.end_date = t.end_date,
    a.notes = t.notes,
    a.cerl_id = t.cerl_id,
    a.corporate_entity = t.corporate_entity
WHERE a.agent_code = t.agent_code;

-- Executed 7/8/19 -- success