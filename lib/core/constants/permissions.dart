/// Centralized Permission Keys for RBAC Authorization
class AppPermissions {
  AppPermissions._();

  // Super Admin
  static const String fullSystemControl = 'full_system_control';
  static const String manageAllOrganizations = 'manage_all_organizations';
  static const String createCompanies = 'create_companies';
  static const String editCompanies = 'edit_companies';
  static const String deactivateCompanies = 'deactivate_companies';
  static const String manageCompanyAdminUsers = 'manage_company_admin_users';
  static const String viewAllUsers = 'view_all_users';
  static const String manageGlobalRolesPermissions = 'manage_global_roles_permissions';
  static const String viewSystemWideAnalytics = 'view_system_wide_analytics';
  static const String manageSubscriptionsPlans = 'manage_subscriptions_plans';
  static const String viewAuditLogs = 'view_audit_logs';
  static const String manageGlobalSettings = 'manage_global_settings';
  static const String viewSystemHealthIntegrations = 'view_system_health_integrations';

  // Company Admin
  static const String manageOrganizationProfile = 'manage_organization_profile';
  static const String createSalesManagers = 'create_sales_managers';
  static const String manageSalesManagers = 'manage_sales_managers';
  static const String createSalesExecutives = 'create_sales_executives';
  static const String manageSalesExecutives = 'manage_sales_executives';
  static const String activateDeactivateUsers = 'activate_deactivate_users';
  static const String assignExecutivesToManagers = 'assign_executives_to_managers';
  static const String manageRestaurants = 'manage_restaurants';
  static const String manageLeads = 'manage_leads';
  static const String viewVisits = 'view_visits';
  static const String viewFollowUps = 'view_follow_ups';
  static const String manageTasks = 'manage_tasks';
  static const String viewAttendance = 'view_attendance';
  static const String viewTeamReports = 'view_team_reports';
  static const String manageProductsPriceLists = 'manage_products_price_lists';
  static const String manageOrganizationSettings = 'manage_organization_settings';
  static const String viewOrganizationNotifications = 'view_organization_notifications';

  // Sales Manager
  static const String viewAssignedExecutives = 'view_assigned_executives';
  static const String viewTeamPerformance = 'view_team_performance';
  static const String viewTeamLeads = 'view_team_leads';
  static const String viewTeamVisits = 'view_team_visits';
  static const String createTasks = 'create_tasks';
  static const String assignTasksToExecutives = 'assign_tasks_to_executives';
  static const String assignRestaurantVisits = 'assign_restaurant_visits';
  static const String assignAreaTerritoryVisits = 'assign_area_territory_visits';
  static const String assignLeadFollowUps = 'assign_lead_follow_ups';
  static const String scheduleDemosMeetings = 'schedule_demos_meetings';
  static const String reassignTasks = 'reassign_tasks';
  static const String monitorTaskProgress = 'monitor_task_progress';
  static const String reviewCompletedTasks = 'review_completed_tasks';
  static const String addManagerNotes = 'add_manager_notes';

  // Sales Executive
  static const String viewAssignedLeads = 'view_assigned_leads';
  static const String createLeads = 'create_leads';
  static const String viewAssignedRestaurants = 'view_assigned_restaurants';
  static const String addRestaurants = 'add_restaurants';
  static const String recordVisits = 'record_visits';
  static const String checkInCheckOut = 'check_in_check_out';
  static const String captureGps = 'capture_gps';
  static const String captureSelfie = 'capture_selfie';
  static const String recordVoiceNotes = 'record_voice_notes';
  static const String generateAiVisitSummaries = 'generate_ai_visit_summaries';
  static const String createFollowUps = 'create_follow_ups';
  static const String viewAssignedTasks = 'view_assigned_tasks';
  static const String updateTaskStatus = 'update_task_status';
  static const String addTaskNotes = 'add_task_notes';
  static const String uploadPhotosDocuments = 'upload_photos_documents';
  static const String viewAssignedTaskLocation = 'view_assigned_task_location';
  static const String navigateToAssignedRestaurants = 'navigate_to_assigned_restaurants';
  static const String completeAssignedTasks = 'complete_assigned_tasks';
  static const String viewOwnAttendancePerformance = 'view_own_attendance_performance';
}
