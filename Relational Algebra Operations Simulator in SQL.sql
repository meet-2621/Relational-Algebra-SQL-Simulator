-- Relational Algebra Operations Simulator - Complete SQL Script
-- Compatible with PostgreSQL (ANSI SQL). Minor changes make it compatible with MySQL/Oracle.
-- Author: Manmeet Kaur
-- Purpose: Create schema, sample data, and example queries for relational algebra concepts.


-- DROP and CREATE database (uncomment/create as needed in your environment)
-- In psql you would run: CREATE DATABASE university;
-- Then connect to it before running the rest of the script.


-- ==========================
-- 1. Schema Creation
-- ==========================
-- Students table
CREATE TABLE Students (
    student_id INT PRIMARY KEY,
    name VARCHAR(50),
    dept_id INT
);

-- Departments table
CREATE TABLE Departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
);

-- Courses table
CREATE TABLE Courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(50),
    dept_id INT
);

-- Enrollments table (many-to-many between Students and Courses)
CREATE TABLE Enrollments (
    student_id INT,
    course_id INT,
    grade CHAR(1),
    PRIMARY KEY(student_id, course_id)
);

-- Foreign key constraints (optional; comment out if you don't want FK checks in sample)
ALTER TABLE IF EXISTS Students
ADD CONSTRAINT fk_students_dept FOREIGN KEY (dept_id) REFERENCES Departments(dept_id);


ALTER TABLE IF EXISTS Courses
ADD CONSTRAINT fk_courses_dept FOREIGN KEY (dept_id) REFERENCES Departments(dept_id);


ALTER TABLE IF EXISTS Enrollments
ADD CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES Students(student_id);


ALTER TABLE IF EXISTS Enrollments
ADD CONSTRAINT fk_enroll_course FOREIGN KEY (course_id) REFERENCES Courses(course_id);

-- ==========================
-- 2. Sample Data
-- ==========================
-- Departments
INSERT INTO Departments (dept_id, dept_name) VALUES
(101, 'Computer Science'),
(102, 'Information Technology'),
(103, 'Electronics');


-- Students
INSERT INTO Students (student_id, name, dept_id) VALUES
(1, 'Aisha Sharma', 101),
(2, 'Rohit Verma', 101),
(3, 'Neha Singh', 102),
(4, 'Suresh Kumar', 103),
(5, 'Priya Patel', NULL); -- student without department (to show outer join behavior)


-- Courses
INSERT INTO Courses (course_id, course_name, dept_id) VALUES
(201, 'Database Systems', 101),
(202, 'Operating Systems', 101),
(203, 'Computer Networks', 102),
(204, 'Digital Electronics', 103),
(205, 'Data Structures', 101);


-- Enrollments: student_id, course_id, grade
INSERT INTO Enrollments (student_id, course_id, grade) VALUES
(1, 201, 'A'),
(1, 202, 'B'),
(1, 205, 'A'),
(2, 201, 'B'),
(2, 205, 'B'),
(3, 203, 'A'),
(4, 204, 'C');

-- Student 5 (Priya) not enrolled in any course to demonstrate EXISTS/NOT EXISTS
SELECT student_id FROM Enrollments WHERE grade = 'B';


-- --------------------------------------------------
-- Division (÷) — students who have taken ALL courses of a particular set
-- Example 1: Students who have taken ALL courses offered by their own department
-- Implementation pattern using NOT EXISTS (portable SQL)
-- --------------------------------------------------
-- Relational algebra intent: student S such that for every course C in S.dept_id, (S,C) in Enrollments
SELECT S.student_id, S.name
FROM Students S
WHERE S.dept_id IS NOT NULL
AND NOT EXISTS (
SELECT 1 FROM Courses C
WHERE C.dept_id = S.dept_id
AND NOT EXISTS (
SELECT 1 FROM Enrollments E
WHERE E.student_id = S.student_id AND E.course_id = C.course_id
)
);


-- Example 2: Classical division example — students who took all courses in a given list
-- Suppose we want students who took courses {201,205} (Database Systems and Data Structures)
SELECT DISTINCT E.student_id
FROM Enrollments E
WHERE E.course_id IN (201,205)
GROUP BY E.student_id
HAVING COUNT(DISTINCT E.course_id) = 2; -- number of courses in the dividing set


-- --------------------------------------------------
-- Tuple Relational Calculus (expressed via SQL using EXISTS/ALL)
-- Example: Names of students who enrolled in at least one course
-- --------------------------------------------------
SELECT S.name
FROM Students S
WHERE EXISTS (
SELECT 1 FROM Enrollments E WHERE E.student_id = S.student_id
);


-- --------------------------------------------------
-- Domain Relational Calculus (expressed via SQL projection/filtering)
-- Example: Find (name, dept_name) pairs for students
-- --------------------------------------------------
SELECT S.name, D.dept_name
FROM Students S JOIN Departments D ON S.dept_id = D.dept_id;


-- --------------------------------------------------
-- Additional useful examples / helpers
-- --------------------------------------------------
-- 1) All courses a particular student (id = 1) took
SELECT C.course_name, E.grade
FROM Enrollments E JOIN Courses C ON E.course_id = C.course_id
WHERE E.student_id = 1;


-- 2) Students along with count of courses they took
SELECT S.student_id, S.name, COUNT(E.course_id) AS courses_taken
FROM Students S LEFT JOIN Enrollments E ON S.student_id = E.student_id
GROUP BY S.student_id, S.name
ORDER BY courses_taken DESC;


-- 3) Courses with no enrolled students (anti-join using NOT EXISTS)
SELECT C.course_id, C.course_name
FROM Courses C
WHERE NOT EXISTS (
SELECT 1 FROM Enrollments E WHERE E.course_id = C.course_id
);


-- 4) Students who took at least one course from a department different than their own
SELECT DISTINCT S.student_id, S.name
FROM Students S JOIN Enrollments E ON S.student_id = E.student_id
JOIN Courses C ON E.course_id = C.course_id
WHERE S.dept_id IS NOT NULL AND C.dept_id <> S.dept_id;


-- ==========================
-- End of script
-- ==========================


-- Notes & Portability
-- - PostgreSQL: the script should run as-is (connect to your database and run).
-- - MySQL: INTERSECT and EXCEPT were added in later versions; if your MySQL version lacks them
-- you can replace INTERSECT with INNER JOIN between subqueries and EXCEPT with a LEFT JOIN + IS NULL or NOT EXISTS pattern.
-- - Oracle: replace EXCEPT with MINUS and remove "IF EXISTS" style clauses used above.