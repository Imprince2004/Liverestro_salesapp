const { db } = require('../config/database');

exports.checkIn = async (req, res) => {
  try {
    const userId = req.user.id;
    const { lat, lng, time } = req.body;

    const active = await db.getActiveAttendance(userId);
    if (active) {
      return res.status(400).json({
        success: false,
        message: 'You are already checked in.',
        data: active
      });
    }

    const checkInRecord = await db.createAttendance(userId, time, lat, lng);
    return res.status(201).json({
      success: true,
      message: 'Checked in successfully.',
      data: checkInRecord
    });
  } catch (error) {
    console.error('checkIn error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to record check-in.'
    });
  }
};

exports.checkOut = async (req, res) => {
  try {
    const userId = req.user.id;
    const { lat, lng, time, is_automatic } = req.body;

    const active = await db.getActiveAttendance(userId);
    if (!active) {
      return res.status(404).json({
        success: false,
        message: 'No active check-in found.'
      });
    }

    const checkOutRecord = await db.updateAttendanceCheckOut(userId, time, lat, lng, is_automatic);
    return res.status(200).json({
      success: true,
      message: 'Checked out successfully.',
      data: checkOutRecord
    });
  } catch (error) {
    console.error('checkOut error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to record check-out.'
    });
  }
};

exports.getActive = async (req, res) => {
  try {
    const userId = req.user.id;
    const active = await db.getActiveAttendance(userId);
    return res.status(200).json({
      success: true,
      data: active
    });
  } catch (error) {
    console.error('getActive error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve active check-in.'
    });
  }
};

exports.getHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const history = await db.getAttendanceHistory(userId);
    return res.status(200).json({
      success: true,
      data: history
    });
  } catch (error) {
    console.error('getHistory error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve attendance history.'
    });
  }
};
