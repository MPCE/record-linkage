USE mpce1;
CREATE TEMPORARY TABLE works_to_update (work_code CHAR(12), new_illegality TEXT);
INSERT INTO works_to_update VALUES
('spbk00014899', '0 (0) Darnton'),('spbk00014966', '0 (0) Darnton'),('spbk00014986', '0 (0) Darnton'),('spbk00015000', '0 (0) Darnton'),('spbk00014957', '0 (0) Darnton'),('spbk00014829', '0 (0) Darnton'),('spbk00014987', '0 (0) Darnton'),('spbk00014830', '0 (0) Darnton'),('spbk00014968', '0 (0) Darnton'),('spbk00014831', '0 (0) Darnton'),('spbk00014832', '0 (0) Darnton'),('spbk00014967', '0 (0) Darnton'),('spbk00014900', '0 (0) Darnton'),('spbk00014833', '0 (0) Darnton'),('spbk00014834', '0 (0) Darnton'),('spbk00014979', '0 (0) Darnton'),('spbk00014990', '0 (0) Darnton'),('spbk00014835', '0 (0) Darnton'),('spbk00014836', '0 (0) Darnton'),('spbk00014837', '0 (0) Darnton'),('spbk00014828', '0 (0) Darnton'),('spbk00014838', '0 (0) Darnton'),('spbk00014839', '0 (0) Darnton'),('spbk00014850', '0 (0) Darnton'),('spbk00014861', '0 (0) Darnton'),('spbk00014872', '0 (0) Darnton'),('spbk00014883', '0 (0) Darnton'),('spbk00014840', '0 (0) Darnton'),('spbk00014894', '0 (0) Darnton'),('spbk00014947', '0 (0) Darnton'),('spbk00014841', '0 (0) Darnton'),('spbk00014913', '0 (0) Darnton'),('spbk00014969', '0 (0) Darnton'),('spbk00014971', '0 (0) Darnton'),('spbk00014970', '0 (0) Darnton'),('spbk00014948', '0 (0) Darnton'),('spbk00014972', '0 (0) Darnton'),('spbk00014995', '0 (0) Darnton'),('spbk00014842', '0 (0) Darnton'),('spbk00014973', '0 (0) Darnton'),('spbk00014843', '0 (0) Darnton'),('spbk00014844', '0 (0) Darnton'),('spbk00014901', '0 (0) Darnton'),('spbk00014902', '0 (0) Darnton'),('spbk00014905', '0 (0) Darnton'),('spbk00014988', '0 (0) Darnton'),('spbk00014845', '0 (0) Darnton'),('spbk00014974', '0 (0) Darnton'),('spbk00014911', '0 (0) Darnton'),('spbk00014846', '0 (0) Darnton'),('spbk00014847', '0 (0) Darnton'),('spbk00014898', '0 (0) Darnton'),('spbk00014912', '0 (0) Darnton'),('spbk00014848', '0 (0) Darnton'),('spbk00014949', '0 (0) Darnton'),('spbk00014950', '0 (0) Darnton'),('spbk00014951', '0 (0) Darnton'),('spbk00014849', '0 (0) Darnton'),('spbk00014952', '0 (0) Darnton'),('spbk00014851', '0 (0) Darnton'),('spbk00014914', '0 (0) Darnton'),('spbk00014953', '0 (0) Darnton'),('spbk00014852', '0 (0) Darnton'),('spbk00014954', '0 (0) Darnton'),('spbk00014989', '0 (0) Darnton'),('spbk00014853', '0 (0) Darnton'),('spbk00014854', '0 (0) Darnton'),('spbk00014955', '0 (0) Darnton'),('spbk00014915', '0 (0) Darnton'),('spbk00014956', '0 (0) Darnton'),('spbk00014916', '0 (0) Darnton'),('spbk00014958', '0 (0) Darnton'),('spbk00014999', '0 (0) Darnton'),('spbk00014917', '0 (0) Darnton'),('spbk00014855', '0 (0) Darnton'),('spbk00014918', '0 (0) Darnton'),('spbk00014856', '0 (0) Darnton'),('spbk00014857', '0 (0) Darnton'),('spbk00014975', '0 (0) Darnton'),('spbk00014903', '0 (0) Darnton'),('spbk00014959', '0 (0) Darnton'),('spbk00014858', '0 (0) Darnton'),('spbk00014859', '0 (0) Darnton'),('spbk00014976', '0 (0) Darnton'),('spbk00014860', '0 (0) Darnton'),('spbk00014919', '0 (0) Darnton'),('spbk00014991', '0 (0) Darnton'),('spbk00014862', '0 (0) Darnton'),('spbk00014921', '0 (0) Darnton'),('spbk00014920', '0 (0) Darnton'),('spbk00014863', '0 (0) Darnton'),('spbk00014864', '0 (0) Darnton'),('spbk00014904', '0 (0) Darnton'),('spbk00014865', '0 (0) Darnton'),('spbk00014977', '0 (0) Darnton'),('spbk00014866', '0 (0) Darnton'),('spbk00014923', '0 (0) Darnton'),('spbk00014922', '0 (0) Darnton'),('spbk00014906', '0 (0) Darnton'),('spbk00014996', '0 (0) Darnton'),('spbk00014867', '0 (0) Darnton'),('spbk00014925', '0 (0) Darnton'),('spbk00014926', '0 (0) Darnton'),('spbk00014927', '0 (0) Darnton'),('spbk00014907', '0 (0) Darnton'),('spbk00014960', '0 (0) Darnton'),('spbk00014868', '0 (0) Darnton'),('spbk00014946', '0 (0) Darnton'),('spbk00014869', '0 (0) Darnton'),('spbk00014997', '0 (0) Darnton'),('spbk00014908', '0 (0) Darnton'),('spbk00014928', '0 (0) Darnton'),('spbk00014930', '0 (0) Darnton'),('spbk00014870', '0 (0) Darnton'),('spbk00014978', '0 (0) Darnton'),('spbk00014871', '0 (0) Darnton'),('spbk00014929', '0 (0) Darnton'),('spbk00014909', '0 (0) Darnton'),('spbk00014924', '0 (0) Darnton'),('spbk00014931', '0 (0) Darnton'),('spbk00014873', '0 (0) Darnton'),('spbk00014961', '0 (0) Darnton'),('spbk00014874', '0 (0) Darnton'),('spbk00014875', '0 (0) Darnton'),('spbk00014932', '0 (0) Darnton'),('spbk00014992', '0 (0) Darnton'),('spbk00014980', '0 (0) Darnton'),('spbk00014876', '0 (0) Darnton'),('spbk00014933', '0 (0) Darnton'),('spbk00014962', '0 (0) Darnton'),('spbk00014981', '0 (0) Darnton'),('spbk00014877', '0 (0) Darnton'),('spbk00014934', '0 (0) Darnton'),('spbk00014935', '0 (0) Darnton'),('spbk00014998', '0 (0) Darnton'),('spbk00014982', '0 (0) Darnton'),('spbk00014936', '0 (0) Darnton'),('spbk00014937', '0 (0) Darnton'),('spbk00014983', '0 (0) Darnton'),('spbk00014878', '0 (0) Darnton'),('spbk00014938', '0 (0) Darnton'),('spbk00014879', '0 (0) Darnton'),('spbk00014880', '0 (0) Darnton'),('spbk00014963', '0 (0) Darnton'),('spbk00014984', '0 (0) Darnton'),('spbk00014964', '0 (0) Darnton'),('spbk00014881', '0 (0) Darnton'),('spbk00014939', '0 (0) Darnton'),('spbk00014993', '0 (0) Darnton'),('spbk00014910', '0 (0) Darnton'),('spbk00014882', '0 (0) Darnton'),('spbk00014884', '0 (0) Darnton'),('spbk00014885', '0 (0) Darnton'),('spbk00014886', '0 (0) Darnton'),('spbk00014994', '0 (0) Darnton'),('spbk00014940', '0 (0) Darnton'),('spbk00014887', '0 (0) Darnton'),('spbk00014888', '0 (0) Darnton'),('spbk00014889', '0 (0) Darnton'),('spbk00014941', '0 (0) Darnton'),('spbk00014827', '0 (0) Darnton'),('spbk00014890', '0 (0) Darnton'),('spbk00014891', '0 (0) Darnton'),('spbk00014892', '0 (0) Darnton'),('spbk00014965', '0 (0) Darnton'),('spbk00014942', '0 (0) Darnton'),('spbk00014943', '0 (0) Darnton'),('spbk00014944', '0 (0) Darnton'),('spbk00014893', '0 (0) Darnton'),('spbk00014985', '0 (0) Darnton'),('spbk00014895', '0 (0) Darnton'),('spbk00014896', '0 (0) Darnton'),('spbk00014897', '0 (0) Darnton'),('spbk00014945', '0 (0) Darnton');
UPDATE work, works_to_update
SET illegality_notes = new_illegality
WHERE work.work_code = works_to_update.work_code;