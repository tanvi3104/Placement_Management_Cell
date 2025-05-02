-- ========================================
-- 1. SCHEMA SETUP
-- ========================================
DROP SCHEMA IF EXISTS placement_cell;
CREATE SCHEMA placement_cell;
USE placement_cell;

-- ========================================
-- 2. TABLES
-- ========================================

-- Department lookup
CREATE TABLE department (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,
    created_at    DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Industry lookup
CREATE TABLE industry (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,
    created_at    DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Company master
CREATE TABLE company (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150) NOT NULL UNIQUE,
    industry_id     INT         NOT NULL,
    contact_person  VARCHAR(100),
    contact_email   VARCHAR(100),
    contact_phone   VARCHAR(20),
    created_at      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (industry_id) REFERENCES industry(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- Student master
CREATE TABLE student (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    department_id INT         NOT NULL,
    is_placed     BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES department(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- Placement facts
CREATE TABLE placement (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    student_id     INT         NOT NULL,
    company_id     INT         NOT NULL,
    salary         DECIMAL(12,2) NOT NULL,
    placed_on      DATE        NOT NULL,
    created_at     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (student_id, company_id),
    FOREIGN KEY (student_id) REFERENCES student(id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (company_id) REFERENCES company(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ========================================
-- 3. TRIGGERS
-- ========================================

-- When a placement is inserted, mark the student as placed
DELIMITER $$
CREATE TRIGGER trg_after_placement_insert
AFTER INSERT ON placement
FOR EACH ROW
BEGIN
    UPDATE student
    SET is_placed = TRUE
    WHERE id = NEW.student_id;
END$$
DELIMITER ;

-- If a placement is deleted, re‑compute the student’s placed status
DELIMITER $$
CREATE TRIGGER trg_after_placement_delete
AFTER DELETE ON placement
FOR EACH ROW
BEGIN
    DECLARE cnt INT;
    SELECT COUNT(*) INTO cnt
    FROM placement
    WHERE student_id = OLD.student_id;
    
    UPDATE student
    SET is_placed = (cnt > 0)
    WHERE id = OLD.student_id;
END$$
DELIMITER ;

-- ========================================
-- 4. VIEWS
-- ========================================

-- View: All placements with details
CREATE VIEW vw_placement_details AS
SELECT
    p.id            AS placement_id,
    s.id            AS student_id,
    s.name          AS student_name,
    d.name          AS department,
    c.id            AS company_id,
    c.name          AS company_name,
    i.name          AS industry,
    p.salary,
    p.placed_on
FROM placement p
JOIN student s   ON p.student_id   = s.id
JOIN department d ON s.department_id = d.id
JOIN company c   ON p.company_id    = c.id
JOIN industry i  ON c.industry_id   = i.id;

-- View: Placement counts per department
CREATE VIEW vw_dept_placement_counts AS
SELECT
    d.id            AS department_id,
    d.name          AS department_name,
    COUNT(p.id)     AS placements_count
FROM department d
LEFT JOIN student s    ON s.department_id = d.id
LEFT JOIN placement p  ON p.student_id    = s.id
GROUP BY d.id, d.name;

-- ========================================
-- 5. STORED PROCEDURES (CRUD)
-- ========================================

-- 5.1 Departments
DELIMITER $$
CREATE PROCEDURE sp_add_department(IN dept_name VARCHAR(100))
BEGIN
    INSERT INTO department (name) VALUES (dept_name);
END$$

CREATE PROCEDURE sp_update_department(
    IN dept_id INT,
    IN new_name VARCHAR(100)
)
BEGIN
    UPDATE department
    SET name = new_name
    WHERE id = dept_id;
END$$

CREATE PROCEDURE sp_delete_department(IN dept_id INT)
BEGIN
    DELETE FROM department
    WHERE id = dept_id;
END$$

-- 5.2 Industries
CREATE PROCEDURE sp_add_industry(IN ind_name VARCHAR(100))
BEGIN
    INSERT INTO industry (name) VALUES (ind_name);
END$$

CREATE PROCEDURE sp_update_industry(
    IN ind_id INT,
    IN new_name VARCHAR(100)
)
BEGIN
    UPDATE industry
    SET name = new_name
    WHERE id = ind_id;
END$$

CREATE PROCEDURE sp_delete_industry(IN ind_id INT)
BEGIN
    DELETE FROM industry
    WHERE id = ind_id;
END$$

-- 5.3 Companies
CREATE PROCEDURE sp_add_company(
    IN comp_name       VARCHAR(150),
    IN ind_id          INT,
    IN contact_person  VARCHAR(100),
    IN contact_email   VARCHAR(100),
    IN contact_phone   VARCHAR(20)
)
BEGIN
    INSERT INTO company (
        name, industry_id, contact_person, contact_email, contact_phone
    ) VALUES (
        comp_name, ind_id, contact_person, contact_email, contact_phone
    );
END$$

CREATE PROCEDURE sp_update_company(
    IN comp_id         INT,
    IN comp_name       VARCHAR(150),
    IN ind_id          INT,
    IN contact_person  VARCHAR(100),
    IN contact_email   VARCHAR(100),
    IN contact_phone   VARCHAR(20)
)
BEGIN
    UPDATE company
    SET
        name           = comp_name,
        industry_id    = ind_id,
        contact_person = contact_person,
        contact_email  = contact_email,
        contact_phone  = contact_phone
    WHERE id = comp_id;
END$$

CREATE PROCEDURE sp_delete_company(IN comp_id INT)
BEGIN
    DELETE FROM company
    WHERE id = comp_id;
END$$

-- 5.4 Students
CREATE PROCEDURE sp_add_student(
    IN stud_name   VARCHAR(100),
    IN stud_email  VARCHAR(100),
    IN stud_phone  VARCHAR(20),
    IN dept_id     INT
)
BEGIN
    INSERT INTO student (name, email, phone, department_id)
    VALUES (stud_name, stud_email, stud_phone, dept_id);
END$$

CREATE PROCEDURE sp_update_student(
    IN stud_id     INT,
    IN stud_name   VARCHAR(100),
    IN stud_email  VARCHAR(100),
    IN stud_phone  VARCHAR(20),
    IN dept_id     INT
)
BEGIN
    UPDATE student
    SET
        name           = stud_name,
        email          = stud_email,
        phone          = stud_phone,
        department_id  = dept_id
    WHERE id = stud_id;
END$$

CREATE PROCEDURE sp_delete_student(IN stud_id INT)
BEGIN
    DELETE FROM student
    WHERE id = stud_id;
END$$

-- 5.5 Placements
CREATE PROCEDURE sp_add_placement(
    IN stud_id   INT,
    IN comp_id   INT,
    IN sal       DECIMAL(12,2),
    IN p_date    DATE
)
BEGIN
    INSERT INTO placement (student_id, company_id, salary, placed_on)
    VALUES (stud_id, comp_id, sal, p_date);
END$$

CREATE PROCEDURE sp_update_placement(
    IN plc_id    INT,
    IN sal       DECIMAL(12,2),
    IN p_date    DATE
)
BEGIN
    UPDATE placement
    SET salary    = sal,
        placed_on = p_date
    WHERE id = plc_id;
END$$

CREATE PROCEDURE sp_delete_placement(IN plc_id INT)
BEGIN
    DELETE FROM placement
    WHERE id = plc_id;
END$$
DELIMITER ;

-- ========================================
-- 6. SAMPLE “INTERACTIVE” USAGE
-- ========================================
-- Add departments & industries
CALL sp_add_department('Computer Science');
CALL sp_add_department('Mechanical Engineering');
CALL sp_add_industry('Information Technology');
CALL sp_add_industry('Automotive');

-- Add companies
CALL sp_add_company('Google', 1, 'Sundar Pichai', 'sundar@google.com', '1234567890');
CALL sp_add_company('Tesla', 2, 'Elon Musk',     'elon@tesla.com',  '0987654321');

-- Add students
CALL sp_add_student('Alice', 'alice@example.com', '9999990000', 1);
CALL sp_add_student('Bob',   'bob@example.com',   '8888881111', 2);

-- Place students
CALL sp_add_placement(1, 1, 1200000, '2025-04-17');
CALL sp_add_placement(2, 2,  800000, '2025-04-18');

-- Query the views to interact:
SELECT * FROM vw_placement_details;
SELECT * FROM vw_dept_placement_counts;

-- ========================================
-- 7. CGPA & ELIGIBILITY
-- ========================================

-- 7.1 Add CGPA to students, and minimum CGPA cutoff to companies
ALTER TABLE student
  ADD COLUMN cgpa      DECIMAL(3,2) NOT NULL DEFAULT 0.00;

ALTER TABLE company
  ADD COLUMN min_cgpa  DECIMAL(3,2) NOT NULL DEFAULT 8.00;

-- 7.2 Seed some sample CGPAs
UPDATE student SET cgpa = 9.10 WHERE id = 1;  -- Alice
UPDATE student SET cgpa = 7.80 WHERE id = 2;  -- Bob

-- 7.3 View: every student ↔ company with eligibility flag
CREATE OR REPLACE VIEW vw_student_eligibility AS
SELECT
    s.id            AS student_id,
    s.name          AS student_name,
    s.cgpa,
    c.id            AS company_id,
    c.name          AS company_name,
    c.min_cgpa,
    (s.cgpa >= c.min_cgpa) AS is_eligible
FROM student s
CROSS JOIN company c;

-- Now students can do:
--   SELECT * FROM vw_student_eligibility
--   WHERE student_id = <their_id> AND is_eligible = TRUE;

-- 7.4 Procedure: list only eligible companies for one student
DELIMITER $$
CREATE PROCEDURE sp_get_eligible_companies_for_student(
    IN stud_id INT
)
BEGIN
    SELECT
        c.id           AS company_id,
        c.name         AS company_name,
        c.min_cgpa
    FROM company c
    JOIN student s ON s.id = stud_id
    WHERE s.cgpa >= c.min_cgpa;
END$$
DELIMITER ;

-- Sample calls:
-- Alice (CGPA 9.10) can view:
CALL sp_get_eligible_companies_for_student(1);

-- Bob (CGPA 7.80) will see none (since min_cgpa = 8.00 by default):
CALL sp_get_eligible_companies_for_student(2);