--  Using any type of the joins create a view that combines multiple tables in a logical way
-- Join to show patients and health conditions they have suffered in their lives: conditions, allergies, medications,
-- procedures
USE hospital;
CREATE VIEW medical_history AS
SELECT 
    patients.P_ID,
    conditions.description AS condition_description,
    allergies.description AS allergy_description,
    medications.reason_description AS medication_description,
    procedures.REASON AS procedure_reason
FROM
    patients
LEFT JOIN conditions ON 
    patients.P_ID = conditions.P_ID
LEFT JOIN allergies ON 
    patients.P_ID = allergies.P_ID
LEFT JOIN medications ON 
    patients.P_ID = medications.P_ID
LEFT JOIN procedures ON 
    patients.P_ID = procedures.P_ID;

SELECT * FROM medical_history;
-- stored function find the patient spent on procedure
DELIMITER //

CREATE FUNCTION personal_healthcare_cost(Healthcare_expenses INT, healthcare_coverage INT)
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE patient_cost INT;
    IF healthcare_coverage IS NOT NULL
        THEN
    SET patient_cost = healthcare_expenses - healthcare_coverage;
    END IF;
    
    RETURN patient_cost;

END //
DELIMITER ;



-- call function for every patient 

SELECT P_ID, last_name, personal_healthcare_cost(Healthcare_expenses, healthcare_coverage) AS patient_cost
FROM patients;


-- query:list patients who spent more than 50000 on there health
SELECT P_ID, first_name, last_name, healthcare_expenses
FROM Patients
WHERE P_ID IN (
    SELECT P_ID
    FROM Patients
    WHERE healthcare_expenses > 50000
);


-- 	 create a stored procedure and demonstrate how it runs
-- All patients by a specific race to understand patient demographics

DELIMITER //

CREATE PROCEDURE PatientsByRace(
    IN raceName VARCHAR(20)
)
BEGIN
    SELECT *
    FROM patients
    WHERE race = raceName;
END //

DELIMITER ;

CALL PatientsByRace('black');
CALL PatientsByRace('white');
CALL PatientsByRace('asian');

USE hospital;
-- create an trigger and demonstrate how it runs (when event happens do something) this trigger adds a new patient data across every table

DELIMITER //

CREATE TRIGGER after_patient_insert
AFTER INSERT ON patients
FOR EACH ROW
BEGIN
    INSERT INTO observations (P_ID, description)
    VALUES (NEW.P_ID, 'New patient added');
END //

DELIMITER ;

-- how the trigger works:

INSERT INTO patients (P_ID, first_name, last_name, race, birth_date)
VALUES ('85G2F', 'Jane', 'Doe', 'white', '1989-01-01');


-- Demonstrate again this:
INSERT INTO patients (P_ID, first_name, last_name, race, birth_date)
VALUES ('89HJ9', 'Gabby', 'Douglas', 'black', '1995-31-12');

SHOW TRIGGERS FROM hospital;

-- Create an event and demonstrate how it runs 

SET GLOBAL event_scheduler = ON;

DELIMITER //
CREATE EVENT update_careplan_status
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    -- Update care plan status based on start and stop dates
    UPDATE careplans
    SET status = 
        CASE
            WHEN start_date <= CURDATE() AND stop_date >= CURDATE() THEN 'Active'
            WHEN stop_date < CURDATE() THEN 'Completed'
            ELSE 'Pending'
        END;
END //

SHOW CREATE EVENT update_careplan_status;


-- Prepare an example query with group by 
--  to demonstrate how to extract data from your DB for analysis:
--  query shows duration of care plans for each patient from most days spent in descending order

SELECT 
P_ID, 
description,
SUM(DATEDIFF(stop_date, start_date)) as careplan_duration_days
FROM careplans 
GROUP BY P_ID, description
ORDER BY SUM(DATEDIFF(stop_date, start_date)) DESC;



-- Create a view that uses at least 3-4 base tables; prepare and demonstrate a query that uses the 
-- view to produce a logically arranged result set for analysis. patients, obsevartions, medications, careplan
-- data a doc/nurse might need to create a careplan

CREATE VIEW careplan_protocol AS
SELECT 
    patients.P_ID AS patient_ID,
    patients.last_name AS surname,
    observations.description AS observation_description,
    observations.value AS observation_measured_vale, 
    observations.UNITS AS unit,    
    careplans.description AS careplan,
	careplans.reason_description AS careplan_reason
   FROM
    patients 
INNER JOIN 
    observations ON patients.P_ID = observations.P_ID
INNER JOIN
    procedures ON patients.P_ID = procedures.P_ID
INNER JOIN
    careplans ON patients.P_ID = careplans.P_ID;

SELECT * FROM careplan_protocol;





