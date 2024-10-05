/* 
EMPLOYEES DATABASE 
SQL Commands/Clauses Used: Aggregate Functions, Joins, Converting Data Types, Window Functions, CTEs, Subqueries
*/

USE employees;

/* Employee Information */

-- Find the total number of current employees in the company.

SELECT DISTINCT 
	*
FROM
    dept_emp
WHERE
    to_date LIKE '9999%'; -- Note: employees with no end date (AKA current employees) have a to_date value starting with '9999'

-- Retrieve the gender distribution of all employees (active or resigned)

SELECT 
	gender,
    COUNT(*) AS gender_count,
    CONCAT(CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(18,2)), '%') AS gender_percent
FROM employees
GROUP BY gender;

-- Newest hire for every department

SELECT a.*
FROM
(SELECT
	d.dept_name,
    de.emp_no,
    de.from_date,
    DENSE_RANK() OVER (PARTITION BY de.dept_no ORDER BY from_date DESC) AS row_num
FROM departments d
JOIN dept_emp de ON d.dept_no = de.dept_no) a
WHERE a.row_num = 1;

-- Find the job titles of employees, how many hold each title, and the average salary for each title

SELECT
	t.title,
    COUNT(t.emp_no) AS titles_count,
    AVG(s.salary) AS avg_salary
FROM titles t
JOIN salaries s ON t.emp_no = s.emp_no
GROUP BY t.title;

-- Retrieve the list of titles with an average salary higher than $60,000

SELECT
	t.title,
    AVG(s.salary) AS avg_salary
FROM titles t
JOIN salaries s ON t.emp_no = s.emp_no
GROUP BY t.title
HAVING avg_salary > 60000
ORDER BY avg_salary DESC;

/* Compensation */

-- Find the number of current employees and the average salary by department.

SELECT
	d.dept_name,
    COUNT(de.emp_no) AS emp_count,
    AVG(s.salary) AS avg_salary
FROM departments d
JOIN dept_emp de ON d.dept_no = de.dept_no
JOIN salaries s ON de.emp_no = s.emp_no
WHERE de.to_date LIKE '9999%' -- Filter to "current" employees only
GROUP BY d.dept_name
ORDER BY emp_count DESC;

-- Retrieve the top 5 highest-paid current employees and their titles

SELECT
	s.emp_no,
    s.salary,
    t.title
FROM salaries s
JOIN titles t ON s.emp_no = t.emp_no
WHERE s.to_date LIKE '9999%' -- Filters for current employees only
ORDER BY salary DESC
LIMIT 5;

-- Find the second highest salary per employee

SELECT 
    emp_no,
    salary
FROM (
		SELECT
			emp_no,
            salary,
			ROW_NUMBER() OVER (PARTITION BY emp_no ORDER BY salary DESC) AS row_num
		FROM salaries
        ) AS max_salary
WHERE row_num = 2;

-- Find the second highest salary in each department

SELECT
	a.dept_name,
    a.salary AS second_highest_salary
FROM
	(
    SELECT
			dept_name,
			salary,
			ROW_NUMBER() OVER (PARTITION BY d.dept_name ORDER BY s.salary DESC) AS row_num
		FROM dept_emp de
		JOIN salaries s ON s.emp_no = de.emp_no
		JOIN departments d ON de.dept_no = d.dept_no
	) a
WHERE a.row_num = 2;

-- Find the number of employees with salaries higher than their respective department's averages

WITH cte_dept_avg_salary -- Find the department average salary
AS (
	SELECT
		d.dept_name,
		AVG(s.salary) AS avg_salary
	FROM departments d
	JOIN dept_emp de ON d.dept_no = de.dept_no
	JOIN salaries s ON s.emp_no = de.emp_no
	GROUP BY d.dept_name
	),

cte_emp_salary AS -- Retrieve the employee's current salary and current department
	(
    SELECT
		s.emp_no,
        MAX(s.salary) AS emp_current_salary,
        d.dept_name
	FROM salaries s
    JOIN dept_emp de ON s.emp_no = de.emp_no
    JOIN departments d ON de.dept_no = d.dept_no
    WHERE de.to_date LIKE '9999%'
    GROUP BY s.emp_no,
            d.dept_name
    )
SELECT
	a.dept_name,
    COUNT(b.emp_no) AS count_emp
FROM cte_dept_avg_salary a
JOIN cte_emp_salary b ON a.dept_name = b.dept_name 
WHERE b.emp_current_salary > a.avg_salary
GROUP BY a.dept_name
ORDER BY a.dept_name ASC;


-- Find employees with a salary higher than their manager's

WITH emp_salaries AS (
SELECT
	de.dept_no AS dept_no,
	de.emp_no AS emp_no,
	MAX(s.salary) AS emp_salary_current -- Only considering the current salary and not historic salary values
FROM dept_emp de
JOIN dept_manager dm ON de.dept_no = dm.dept_no AND dm.to_date LIKE '9999%'
JOIN salaries s ON de.emp_no = s.emp_no
WHERE de.to_date LIKE '9999%' -- Only considering the current department the employee works in. In this dataset, employees with no end dates have date values in the year '9999'. 
GROUP BY de.dept_no,
	de.emp_no),

manager_salaries AS (
SELECT
	dm.dept_no AS dept_no,
	dm.emp_no AS manager_id,
	MAX(s.salary) AS manager_salary_current  -- Only considering the current salary and not historic salary values
FROM dept_manager dm
JOIN salaries s ON dm.emp_no = s.emp_no
WHERE dm.to_date LIKE '9999%' -- Only considering current department managers
GROUP BY dm.dept_no,
	dm.emp_no)

SELECT
	es.dept_no,
    es.emp_no,
    es.emp_salary_current,
    ms.manager_id,
    ms.manager_salary_current
FROM emp_salaries es
JOIN manager_salaries ms ON es.dept_no = ms.dept_no
WHERE emp_salary_current > manager_salary_current; -- Using two CTEs we find that 33,116 employees have higher salaries than their managers.

