DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'enforce_min_salary') THEN
        DROP TRIGGER enforce_min_salary ON Works;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'enforce_max_payroll') THEN
        DROP TRIGGER enforce_max_payroll ON Works;
    END IF;
END $$;

-- Drop functions if they exist
DROP FUNCTION IF EXISTS check_min_salary;
DROP FUNCTION IF EXISTS check_total_payroll;


-- a. Create a trigger to ensure that the salary of an employee cannot be reduced below $30,000.
CREATE OR REPLACE FUNCTION check_min_salary()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.salary < 30000 THEN
        RAISE EXCEPTION 'Salary cannot be less than $30,000';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_min_salary
BEFORE INSERT OR UPDATE ON Works
FOR EACH ROW
EXECUTE FUNCTION check_min_salary();

-- b. Create a trigger to ensure that the total payroll of a company does not exceed $500,000.
CREATE OR REPLACE FUNCTION check_total_payroll()
RETURNS TRIGGER AS $$
DECLARE
    total_payroll DECIMAL(10, 2);
BEGIN
    SELECT COALESCE(SUM(salary), 0) + NEW.salary
    INTO total_payroll
    FROM Works
    WHERE company_name = NEW.company_name;

    IF total_payroll > 500000 THEN
        RAISE EXCEPTION 'Total payroll for % exceeds $500,000', NEW.company_name;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_max_payroll
BEFORE INSERT OR UPDATE ON Works
FOR EACH ROW
EXECUTE FUNCTION check_total_payroll();