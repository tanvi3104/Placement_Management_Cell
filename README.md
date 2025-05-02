# 📊 Placement Cell Database System

This SQL schema sets up a comprehensive Placement Cell Management System tailored for academic institutions. It allows efficient storage, retrieval, and management of placement-related data including students, departments, companies, industries, and placements. 

The system automates placement status updates, enforces eligibility criteria based on CGPA, and provides easy-to-query views and procedures for common operations such as adding entities, updating records, and generating reports.

---

## 📁 SCHEMA OVERVIEW

The schema is named: `placement_cell`

### ✅ Key Entities:
- **Department**: Stores academic department info.
- **Industry**: Categorizes companies.
- **Company**: Stores details of companies visiting for placements.
- **Student**: Stores student profiles, including CGPA and placement status.
- **Placement**: Tracks student placements with salary and date info.

---

## ⟳ TABLE RELATIONSHIPS

- `student.department_id` → `department.id`
- `company.industry_id` → `industry.id`
- `placement.student_id` → `student.id`
- `placement.company_id` → `company.id`

---

## ⚙️ FUNCTIONALITY

### 🔁 Triggers
- `trg_after_placement_insert`: Automatically sets `is_placed = TRUE` when a student is placed.
- `trg_after_placement_delete`: Recomputes `is_placed` if a placement is removed.

### 👁️ Views
- `vw_placement_details`: Full placement info including student, department, company, and industry.
- `vw_dept_placement_counts`: Shows placement count per department.
- `vw_student_eligibility`: Maps students to companies based on CGPA eligibility.

---

## 📦 STORED PROCEDURES

### 🏫 Departments
- `sp_add_department`
- `sp_update_department`
- `sp_delete_department`

### 🏭 Industries
- `sp_add_industry`
- `sp_update_industry`
- `sp_delete_industry`

### 🏢 Companies
- `sp_add_company`
- `sp_update_company`
- `sp_delete_company`

### 🎓 Students
- `sp_add_student`
- `sp_update_student`
- `sp_delete_student`

### 📄 Placements
- `sp_add_placement`
- `sp_update_placement`
- `sp_delete_placement`

### 🎯 Eligibility
- `sp_get_eligible_companies_for_student(stud_id)`: Returns all companies the student is eligible for based on CGPA.

---

## 🧪 SAMPLE USAGE

```sql
-- Add Departments and Industries
CALL sp_add_department('Computer Science');
CALL sp_add_industry('Information Technology');

-- Add a Company
CALL sp_add_company('Google', 1, 'Sundar Pichai', 'sundar@google.com', '1234567890');

-- Add a Student
CALL sp_add_student('Alice', 'alice@example.com', '9999990000', 1);

-- Place a Student
CALL sp_add_placement(1, 1, 1200000, '2025-04-17');

-- Get Eligible Companies for a Student
CALL sp_get_eligible_companies_for_student(1);
```

---

## 🧠 NOTES

- `cgpa` field was added to `student` and `min_cgpa` to `company` for eligibility tracking.
- Placement inserts and deletes automatically update `is_placed` flag via triggers.
- Use views to generate reports or UI data in frontend apps.

---

## 📌 REQUIREMENTS

- MySQL 8.0+ (for `DEFAULT CURRENT_TIMESTAMP` and `ON UPDATE` expressions)
- Basic understanding of SQL joins, triggers, and stored procedures

---

## 📄 EXPORT & USAGE

You can run the script in any MySQL-compatible client such as MySQL Workbench or phpMyAdmin.




