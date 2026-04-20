-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 20, 2026 at 08:49 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `pvamu_registration`
--

DELIMITER $$
--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `calculate_priority_score` (`p_student_id` INT, `p_section_id` INT, `p_timestamp` DATETIME) RETURNS INT(11) DETERMINISTIC READS SQL DATA BEGIN
		    DECLARE score INT DEFAULT 0;
    DECLARE v_major_id INT;
    DECLARE v_grad_month VARCHAR(15);
    DECLARE v_grad_year INT;
    DECLARE v_course_id INT;
    DECLARE grad_date DATE;
    DECLARE months_to_graduation INT;
    DECLARE wait_days INT DEFAULT 0;

	SELECT major_id, graduation_month, graduation_year
INTO v_major_id, v_grad_month, v_grad_year
FROM student
WHERE student_id = p_student_id;

SELECT course_id
INTO v_course_id
FROM section
WHERE section_id = p_section_id;

SET grad_date = STR_TO_DATE(
		CONCAT('01', v_grad_month, ' ', v_grad_year),
		'%d %M %Y'
);

SET months_to_graduation = TIMESTAMPDIFF(
		MONTH,
		CURDATE(),
		grad_date
	);

 IF months_to_graduation BETWEEN 0 AND 6 THEN
        SET score = score + 50;
    ELSEIF months_to_graduation BETWEEN 7 AND 12 THEN
        SET score = score + 40;
    ELSEIF months_to_graduation BETWEEN 13 AND 18 THEN
        SET score = score + 25;
    END IF;

  
    IF EXISTS (
        SELECT 1
        FROM degree_plan
        WHERE major_id = v_major_id
          AND course_id = v_course_id
    ) THEN
        SET score = score + 30;
    END IF;

    
    SET wait_days = TIMESTAMPDIFF(DAY, p_timestamp, NOW());
    SET score = score + LEAST(wait_days * 2, 20);

    RETURN score;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `course`
--

CREATE TABLE `course` (
  `course_id` int(11) NOT NULL,
  `course_code` varchar(20) NOT NULL,
  `course_name` varchar(100) NOT NULL,
  `credit_hours` int(11) NOT NULL,
  `department` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Gives course information. 1-to-many relationship with section';

--
-- Dumping data for table `course`
--

INSERT INTO `course` (`course_id`, `course_code`, `course_name`, `credit_hours`, `department`) VALUES
(201, 'COMP3395', 'Database Systems', 3, 'Computer Science'),
(202, 'COMP2336', 'Data Structures', 3, 'Computer Science'),
(203, 'MATH2414', 'Calculus II', 4, 'Mathematics'),
(204, 'BIOL1306', 'General Biology', 4, 'Biology'),
(205, 'COMP1315', 'Intro to Programming', 3, 'Computer Science'),
(206, 'MATH1314', 'College Algebra', 3, 'Mathematics'),
(209, 'MATH3307', 'Probability and Statistics', 4, 'Mathematics');

-- --------------------------------------------------------

--
-- Table structure for table `degree_plan`
--

CREATE TABLE `degree_plan` (
  `degree_plan_id` int(11) NOT NULL,
  `major_id` int(11) NOT NULL,
  `course_id` int(11) NOT NULL,
  `is_required` tinyint(1) NOT NULL COMMENT '// is the course required depending upon the degree plan',
  `recommended_semester` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='recommended_courses pulls information from THIS table';

--
-- Dumping data for table `degree_plan`
--

INSERT INTO `degree_plan` (`degree_plan_id`, `major_id`, `course_id`, `is_required`, `recommended_semester`) VALUES
(601, 1, 201, 1, 6),
(602, 1, 202, 1, 4),
(603, 1, 205, 1, 1),
(604, 2, 203, 1, 3),
(605, 2, 206, 1, 1),
(606, 3, 204, 1, 1);

-- --------------------------------------------------------

--
-- Table structure for table `enrollment`
--

CREATE TABLE `enrollment` (
  `enrollment_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `section_id` int(11) NOT NULL,
  `status` varchar(20) NOT NULL COMMENT 'Enrolled, Dropped, Completed',
  `grade` varchar(2) NOT NULL,
  `date_enrolled` datetime NOT NULL,
  `credits_earned` int(11) NOT NULL,
  `major_id` int(11) DEFAULT NULL
) ;

--
-- Dumping data for table `enrollment`
--

INSERT INTO `enrollment` (`enrollment_id`, `student_id`, `section_id`, `status`, `grade`, `date_enrolled`, `credits_earned`, `major_id`) VALUES
(401, 101, 301, 'Enrolled', 'A', '0000-00-00 00:00:00', 0, 1),
(402, 102, 301, 'Enrolled', 'B', '0000-00-00 00:00:00', 0, 1),
(403, 103, 302, 'Enrolled', '', '0000-00-00 00:00:00', 0, 2),
(404, 104, 304, 'Enrolled', '', '0000-00-00 00:00:00', 0, 3),
(405, 105, 305, 'Enrolled', 'A', '0000-00-00 00:00:00', 0, 1),
(406, 106, 306, 'Enrolled', '', '0000-00-00 00:00:00', 0, 2);

-- --------------------------------------------------------

--
-- Table structure for table `major`
--

CREATE TABLE `major` (
  `major_id` int(11) NOT NULL,
  `major_name` varchar(100) NOT NULL,
  `total_credits_required` int(11) NOT NULL,
  `degree_type` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='CONNECTS DEGREE_PLAN & ENROLLMENT W/ MAJOR_ID';

--
-- Dumping data for table `major`
--

INSERT INTO `major` (`major_id`, `major_name`, `total_credits_required`, `degree_type`) VALUES
(1, 'Computer Science', 120, 'BS'),
(2, 'Mathematics', 120, 'BS'),
(3, 'Biology', 120, 'BS');

-- --------------------------------------------------------

--
-- Table structure for table `recommended_courses`
--

CREATE TABLE `recommended_courses` (
  `recommendation_id` int(11) NOT NULL,
  `student_id` int(11) DEFAULT NULL,
  `course_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='shows all recommended courses for student. USE recommended_course_summary for the GROUPED VERSION.';

--
-- Dumping data for table `recommended_courses`
--

INSERT INTO `recommended_courses` (`recommendation_id`, `student_id`, `course_id`, `created_at`) VALUES
(1, 105, 201, '2026-04-20 06:37:11'),
(2, 101, 202, '2026-04-20 06:37:11'),
(3, 102, 202, '2026-04-20 06:37:11'),
(4, 105, 202, '2026-04-20 06:37:11'),
(5, 101, 205, '2026-04-20 06:37:11'),
(6, 102, 205, '2026-04-20 06:37:11'),
(7, 103, 203, '2026-04-20 06:37:11'),
(8, 106, 203, '2026-04-20 06:37:11'),
(9, 103, 206, '2026-04-20 06:37:11');

-- --------------------------------------------------------

--
-- Table structure for table `recommended_courses_summary`
--

CREATE TABLE `recommended_courses_summary` (
  `student_id` int(11) DEFAULT NULL,
  `recommended_courses` mediumtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='shows all recommended courses for student.';

--
-- Dumping data for table `recommended_courses_summary`
--

INSERT INTO `recommended_courses_summary` (`student_id`, `recommended_courses`) VALUES
(101, '202,205'),
(102, '202,205'),
(103, '203,206'),
(105, '201,202'),
(106, '203');

-- --------------------------------------------------------

--
-- Table structure for table `section`
--

CREATE TABLE `section` (
  `section_id` int(11) NOT NULL,
  `course_id` int(11) NOT NULL,
  `semester` varchar(20) NOT NULL,
  `year` tinyint(4) NOT NULL,
  `capacity` tinyint(4) NOT NULL,
  `enrollment_count` int(11) DEFAULT 0,
  `night_or_day` varchar(5) DEFAULT NULL,
  `time_of_class` time DEFAULT NULL,
  `day_of_class` varchar(10) DEFAULT NULL,
  `synchronous_or_asynchronous` tinyint(1) DEFAULT NULL COMMENT '1 == synchronous, 0 = asynchronous'
) ;

--
-- Dumping data for table `section`
--

INSERT INTO `section` (`section_id`, `course_id`, `semester`, `year`, `capacity`, `enrollment_count`, `night_or_day`, `time_of_class`, `day_of_class`, `synchronous_or_asynchronous`) VALUES
(301, 201, 'Spring', 127, 2, 2, NULL, NULL, NULL, NULL),
(302, 202, 'Spring', 127, 3, 2, NULL, NULL, NULL, NULL),
(303, 203, 'Spring', 127, 2, 1, NULL, NULL, NULL, NULL),
(304, 204, 'Spring', 127, 3, 1, NULL, NULL, NULL, NULL),
(305, 205, 'Spring', 127, 3, 3, NULL, NULL, NULL, NULL),
(306, 206, 'Spring', 127, 2, 1, NULL, NULL, NULL, NULL),
(307, 209, 'Spring', 127, 6, 2, 'day', '10:00:00', 'T/TH', 1);

-- --------------------------------------------------------

--
-- Table structure for table `student`
--

CREATE TABLE `student` (
  `student_id` int(11) NOT NULL,
  `first_name` text NOT NULL,
  `last_name` text NOT NULL,
  `email` text DEFAULT NULL,
  `classification` varchar(10) NOT NULL,
  `major_id` int(11) DEFAULT NULL,
  `total_credits_completed` tinyint(4) DEFAULT 0,
  `graduation_month` varchar(15) DEFAULT NULL,
  `graduation_year` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Student Data';

--
-- Dumping data for table `student`
--

INSERT INTO `student` (`student_id`, `first_name`, `last_name`, `email`, `classification`, `major_id`, `total_credits_completed`, `graduation_month`, `graduation_year`) VALUES
(101, 'India', 'Hoover', 'india.hoover@email.com', 'Senior', 1, 105, 'May', 2026),
(102, 'Sarah', 'Obeng', 'sarah.obeng@email.com', 'Junior', 1, 75, 'May', 2027),
(103, 'Raylen', 'Williams', 'raylen.w@email.com', 'Senior', 2, 110, 'December', 2026),
(104, 'James', 'Carter', 'james.c@email.com', 'Sophomore', 3, 45, 'May', 2028),
(105, 'Kaitlyn', 'Smith', 'kaitlyn.s@email.com', 'Senior', 1, 98, 'May', 2026),
(106, 'Denise', 'Williams', 'denise.w@email.com', 'Freshman', 2, 15, 'May', 2029);

-- --------------------------------------------------------

--
-- Table structure for table `waitlist`
--

CREATE TABLE `waitlist` (
  `waitlist_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `section_id` int(11) NOT NULL,
  `priority_score` int(11) NOT NULL,
  `timestamp_joined` datetime NOT NULL DEFAULT current_timestamp() COMMENT 'Tiebreaker',
  `notification_sent` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0 --> not notified\r\n1 --> notified',
  `expiration_time` datetime NOT NULL COMMENT 'Automates next selection',
  `notified_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

--
-- Dumping data for table `waitlist`
--

INSERT INTO `waitlist` (`waitlist_id`, `student_id`, `section_id`, `priority_score`, `timestamp_joined`, `notification_sent`, `expiration_time`, `notified_at`) VALUES
(501, 105, 301, 70, '2026-03-30 10:00:00', 0, '0000-00-00 00:00:00', '2026-04-14 20:40:39'),
(502, 103, 301, 60, '2026-03-30 10:05:00', 0, '0000-00-00 00:00:00', '2026-04-14 20:40:39'),
(503, 102, 305, 60, '2026-03-30 11:00:00', 0, '0000-00-00 00:00:00', '2026-04-14 20:40:39'),
(504, 101, 305, 70, '2026-03-30 11:10:00', 0, '0000-00-00 00:00:00', '2026-04-14 20:40:39'),
(505, 106, 301, 20, '2026-03-31 11:20:00', 0, '0000-00-00 00:00:00', '2026-04-14 20:40:39'),
(506, 104, 305, 20, '2026-04-01 11:30:00', 0, '0000-00-00 00:00:00', '2026-04-14 20:40:39');

--
-- Triggers `waitlist`
--
DELIMITER $$
CREATE TRIGGER `trg_before_insert_waitlist` BEFORE INSERT ON `waitlist` FOR EACH ROW BEGIN
    
    IF NEW.timestamp_joined IS NULL THEN
        SET NEW.timestamp_joined = CURRENT_TIMESTAMP;
    END IF;

    
    SET NEW.priority_score =
        calculate_priority_score(
            NEW.student_id,
            NEW.section_id,
            NEW.timestamp_joined
        );
END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `course`
--
ALTER TABLE `course`
  ADD PRIMARY KEY (`course_id`);

--
-- Indexes for table `degree_plan`
--
ALTER TABLE `degree_plan`
  ADD PRIMARY KEY (`degree_plan_id`),
  ADD KEY `fk_course_id` (`course_id`),
  ADD KEY `fk_major_id` (`major_id`);

--
-- Indexes for table `enrollment`
--
ALTER TABLE `enrollment`
  ADD PRIMARY KEY (`enrollment_id`),
  ADD KEY `fk_student_id_enrollemtn` (`student_id`),
  ADD KEY `fk_section_id_enrollment` (`section_id`),
  ADD KEY `fk_major` (`major_id`);

--
-- Indexes for table `major`
--
ALTER TABLE `major`
  ADD PRIMARY KEY (`major_id`);

--
-- Indexes for table `recommended_courses`
--
ALTER TABLE `recommended_courses`
  ADD PRIMARY KEY (`recommendation_id`),
  ADD KEY `student_id` (`student_id`),
  ADD KEY `course_id` (`course_id`);

--
-- Indexes for table `section`
--
ALTER TABLE `section`
  ADD PRIMARY KEY (`section_id`),
  ADD KEY `course_id` (`course_id`);

--
-- Indexes for table `student`
--
ALTER TABLE `student`
  ADD PRIMARY KEY (`student_id`),
  ADD UNIQUE KEY `email` (`email`) USING HASH,
  ADD KEY `fk_student_major` (`major_id`);

--
-- Indexes for table `waitlist`
--
ALTER TABLE `waitlist`
  ADD PRIMARY KEY (`waitlist_id`),
  ADD KEY `fk_student_id` (`student_id`),
  ADD KEY `fk_section_id` (`section_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `course`
--
ALTER TABLE `course`
  MODIFY `course_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=210;

--
-- AUTO_INCREMENT for table `degree_plan`
--
ALTER TABLE `degree_plan`
  MODIFY `degree_plan_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=607;

--
-- AUTO_INCREMENT for table `enrollment`
--
ALTER TABLE `enrollment`
  MODIFY `enrollment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `major`
--
ALTER TABLE `major`
  MODIFY `major_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `recommended_courses`
--
ALTER TABLE `recommended_courses`
  MODIFY `recommendation_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `section`
--
ALTER TABLE `section`
  MODIFY `section_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `waitlist`
--
ALTER TABLE `waitlist`
  MODIFY `waitlist_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `degree_plan`
--
ALTER TABLE `degree_plan`
  ADD CONSTRAINT `fk_course_id` FOREIGN KEY (`course_id`) REFERENCES `course` (`course_id`),
  ADD CONSTRAINT `fk_major_id` FOREIGN KEY (`major_id`) REFERENCES `major` (`major_id`);

--
-- Constraints for table `enrollment`
--
ALTER TABLE `enrollment`
  ADD CONSTRAINT `fk_major` FOREIGN KEY (`major_id`) REFERENCES `major` (`major_id`),
  ADD CONSTRAINT `fk_section_id_enrollment` FOREIGN KEY (`section_id`) REFERENCES `section` (`section_id`),
  ADD CONSTRAINT `fk_student_id_enrollemtn` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`);

--
-- Constraints for table `recommended_courses`
--
ALTER TABLE `recommended_courses`
  ADD CONSTRAINT `recommended_courses_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`),
  ADD CONSTRAINT `recommended_courses_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `course` (`course_id`);

--
-- Constraints for table `section`
--
ALTER TABLE `section`
  ADD CONSTRAINT `fk_section_course` FOREIGN KEY (`course_id`) REFERENCES `course` (`course_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `student`
--
ALTER TABLE `student`
  ADD CONSTRAINT `fk_student_major` FOREIGN KEY (`major_id`) REFERENCES `major` (`major_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `waitlist`
--
ALTER TABLE `waitlist`
  ADD CONSTRAINT `fk_section_id` FOREIGN KEY (`section_id`) REFERENCES `section` (`section_id`),
  ADD CONSTRAINT `fk_student_id` FOREIGN KEY (`student_id`) REFERENCES `student` (`student_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
