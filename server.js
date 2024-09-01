const express = require('express');
const session = require('express-session');
const mysql = require('mysql');
const path = require('path');

const app = express();
const port = 3300;

// Create a connection to MySQL database
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'my_db'
});

// Connect to MySQL
db.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL database:', err);
    return;
  }
  console.log('Connected to MySQL database');
});

// Middleware to enable session management
app.use(session({
  secret: 'your_secret_key_here',
  resave: false,
  saveUninitialized: false
}));

// Middleware to parse JSON bodies
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from the 'public' directory
app.use(express.static(path.join(__dirname, 'public')));

// Serve the homepage.html file
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'homepage.html'));
});

// Handle signup form submission
app.post('/signup', (req, res) => {
  const { fullname, email, username, password } = req.body;

  // Check if the username or email already exists in the database
  const checkQuery = 'SELECT * FROM users WHERE username = ? OR email = ?';
  db.query(checkQuery, [username, email], (checkErr, checkResult) => {
    if (checkErr) {
      console.error('Error checking username or email:', checkErr);
      res.status(500).send('Error registering user');
      return;
    }

    // If a user with the same username or email already exists, send a response indicating the conflict
    if (checkResult.length > 0) {
      res.status(409).send('username or email already exists');
      return;
    }

    // Insert user data into the 'users' table if no conflicts found
    const insertQuery = 'INSERT INTO users (fullname, email, username, password) VALUES (?, ?, ?, ?)';
    db.query(insertQuery, [fullname, email, username, password], (insertErr, insertResult) => {
      if (insertErr) {
        console.error('Error inserting user data into database:', insertErr);
        res.status(500).send('Error registering user');
        return;
      }
      console.log('User registered successfully');
      res.status(201).send('User registered successfully');
    });
  });
});

// Handle login form submission
app.post('/login', (req, res) => {
  const { username, password } = req.body;

  // Query the database to authenticate the user
  const query = 'SELECT * FROM users WHERE username = ? AND password = ?';
  db.query(query, [username, password], (err, results) => {
    if (err) {
      console.error('Error authenticating user:', err);
      res.status(500).send('Internal server error');
      return;
    }

    // Check if user was found
    if (results.length === 0) {
      res.status(401).send('Invalid username or password');
      return;
    }

    // User authenticated successfully
    const user = results[0];
    req.session.user = { username };
    req.session.userId = results[0].id;
    res.status(200).json({
      message: 'Login successful',
      username: user.username, // Include the username in the response
      role_id: user.role_id // Include the role_id in the response
    });
  });
});

// Middleware to set the session variable in MySQL
app.use((req, res, next) => {
  if (req.session.userId) {
    const setSessionVariableQuery = `SET @userId = ${req.session.userId}`;
    db.query(setSessionVariableQuery, (err) => {
      if (err) {
        console.error('Error setting MySQL session variable:', err);
        return res.status(500).json({ error: 'Internal server error' });
      }
      next();
    });
  } else {
    next();
  }
});

// Route to fetch currently logged-in user's information
app.get('/current-user', (req, res) => {
  const userId = req.session.userId;
  const currentUser = req.session.user;
  if (currentUser) {
    const query = 'SELECT username FROM users WHERE id = ?';
    db.query(query, [userId], (err, results) => {
      if (err) {
        res.status(500).json({ message: 'Internal Server Error' });
        return; // Add return to exit from the callback
      }

      if (results.length > 0) {
        res.status(200).json({ user: { id: userId, username: results[0].username } });
      } else {
        res.status(404).json({ message: 'User not found' });
      }
    });
  } else {
    res.status(401).json({ message: 'User not logged in' });
  }
});


// Add a new route to handle fetching user statistics
app.get('/user-statistics', (req, res) => {
  // Query to fetch user statistics from the database
  const query = `
      SELECT
          COUNT(*) AS totalUsers,
          SUM(CASE WHEN role_id IN (2, 3) THEN 1 ELSE 0 END) AS adminUsers,
          SUM(CASE WHEN role_id = 4 THEN 1 ELSE 0 END) AS clientUsers,
          SUM(CASE WHEN role_id = 1 THEN 1 ELSE 0 END) AS superadminUsers,
          SUM(CASE WHEN DATE(created_at) = CURDATE() THEN 1 ELSE 0 END) AS newUsersToday,
          SUM(CASE WHEN WEEK(created_at) = WEEK(NOW()) THEN 1 ELSE 0 END) AS newUsersThisWeek,
          SUM(CASE WHEN MONTH(created_at) = MONTH(NOW()) THEN 1 ELSE 0 END) AS newUsersThisMonth
      FROM users
  `;

  // Execute the query
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching user statistics:', err);
      res.status(500).send('Internal server error');
      return;
    }

    // Send the user statistics as JSON response
    res.json(results[0]);
  });
});

//Start for Manage-Users for Superadmin

// Add a new route to handle fetching user data with role names and creation date
app.get('/users', (req, res) => {
  // Extract search term and role filter from query parameters
  const { search, role } = req.query;

  // Construct the SQL query to fetch user data including role names and creation date
  let query = `
    SELECT users.id, users.username, users.email, user_roles.role_name AS role, users.created_at, users.status
    FROM users
    INNER JOIN user_roles ON users.role_id = user_roles.role_id
  `;

  // Add WHERE clause if search term is provided
  if (search) {
    query += ` WHERE username LIKE '%${search}%' OR email LIKE '%${search}%'`;
  }

  // Add WHERE clause if role filter is provided
  if (role) {
    query += ` AND user_roles.role_name = '${role}'`;
  }

  // Execute the query
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching user data:', err);
      res.status(500).send('Internal server error');
      return;
    }

    // Send the user data as JSON response
    res.json(results);
  });
});

// Fetch user data by ID for editing
app.get('/users/:userId', (req, res) => {
  const userId = req.params.userId;
  // Query the database to fetch user data by ID
  const query = 'SELECT * FROM users WHERE id = ?';
  db.query(query, [userId], (err, results) => {
    if (err) {
      console.error('Error fetching user data:', err);
      res.status(500).send('Internal server error');
      return;
    }
    // Check if user was found
    if (results.length === 0) {
      res.status(404).send('User not found');
      return;
    }
    // User data found, send it as JSON response
    res.json(results[0]);
  });
});

// Handle user update (PUT request)
app.put('/users/:userId', (req, res) => {
  const userId = req.params.userId;
  const { username, email, password, role, status } = req.body;

  // Update user data in the database
  const updateQuery = 'UPDATE users SET username = ?, email = ?, password = ?, role_id = ?, status = ? WHERE id = ?';
  db.query(updateQuery, [username, email, password, role, status, userId], (err, result) => {
    if (err) {
      console.error('Error updating user:', err);
      res.status(500).send('Internal server error');
      return;
    }
    console.log('User updated successfully');
    res.status(200).send('User updated successfully');
  });
});


//For Delete user button
// Handle user deletion
app.delete('/users/:userId', (req, res) => {
  const userId = req.params.userId;
  // Perform deletion logic (e.g., delete user with the provided ID from the database)
  db.query('DELETE FROM users WHERE id = ?', [userId], (err, result) => {
    if (err) {
      console.error('Error deleting user:', err);
      res.status(500).send('Internal server error');
      return;
    }
    console.log('User deleted successfully');
    res.status(200).send('User deleted successfully');
  });
});

//For add user form submission
app.post('/users', (req, res) => {
  const { username, email, role, status, password } = req.body;

  // Check if the username or email already exists in the database
  const checkQuery = 'SELECT * FROM users WHERE username = ? OR email = ?';
  db.query(checkQuery, [username, email], (checkErr, checkResult) => {
    if (checkErr) {
      console.error('Error checking username or email:', checkErr);
      res.status(500).send('Error adding user');
      return;
    }

    // If a user with the same username or email already exists, send a response indicating the conflict
    if (checkResult.length > 0) {
      res.status(409).send('Username or email already exists');
      return;
    }

    // Insert user data into the 'users' table if no conflicts found
    const insertQuery = 'INSERT INTO users (username, email, role_id, status, password) VALUES (?, ?, (SELECT role_id FROM user_roles WHERE role_name = ?), ?, ?)';
    db.query(insertQuery, [username, email, role, status, password], (insertErr, insertResult) => {
      if (insertErr) {
        console.error('Error adding user:', insertErr);
        res.status(500).send('Error adding user');
        return;
      }
      console.log('User added successfully');
      res.status(201).send('User added successfully');
    });
  });
});
//End for Mange-Users for Superadmin

// Route to get change logs
app.get('/api/logs', (req, res) => {
  const query = 'SELECT * FROM change_logs ORDER BY timestamp DESC';

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching logs:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    res.json(results);
  });
});

// End for superadmin

//For Sched Admin
// Define route to fetch scheduling operation data based on interval
app.get('/scheduling/overview', (req, res) => {
  // Retrieve the interval from the query parameters
  const { interval } = req.query;

  // Construct the SQL query based on the interval
  let sqlQuery;
  switch (interval) {
    case 'last-month':
      sqlQuery = `
        SELECT 
            COUNT(*) AS total_appointments,
            SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_appointments,
            SUM(CASE WHEN status = 'Confirmed' THEN 1 ELSE 0 END) AS confirmed_appointments,
            SUM(CASE WHEN status = 'Ongoing' THEN 1 ELSE 0 END) AS ongoing_appointments,
            SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_appointments,
            SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_appointments
        FROM 
            appointments
        WHERE
            created_at >= DATE_FORMAT(CURDATE() - INTERVAL 1 MONTH, '%Y-%m-01')
            AND created_at < DATE_FORMAT(CURDATE(), '%Y-%m-01');`;
      break;
    case 'today':
      sqlQuery = `
              SELECT 
                  COUNT(*) AS total_appointments,
                  SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_appointments,
                  SUM(CASE WHEN status = 'Confirmed' THEN 1 ELSE 0 END) AS confirmed_appointments,
                  SUM(CASE WHEN status = 'Ongoing' THEN 1 ELSE 0 END) AS ongoing_appointments,
                  SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_appointments,
                  SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_appointments
              FROM 
                  appointments
              WHERE
                  DATE(created_at) = CURDATE();`;
      break;
    case 'monthly':
      sqlQuery = `
              SELECT 
                  COUNT(*) AS total_appointments,
                  SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_appointments,
                  SUM(CASE WHEN status = 'Confirmed' THEN 1 ELSE 0 END) AS confirmed_appointments,
                  SUM(CASE WHEN status = 'Ongoing' THEN 1 ELSE 0 END) AS ongoing_appointments,
                  SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_appointments,
                  SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_appointments
              FROM 
                  appointments
              WHERE
                  MONTH(created_at) = MONTH(CURRENT_DATE())
                  AND YEAR(created_at) = YEAR(CURRENT_DATE());`;
      break;
    case 'yearly':
      sqlQuery = `
              SELECT 
                  COUNT(*) AS total_appointments,
                  SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) AS pending_appointments,
                  SUM(CASE WHEN status = 'Confirmed' THEN 1 ELSE 0 END) AS confirmed_appointments,
                  SUM(CASE WHEN status = 'Ongoing' THEN 1 ELSE 0 END) AS ongoing_appointments,
                  SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) AS completed_appointments,
                  SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_appointments
              FROM 
                  appointments
              WHERE
                  YEAR(created_at) = YEAR(CURRENT_DATE());`;
      break;
    default:
      // Invalid interval provided
      return res.status(400).json({ error: 'Invalid interval' });
  }

  // Execute the SQL query using the db connection
  db.query(sqlQuery, (err, results) => {
    if (err) {
      console.error('Error executing SQL query:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    // Send scheduling operation data as JSON response
    res.json(results[0]);
  });
});

// Route to fetch today's confirmed appointments
app.get('/api/appointments/today', (req, res) => {
  const today = new Date().toISOString().split('T')[0]; // Get today's date in YYYY-MM-DD format
  const sql = `
    SELECT a.*, u.username AS owner_username 
    FROM appointments a 
    LEFT JOIN users u ON a.user_id = u.id
    WHERE a.appointment_date = ? AND a.status = 'confirmed'
  `;

  db.query(sql, [today], (err, results) => {
    if (err) {
      console.error('Error fetching today\'s appointments:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    // Transform the results to handle multiple purposes
    const appointments = results.map(appointment => ({
      ...appointment,
      purpose: appointment.purpose ? appointment.purpose.split(',') : []
    }));

    // Send the fetched appointments as JSON response
    res.json(appointments);
  });
});

// Route to update an appointment status by ID (working)
app.put('/api/appointments/:id/status', (req, res) => {
  const appointmentId = req.params.id;
  const { status } = req.body;

  // Update query for the appointment status
  const updateQuery = 'UPDATE appointments SET status = ? WHERE id = ?';

  db.query(updateQuery, [status, appointmentId], (err, result) => {
    if (err) {
      console.error('Error updating appointment status:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    res.json({ success: true, message: 'Appointment status updated successfully' });
  });
});

// Route to fetch all pending appointments (working)
app.get('/api/appointments/pending', (req, res) => {
  const sql = 'SELECT a.*, u.username AS owner_username FROM appointments a LEFT JOIN users u ON a.user_id = u.id WHERE a.status = "Pending"';

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching pending appointments:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    const appointments = results.map(appointment => ({
      ...appointment,
      purpose: appointment.purpose ? appointment.purpose.split(',') : []
    }));

    res.json(appointments);
  });
});

// Route to reschedule an appointment by ID (with conflict check)
app.put('/api/appointments/:id/reschedule', (req, res) => {
  const appointmentId = req.params.id;
  const { appointment_date, appointment_time } = req.body;

  // Server-side validation
  const currentDate = new Date();
  const selectedDate = new Date(appointment_date);
  const [hours, minutes] = appointment_time.split(':').map(Number);

  if (selectedDate < currentDate.setHours(0, 0, 0, 0)) {
    res.status(400).json({ error: 'The appointment date cannot be in the past or today.' });
    return;
  }

  if (hours < 9 || hours > 16 || (hours === 16 && minutes > 0)) {
    res.status(400).json({ error: 'The appointment time must be between 9:00 AM and 4:00 PM.' });
    return;
  }

  // Query to check for conflicting appointments
  const conflictQuery = `
    SELECT COUNT(*) AS count
    FROM appointments
    WHERE appointment_date = ? AND appointment_time = ? AND status IN ('pending', 'confirmed') AND id != ?
  `;

  db.query(conflictQuery, [appointment_date, appointment_time, appointmentId], (err, result) => {
    if (err) {
      console.error('Error checking for conflicts:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    if (result[0].count > 0) {
      res.status(409).json({ error: 'The selected date and time are already occupied by another appointment.' });
      return;
    }

    // Query to update the appointment
    const updateQuery = 'UPDATE appointments SET appointment_date = ?, appointment_time = ? WHERE id = ?';

    db.query(updateQuery, [appointment_date, appointment_time, appointmentId], (err, result) => {
      if (err) {
        console.error('Error rescheduling appointment:', err);
        res.status(500).json({ error: 'Internal server error' });
        return;
      }

      res.json({ success: true, message: 'Appointment rescheduled successfully' });
    });
  });
});


//For manage-sched-data
// Route to fetch all appointments
app.get('/api/appointments', (req, res) => {
  // Query to fetch all appointments from the database
  const sql = 'SELECT a.*, u.username AS owner_username FROM appointments a LEFT JOIN users u ON a.user_id = u.id';

  // Execute the query
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching appointments:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    // Transform the results to handle multiple purposes
    const appointments = results.map(appointment => ({
      ...appointment,
      purpose: appointment.purpose ? appointment.purpose.split(',') : []
    }));

    // Send the fetched appointments as JSON response
    res.json(results);
  });
});

// Route to fetch appointment details by ID
app.get('/api/appointments/:id', (req, res) => {
  const appointmentId = req.params.id;

  // Query to fetch appointment details by ID from the database
  const sql = 'SELECT a.*, u.username AS owner_username FROM appointments a LEFT JOIN users u ON a.user_id = u.id WHERE a.ID = ?';

  // Execute the query with the appointment ID as parameter
  db.query(sql, [appointmentId], (err, results) => {
    if (err) {
      console.error('Error fetching appointment details:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    // Check if appointment with the specified ID exists
    if (results.length === 0) {
      res.status(404).json({ error: 'Appointment not found' });
      return;
    }

    // Send the fetched appointment details as JSON response
    res.json(results[0]);
  });
});

// Route to update an appointment by ID
app.put('/api/appointments/:id', (req, res) => {
  const appointmentId = req.params.id;
  const { appointment_date, appointment_time, purpose, status } = req.body;

  // Ensure to fetch the current values for unchangeable fields if needed
  const getAppointmentQuery = 'SELECT pet_name, user_id, species FROM appointments WHERE id = ?';

  db.query(getAppointmentQuery, [appointmentId], (err, appointmentResult) => {
    if (err) {
      console.error('Error fetching appointment details:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    if (appointmentResult.length === 0) {
      res.status(404).json({ error: 'Appointment not found' });
      return;
    }

    const { pet_name, user_id, species } = appointmentResult[0];

    // Server-side validation
    const currentDate = new Date();
    const selectedDate = new Date(appointment_date);
    const [hours, minutes] = appointment_time.split(':').map(Number);

    if (selectedDate < currentDate.setHours(0, 0, 0, 0)) {
      res.status(400).json({ error: 'The appointment date cannot be in the past or today.' });
      return;
    }

    if (hours < 9 || hours > 16 || (hours === 16 && minutes > 0)) {
      res.status(400).json({ error: 'The appointment time must be between 9:00 AM and 4:00 PM.' });
      return;
    }

    // Query to check if the appointment date and time are already taken
    const checkAvailabilityQuery = 'SELECT COUNT(*) AS count FROM appointments WHERE appointment_date = ? AND appointment_time = ? AND id != ?';

    db.query(checkAvailabilityQuery, [appointment_date, appointment_time, appointmentId], (err, availabilityResult) => {
      if (err) {
        console.error('Error checking appointment availability:', err);
        res.status(500).json({ error: 'Internal server error' });
        return;
      }

      if (availabilityResult[0].count > 0) {
        res.status(400).json({ error: 'The appointment date and time are already taken.' });
        return;
      }

      // Update query for the appointment
      const updateQuery = 'UPDATE appointments SET pet_name = ?, user_id = ?, species = ?, appointment_date = ?, appointment_time = ?, purpose = ?, status = ? WHERE id = ?';

      db.query(updateQuery, [pet_name, user_id, species, appointment_date, appointment_time, purpose.join(','), status, appointmentId], (err, result) => {
        if (err) {
          console.error('Error updating appointment:', err);
          res.status(500).json({ error: 'Internal server error' });
          return;
        }

        res.json({ success: true, message: 'Appointment updated successfully' });
      });
    });
  });
});


// Route to delete an appointment by ID
app.delete('/api/appointments/:id', (req, res) => {
  const appointmentId = req.params.id;

  const sql = 'DELETE FROM appointments WHERE id = ?';

  db.query(sql, [appointmentId], (err, result) => {
    if (err) {
      console.error('Error deleting appointment:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    if (result.affectedRows === 0) {
      res.status(404).json({ error: 'Appointment not found' });
      return;
    }

    res.json({ message: 'Appointment deleted successfully' });
  });
});

// Handle search request
app.get('/search', (req, res) => {
  const { searchQuery, criteria, status } = req.query;

  let query = `
    SELECT appointments.id, appointments.pet_name, users.username AS owner_username, appointments.species, 
           appointments.appointment_date, appointments.appointment_time, appointments.purpose, appointments.status 
    FROM appointments 
    JOIN users ON appointments.user_id = users.id
    WHERE 1 = 1
  `;
  const params = [];

  if (searchQuery) {
    if (criteria === 'owner_username') {
      query += ' AND users.username LIKE ?';
    } else {
      query += ` AND appointments.${criteria} LIKE ?`;
    }
    const searchPattern = `%${searchQuery}%`;
    params.push(searchPattern);
  }

  if (status) {
    query += ' AND appointments.status = ?';
    params.push(status);
  }

  db.query(query, params, (err, results) => {
    if (err) {
      console.error('Error searching appointments:', err);
      res.status(500).send('Internal server error');
      return;
    }
    res.json(results);
  });
});

// For History/Completed Appointments
// Route to fetch completed appointments
app.get('/api/completed-appointments', (req, res) => {
  // Query to fetch completed appointments from the database
  const sql = 'SELECT a.*, u.username AS owner_username FROM appointments a LEFT JOIN users u ON a.user_id = u.id WHERE a.status = "Completed"';

  // Execute the query
  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching completed appointments:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    // Send the fetched completed appointments as JSON response
    res.json(results);
  });
});

// Route to fetch appointment history
app.get('/api/appointment-history', (req, res) => {
  // Query the appointment history table in the database and return the data
  const sql = 'SELECT * FROM appointment_history';

  db.query(sql, (err, results) => {
    if (err) {
      console.error('Error fetching appointment history:', err);
      res.status(500).json({ error: 'Internal server error' });
      return;
    }

    // Send the fetched appointment history as JSON response
    res.json(results);
  });
});

//End for Sched Admin

// Start for Client
// Check for existing appointment slot
app.post('/check-appointment', (req, res) => {
  const { date, time, userId } = req.body;

  // Check if the date is beyond the next three days from today
  const today = new Date();
  const appointmentDate = new Date(date);
  const threeDaysFromNow = new Date(today);
  threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

  if (appointmentDate <= threeDaysFromNow) {
    return res.json({ valid: false, message: 'Appointment date must be beyond the next 3 days and not today or from the past.' });
  }

  // Check if the time is within the allowed range
  const appointmentTime = new Date(`1970-01-01T${time}:00`);
  const startTime = new Date('1970-01-01T09:00:00');
  const endTime = new Date('1970-01-01T16:00:00');
  if (appointmentTime < startTime || appointmentTime > endTime) {
    return res.json({ valid: false, message: 'Appointment time must be between 9 AM and 4 PM.' });
  }

  const query = 'SELECT * FROM appointments WHERE appointment_date = ? AND appointment_time = ? and (status = "Pending" OR status = "Confirmed")';
  db.query(query, [date, time], (err, results) => {
    if (err) throw err;
    if (results.length > 0) {
      return res.json({ valid: false, message: 'This appointment slot is already booked. Please choose another date or time.' });
    }

    // Check if there are already 8 Pending and Confirmed appointments on the same date
    const countQuery = 'SELECT COUNT(*) as count FROM appointments WHERE appointment_date = ? AND (status = "Pending" OR status = "Confirmed")';
    db.query(countQuery, [date], (err, countResults) => {
      if (err) throw err;
      if (countResults[0].count >= 8) {
        return res.json({ valid: false, message: 'All slots are occupied on this date. Please choose another date.' });
      }

      // Check if the user already has an appointment on the selected date
      const userQuery = 'SELECT * FROM appointments WHERE appointment_date = ? AND user_id = ? AND (status = "Pending" OR status = "Confirmed")';
      db.query(userQuery, [date, userId], (err, userResults) => {
        if (err) throw err;
        if (userResults.length > 0) {
          return res.json({ valid: false, message: 'You already have an appointment on this date.' });
        }

        res.json({ valid: true });
      });
    });
  });
});


// Check for pending appointments
app.get('/check-pending-appointments', (req, res) => {
  const userId = req.session.userId; // Assuming userId is stored in session
  const query = 'SELECT COUNT(*) as count FROM appointments WHERE user_id = ? AND status = "Pending"';
  db.query(query, [userId], (err, results) => {
    if (err) throw err;
    res.json({ count: results[0].count });
  });
});

// Create new appointment
app.post('/create-appointment', (req, res) => {
  const { petName, species, date, time, purposes } = req.body;
  const userId = req.session.userId; // Assuming userId is stored in session
  const purposesString = purposes.join(',');
  const query = 'INSERT INTO appointments (pet_name, species, appointment_date, appointment_time, purpose, status, user_id) VALUES (?, ?, ?, ?, ?, "Pending", ?)';
  db.query(query, [petName, species, date, time, purposesString, userId], (err, results) => {
    if (err) throw err;
    res.json({ success: true });
  });
});

// Get all appointments
app.get('/get-appointments', (req, res) => {
  const userId = req.session.userId; // Assuming userId is stored in session
  const query = 'SELECT * FROM appointments WHERE user_id = ? ORDER BY appointment_date DESC, appointment_time DESC';
  db.query(query, [userId], (err, results) => {
    if (err) throw err;
    res.json(results);
  });
});

// Cancel appointment
app.post('/cancel-appointment/:id', (req, res) => {
  const appointmentId = req.params.id;
  const query = 'UPDATE appointments SET status = "Cancelled" WHERE id = ?';
  db.query(query, [appointmentId], (err, results) => {
    if (err) throw err;
    res.json({ success: true });
  });
});

// Route to fetch user details
app.get('/user-details', (req, res) => {
  const userId = req.session.userId;
  const currentUser = req.session.user;
  if (currentUser) {
    const query = 'SELECT id, fullname, email, username, role_id, created_at FROM users WHERE id = ?';
    db.query(query, [userId], (err, results) => {
      if (err) {
        res.status(500).json({ message: 'Internal Server Error' });
        return;
      }

      if (results.length > 0) {
        const userDetails = {
          id: results[0].id,
          fullname: results[0].fullname,
          email: results[0].email,
          username: results[0].username,
          role_id: results[0].role_id,
          created_at: results[0].created_at
        };
        res.status(200).json({ user: userDetails });
      } else {
        res.status(404).json({ message: 'User not found' });
      }
    });
  } else {
    res.status(401).json({ message: 'User not logged in' });
  }
});

// End for Client

//For logout
app.post('/logout', (req, res) => {
  // Perform any cleanup tasks if needed (e.g., clearing session data)
  // For example, if you're using express-session, you can destroy the session:
  req.session.destroy();

  // Send a success response indicating successful logout
  res.status(200).send('Logout successful');
});
//End for logout

// Start the server
app.listen(port, () => {
  console.log(`Server is listening at http://localhost:${port}`);
});
