const express = require('express');
const { userService } = require('../grpc-clients');

const router = express.Router();

// Create User
router.post('/', async (req, res) => {
  try {
    const { name, email, phone, address } = req.body;

    if (!name || !email) {
      return res.status(400).json({ error: 'Name and email are required' });
    }

    const response = await userService.createUser({
      name,
      email,
      phone: phone || '',
      address: address || ''
    });

    res.status(201).json({
      success: true,
      data: response.user,
      message: response.message
    });
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({
      success: false,
      error: error.details || 'Failed to create user'
    });
  }
});

// Get User by ID
router.get('/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id);

    if (isNaN(id)) {
      return res.status(400).json({ error: 'Invalid user ID' });
    }

    const response = await userService.getUser({ id });

    res.json({
      success: true,
      data: response.user
    });
  } catch (error) {
    console.error('Error getting user:', error);
    
    if (error.code === grpc.status.NOT_FOUND) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.status(500).json({
      success: false,
      error: error.details || 'Failed to get user'
    });
  }
});

// Update User
router.put('/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const { name, email, phone, address } = req.body;

    if (isNaN(id)) {
      return res.status(400).json({ error: 'Invalid user ID' });
    }

    const response = await userService.updateUser({
      id,
      name: name || '',
      email: email || '',
      phone: phone || '',
      address: address || ''
    });

    res.json({
      success: true,
      data: response.user,
      message: response.message
    });
  } catch (error) {
    console.error('Error updating user:', error);
    
    if (error.code === 5) { // NOT_FOUND
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.status(500).json({
      success: false,
      error: error.details || 'Failed to update user'
    });
  }
});

// Delete User
router.delete('/:id', async (req, res) => {
  try {
    const id = parseInt(req.params.id);

    if (isNaN(id)) {
      return res.status(400).json({ error: 'Invalid user ID' });
    }

    const response = await userService.deleteUser({ id });

    res.json({
      success: response.success,
      message: response.message
    });
  } catch (error) {
    console.error('Error deleting user:', error);
    
    if (error.code === 5) { // NOT_FOUND
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.status(500).json({
      success: false,
      error: error.details || 'Failed to delete user'
    });
  }
});

// List Users
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;

    const response = await userService.listUsers({ page, limit });

    res.json({
      success: true,
      data: response.users,
      pagination: {
        page,
        limit,
        total: response.total
      }
    });
  } catch (error) {
    console.error('Error listing users:', error);
    res.status(500).json({
      success: false,
      error: error.details || 'Failed to list users'
    });
  }
});

// Validate User
router.get('/:id/validate', async (req, res) => {
  try {
    const user_id = parseInt(req.params.id);

    if (isNaN(user_id)) {
      return res.status(400).json({ error: 'Invalid user ID' });
    }

    const response = await userService.validateUser({ user_id });

    res.json({
      success: true,
      is_valid: response.is_valid,
      user: response.user
    });
  } catch (error) {
    console.error('Error validating user:', error);
    res.status(500).json({
      success: false,
      error: error.details || 'Failed to validate user'
    });
  }
});

module.exports = router;

