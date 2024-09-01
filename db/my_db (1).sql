-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 01, 2024 at 03:02 PM
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
-- Database: `my_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `log_appointment_delete` (`adminId` INT, `appointmentId` INT)   BEGIN
    DECLARE adminUsername VARCHAR(100);

    -- Fetch admin username
    SELECT username INTO adminUsername FROM users WHERE id = adminId;

    -- Insert into appointment_history
    INSERT INTO appointment_history (admin_username, action, details)
    VALUES (adminUsername, 'delete', CONCAT('Deleted appointment ID ', appointmentId));
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `log_appointment_insert` (`adminId` INT, `appointmentId` INT)   BEGIN
    DECLARE adminUsername VARCHAR(100);

    -- Fetch admin username
    SELECT username INTO adminUsername FROM users WHERE id = adminId;

    -- Insert into appointment_history
    INSERT INTO appointment_history (admin_username, action, details)
    VALUES (adminUsername, 'insert', CONCAT('Created appointment ID ', appointmentId));
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `log_appointment_update` (`adminId` INT, `appointmentId` INT, `changes` TEXT)   BEGIN
    DECLARE adminUsername VARCHAR(100);

    -- Fetch admin username
    SELECT username INTO adminUsername FROM users WHERE id = adminId;

    -- Insert into appointment_history
    INSERT INTO appointment_history (admin_username, action, details)
    VALUES (adminUsername, 'update', CONCAT('Updated appointment ID ', appointmentId, ': ', changes));
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `appointments`
--

CREATE TABLE `appointments` (
  `id` int(11) NOT NULL,
  `pet_name` varchar(100) DEFAULT NULL,
  `species` varchar(100) DEFAULT NULL,
  `appointment_date` date DEFAULT NULL,
  `appointment_time` time DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `purpose` text DEFAULT NULL,
  `status` enum('Pending','Confirmed','Completed','Cancelled') DEFAULT 'Pending',
  `user_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `appointments`
--

INSERT INTO `appointments` (`id`, `pet_name`, `species`, `appointment_date`, `appointment_time`, `created_at`, `updated_at`, `purpose`, `status`, `user_id`) VALUES
(23, 'Dudoy', 'Dog', '2024-06-03', '09:00:00', '2024-05-28 01:30:13', '2024-05-28 05:16:59', 'S1', 'Confirmed', 11),
(24, 'jingoy', 'Cat', '2024-05-30', '12:00:00', '2024-05-28 01:43:35', '2024-05-28 05:18:35', 'S1,S4', 'Confirmed', 10),
(25, 'Pet1', 'Cat', '2024-06-01', '09:00:00', '2024-05-28 03:19:04', '2024-05-28 03:19:14', '', 'Cancelled', 12),
(26, 'Pet1', 'Cat', '2024-06-02', '09:00:00', '2024-05-28 03:19:49', '2024-05-28 05:17:06', '', 'Cancelled', 12),
(27, 'Pet1', 'Cat', '2024-06-04', '09:00:00', '2024-05-28 03:20:39', '2024-07-10 00:21:04', '', 'Cancelled', 12),
(28, 'Pet3', 'Dog', '2024-06-01', '10:00:00', '2024-05-28 03:34:14', '2024-05-28 03:34:26', '', 'Cancelled', 12),
(29, 'Pet3', 'Dog', '2024-06-01', '15:00:00', '2024-05-28 03:34:51', '2024-07-10 00:21:06', '', 'Cancelled', 12),
(30, 'willow', 'Dog', '2024-06-01', '14:00:00', '2024-05-28 03:43:54', '2024-05-28 03:44:07', 'S5', 'Cancelled', 10),
(31, 'Jones', 'Cat', '2024-06-01', '11:00:00', '2024-05-28 03:44:43', '2024-05-28 03:44:43', 'S5', 'Pending', 10),
(32, 'pogi', 'Cat', '2024-06-08', '09:00:00', '2024-05-28 09:31:48', '2024-05-28 09:51:17', 'S1', 'Confirmed', 14),
(33, 'jojo', 'Dog', '2024-07-25', '13:00:00', '2024-07-10 00:21:06', '2024-07-10 00:21:06', 'S1,S8', 'Pending', 12);

--
-- Triggers `appointments`
--
DELIMITER $$
CREATE TRIGGER `appointment_delete_trigger` AFTER DELETE ON `appointments` FOR EACH ROW BEGIN
    DECLARE admin_username VARCHAR(100);
    -- Retrieve the username based on @userId
    SELECT username INTO admin_username FROM users WHERE id = @userId;

    INSERT INTO appointment_history (admin_username, action, details)
    VALUES (admin_username, 'delete', CONCAT('Deleted appointment: Pet Name: ', OLD.pet_name, ', Species: ', OLD.species, ', Date: ', OLD.appointment_date, ', Time: ', OLD.appointment_time, ', Purpose: ', OLD.purpose, ', Status: ', OLD.status));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `appointment_insert_trigger` AFTER INSERT ON `appointments` FOR EACH ROW BEGIN
    DECLARE admin_username VARCHAR(100);
    -- Retrieve the username based on @userId
    SELECT username INTO admin_username FROM users WHERE id = @userId;

    INSERT INTO appointment_history (admin_username, action, details)
    VALUES (admin_username, 'insert', CONCAT('Created appointment: Pet Name: ', NEW.pet_name, ', Species: ', NEW.species, ', Date: ', NEW.appointment_date, ', Time: ', NEW.appointment_time, ', Purpose: ', NEW.purpose, ', Status: ', NEW.status));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `appointment_update_trigger` AFTER UPDATE ON `appointments` FOR EACH ROW BEGIN
    DECLARE changes TEXT;
    DECLARE admin_username VARCHAR(100);
    SET changes = '';

    -- Retrieve the username based on @userId
    SELECT username INTO admin_username FROM users WHERE id = @userId;

    IF OLD.pet_name != NEW.pet_name THEN
        SET changes = CONCAT(changes, 'Pet Name changed from ', OLD.pet_name, ' to ', NEW.pet_name, '. ');
    END IF;
    IF OLD.species != NEW.species THEN
        SET changes = CONCAT(changes, 'Species changed from ', OLD.species, ' to ', NEW.species, '. ');
    END IF;
    IF OLD.appointment_date != NEW.appointment_date THEN
        SET changes = CONCAT(changes, 'Date changed from ', OLD.appointment_date, ' to ', NEW.appointment_date, '. ');
    END IF;
    IF OLD.appointment_time != NEW.appointment_time THEN
        SET changes = CONCAT(changes, 'Time changed from ', OLD.appointment_time, ' to ', NEW.appointment_time, '. ');
    END IF;
    IF OLD.purpose != NEW.purpose THEN
        SET changes = CONCAT(changes, 'Purpose changed from ', OLD.purpose, ' to ', NEW.purpose, '. ');
    END IF;
    IF OLD.status != NEW.status THEN
        SET changes = CONCAT(changes, 'Status changed from ', OLD.status, ' to ', NEW.status, '. ');
    END IF;

    INSERT INTO appointment_history (admin_username, action, details)
    VALUES (admin_username, 'update', CONCAT('Updated appointment ID ', OLD.id, ': ', changes));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `appointments_log_delete_trigger` AFTER DELETE ON `appointments` FOR EACH ROW BEGIN
    DECLARE admin_username VARCHAR(100);
    SELECT username INTO admin_username FROM users WHERE id = @userId;

    INSERT INTO change_logs (admin_username, table_name, action, details)
    VALUES (admin_username, 'appointments', 'delete', CONCAT('Deleted appointment: Pet Name: ', OLD.pet_name, ', Species: ', OLD.species, ', Date: ', OLD.appointment_date, ', Time: ', OLD.appointment_time, ', Purpose: ', OLD.purpose, ', Status: ', OLD.status));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `appointments_log_insert_trigger` AFTER INSERT ON `appointments` FOR EACH ROW BEGIN
    DECLARE admin_username VARCHAR(100);
    SELECT username INTO admin_username FROM users WHERE id = @userId;

    INSERT INTO change_logs (admin_username, table_name, action, details)
    VALUES (admin_username, 'appointments', 'insert', CONCAT('Created appointment: Pet Name: ', NEW.pet_name, ', Species: ', NEW.species, ', Date: ', NEW.appointment_date, ', Time: ', NEW.appointment_time, ', Purpose: ', NEW.purpose, ', Status: ', NEW.status));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `appointments_log_update_trigger` AFTER UPDATE ON `appointments` FOR EACH ROW BEGIN
    DECLARE changes TEXT;
    DECLARE admin_username VARCHAR(100);
    SET changes = '';

    IF OLD.pet_name != NEW.pet_name THEN
        SET changes = CONCAT(changes, 'Pet Name changed from ', OLD.pet_name, ' to ', NEW.pet_name, '. ');
    END IF;
    IF OLD.species != NEW.species THEN
        SET changes = CONCAT(changes, 'Species changed from ', OLD.species, ' to ', NEW.species, '. ');
    END IF;
    IF OLD.appointment_date != NEW.appointment_date THEN
        SET changes = CONCAT(changes, 'Date changed from ', OLD.appointment_date, ' to ', NEW.appointment_date, '. ');
    END IF;
    IF OLD.appointment_time != NEW.appointment_time THEN
        SET changes = CONCAT(changes, 'Time changed from ', OLD.appointment_time, ' to ', NEW.appointment_time, '. ');
    END IF;
    IF OLD.purpose != NEW.purpose THEN
        SET changes = CONCAT(changes, 'Purpose changed from ', OLD.purpose, ' to ', NEW.purpose, '. ');
    END IF;
    IF OLD.status != NEW.status THEN
        SET changes = CONCAT(changes, 'Status changed from ', OLD.status, ' to ', NEW.status, '. ');
    END IF;

    SELECT username INTO admin_username FROM users WHERE id = @userId;

    INSERT INTO change_logs (admin_username, table_name, action, details)
    VALUES (admin_username, 'appointments', 'update', CONCAT('Updated appointment ID ', OLD.id, ': ', changes));
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `appointment_history`
--

CREATE TABLE `appointment_history` (
  `id` int(11) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  `admin_username` varchar(100) DEFAULT NULL,
  `action` varchar(50) DEFAULT NULL,
  `details` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `appointment_history`
--

INSERT INTO `appointment_history` (`id`, `timestamp`, `admin_username`, `action`, `details`) VALUES
(29, '2024-05-28 01:30:13', 'miguel', 'insert', 'Created appointment: Pet Name: Dudoy, Species: Dog, Date: 2024-06-05, Time: 09:00:00, Purpose: S1, Status: Pending'),
(30, '2024-05-28 01:43:35', NULL, 'insert', 'Created appointment: Pet Name: jingoy, Species: Cat, Date: 2024-05-28, Time: 09:00:00, Purpose: S1,S4, Status: Confirmed'),
(31, '2024-05-28 03:02:21', 'schedadmin', 'update', 'Updated appointment ID 23: Date changed from 2024-06-05 to 2024-06-04. Status changed from Pending to Confirmed. '),
(32, '2024-05-28 03:02:42', 'schedadmin', 'update', 'Updated appointment ID 23: Date changed from 2024-06-04 to 2024-06-03. Status changed from Confirmed to Pending. '),
(33, '2024-05-28 03:19:04', 'client123', 'insert', 'Created appointment: Pet Name: Pet1, Species: Cat, Date: 2024-06-01, Time: 09:00:00, Purpose: , Status: Pending'),
(34, '2024-05-28 03:19:14', 'client123', 'update', 'Updated appointment ID 25: Status changed from Pending to Cancelled. '),
(35, '2024-05-28 03:19:49', 'client123', 'insert', 'Created appointment: Pet Name: Pet1, Species: Cat, Date: 2024-06-02, Time: 09:00:00, Purpose: , Status: Pending'),
(36, '2024-05-28 03:20:39', 'client123', 'insert', 'Created appointment: Pet Name: Pet1, Species: Cat, Date: 2024-06-04, Time: 09:00:00, Purpose: , Status: Pending'),
(37, '2024-05-28 03:34:14', 'client123', 'insert', 'Created appointment: Pet Name: Pet3, Species: Dog, Date: 2024-06-01, Time: 10:00:00, Purpose: , Status: Pending'),
(38, '2024-05-28 03:34:26', 'client123', 'update', 'Updated appointment ID 28: Status changed from Pending to Cancelled. '),
(39, '2024-05-28 03:34:51', 'client123', 'insert', 'Created appointment: Pet Name: Pet3, Species: Dog, Date: 2024-06-01, Time: 15:00:00, Purpose: , Status: Pending'),
(40, '2024-05-28 03:43:54', 'ClientOne', 'insert', 'Created appointment: Pet Name: willow, Species: Dog, Date: 2024-06-01, Time: 14:00:00, Purpose: S5, Status: Pending'),
(41, '2024-05-28 03:44:07', 'ClientOne', 'update', 'Updated appointment ID 30: Status changed from Pending to Cancelled. '),
(42, '2024-05-28 03:44:43', 'ClientOne', 'insert', 'Created appointment: Pet Name: Jones, Species: Cat, Date: 2024-06-01, Time: 11:00:00, Purpose: S5, Status: Pending'),
(43, '2024-05-28 05:16:59', 'schedadmin', 'update', 'Updated appointment ID 23: Status changed from Pending to Confirmed. '),
(44, '2024-05-28 05:17:06', 'schedadmin', 'update', 'Updated appointment ID 26: Status changed from Pending to Cancelled. '),
(45, '2024-05-28 05:17:24', 'schedadmin', 'update', 'Updated appointment ID 27: '),
(46, '2024-05-28 05:17:39', 'schedadmin', 'update', 'Updated appointment ID 24: Date changed from 2024-05-28 to 2024-05-29. Time changed from 09:00:00 to 12:00:00. '),
(47, '2024-05-28 05:18:35', 'schedadmin', 'update', 'Updated appointment ID 24: Date changed from 2024-05-29 to 2024-05-30. '),
(48, '2024-05-28 09:31:48', 'miguel1', 'insert', 'Created appointment: Pet Name: pogi, Species: Cat, Date: 2024-06-08, Time: 09:00:00, Purpose: S1, Status: Pending'),
(49, '2024-05-28 09:51:17', 'schedadmin', 'update', 'Updated appointment ID 32: Status changed from Pending to Confirmed. '),
(50, '2024-07-10 00:21:04', 'client123', 'update', 'Updated appointment ID 27: Status changed from Pending to Cancelled. '),
(51, '2024-07-10 00:21:06', 'client123', 'update', 'Updated appointment ID 29: Status changed from Pending to Cancelled. '),
(52, '2024-07-10 00:21:06', 'client123', 'insert', 'Created appointment: Pet Name: jojo, Species: Dog, Date: 2024-07-25, Time: 13:00:00, Purpose: S1,S8, Status: Pending');

-- --------------------------------------------------------

--
-- Table structure for table `change_logs`
--

CREATE TABLE `change_logs` (
  `id` int(11) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  `admin_username` varchar(100) DEFAULT NULL,
  `table_name` varchar(50) NOT NULL,
  `action` varchar(50) NOT NULL,
  `details` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `change_logs`
--

INSERT INTO `change_logs` (`id`, `timestamp`, `admin_username`, `table_name`, `action`, `details`) VALUES
(24, '2024-05-27 13:21:45', 'superadmin', 'users', 'insert', 'Created user: Username: ClientOne, Email: client1@gmail.com, Role: 4, Status: active'),
(25, '2024-05-28 01:28:26', 'ClientOne', 'users', 'insert', 'Created user: Username: miguel, Email: miguelbolneo02@gmail.com, Role: 4, Status: active'),
(26, '2024-05-28 01:30:13', 'miguel', 'appointments', 'insert', 'Created appointment: Pet Name: Dudoy, Species: Dog, Date: 2024-06-05, Time: 09:00:00, Purpose: S1, Status: Pending'),
(27, '2024-05-28 01:43:35', NULL, 'appointments', 'insert', 'Created appointment: Pet Name: jingoy, Species: Cat, Date: 2024-05-28, Time: 09:00:00, Purpose: S1,S4, Status: Confirmed'),
(28, '2024-05-28 03:02:21', 'schedadmin', 'appointments', 'update', 'Updated appointment ID 23: Date changed from 2024-06-05 to 2024-06-04. Status changed from Pending to Confirmed. '),
(29, '2024-05-28 03:02:42', 'schedadmin', 'appointments', 'update', 'Updated appointment ID 23: Date changed from 2024-06-04 to 2024-06-03. Status changed from Confirmed to Pending. '),
(30, '2024-05-28 03:16:14', 'ClientOne', 'users', 'insert', 'Created user: Username: client123, Email: clientone@gmail.com, Role: 4, Status: active'),
(31, '2024-05-28 03:19:04', 'client123', 'appointments', 'insert', 'Created appointment: Pet Name: Pet1, Species: Cat, Date: 2024-06-01, Time: 09:00:00, Purpose: , Status: Pending'),
(32, '2024-05-28 03:19:14', 'client123', 'appointments', 'update', 'Updated appointment ID 25: Status changed from Pending to Cancelled. '),
(33, '2024-05-28 03:19:49', 'client123', 'appointments', 'insert', 'Created appointment: Pet Name: Pet1, Species: Cat, Date: 2024-06-02, Time: 09:00:00, Purpose: , Status: Pending'),
(34, '2024-05-28 03:20:39', 'client123', 'appointments', 'insert', 'Created appointment: Pet Name: Pet1, Species: Cat, Date: 2024-06-04, Time: 09:00:00, Purpose: , Status: Pending'),
(35, '2024-05-28 03:34:14', 'client123', 'appointments', 'insert', 'Created appointment: Pet Name: Pet3, Species: Dog, Date: 2024-06-01, Time: 10:00:00, Purpose: , Status: Pending'),
(36, '2024-05-28 03:34:26', 'client123', 'appointments', 'update', 'Updated appointment ID 28: Status changed from Pending to Cancelled. '),
(37, '2024-05-28 03:34:51', 'client123', 'appointments', 'insert', 'Created appointment: Pet Name: Pet3, Species: Dog, Date: 2024-06-01, Time: 15:00:00, Purpose: , Status: Pending'),
(38, '2024-05-28 03:43:54', 'ClientOne', 'appointments', 'insert', 'Created appointment: Pet Name: willow, Species: Dog, Date: 2024-06-01, Time: 14:00:00, Purpose: S5, Status: Pending'),
(39, '2024-05-28 03:44:07', 'ClientOne', 'appointments', 'update', 'Updated appointment ID 30: Status changed from Pending to Cancelled. '),
(40, '2024-05-28 03:44:43', 'ClientOne', 'appointments', 'insert', 'Created appointment: Pet Name: Jones, Species: Cat, Date: 2024-06-01, Time: 11:00:00, Purpose: S5, Status: Pending'),
(41, '2024-05-28 05:16:59', 'schedadmin', 'appointments', 'update', 'Updated appointment ID 23: Status changed from Pending to Confirmed. '),
(42, '2024-05-28 05:17:06', 'schedadmin', 'appointments', 'update', 'Updated appointment ID 26: Status changed from Pending to Cancelled. '),
(43, '2024-05-28 05:17:24', 'schedadmin', 'appointments', 'update', 'Updated appointment ID 27: '),
(44, '2024-05-28 05:17:39', 'schedadmin', 'appointments', 'update', 'Updated appointment ID 24: Date changed from 2024-05-28 to 2024-05-29. Time changed from 09:00:00 to 12:00:00. '),
(45, '2024-05-28 05:18:35', 'schedadmin', 'appointments', 'update', 'Updated appointment ID 24: Date changed from 2024-05-29 to 2024-05-30. '),
(46, '2024-05-28 05:21:31', 'superadmin', 'users', 'insert', 'Created user: Username: pollly, Email: polly@gmail.com, Role: 4, Status: active'),
(47, '2024-05-28 05:21:57', 'superadmin', 'users', 'update', 'Updated user ID 13: Username changed from pollly to polllys. Email changed from polly@gmail.com to pollys@gmail.com. Role changed from 4 to 2. Status changed from active to inactive. '),
(48, '2024-05-28 05:22:03', 'superadmin', 'users', 'delete', 'Deleted user: Username: polllys, Email: pollys@gmail.com, Role: 2, Status: inactive'),
(49, '2024-05-28 09:25:33', NULL, 'users', 'insert', 'Created user: Username: miguel1, Email: miguelbolneo87@gmail.com, Role: 4, Status: active'),
(50, '2024-05-28 09:31:48', 'miguel1', 'appointments', 'insert', 'Created appointment: Pet Name: pogi, Species: Cat, Date: 2024-06-08, Time: 09:00:00, Purpose: S1, Status: Pending'),
(51, '2024-05-28 09:51:17', 'schedadmin', 'appointments', 'update', 'Updated appointment ID 32: Status changed from Pending to Confirmed. '),
(52, '2024-05-28 10:07:50', 'superadmin', 'users', 'insert', 'Created user: Username: lala, Email: miguelbolneo020221@gmail.com, Role: 4, Status: active'),
(53, '2024-05-28 10:08:31', NULL, 'users', 'delete', 'Deleted user: Username: superadmin, Email: john@example.com, Role: 1, Status: active'),
(54, '2024-07-10 00:21:04', 'client123', 'appointments', 'update', 'Updated appointment ID 27: Status changed from Pending to Cancelled. '),
(55, '2024-07-10 00:21:06', 'client123', 'appointments', 'update', 'Updated appointment ID 29: Status changed from Pending to Cancelled. '),
(56, '2024-07-10 00:21:06', 'client123', 'appointments', 'insert', 'Created appointment: Pet Name: jojo, Species: Dog, Date: 2024-07-25, Time: 13:00:00, Purpose: S1,S8, Status: Pending');

-- --------------------------------------------------------

--
-- Table structure for table `services`
--

CREATE TABLE `services` (
  `id` int(11) NOT NULL,
  `service_code` varchar(50) DEFAULT NULL,
  `service_name` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `services`
--

INSERT INTO `services` (`id`, `service_code`, `service_name`) VALUES
(1, 'S1', 'Full Groom'),
(2, 'S2', 'Basic Groom'),
(3, 'S3', 'Nail Trim'),
(4, 'S4', 'Ear Clean'),
(5, 'S5', 'Face Trim'),
(6, 'S6', 'Paw Trim'),
(7, 'S7', 'Shower & Blow Dry'),
(8, 'S8', 'Toothbrush'),
(9, 'S9', 'Anal Sac Clean');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `fullname` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `username` varchar(100) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `role_id` int(11) DEFAULT 4,
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `fullname`, `email`, `username`, `password`, `role_id`, `status`, `created_at`) VALUES
(2, 'Jane Smith', 'jane@example.com', 'schedadmin', 'schedadmin', 2, 'active', '2024-05-17 22:39:20'),
(3, 'Alice Johnson', 'alice@example.com', 'shopadmin', 'shopadmin', 3, 'active', '2024-05-17 22:39:20'),
(10, 'Client', 'client1@gmail.com', 'ClientOne', 'Clientone1!', 4, 'active', '2024-05-27 21:21:45'),
(11, 'bolneo, mgiuel joaquin s.', 'miguelbolneo02@gmail.com', 'miguel', 'Miguel#123', 4, 'active', '2024-05-28 09:28:26'),
(12, 'Client One', 'clientone@gmail.com', 'client123', 'Clientone123!', 4, 'active', '2024-05-28 11:16:14'),
(14, 'Bolneo, Miguel Joaquin S.', 'miguelbolneo87@gmail.com', 'miguel1', 'Miguel#11', 4, 'active', '2024-05-28 17:25:33'),
(15, NULL, 'miguelbolneo020221@gmail.com', 'lala', 'Miguel#22', 4, 'active', '2024-05-28 18:07:50');

--
-- Triggers `users`
--
DELIMITER $$
CREATE TRIGGER `users_log_delete_trigger` AFTER DELETE ON `users` FOR EACH ROW BEGIN
    DECLARE admin_username VARCHAR(100);
    SELECT username INTO admin_username FROM users WHERE id = @userId;

    INSERT INTO change_logs (admin_username, table_name, action, details)
    VALUES (admin_username, 'users', 'delete', CONCAT('Deleted user: Username: ', OLD.username, ', Email: ', OLD.email, ', Role: ', OLD.role_id, ', Status: ', OLD.status));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `users_log_insert_trigger` AFTER INSERT ON `users` FOR EACH ROW BEGIN
    DECLARE admin_username VARCHAR(100);
    SELECT username INTO admin_username FROM users WHERE id = @userId;
    
    INSERT INTO change_logs (admin_username, table_name, action, details)
    VALUES (admin_username, 'users', 'insert', CONCAT('Created user: Username: ', NEW.username, ', Email: ', NEW.email, ', Role: ', NEW.role_id, ', Status: ', NEW.status));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `users_log_update_trigger` AFTER UPDATE ON `users` FOR EACH ROW BEGIN
    DECLARE changes TEXT;
    DECLARE admin_username VARCHAR(100);
    SET changes = '';

    IF OLD.username != NEW.username THEN
        SET changes = CONCAT(changes, 'Username changed from ', OLD.username, ' to ', NEW.username, '. ');
    END IF;
    IF OLD.email != NEW.email THEN
        SET changes = CONCAT(changes, 'Email changed from ', OLD.email, ' to ', NEW.email, '. ');
    END IF;
    IF OLD.role_id != NEW.role_id THEN
        SET changes = CONCAT(changes, 'Role changed from ', OLD.role_id, ' to ', NEW.role_id, '. ');
    END IF;
    IF OLD.status != NEW.status THEN
        SET changes = CONCAT(changes, 'Status changed from ', OLD.status, ' to ', NEW.status, '. ');
    END IF;

    SELECT username INTO admin_username FROM users WHERE id = @userId;

    INSERT INTO change_logs (admin_username, table_name, action, details)
    VALUES (admin_username, 'users', 'update', CONCAT('Updated user ID ', OLD.id, ': ', changes));
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user_roles`
--

CREATE TABLE `user_roles` (
  `role_id` int(11) NOT NULL,
  `role_name` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_roles`
--

INSERT INTO `user_roles` (`role_id`, `role_name`) VALUES
(1, 'superadmin'),
(2, 'scheduleadmin'),
(3, 'shopadmin'),
(4, 'client');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `appointments`
--
ALTER TABLE `appointments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `appointments_ibfk_1` (`user_id`);

--
-- Indexes for table `appointment_history`
--
ALTER TABLE `appointment_history`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `change_logs`
--
ALTER TABLE `change_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `services`
--
ALTER TABLE `services`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD KEY `role_id` (`role_id`);

--
-- Indexes for table `user_roles`
--
ALTER TABLE `user_roles`
  ADD PRIMARY KEY (`role_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `appointments`
--
ALTER TABLE `appointments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT for table `appointment_history`
--
ALTER TABLE `appointment_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

--
-- AUTO_INCREMENT for table `change_logs`
--
ALTER TABLE `change_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=57;

--
-- AUTO_INCREMENT for table `services`
--
ALTER TABLE `services`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `user_roles`
--
ALTER TABLE `user_roles`
  MODIFY `role_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `appointments`
--
ALTER TABLE `appointments`
  ADD CONSTRAINT `appointments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `appointments_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `user_roles` (`role_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
